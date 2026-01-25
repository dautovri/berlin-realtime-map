import Foundation

/// Events service for fetching event data from Berlin's events API
@Observable
final class EventsService: @unchecked Sendable {
    static let shared = EventsService()
    
    private let cacheService = CacheService()
    private let baseURL = "https://api.berlin.de/events/"
    
    private init() {}
    
    // MARK: - Events Fetching
    
    func fetchEvents() async throws -> [Event] {
        let cacheKey = "events"
        
        // Check cache (1 hour)
        if let cached: [Event] = cacheService.get(cacheKey), 
           Date().timeIntervalSince(cached.first?.date ?? Date.distantPast) < 3600 {
            return cached
        }
        
        // Fetch from API
        let events = try await fetchEventsFromAPI()
        
        // Cache the result
        cacheService.set(events, forKey: cacheKey, ttl: 3600)
        
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
        
        let apiResponse = try JSONDecoder().decode(BerlinEventsResponse.self, from: data)
        
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
    init?(from berlinEvent: BerlinEvent) {
        guard let id = berlinEvent.id,
              let name = berlinEvent.name,
              let locationName = berlinEvent.location?.name,
              let lat = berlinEvent.location?.latitude,
              let lon = berlinEvent.location?.longitude,
              let dateString = berlinEvent.date?.start,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        
        self.id = id
        self.name = name
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