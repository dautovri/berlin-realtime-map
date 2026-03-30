import Foundation

/// Events service for fetching event data from Berlin's events API
actor EventsService {
    private var cachedEvents: [Event]?
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 3600
    private let baseURL = "https://api.berlin.de/events/"
    private let decoder = JSONDecoder()
    nonisolated(unsafe) fileprivate static let isoFormatter = ISO8601DateFormatter()
    
    init() {}
    
    // MARK: - Events Fetching
    
    func fetchEvents() async throws -> [Event] {
        // Return cached if fresh
        if let cached = cachedEvents,
           let ts = cacheTimestamp,
           Date().timeIntervalSince(ts) < cacheTTL {
            return cached
        }
        
        // Fetch from API
        let events = try await fetchEventsFromAPI()
        
        // Cache the result
        cachedEvents = events
        cacheTimestamp = Date()
        
        return events
    }
    
    private func fetchEventsFromAPI() async throws -> [Event] {
        let urlString = "\(baseURL)?limit=50"
        guard let url = URL(string: urlString) else {
            throw EventsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw EventsError.networkError("Invalid response")
        }
        
        let apiResponse = try decoder.decode(BerlinEventsResponse.self, from: data)
        
        return apiResponse.events.compactMap { Event(from: $0) }
    }
}

// MARK: - API Response Models

private struct BerlinEventsResponse: Codable {
    let events: [BerlinEvent]
}

private struct BerlinEvent: Codable {
    let id: String
    let name: String
    let location: BerlinLocation?
    let date: BerlinDate?
    let description: String?
    
    struct BerlinLocation: Codable {
        let name: String?
        let latitude: Double?
        let longitude: Double?
    }
    
    struct BerlinDate: Codable {
        let start: String?
    }
}

// MARK: - Extensions

extension Event {
    fileprivate init?(from berlinEvent: BerlinEvent) {
        guard let locationName = berlinEvent.location?.name,
              let lat = berlinEvent.location?.latitude,
              let lon = berlinEvent.location?.longitude,
              let dateString = berlinEvent.date?.start,
              let date = EventsService.isoFormatter.date(from: dateString) else {
            return nil
        }
        
        self.id = berlinEvent.id
        self.name = berlinEvent.name
        self.location = locationName
        self.latitude = lat
        self.longitude = lon
        self.date = date
        self.description = berlinEvent.description
    }
}

// MARK: - Errors

enum EventsError: LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode events data"
        }
    }
}