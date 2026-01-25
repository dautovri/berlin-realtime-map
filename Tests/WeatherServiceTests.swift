import XCTest
@testable import BerlinTransportMap

class WeatherServiceTests: XCTestCase {

    var weatherService: WeatherService!
    var mockCacheService: MockCacheService!
    var mockURLSession: MockURLSession!

    override func setUp() {
        super.setUp()
        // Note: WeatherService is a singleton, but for testing we might need to inject dependencies.
        // For now, we'll test the methods directly.
        // To properly test, we might need to refactor WeatherService to accept cacheService and URLSession as dependencies.
    }

    override func tearDown() {
        weatherService = nil
        mockCacheService = nil
        mockURLSession = nil
        super.tearDown()
    }

    func testWeatherStructInitialization() {
        let timestamp = Date()
        let weather = Weather(
            temperature: 20.0,
            condition: "Clear",
            precipitationProbability: 0.0,
            icon: "01d",
            timestamp: timestamp
        )

        XCTAssertEqual(weather.temperature, 20.0)
        XCTAssertEqual(weather.condition, "Clear")
        XCTAssertEqual(weather.precipitationProbability, 0.0)
        XCTAssertEqual(weather.icon, "01d")
        XCTAssertEqual(weather.timestamp, timestamp)
    }

    func testWeatherErrorDescriptions() {
        let invalidURLError = WeatherError.invalidURL
        XCTAssertEqual(invalidURLError.errorDescription, "Invalid URL")

        let networkError = WeatherError.networkError("Connection failed")
        XCTAssertEqual(networkError.errorDescription, "Network error: Connection failed")

        let decodingError = WeatherError.decodingError
        XCTAssertEqual(decodingError.errorDescription, "Failed to decode weather data")
    }

    // Note: Full integration tests for fetchWeather would require API key and network mocking.
    // For now, basic struct tests are covered.
    // To improve: Add protocol for URLSession and CacheService, inject mocks.
}