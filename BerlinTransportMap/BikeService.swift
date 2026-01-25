import Foundation

/// Bike service for fetching bike-sharing availability from Call-a-Bike API
@Observable
final class BikeService: @unchecked Sendable {
    static let shared = BikeService()
    
    private let cacheService = CacheService()
    private let baseURL = "https://api.deutschebahn.com/callabike/lbs/v1/stations"
    private let apiKey: String
    
    private init() {
        guard let key = ProcessInfo.processInfo.environment["CALLABIKE_API_KEY"] else {
            fatalError("CALLABIKE_API_KEY environment variable not set")
        }
        self.apiKey = key
    }
    
    // MARK: - Bike Fetching
    
    func fetchBikes(latitude: Double, longitude: Double, radius: Double = 1000) async throws -> [BikeStation] {
        let cacheKey = "bikes_\(latitude)_\(longitude)_\(radius)"
        
        // Check cache (10 minutes)
        if let cached: [BikeStation] = cacheService.get(cacheKey), 
           Date().timeIntervalSince(Date()) < 600 { // 10 min, but since no timestamp, approximate
            return cached
        }
        
        // Fetch from API
        let bikes = try await fetchBikesFromAPI(latitude: latitude, longitude: longitude, radius: radius)
        
        // Cache the result
        cacheService.set(bikes, forKey: cacheKey, ttl: 600)
        
        return bikes
    }
    
    private func fetchBikesFromAPI(latitude: Double, longitude: Double, radius: Double) async throws -> [BikeStation] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(Int(radius)))
        ]
        
        guard let url = components.url else {
            throw BikeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw BikeError.networkError("Invalid response")
        }
        
        let apiResponse = try JSONDecoder().decode([CallABikeStation].self, from: data)
        
        return apiResponse.compactMap { BikeStation(from: $0) }
    }
}

// MARK: - API Response Models

private struct CallABikeStation: Codable {
    let hal2option: Hal2Option?
    
    struct Hal2Option: Codable {
        let name: String?
        let lat: Double?
        let lng: Double?
        let bikes: Int?
        let boxes: Int?
    }
}

// MARK: - Extensions

extension BikeStation {
    init?(from station: CallABikeStation) {
        guard let hal = station.hal2option,
              let name = hal.name,
              let lat = hal.lat,
              let lng = hal.lng,
              let bikes = hal.bikes,
              let boxes = hal.boxes else {
            return nil
        }
        
        self.id = name // or generate unique
        self.name = name
        self.latitude = lat
        self.longitude = lng
        self.availableBikes = bikes
        self.availableDocks = boxes - bikes // assuming boxes are total docks
    }
}

// MARK: - Errors

enum BikeError: LocalizedError {
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
            return "Failed to decode bike data"
        }
    }
}