import Foundation
import CoreLocation

/// Service for analyzing user location patterns and predicting future locations
@Observable
final class UserPatternService {
    private let userDefaults = UserDefaults.standard
    private let maxHistorySize = 50
    private let historyKey = "userLocationHistory"
    
    struct LocationHistory: Codable {
        let latitude: Double
        let longitude: Double
        let timestamp: Date
        let speed: Double?
        let course: Double?
    }
    
    struct MovementPattern {
        let direction: Double // bearing in degrees
        let speed: Double // meters per second
        let confidence: Double // 0-1
    }
    
    var locationHistory: [LocationHistory] = []
    
    init() {
        loadHistory()
    }
    
    /// Record a new location update
    func recordLocation(_ location: CLLocation) {
        let history = LocationHistory(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil
        )
        
        locationHistory.append(history)
        
        // Keep only recent history
        if locationHistory.count > maxHistorySize {
            locationHistory.removeFirst(locationHistory.count - maxHistorySize)
        }
        
        saveHistory()
    }
    
    /// Analyze current movement pattern
    func analyzeCurrentPattern() -> MovementPattern? {
        guard locationHistory.count >= 2 else { return nil }
        
        let recent = locationHistory.suffix(5) // Last 5 locations
        guard recent.count >= 2 else { return nil }
        
        // Calculate average direction and speed
        var directions: [Double] = []
        var speeds: [Double] = []
        
        for i in 1..<recent.count {
            let prev = recent[recent.index(recent.startIndex, offsetBy: i-1)]
            let curr = recent[recent.index(recent.startIndex, offsetBy: i)]
            
            let coord1 = CLLocationCoordinate2D(latitude: prev.latitude, longitude: prev.longitude)
            let coord2 = CLLocationCoordinate2D(latitude: curr.latitude, longitude: curr.longitude)
            
            let bearing = calculateBearing(from: coord1, to: coord2)
            directions.append(bearing)
            
            if let speed = curr.speed, speed > 0 {
                speeds.append(speed)
            }
        }
        
        guard !directions.isEmpty else { return nil }
        
        let avgDirection = directions.reduce(0, +) / Double(directions.count)
        let avgSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        
        // Calculate confidence based on direction consistency
        let directionVariance = directions.map { pow($0 - avgDirection, 2) }.reduce(0, +) / Double(directions.count)
        let confidence = max(0, 1 - directionVariance / 180.0) // Normalize variance
        
        return MovementPattern(direction: avgDirection, speed: avgSpeed, confidence: confidence)
    }
    
    /// Predict likely future locations based on current pattern
    func predictFutureLocations(from currentLocation: CLLocation, timeAhead: TimeInterval = 300) -> [CLLocationCoordinate2D] {
        guard let pattern = analyzeCurrentPattern(), pattern.confidence > 0.3 else {
            // If no clear pattern, predict in cardinal directions
            return predictNearbyAreas(from: currentLocation)
        }
        
        let distance = pattern.speed * timeAhead // Estimated distance in meters
        let prediction = locationAtDistance(distance, bearing: pattern.direction, from: currentLocation.coordinate)
        
        return [prediction]
    }
    
    /// Predict nearby areas when no clear movement pattern
    private func predictNearbyAreas(from location: CLLocation) -> [CLLocationCoordinate2D] {
        let distances = [500.0, 1000.0, 1500.0] // 500m, 1km, 1.5km ahead
        let bearings = [0, 90, 180, 270] // North, East, South, West
        
        var predictions: [CLLocationCoordinate2D] = []
        
        for distance in distances {
            for bearing in bearings {
                let coord = locationAtDistance(distance, bearing: Double(bearing), from: location.coordinate)
                predictions.append(coord)
            }
        }
        
        return predictions
    }
    
    /// Calculate bearing between two coordinates
    private func calculateBearing(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let lat1 = coord1.latitude * .pi / 180
        let lon1 = coord1.longitude * .pi / 180
        let lat2 = coord2.latitude * .pi / 180
        let lon2 = coord2.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let bearing = atan2(y, x)
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /// Calculate location at distance and bearing from coordinate
    private func locationAtDistance(_ distance: Double, bearing: Double, from coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0 // meters
        let angularDistance = distance / earthRadius
        let bearingRad = bearing * .pi / 180
        
        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(angularDistance) * cos(lat1), cos(angularDistance) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
    
    /// Clear location history
    func clearHistory() {
        locationHistory.removeAll()
        userDefaults.removeObject(forKey: historyKey)
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(locationHistory)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("Failed to save location history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        do {
            locationHistory = try JSONDecoder().decode([LocationHistory].self, from: data)
        } catch {
            print("Failed to load location history: \(error)")
            locationHistory = []
        }
    }
}
