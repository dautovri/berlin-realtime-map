import Foundation

/// Parking service for fetching parking availability from Berlin's open data API
@Observable
final class ParkingService: @unchecked Sendable {
    static let shared = ParkingService()
    
    private let cacheService = CacheService()
    private let baseURL = "https://api.berlin.de/parkleitsystem/parking"
    
    private init() {}
    
    // MARK: - Parking Fetching
    
    func fetchParking(latitude: Double, longitude: Double, radius: Double = 2000) async throws -> [ParkingFacility] {
        let cacheKey = "parking_\(latitude)_\(longitude)_\(radius)"
        
        // Check cache (5 minutes)
        if let cached: [ParkingFacility] = cacheService.get(cacheKey), 
           Date().timeIntervalSince(Date()) < 300 { // 5 min
            return cached
        }
        
        // Fetch from API
        let parking = try await fetchParkingFromAPI(latitude: latitude, longitude: longitude, radius: radius)
        
        // Cache the result
        cacheService.set(parking, forKey: cacheKey, ttl: 300)
        
        return parking
    }
    
    private func fetchParkingFromAPI(latitude: Double, longitude: Double, radius: Double) async throws -> [ParkingFacility] {
        let urlString = "\(baseURL)?lat=\(latitude)&lng=\(longitude)&radius=\(Int(radius))"
        guard let url = URL(string: urlString) else {
            throw ParkingError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ParkingError.networkError("Invalid response")
        }
        
        let apiResponse = try JSONDecoder().decode([BerlinParkingFacility].self, from: data)
        
        return apiResponse.compactMap { ParkingFacility(from: $0) }
    }
}

// MARK: - API Response Models

private struct BerlinParkingFacility: Codable {
    let id: String
    let name: String
    let lat: Double?
    let lng: Double?
    let free: Int?
    let total: Int?
}

// MARK: - Extensions

extension ParkingFacility {
    init?(from facility: BerlinParkingFacility) {
        guard let id = facility.id,
              let name = facility.name,
              let lat = facility.lat,
              let lng = facility.lng,
              let free = facility.free,
              let total = facility.total else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.latitude = lat
        self.longitude = lng
        self.availableSpaces = free
        self.totalSpaces = total
    }
}

// MARK: - Errors

enum ParkingError: LocalizedError {
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
            return "Failed to decode parking data"
        }
    }
}