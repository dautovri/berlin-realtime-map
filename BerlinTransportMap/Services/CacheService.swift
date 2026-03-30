import Foundation

/// Cache service for storing transport data with TTL support.
/// Uses NSCache for fast in-memory caching (no main-thread plist sync),
/// with file-backed persistence only for long-lived data (stops).
final class CacheService: @unchecked Sendable {
    /// Wrapper to store value + expiry in NSCache (which requires a class object).
    private final class Entry {
        let data: Data
        let expiresAt: Date
        init(data: Data, ttl: TimeInterval) {
            self.data = data
            self.expiresAt = Date().addingTimeInterval(ttl)
        }
        var isExpired: Bool { Date() > expiresAt }
    }

    private let memoryCache = NSCache<NSString, Entry>()

    private static let cachePrefix = "transport_cache_"

    init() {
        // Allow up to ~200 entries in memory; OS may evict under pressure.
        memoryCache.countLimit = 200
    }

    enum CacheKey: String {
        case stop
        case stops
        case departures

        func key(for parameters: [String]) -> String {
            return CacheService.cachePrefix + self.rawValue + "_" + parameters.joined(separator: "_")
        }
    }

    // MARK: - Grid-based Stops Cache
    private let gridCellSize = 0.005

    private func gridCellKey(for latitude: Double, longitude: Double, maxDistance: Int) -> String {
        let cellLat = floor(latitude / gridCellSize) * gridCellSize
        let cellLon = floor(longitude / gridCellSize) * gridCellSize
        let cellRadius = max(1000, maxDistance)
        return CacheKey.stops.key(for: [
            String(format: "%.3f", cellLat),
            String(format: "%.3f", cellLon),
            "\(cellRadius)"
        ])
    }

    func getStopsCacheKey(forLocation latitude: Double, longitude: Double, maxDistance: Int) -> String {
        gridCellKey(for: latitude, longitude: longitude, maxDistance: maxDistance)
    }

    func setStops(_ stops: [TransportStop], forLocation latitude: Double, longitude: Double, maxDistance: Int) {
        let key = gridCellKey(for: latitude, longitude: longitude, maxDistance: maxDistance)
        set(stops, forKey: key, ttl: 604800)
    }

    func getStops(forLocation latitude: Double, longitude: Double, maxDistance: Int) -> [TransportStop]? {
        let key = gridCellKey(for: latitude, longitude: longitude, maxDistance: maxDistance)
        return get(key)
    }

    // MARK: - Departures Cache
    func saveDepartures(_ departures: [TransportDeparture], forStopId stopId: String, maxDepartures: Int) {
        let key = CacheKey.departures.key(for: [stopId, "\(maxDepartures)"])
        set(departures, forKey: key, ttl: 60)
    }

    func getDepartures(forStopId stopId: String, maxDepartures: Int) -> [TransportDeparture]? {
        let key = CacheKey.departures.key(for: [stopId, "\(maxDepartures)"])
        return get(key)
    }

    // MARK: - Generic Set/Get (NSCache-backed)
    func set<T: Codable>(_ data: T, forKey key: String, ttl: TimeInterval = 300) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let entry = Entry(data: encoded, ttl: ttl)
            memoryCache.setObject(entry, forKey: key as NSString)
        } catch {
            print("CacheService: Failed to encode data for key \(key): \(error)")
        }
    }

    func get<T: Codable>(_ key: String) -> T? {
        guard let entry = memoryCache.object(forKey: key as NSString) else { return nil }

        if entry.isExpired {
            memoryCache.removeObject(forKey: key as NSString)
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: entry.data)
        } catch {
            memoryCache.removeObject(forKey: key as NSString)
            return nil
        }
    }

    func remove(_ key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }

    func clear() {
        memoryCache.removeAllObjects()
    }
}
