import Foundation
import CoreLocation

/// Service for predictive loading of transport data based on user patterns
@MainActor
@Observable
final class PredictiveLoader {
    private let transportService: TransportService
    private let vehicleRadarService: VehicleRadarService
    private let cacheService: CacheService
    private let networkMonitor: NetworkMonitor
    private let userPatternService = UserPatternService()
    
    private let preloadDistanceThreshold = 800.0
    private let preloadTimeThreshold = 300.0
    private let maxConcurrentPreloads = 3
    
    private var activePreloads: Set<String> = []
    private var lastPreloadLocation: CLLocation?
    private var isActive = false
    
    private var preloadedStops: [String: [TransportStop]] = [:]
    private var preloadedDepartures: [String: [TransportDeparture]] = [:]
    
    init(transportService: TransportService, vehicleRadarService: VehicleRadarService, cacheService: CacheService, networkMonitor: NetworkMonitor) {
        self.transportService = transportService
        self.vehicleRadarService = vehicleRadarService
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
    }
    
    /// Start predictive loading
    func startPredictiveLoading() {
        isActive = true
        print("Predictive loading started")
    }
    
    /// Stop predictive loading
    func stopPredictiveLoading() {
        isActive = false
        activePreloads.removeAll()
        print("Predictive loading stopped")
    }
    
    /// Handle location update and trigger predictive loading
    func handleLocationUpdate(_ location: CLLocation) {
        guard isActive else { return }
        
        userPatternService.recordLocation(location)
        
        // Check if we should preload based on distance
        if let lastLocation = lastPreloadLocation {
            let distance = location.distance(from: lastLocation)
            guard distance > preloadDistanceThreshold else { return }
        }
        
        lastPreloadLocation = location
         
         // Predict future locations
         let predictedLocations = userPatternService.predictFutureLocations(from: location, timeAhead: preloadTimeThreshold)
         
         // Preload data for predicted locations
         for predictedLocation in predictedLocations.prefix(maxConcurrentPreloads) {
             preloadDataForLocation(predictedLocation)
         }
     }
     
     /// Preload stops and departures for a predicted location
     private func preloadDataForLocation(_ coordinate: CLLocationCoordinate2D) {
         let locationKey = locationKey(for: coordinate)
         
         guard !activePreloads.contains(locationKey) else { return }
         activePreloads.insert(locationKey)
         
         Task {
             do {
                     print("Preloading data for location: \(coordinate.latitude), \(coordinate.longitude)")
                     
                     // Preload nearby stops
                     let stops = try await self.transportService.queryNearbyStops(
                         latitude: coordinate.latitude,
                         longitude: coordinate.longitude,
                         maxDistance: 1500,
                         maxLocations: 20
                     )
                     
                     // Cache preloaded stops
                     self.preloadedStops[locationKey] = stops
                     
                     // Preload departures for top stops — collect results from nonisolated
                     // tasks, then apply them on @MainActor after the group finishes.
                     let fetchedDepartures = await withTaskGroup(
                         of: (String, [TransportDeparture])?.self
                     ) { group in
                         for stop in stops.prefix(5) {
                             group.addTask {
                                 do {
                                     let deps = try await self.transportService.queryDepartures(
                                         stationId: stop.vbbStopId,
                                         maxDepartures: 10
                                     )
                                     return (stop.vbbStopId, deps)
                                 } catch {
                                     print("Failed to preload departures for \(stop.name): \(error)")
                                     return nil
                                 }
                             }
                         }
                         var results: [(String, [TransportDeparture])] = []
                         for await result in group {
                             if let r = result { results.append(r) }
                         }
                         return results
                     }
                     for (stopId, deps) in fetchedDepartures {
                         self.preloadedDepartures[stopId] = deps
                     }
                     
                     print("Preloaded \(stops.count) stops and departures for predicted location")
                     
                 } catch {
                     print("Failed to preload data for predicted location: \(error)")
                 }
                 
                 self.activePreloads.remove(locationKey)
             }
     }
     
     /// Get preloaded stops for a location if available
     func getPreloadedStops(for coordinate: CLLocationCoordinate2D, maxDistance: Int = 1500) -> [TransportStop]? {
         let locationKey = locationKey(for: coordinate)
         return preloadedStops[locationKey]
     }
     
     /// Get preloaded departures for a stop if available
     func getPreloadedDepartures(for stationId: String) -> [TransportDeparture]? {
         return preloadedDepartures[stationId]
     }
     
     /// Check if data is available for a location (preloaded or needs loading)
     func hasPreloadedData(for coordinate: CLLocationCoordinate2D) -> Bool {
         let locationKey = locationKey(for: coordinate)
         return preloadedStops[locationKey] != nil
     }
     
     /// Clear preloaded data cache
     func clearPreloadedData() {
         preloadedStops.removeAll()
         preloadedDepartures.removeAll()
         activePreloads.removeAll()
         lastPreloadLocation = nil
     }
     
     /// Generate a cache key for a location
     private func locationKey(for coordinate: CLLocationCoordinate2D) -> String {
         // Round to ~100m precision for caching
         let lat = round(coordinate.latitude * 1000) / 1000
         let lon = round(coordinate.longitude * 1000) / 1000
         return "\(lat),\(lon)"
     }
 }
