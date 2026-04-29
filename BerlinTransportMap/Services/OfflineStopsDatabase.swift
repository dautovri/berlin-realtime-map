import Foundation

/// Per-city offline database of transport stops.
/// Loads from app bundle (Berlin only — other cities have no bundled stops yet)
/// or from a per-city cache, then keeps in-memory state for the active city.
/// Switching cities clears in-memory stops; the cache is preserved on disk under
/// a per-city filename so re-selecting a city is instant.
actor OfflineStopsDatabase {
    static let shared = OfflineStopsDatabase()

    private let fileManager = FileManager.default
    private let cacheDirectoryName = "TransportStops"
    private let cacheTTL: TimeInterval = 604800 // 7 days

    private var currentCity: CityConfig = .berlin
    private var allStops: [TransportStop] = []
    private var isLoaded = false

    // MARK: - Path helpers

    /// Bundle-only stops file. Berlin ships with `berlin_all_stops.json`; other
    /// cities have no bundle file (yet) and fall through to API fetch.
    private var bundledURL: URL? {
        let stem = "\(currentCity.id)_all_stops"
        return Bundle.main.url(forResource: stem, withExtension: "json")
            ?? Bundle.main.url(forResource: stem, withExtension: nil)
    }

    private var cacheDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent(cacheDirectoryName, isDirectory: true)
    }

    private var cachedFileURL: URL {
        cacheDirectoryURL.appendingPathComponent("\(currentCity.id)_all_stops_cached.json")
    }

    private var metadataFileURL: URL {
        cacheDirectoryURL.appendingPathComponent("\(currentCity.id)_stops_metadata.json")
    }

    private var applicationSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {}

    // MARK: - Public API

    /// Snapshot of which city's stops are currently in memory. Lets callers
    /// guard a search short-circuit so they don't serve Berlin stops to a Munich query.
    func activeCityId() -> String { currentCity.id }

    /// Switch the active city. Drops in-memory stops; the disk cache stays put.
    /// Subsequent `loadIfNeeded()` calls hydrate the new city.
    func switchCity(_ city: CityConfig) {
        guard city.id != currentCity.id else { return }
        currentCity = city
        allStops = []
        isLoaded = false
    }

    /// Load all stops for the active city — from bundle, then cache, then network.
    func loadIfNeeded() async {
        guard !isLoaded else { return }

        try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)

        if loadFromBundle() {
            print("OfflineStopsDatabase[\(currentCity.id)]: Loaded \(allStops.count) stops from app bundle")
            isLoaded = true
            return
        }

        if loadFromCache() {
            print("OfflineStopsDatabase[\(currentCity.id)]: Loaded \(allStops.count) stops from cache")
            isLoaded = true
            return
        }

        await downloadAndCache()
        isLoaded = true
    }

    func getAllStops() -> [TransportStop] {
        return allStops
    }

    /// Find stops near a location. Caller must verify they're querying the right city.
    func findStops(latitude: Double, longitude: Double, maxDistance: Int) -> [TransportStop] {
        let maxDistDouble = Double(maxDistance)
        // Bounding-box pre-filter — skip trig for clearly-out-of-range stops.
        // 1° latitude ≈ 111 km. For longitude, scale by cos(latitude) so the box
        // stays correct outside Berlin's specific latitude.
        let latMargin = maxDistDouble / 111_000.0
        let cosLat = cos(latitude * .pi / 180)
        let lonMargin = maxDistDouble / (111_000.0 * max(cosLat, 0.000_001))
        let minLat = latitude - latMargin
        let maxLat = latitude + latMargin
        let minLon = longitude - lonMargin
        let maxLon = longitude + lonMargin

        return allStops.filter { stop in
            guard stop.latitude >= minLat, stop.latitude <= maxLat,
                  stop.longitude >= minLon, stop.longitude <= maxLon else {
                return false
            }
            let distance = calculateDistance(
                lat1: latitude, lon1: longitude,
                lat2: stop.latitude, lon2: stop.longitude
            )
            return distance <= maxDistDouble
        }
    }

    func searchStops(query: String) -> [TransportStop] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        return allStops.filter { stop in
            stop.name.localizedStandardContains(trimmed)
        }
    }

    func refresh() async {
        await downloadAndCache()
    }

    // MARK: - Private

    private func loadFromBundle() -> Bool {
        guard let bundledURL, fileManager.fileExists(atPath: bundledURL.path) else {
            return false
        }

        do {
            let data = try Data(contentsOf: bundledURL)

            struct VBBStop: Decodable {
                let id: String?
                let name: String?
                let location: VBBLocation?
                let products: VBBProducts?
            }

            struct VBBLocation: Decodable {
                let latitude: Double?
                let longitude: Double?
            }

            struct VBBProducts: Decodable {
                let suburban: Bool?
                let subway: Bool?
                let tram: Bool?
                let bus: Bool?
                let ferry: Bool?
                let express: Bool?
                let regional: Bool?

                var toTransportProducts: [TransportProduct] {
                    var result: [TransportProduct] = []
                    if suburban == true { result.append(.suburbanTrain) }
                    if subway == true { result.append(.subway) }
                    if tram == true { result.append(.tram) }
                    if bus == true { result.append(.bus) }
                    if ferry == true { result.append(.ferry) }
                    if express == true { result.append(.highSpeedTrain) }
                    if regional == true { result.append(.regionalTrain) }
                    return result
                }
            }

            if let vbbStops = try? decoder.decode([VBBStop].self, from: data) {
                allStops = vbbStops.compactMap { vbbStop -> TransportStop? in
                    guard let id = vbbStop.id, let name = vbbStop.name else { return nil }
                    return TransportStop(
                        id: id,
                        name: name,
                        latitude: vbbStop.location?.latitude ?? 0,
                        longitude: vbbStop.location?.longitude ?? 0,
                        products: vbbStop.products?.toTransportProducts ?? []
                    )
                }
            } else if let transportStops = try? decoder.decode([TransportStop].self, from: data) {
                allStops = transportStops
            } else {
                print("OfflineStopsDatabase[\(currentCity.id)]: Unknown JSON format in bundled stops")
                return false
            }

            try? saveToCache()
            return true
        } catch {
            print("OfflineStopsDatabase[\(currentCity.id)]: Failed to load bundled stops: \(error)")
            return false
        }
    }

    private func loadFromCache() -> Bool {
        guard fileManager.fileExists(atPath: cachedFileURL.path) else {
            return false
        }

        do {
            let data = try Data(contentsOf: cachedFileURL)
            allStops = try decoder.decode([TransportStop].self, from: data)

            if let metadataData = try? Data(contentsOf: metadataFileURL),
               let metadata = try? decoder.decode(Metadata.self, from: metadataData) {
                let age = Date().timeIntervalSince(metadata.lastUpdated)
                if age > cacheTTL {
                    print("OfflineStopsDatabase[\(currentCity.id)]: Cache expired (\(Int(age / 86400)) days old), will refresh")
                }
            }

            return true
        } catch {
            print("OfflineStopsDatabase[\(currentCity.id)]: Failed to load cached stops: \(error)")
            return false
        }
    }

    private func saveToCache() throws {
        let data = try encoder.encode(allStops)
        try data.write(to: cachedFileURL)
        try excludeFromBackup(url: cachedFileURL)

        let metadata = Metadata(lastUpdated: Date(), stopCount: allStops.count)
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataFileURL)
        try excludeFromBackup(url: metadataFileURL)
    }

    private func excludeFromBackup(url: URL) throws {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(resourceValues)
    }

    private func downloadAndCache() async {
        // Snapshot the city we started with. The actor serializes calls but suspends
        // at every `await fetchStopsForArea`, which means `switchCity` can run between
        // network calls. Without this snapshot, a Berlin download mid-flight would
        // resume after a Munich switch and write Berlin data to munich_all_stops_cached.json
        // — poisoning the cache for the next launch.
        let cityAtStart = currentCity
        print("OfflineStopsDatabase[\(cityAtStart.id)]: Downloading stops...")

        do {
            var allStopsFetched: [TransportStop] = []

            // Per-city grid derived from CityConfig.boundingBox.
            let region = cityAtStart.boundingBox
            let centerLat = region.center.latitude
            let centerLon = region.center.longitude
            let halfLat = region.span.latitudeDelta / 2.0
            let halfLon = region.span.longitudeDelta / 2.0
            let minLat = centerLat - halfLat
            let maxLat = centerLat + halfLat
            let minLon = centerLon - halfLon
            let maxLon = centerLon + halfLon

            // ~5km lat steps; ~7km lon steps at ~52° (close enough for Germany).
            let latStep = 0.05
            let lonStep = 0.08

            for lat in stride(from: minLat, through: maxLat, by: latStep) {
                for lon in stride(from: minLon, through: maxLon, by: lonStep) {
                    // Bail if the active city changed mid-download. Don't poison
                    // the cache or claim isLoaded for a city we no longer care about.
                    guard currentCity.id == cityAtStart.id else {
                        print("OfflineStopsDatabase[\(cityAtStart.id)]: Aborted — city switched to \(currentCity.id) mid-download")
                        return
                    }
                    let stops = try await fetchStopsForArea(
                        latitude: lat,
                        longitude: lon,
                        distance: 8000,
                        baseURL: cityAtStart.apiBaseURL
                    )
                    allStopsFetched.append(contentsOf: stops)
                }
            }

            // Final guard before write — same race window as the loop guard.
            guard currentCity.id == cityAtStart.id else {
                print("OfflineStopsDatabase[\(cityAtStart.id)]: Aborted — city switched to \(currentCity.id) before write")
                return
            }

            var seenIds = Set<String>()
            allStops = allStopsFetched.filter { stop in
                if seenIds.contains(stop.id) { return false }
                seenIds.insert(stop.id)
                return true
            }

            try saveToCache()
            print("OfflineStopsDatabase[\(cityAtStart.id)]: Saved \(allStops.count) unique stops to cache")
        } catch {
            print("OfflineStopsDatabase[\(cityAtStart.id)]: Failed to download stops: \(error)")
        }
    }

    private func fetchStopsForArea(latitude: Double, longitude: Double, distance: Int, baseURL: String) async throws -> [TransportStop] {
        let urlString = "\(baseURL)/locations/nearby"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "distance", value: String(distance)),
            URLQueryItem(name: "results", value: "300"),
            URLQueryItem(name: "type", value: "station")
        ]

        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: finalURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct VBBLocationResponse: Decodable {
            let id: String?
            let name: String?
            let location: VBBLocationInner?

            struct VBBLocationInner: Decodable {
                let latitude: Double
                let longitude: Double
            }
        }

        let locations = try decoder.decode([VBBLocationResponse].self, from: data)

        return locations.map { resp in
            TransportStop(
                id: resp.id ?? UUID().uuidString,
                name: resp.name ?? "Unknown",
                latitude: resp.location?.latitude ?? 0,
                longitude: resp.location?.longitude ?? 0
            )
        }
    }

    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        return earthRadius * c
    }

    private struct Metadata: Codable {
        let lastUpdated: Date
        let stopCount: Int
    }
}
