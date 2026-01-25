import Foundation
import TripKit

/// Cache service for storing transport data with TTL support
final class CacheService {
    private let userDefaults = UserDefaults.standard
    private static let cachePrefix = "transport_cache_"
    
    struct CachedItem<T: Codable>: Codable {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval // Time to live in seconds
    }
    
    // MARK: - Cache Keys
    enum CacheKey: String {
        case stops
        case departures
        case vehicles
        
        func key(for parameters: [String]) -> String {
            return CacheService.cachePrefix + self.rawValue + "_" + parameters.joined(separator: "_")
        }
    }
    
    // MARK: - Set Data
    func set<T: Codable>(_ data: T, forKey key: String, ttl: TimeInterval = 300) { // Default 5 minutes
        let item = CachedItem(data: data, timestamp: Date(), ttl: ttl)
        do {
            let encoded = try JSONEncoder().encode(item)
            userDefaults.set(encoded, forKey: key)
        } catch {
            print("CacheService: Failed to encode data for key \(key): \(error)")
        }
    }
    
    // MARK: - Get Data
    func get<T: Codable>(_ key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            let item = try JSONDecoder().decode(CachedItem<T>.self, from: data)
            
            // Check if expired
            if Date().timeIntervalSince(item.timestamp) > item.ttl {
                remove(key)
                return nil
            }
            
            return item.data
        } catch {
            print("CacheService: Failed to decode data for key \(key): \(error)")
            remove(key) // Remove corrupted data
            return nil
        }
    }
    
    // MARK: - Remove Data
    func remove(_ key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Clear Cache
    func clear() {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(CacheService.cachePrefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
    
    // MARK: - Cache Age
    func age(of key: String) -> TimeInterval? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            let item = try JSONDecoder().decode(CachedItem<Data>.self, from: data)
            return Date().timeIntervalSince(item.timestamp)
        } catch {
            return nil
        }
    }
    
    // MARK: - Convenience Methods for Transport Data
    
    func setStops(_ stops: [TransportStop], forLocation latitude: Double, longitude: Double, maxDistance: Int, maxLocations: Int, ttl: TimeInterval = 600) { // 10 min
        let key = CacheKey.stops.key(for: [String(format: "%.6f", latitude), String(format: "%.6f", longitude), "\(maxDistance)", "\(maxLocations)"])
        set(stops, forKey: key, ttl: ttl)
    }
    
    func getStops(forLocation latitude: Double, longitude: Double, maxDistance: Int, maxLocations: Int) -> [TransportStop]? {
        let key = CacheKey.stops.key(for: [String(format: "%.6f", latitude), String(format: "%.6f", longitude), "\(maxDistance)", "\(maxLocations)"])
        return get(key)
    }
    
    func setDepartures(_ departures: [TransportDeparture], forStationId stationId: String, maxDepartures: Int, ttl: TimeInterval = 60) { // 1 min
        let key = CacheKey.departures.key(for: [stationId, "\(maxDepartures)"])
        set(departures, forKey: key, ttl: ttl)
    }
    
    func getDepartures(forStationId stationId: String, maxDepartures: Int) -> [TransportDeparture]? {
        let key = CacheKey.departures.key(for: [stationId, "\(maxDepartures)"])
        return get(key)
    }
    
    // Vehicles cache
    func setVehicles(_ vehicles: [Vehicle], forBoundingBox north: Double, west: Double, south: Double, east: Double, duration: Int, ttl: TimeInterval = 60) { // 1 min for vehicles
        let key = CacheKey.vehicles.key(for: [String(format: "%.6f", north), String(format: "%.6f", west), String(format: "%.6f", south), String(format: "%.6f", east), "\(duration)"])
        set(vehicles, forKey: key, ttl: ttl)
    }
    
    func getVehiclesCacheKey(forBoundingBox north: Double, west: Double, south: Double, east: Double, duration: Int) -> String {
        return CacheKey.vehicles.key(for: [String(format: "%.6f", north), String(format: "%.6f", west), String(format: "%.6f", south), String(format: "%.6f", east), "\(duration)"])
    }
}