import Foundation
import CoreLocation

/// Service for predictive loading of transport data based on user patterns
@Observable
final class PredictiveLoader {
    private let transportService = TransportService()
    private let userPatternService = UserPatternService()
    private let backgroundQueue = DispatchQueue.global(qos: .background)
    
    // Configuration
    private let preloadDistanceThreshold = 800.0 // meters
    private let preloadTimeThreshold = 300.0 // 5 minutes
    private let maxConcurrentPreloads = 3
    
    // State
    private var activePreloads: Set<String> = [] // Prevent duplicate preloads
    private var lastPreloadLocation: CLLocation?
    private var isActive = false
    
    // Preloaded data cache (temporary, not persisted)
    private var preloadedStops: [String: [TransportStop]] = [:] // key: location hash
    private var preloadedDepartures: [String: [TransportDeparture]] = [:] // key: stopId
    
    init() {
        // Background tasks setup would go here for iOS
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
         
         backgroundQueue.async {
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
                     await MainActor.run {
                         self.preloadedStops[locationKey] = stops
                     }
                     
                     // Preload departures for top stops
                     await withTaskGroup(of: Void.self) { group in
                         for stop in stops.prefix(5) {
                             group.addTask {
                                 do {
                                     let departures = try await self.transportService.queryDepartures(
                                         stationId: stop.vbbStopId,
                                         maxDepartures: 10
                                     )
                                     
                                     await MainActor.run {
                                         self.preloadedDepartures[stop.vbbStopId] = departures
                                     }
                                 } catch {
                                     print("Failed to preload departures for \(stop.name): \(error)")
                                 }
                             }
                         }
                     }
                     
                     print("Preloaded \(stops.count) stops and departures for predicted location")
                     
                 } catch {
                     print("Failed to preload data for predicted location: \(error)")
                 }
                 
                 await MainActor.run {
                     self.activePreloads.remove(locationKey)
                 }
             }
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
