import Foundation

/// Cache service for storing transport data with TTL support
/// Only caches individual stops and departures - never downloads whole city
final class CacheService {
    private let userDefaults = UserDefaults.standard
    private static let cachePrefix = "transport_cache_"

    struct CachedItem<T: Codable>: Codable {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    enum CacheKey: String {
        case stop
        case stops
        case departures
        case vehicles

        func key(for parameters: [String]) -> String {
            return CacheService.cachePrefix + self.rawValue + "_" + parameters.joined(separator: "_")
        }
    }

    // MARK: - Grid-based Stops Cache
    // Grid cell size in degrees (~500m at Berlin's latitude)
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
        // Stops rarely change - cache for 7 days
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

    // MARK: - Vehicles Cache
    func setVehicles(_ vehicles: [Vehicle], forBoundingBox north: Double, west: Double, south: Double, east: Double, duration: Int, ttl: TimeInterval = 60) {
        let key = getVehiclesCacheKey(forBoundingBox: north, west: west, south: south, east: east, duration: duration)
        set(vehicles, forKey: key, ttl: ttl)
    }

    func getVehicles(forBoundingBox north: Double, west: Double, south: Double, east: Double, duration: Int) -> [Vehicle]? {
        let key = getVehiclesCacheKey(forBoundingBox: north, west: west, south: south, east: east, duration: duration)
        return get(key)
    }

    func getVehiclesCacheKey(forBoundingBox north: Double, west: Double, south: Double, east: Double, duration: Int) -> String {
        CacheKey.vehicles.key(for: [String(format: "%.6f", north), String(format: "%.6f", west), String(format: "%.6f", south), String(format: "%.6f", east), "\(duration)"])
    }

    // MARK: - Generic Set/Get
    func set<T: Codable>(_ data: T, forKey key: String, ttl: TimeInterval = 300) {
        let item = CachedItem(data: data, timestamp: Date(), ttl: ttl)
        do {
            let encoded = try JSONEncoder().encode(item)
            userDefaults.set(encoded, forKey: key)
        } catch {
            print("CacheService: Failed to encode data for key \(key): \(error)")
        }
    }

    func get<T: Codable>(_ key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }

        do {
            let item = try JSONDecoder().decode(CachedItem<T>.self, from: data)

            if item.isExpired {
                remove(key)
                return nil
            }

            return item.data
        } catch {
            remove(key)
            return nil
        }
    }

    func remove(_ key: String) {
        userDefaults.removeObject(forKey: key)
    }

    func clear() {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(CacheService.cachePrefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }

    func age(of key: String) -> TimeInterval? {
        guard let data = userDefaults.data(forKey: key) else { return nil }

        do {
            let item = try JSONDecoder().decode(CachedItem<Data>.self, from: data)
            return Date().timeIntervalSince(item.timestamp)
        } catch {
            return nil
        }
    }
}
