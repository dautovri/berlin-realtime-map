import Foundation

struct Journey: Identifiable, Codable {
    let id: UUID
    let startStopId: String
    let endStopId: String
    let transportMode: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    
    init(startStop: TransportStop, endStop: TransportStop, transportMode: TransportMode, startTime: Date = Date()) {
        self.id = UUID()
        self.startStopId = startStop.id
        self.endStopId = endStop.id
        self.transportMode = transportMode.rawValue
        self.startTime = startTime
    }
    
    mutating func complete(endTime: Date = Date()) {
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}

struct RouteSuggestion: Identifiable {
    let id: UUID
    let startStop: TransportStop
    let endStop: TransportStop
    let transportMode: TransportMode
    let frequency: Int
    
    init(startStop: TransportStop, endStop: TransportStop, transportMode: TransportMode, frequency: Int) {
        self.id = UUID()
        self.startStop = startStop
        self.endStop = endStop
        self.transportMode = transportMode
        self.frequency = frequency
    }
}