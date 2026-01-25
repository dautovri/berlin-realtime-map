import Foundation

@Observable
final class JourneyService {
    private let userDefaultsKey = "journeyHistory"
    
    func saveJourney(_ journey: Journey) {
        var history = getHistory()
        history.append(journey)
        // Keep last 100 journeys
        if history.count > 100 {
            history = Array(history.suffix(100))
        }
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func getHistory() -> [Journey] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Journey].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.startTime > $1.startTime }
    }
    
    func getFrequentRoutes() -> [RouteSuggestion] {
        let history = getHistory()
        
        // Group by route (startStopId + endStopId + transportMode)
        var routeCounts: [String: (startId: String, endId: String, mode: String, count: Int)] = [:]
        
        for journey in history {
            let key = "\(journey.startStopId)_\(journey.endStopId)_\(journey.transportMode)"
            if let existing = routeCounts[key] {
                routeCounts[key] = (existing.startId, existing.endId, existing.mode, existing.count + 1)
            } else {
                routeCounts[key] = (journey.startStopId, journey.endStopId, journey.transportMode, 1)
            }
        }
        
        // Create suggestions for routes used more than once
        return routeCounts.values.filter { $0.count > 1 }.map { data in
            // For simplicity, create dummy stops (in real app, fetch from service)
            let startStop = TransportStop(id: data.startId, name: "Stop \(data.startId)", latitude: 0, longitude: 0)
            let endStop = TransportStop(id: data.endId, name: "Stop \(data.endId)", latitude: 0, longitude: 0)
            let mode = TransportMode(rawValue: data.mode) ?? .bus
            
            return RouteSuggestion(startStop: startStop, endStop: endStop, transportMode: mode, frequency: data.count)
        }.sorted { $0.frequency > $1.frequency }
    }
}