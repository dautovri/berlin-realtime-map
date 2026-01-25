import Foundation

struct HistoricalData: Codable, Identifiable {
    let id: UUID
    let stopId: String
    let vehicleId: String
    let lineName: String
    let dayOfWeek: Int // 1-7 (Sunday = 1)
    let hourOfDay: Int // 0-23
    let actualArrivalTime: Date
    let scheduledArrivalTime: Date?
    let delayMinutes: Int
    
    init(stopId: String, vehicleId: String, lineName: String, dayOfWeek: Int, hourOfDay: Int, actualArrivalTime: Date, scheduledArrivalTime: Date?, delayMinutes: Int) {
        self.id = UUID()
        self.stopId = stopId
        self.vehicleId = vehicleId
        self.lineName = lineName
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.actualArrivalTime = actualArrivalTime
        self.scheduledArrivalTime = scheduledArrivalTime
        self.delayMinutes = delayMinutes
    }
    
    // Create from current vehicle arrival
    init?(from vehicle: Vehicle, at stop: TransportStop, scheduledTime: Date?) {
        guard let currentLocation = vehicle.currentLocation else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let delayMinutes = scheduledTime != nil ? Int(now.timeIntervalSince(scheduledTime!) / 60) : 0
        
        self.init(
            stopId: stop.id,
            vehicleId: vehicle.tripId,
            lineName: vehicle.line?.displayName ?? "?",
            dayOfWeek: calendar.component(.weekday, from: now),
            hourOfDay: calendar.component(.hour, from: now),
            actualArrivalTime: now,
            scheduledArrivalTime: scheduledTime,
            delayMinutes: delayMinutes
        )
    }
}

// Storage manager for historical data
class HistoricalDataStorage {
    private let userDefaultsKey = "historicalTransportData"
    private let maxEntries = 10000 // Limit storage size
    
    func save(_ data: HistoricalData) {
        var existing = load()
        existing.append(data)
        
        // Keep only recent entries
        if existing.count > maxEntries {
            existing = Array(existing.suffix(maxEntries))
        }
        
        if let encoded = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func load() -> [HistoricalData] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([HistoricalData].self, from: data) else {
            return []
        }
        return decoded
    }
    
    func load(for stopId: String, lineName: String, dayOfWeek: Int, hourOfDay: Int) -> [HistoricalData] {
        return load().filter {
            $0.stopId == stopId &&
            $0.lineName == lineName &&
            $0.dayOfWeek == dayOfWeek &&
            abs($0.hourOfDay - hourOfDay) <= 1 // Within 1 hour
        }
    }
}