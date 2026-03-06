import Foundation

final class PredictionService {
    private let storage = HistoricalDataStorage()
    
    /// Predict arrival time for a vehicle at a specific stop
    func predictArrival(for vehicle: Vehicle, at stop: TransportStop) -> Date? {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now)
        let hourOfDay = calendar.component(.hour, from: now)
        
        let lineName = vehicle.line?.displayName ?? "?"
        
        // Load historical data for similar conditions
        let historical = storage.load(for: stop.id, lineName: lineName, dayOfWeek: dayOfWeek, hourOfDay: hourOfDay)
        
        guard !historical.isEmpty else {
            return nil // No historical data
        }
        
        // Calculate average delay
        let totalDelay = historical.reduce(0) { $0 + $1.delayMinutes }
        let averageDelay = Double(totalDelay) / Double(historical.count)
        
        // Apply average delay to current time
        return now.addingTimeInterval(averageDelay * 60)
    }
    
    /// Record actual arrival for learning
    func recordArrival(vehicle: Vehicle, at stop: TransportStop, scheduledTime: Date?) {
        if let data = HistoricalData(from: vehicle, at: stop, scheduledTime: scheduledTime) {
            storage.save(data)
        }
    }
    
    /// Get prediction confidence (0-1) based on data points
    func predictionConfidence(for vehicle: Vehicle, at stop: TransportStop) -> Double {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now)
        let hourOfDay = calendar.component(.hour, from: now)
        let lineName = vehicle.line?.displayName ?? "?"
        
        let historical = storage.load(for: stop.id, lineName: lineName, dayOfWeek: dayOfWeek, hourOfDay: hourOfDay)
        
        // Confidence based on number of data points (max at 10+)
        return min(Double(historical.count) / 10.0, 1.0)
    }
}