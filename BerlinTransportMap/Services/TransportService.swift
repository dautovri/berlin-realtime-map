import CoreLocation
import Foundation
import Observation

/// Transport service using VBB REST API (https://v6.vbb.transport.rest)
@MainActor
@Observable
final class TransportService {
    private let baseURL = "https://v6.vbb.transport.rest"
    private let session: URLSession
    private let offlineDatabase = OfflineStopsDatabase.shared
    private let decoder = JSONDecoder()
    private let isoDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
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

        // Try offline database first for instant results
        await offlineDatabase.loadIfNeeded()
        let offlineResults = await offlineDatabase.searchStops(query: query)
        
        if !offlineResults.isEmpty {
            return Array(offlineResults.prefix(maxLocations))
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
