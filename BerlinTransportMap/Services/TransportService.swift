import CoreLocation
import Foundation
import Observation

/// Transport service using HAFAS REST API (VBB or DB endpoints).
@MainActor
@Observable
final class TransportService {
    private var baseURL: String
    private(set) var cityId: String
    private let session: URLSession
    private let offlineDatabase = OfflineStopsDatabase.shared
    private let decoder = JSONDecoder()
    private let isoDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(city: CityConfig = .berlin) {
        self.baseURL = Env.resolvedBaseURL(for: city)
        self.cityId = city.id
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    /// Switch the service to a different city at runtime.
    /// Note: views that hold their own load Tasks are responsible for cancelling them
    /// on city change (see TransportMapView's onChange handler) — the service can't
    /// own task lifetimes because callers are the ones still alive after a fetch returns.
    func updateCity(_ city: CityConfig) {
        baseURL = Env.resolvedBaseURL(for: city)
        cityId = city.id
    }

    func queryNearbyStops(latitude: Double, longitude: Double, maxDistance: Int = 2000, maxLocations: Int = 50) async throws -> [TransportStop] {
        try Task.checkCancellation()

        var components = URLComponents(string: "\(baseURL)/locations/nearby")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "distance", value: String(maxDistance)),
            URLQueryItem(name: "results", value: String(maxLocations)),
            URLQueryItem(name: "type", value: "station")
        ]

        guard let url = components.url else {
            throw TransportError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TransportError.networkError("Invalid response")
        }

        try Task.checkCancellation()

        let locations = try decoder.decode([VBBSimpleLocation].self, from: data)
        return locations.map { TransportStop(from: $0) }
    }

    func queryDepartures(stationId: String, maxDepartures: Int = 20) async throws -> [TransportDeparture] {
        try Task.checkCancellation()

        guard let encodedId = stationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw TransportError.invalidURL
        }

        var components = URLComponents(string: "\(baseURL)/stops/\(encodedId)/departures")!
        components.queryItems = [
            URLQueryItem(name: "results", value: String(maxDepartures)),
            URLQueryItem(name: "linesOfStops", value: "false"),
            URLQueryItem(name: "remarks", value: "false")
        ]

        guard let url = components.url else {
            throw TransportError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransportError.networkError("Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TransportError.networkError("HTTP \(httpResponse.statusCode)")
        }

        try Task.checkCancellation()

        let departures = try isoDecoder.decode([VBBDeparture].self, from: data)
        return departures.map { TransportDeparture(from: $0) }
    }

    func searchLocations(query: String, maxLocations: Int = 20) async throws -> [TransportStop] {
        try Task.checkCancellation()

        // Only short-circuit to the offline DB when it actually represents the active city.
        // Otherwise we'd serve Berlin matches to a Munich query.
        await offlineDatabase.loadIfNeeded()
        let activeOfflineCity = await offlineDatabase.activeCityId()
        if activeOfflineCity == cityId {
            let offlineResults = await offlineDatabase.searchStops(query: query)
            if !offlineResults.isEmpty {
                return Array(offlineResults.prefix(maxLocations))
            }
        }

        // Fallback to API if offline DB has no results
        var components = URLComponents(string: "\(baseURL)/locations")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "results", value: String(maxLocations)),
            URLQueryItem(name: "type", value: "station"),
            URLQueryItem(name: "stops", value: "true"),
            URLQueryItem(name: "addresses", value: "false"),
            URLQueryItem(name: "poi", value: "false")
        ]

        guard let url = components.url else {
            throw TransportError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TransportError.networkError("Invalid response")
        }

        try Task.checkCancellation()

        let locations = try decoder.decode([VBBSimpleLocation].self, from: data)
        return locations.map { TransportStop(from: $0) }
    }
}
