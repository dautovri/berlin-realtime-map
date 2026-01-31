import Foundation

/// Offline database of all Berlin transport stops
/// Downloads once on first launch, then loads from local storage
final class OfflineStopsDatabase {
    static let shared = OfflineStopsDatabase()
    
    private let fileManager = FileManager.default
    private let stopsFileName = "berlin_all_stops.json"
    private let metadataFileName = "berlin_stops_metadata.json"
    private let cacheTTL: TimeInterval = 604800 // 7 days
    
    private var allStops: [TransportStop] = []
    private var isLoaded = false
    
    private var stopsFileURL: URL {
        documentsDirectory.appendingPathComponent(stopsFileName)
    }
    
    private var metadataFileURL: URL {
        documentsDirectory.appendingPathComponent(metadataFileName)
    }
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Load all stops from local storage or fetch if needed
    func loadIfNeeded() async {
        guard !isLoaded else { return }
        
        if loadFromLocal() {
            print("OfflineStopsDatabase: Loaded \(allStops.count) stops from local storage")
            isLoaded = true
            return
        }
        
        // Download on first launch
        await downloadAndSave()
        isLoaded = true
    }
    
    /// Get all stops
    func getAllStops() -> [TransportStop] {
        return allStops
    }
    
    /// Find stops near a location
    func findStops(latitude: Double, longitude: Double, maxDistance: Int) -> [TransportStop] {
        let maxDistDouble = Double(maxDistance)
        return allStops.filter { stop in
            let distance = calculateDistance(
                lat1: latitude, lon1: longitude,
                lat2: stop.latitude, lon2: stop.longitude
            )
            return distance <= maxDistDouble
        }
    }
    
    /// Find stops matching a search query
    func searchStops(query: String) -> [TransportStop] {
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard lowercasedQuery.count >= 2 else { return [] }
        
        return allStops.filter { stop in
            stop.name.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Force refresh from network
    func refresh() async {
        await downloadAndSave()
    }
    
    // MARK: - Private Methods
    
    private func loadFromLocal() -> Bool {
        guard fileManager.fileExists(atPath: stopsFileURL.path) else {
            return false
        }
        
        do {
            let data = try Data(contentsOf: stopsFileURL)
            allStops = try JSONDecoder().decode([TransportStop].self, from: data)
            
            // Check if data is expired
            if let metadataData = try? Data(contentsOf: metadataFileURL),
               let metadata = try? JSONDecoder().decode(Metadata.self, from: metadataData) {
                let age = Date().timeIntervalSince(metadata.lastUpdated)
                if age > cacheTTL {
                    print("OfflineStopsDatabase: Cache expired (\(Int(age / 86400)) days old), will refresh")
                    return true // Still return true to use existing data while refreshing
                }
            }
            
            return true
        } catch {
            print("OfflineStopsDatabase: Failed to load local stops: \(error)")
            return false
        }
    }
    
    private func downloadAndSave() async {
        print("OfflineStopsDatabase: Downloading all Berlin stops...")
        
        do {
            // VBB API - get all stops in Berlin area
            // Berlin bbox: 52.34 to 52.68 lat, 13.08 to 13.76 lon
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
            
            // Save to local storage
            try saveToLocal()
            
            print("OfflineStopsDatabase: Saved \(allStops.count) unique stops")
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
        
        let decoder = JSONDecoder()
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
    
    private func saveToLocal() throws {
        // Save stops
        let encoder = JSONEncoder()
        let stopsData = try encoder.encode(allStops)
        try stopsData.write(to: stopsFileURL)
        
        // Save metadata
        let metadata = Metadata(lastUpdated: Date(), stopCount: allStops.count)
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataFileURL)
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
