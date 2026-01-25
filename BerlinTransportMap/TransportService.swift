import Foundation
import TripKit
import CoreLocation

/// Transport service using TripKit for Berlin public transport data
@Observable
final class TransportService: @unchecked Sendable {
    private let provider: BvgProvider
    private let backgroundQueue = DispatchQueue.global(qos: .background)
    private let cacheService = CacheService()

    // BVG API authorization - these are public keys used by the BVG app
    nonisolated(unsafe) private static let apiAuthorization: [String: Any] = [
        "type": "AID",
        "aid": "1Rxs112shyHLatUX4fofnmdxK"
    ]

    init() {
        self.provider = BvgProvider(apiAuthorization: Self.apiAuthorization)
    }

    // MARK: - Error Mapping

    private func mapTripKitFailure(_ error: Error) throws -> TransportError {
        if error is CancellationError {
            throw error
        }

        if let urlError = error as? URLError {
            return .networkError("\(urlError.code.rawValue) \(urlError.code)")
        }

        // Prefer a stable/debuggable message over an often-empty localizedDescription.
        let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
        return .networkError(message)
    }

    // MARK: - Query Nearby Stops

    func queryNearbyStops(latitude: Double, longitude: Double, maxDistance: Int = 2000, maxLocations: Int = 50) async throws -> [TransportStop] {
        // Check cache first
        if let cachedStops = cacheService.getStops(forLocation: latitude, longitude: longitude, maxDistance: maxDistance, maxLocations: maxLocations) {
            return cachedStops
        }
        
        // Fetch from network
        let stops = try await fetchNearbyStops(latitude: latitude, longitude: longitude, maxDistance: maxDistance, maxLocations: maxLocations)
        
        // Cache the result
        cacheService.setStops(stops, forLocation: latitude, longitude: longitude, maxDistance: maxDistance, maxLocations: maxLocations)
        
        return stops
    }
    
    private func fetchNearbyStops(latitude: Double, longitude: Double, maxDistance: Int, maxLocations: Int) async throws -> [TransportStop] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        // TripKit uses Int coordinates (lat/lon * 1e6)
                        let lat = Int(latitude * 1_000_000)
                        let lon = Int(longitude * 1_000_000)
                        
                        let location = Location(lat: lat, lon: lon)
                        
                        let (_, result) = await self.provider.queryNearbyLocations(
                            location: location,
                            types: [.station],
                            maxDistance: maxDistance,
                            maxLocations: maxLocations
                        )
                        
                        switch result {
                        case .success(let locations):
                            try Task.checkCancellation()
                            let stops = locations.compactMap { TransportStop(from: $0) }
                            continuation.resume(returning: stops)
                        case .invalidId:
                            continuation.resume(throwing: TransportError.invalidLocation)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Query Departures

    func queryDepartures(stationId: String, maxDepartures: Int = 20) async throws -> [TransportDeparture] {
        // Check cache first
        if let cachedDepartures = cacheService.getDepartures(forStationId: stationId, maxDepartures: maxDepartures) {
            return cachedDepartures
        }
        
        // Fetch from network
        let departures = try await fetchDepartures(stationId: stationId, maxDepartures: maxDepartures)
        
        // Cache the result
        cacheService.setDepartures(departures, forStationId: stationId, maxDepartures: maxDepartures)
        
        return departures
    }
    
    private func fetchDepartures(stationId: String, maxDepartures: Int) async throws -> [TransportDeparture] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        let (_, result) = await self.provider.queryDepartures(
                            stationId: stationId,
                            departures: true,
                            time: nil,
                            maxDepartures: maxDepartures,
                            equivs: false
                        )
                        
                        switch result {
                        case .success(let stationDepartures):
                            try Task.checkCancellation()
                            let departures = stationDepartures.flatMap { stationDep in
                                stationDep.departures.compactMap { TransportDeparture(from: $0, stop: stationDep.stopLocation) }
                            }
                            continuation.resume(returning: departures)
                        case .invalidStation:
                            continuation.resume(throwing: TransportError.invalidStation)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Search Locations

    func searchLocations(query: String, maxLocations: Int = 20) async throws -> [TransportStop] {
        // For search, use a simple key
        let cacheKey = "search_\(query)_\(maxLocations)"
        if let cachedStops: [TransportStop] = cacheService.get(cacheKey) {
            return cachedStops
        }
        
        let stops = try await fetchSearchLocations(query: query, maxLocations: maxLocations)
        
        // Cache with shorter TTL for search
        cacheService.set(stops, forKey: cacheKey, ttl: 300) // 5 min
        
        return stops
    }
    
    private func fetchSearchLocations(query: String, maxLocations: Int) async throws -> [TransportStop] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        let (_, result) = await self.provider.suggestLocations(
                            constraint: query,
                            types: [.station],
                            maxLocations: maxLocations
                        )
                        
                        switch result {
                        case .success(let suggestions):
                            try Task.checkCancellation()
                            let stops = suggestions.compactMap { TransportStop(from: $0.location) }
                            continuation.resume(returning: stops)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Batch query nearby stops and their departures for efficient data fetching
    func queryNearbyStopsAndDepartures(latitude: Double, longitude: Double, maxDistance: Int = 2000, maxStops: Int = 10, maxDeparturesPerStop: Int = 10) async throws -> ([TransportStop], [TransportDeparture]) {
        let stops = try await queryNearbyStops(latitude: latitude, longitude: longitude, maxDistance: maxDistance, maxLocations: maxStops)
        
        let departures = try await withThrowingTaskGroup(of: [TransportDeparture].self) { group in
            for stop in stops.prefix(5) { // Limit to top 5 stops to batch efficiently
                group.addTask {
                    try await self.queryDepartures(stationId: stop.vbbStopId, maxDepartures: maxDeparturesPerStop)
                }
            }
            var allDepartures: [TransportDeparture] = []
            for try await deps in group {
                allDepartures.append(contentsOf: deps)
            }
            return allDepartures
        }
        
        return (stops, departures)
    }
}

