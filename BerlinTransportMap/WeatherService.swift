import Foundation

/// Weather service for fetching weather data from OpenWeatherMap
@Observable
final class WeatherService: @unchecked Sendable {
    static let shared = WeatherService()
    
    private let cacheService = CacheService()
    private let apiKey: String
    
    private init() {
        guard let key = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] else {
            fatalError("OPENWEATHER_API_KEY environment variable not set")
        }
        self.apiKey = key
    }
    
    // MARK: - Weather Fetching
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let cacheKey = "weather_\(latitude)_\(longitude)"
        
        // Check cache (30 minutes)
        if let cached: Weather = cacheService.get(cacheKey), 
           Date().timeIntervalSince(cached.timestamp) < 1800 { // 30 min
            return cached
        }
        
        // Fetch from API
        let weather = try await fetchWeatherFromAPI(latitude: latitude, longitude: longitude)
        
        // Cache the result
        cacheService.set(weather, forKey: cacheKey, ttl: 1800)
        
        return weather
    }
    
    private func fetchWeatherFromAPI(latitude: Double, longitude: Double) async throws -> Weather {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherError.networkError("Invalid response")
        }
        
        let apiResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
        
        let precipitationProb = (apiResponse.rain?.oneHour ?? 0) > 0 || (apiResponse.snow?.oneHour ?? 0) > 0 ? 0.8 : 0.0
        
        return Weather(
            temperature: apiResponse.main.temp,
            condition: apiResponse.weather.first?.main ?? "Unknown",
            precipitationProbability: precipitationProb,
            icon: apiResponse.weather.first?.icon ?? "",
            timestamp: Date()
        )
    }
}

// MARK: - API Response Models

private struct OpenWeatherResponse: Codable {
    let weather: [WeatherInfo]
    let main: MainInfo
    let rain: PrecipitationInfo?
    let snow: PrecipitationInfo?
}

private struct WeatherInfo: Codable {
    let main: String
    let icon: String
}

private struct MainInfo: Codable {
    let temp: Double
}

private struct PrecipitationInfo: Codable {
    let oneHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
    }
}

// MARK: - Errors

enum WeatherError: LocalizedError {
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
            return "Failed to decode weather data"
        }
    }
}