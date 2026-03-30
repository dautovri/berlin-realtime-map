import Foundation

/// Offline database of all Berlin transport stops
/// Loads from app bundle on first launch, then caches to Application Support
/// Follows iOS 18+ best practices for file storage
actor OfflineStopsDatabase {
    static let shared = OfflineStopsDatabase()
    
    private let fileManager = FileManager.default
    private let bundledFileName = "berlin_all_stops"
    private let bundledExtension = "json"
    private let cacheDirectoryName = "TransportStops"
    private let stopsFileName = "berlin_all_stops_cached.json"
    private let metadataFileName = "berlin_stops_metadata.json"
    private let cacheTTL: TimeInterval = 604800 // 7 days
    
    private var allStops: [TransportStop] = []
    private var isLoaded = false
    
    private var bundledURL: URL {
        Bundle.main.url(forResource: bundledFileName, withExtension: bundledExtension) ?? Bundle.main.url(forResource: bundledFileName, withExtension: nil)!
    }
    
    private var cacheDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent(cacheDirectoryName, isDirectory: true)
    }
    
    private var cachedFileURL: URL {
        cacheDirectoryURL.appendingPathComponent(stopsFileName)
    }
    
    private var metadataFileURL: URL {
        cacheDirectoryURL.appendingPathComponent(metadataFileName)
    }
    
    private var applicationSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Load all stops - from bundle or cached file
    func loadIfNeeded() async {
        guard !isLoaded else { return }
        
        // Ensure cache directory exists
        try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        
        if loadFromBundle() {
            print("OfflineStopsDatabase: Loaded \(allStops.count) stops from app bundle")
            isLoaded = true
            return
        }
        
        if loadFromCache() {
            print("OfflineStopsDatabase: Loaded \(allStops.count) stops from cache")
            isLoaded = true
            return
        }
        
        // Download and cache on first launch
        await downloadAndCache()
        isLoaded = true
    }
    
    /// Get all stops
    func getAllStops() -> [TransportStop] {
        return allStops
    }
    
    /// Find stops near a location
    func findStops(latitude: Double, longitude: Double, maxDistance: Int) -> [TransportStop] {
        let maxDistDouble = Double(maxDistance)
        // Fast bounding-box pre-filter — skip trig for clearly-out-of-range stops.
        // 1 degree latitude ≈ 111 km; at Berlin's latitude, 1° longitude ≈ 65 km.
        let latMargin = maxDistDouble / 111_000.0
        let lonMargin = maxDistDouble / 65_000.0
        let minLat = latitude - latMargin
        let maxLat = latitude + latMargin
        let minLon = longitude - lonMargin
        let maxLon = longitude + lonMargin

        return allStops.filter { stop in
            // Cheap rectangle test first
            guard stop.latitude >= minLat, stop.latitude <= maxLat,
                  stop.longitude >= minLon, stop.longitude <= maxLon else {
                return false
            }
            // Expensive distance only for candidates inside the box
            let distance = calculateDistance(
                lat1: latitude, lon1: longitude,
                lat2: stop.latitude, lon2: stop.longitude
            )
            return distance <= maxDistDouble
        }
    }
    
    /// Find stops matching a search query
    func searchStops(query: String) -> [TransportStop] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        
        return allStops.filter { stop in
            stop.name.localizedStandardContains(trimmed)
        }
    }
    
    /// Force refresh from network
    func refresh() async {
        await downloadAndCache()
    }
    
    // MARK: - Private Methods
    
    private func loadFromBundle() -> Bool {
        guard fileManager.fileExists(atPath: bundledURL.path) else {
            return false
        }
        
        do {
            let data = try Data(contentsOf: bundledURL)
            
            // Try parsing as array of VBB API format first (includes products)
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
                print("OfflineStopsDatabase: Unknown JSON format in bundled stops")
                return false
            }
            
            // Copy to cache for future use
            try? saveToCache()
            
            return true
        } catch {
            print("OfflineStopsDatabase: Failed to load bundled stops: \(error)")
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
            
            // Check if cache is expired
            if let metadataData = try? Data(contentsOf: metadataFileURL),
               let metadata = try? decoder.decode(Metadata.self, from: metadataData) {
                let age = Date().timeIntervalSince(metadata.lastUpdated)
                if age > cacheTTL {
                    print("OfflineStopsDatabase: Cache expired (\(Int(age / 86400)) days old), will refresh")
                    // Still return true to use existing data while refreshing in background
                }
            }
            
            return true
        } catch {
            print("OfflineStopsDatabase: Failed to load cached stops: \(error)")
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
    
    /// Mark file as excluded from iCloud backup (required by Apple guidelines)
    private func excludeFromBackup(url: URL) throws {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(resourceValues)
    }
    
    private func downloadAndCache() async {
        print("OfflineStopsDatabase: Downloading all Berlin stops...")
        
        do {
            var allStopsFetched: [TransportStop] = []
            
            // Fetch stops in a grid pattern to cover Berlin
            let latStep = 0.05 // ~5km
            let lonStep = 0.08 // ~7km
            
            for lat in stride(from: 52.34, through: 52.68, by: latStep) {
                for lon in stride(from: 13.08, through: 13.76, by: lonStep) {
                    let stops = try await fetchStopsForArea(
                        latitude: lat,
                        longitude: lon,
                        distance: 8000
                    )
                    allStopsFetched.append(contentsOf: stops)
                }
            }
            
            // Remove duplicates by ID
            var seenIds = Set<String>()
            allStops = allStopsFetched.filter { stop in
                if seenIds.contains(stop.id) {
                    return false
                }
                seenIds.insert(stop.id)
                return true
            }
            
            // Save to cache
            try saveToCache()
            
            print("OfflineStopsDatabase: Saved \(allStops.count) unique stops to cache")
        } catch {
            print("OfflineStopsDatabase: Failed to download stops: \(error)")
        }
    }
    
    private func fetchStopsForArea(latitude: Double, longitude: Double, distance: Int) async throws -> [TransportStop] {
        let urlString = "https://v6.vbb.transport.rest/locations/nearby"
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
    
    // MARK: - Metadata
    
    private struct Metadata: Codable {
        let lastUpdated: Date
        let stopCount: Int
    }
}
