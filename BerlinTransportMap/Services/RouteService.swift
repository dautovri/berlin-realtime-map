import Foundation
import CoreLocation

@MainActor
@Observable
final class RouteService {
    private var baseURL: String
    private let session: URLSession

    init(city: CityConfig = .berlin) {
        self.baseURL = Env.resolvedBaseURL(for: city)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Switch the service to a different city at runtime.
    func updateCity(_ city: CityConfig) {
        baseURL = Env.resolvedBaseURL(for: city)
    }

    func planRoute(start: TransportStop, end: TransportStop, mode: TransportMode, includeBikes: Bool = false) async throws -> Route {
        try Task.checkCancellation()

        var components = URLComponents(string: "\(baseURL)/journeys")!
        components.queryItems = [
            URLQueryItem(name: "from", value: start.id),
            URLQueryItem(name: "to", value: end.id),
            URLQueryItem(name: "results", value: "3"),
            URLQueryItem(name: "departure", value: "now")
        ]

        guard let url = components.url else {
            throw RouteError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RouteError.networkError("Invalid response")
        }

        try Task.checkCancellation()

        let decoder = JSONDecoder()
        let journeysResponse = try decoder.decode(VBBJourneysResponse.self, from: data)

        guard let firstJourney = journeysResponse.journeys.first else {
            throw RouteError.noRoutesFound
        }

        return Route(from: firstJourney)
    }
}

// MARK: - VBB API Models (/journeys)

struct VBBJourneysResponse: Decodable {
    let journeys: [VBBJourney]
}

struct VBBJourney: Decodable {
    let legs: [VBBJourneyLeg]
}

struct VBBJourneyLeg: Decodable {
    let origin: VBBJourneyStop?
    let destination: VBBJourneyStop?
    let departure: String?
    let plannedDeparture: String?
    let arrival: String?
    let plannedArrival: String?
    let line: VBBLine?
    let walking: Bool?
}

struct VBBJourneyStop: Decodable {
    let id: String?
    let name: String?
    let location: VBBJourneyCoordinate?
}

struct VBBJourneyCoordinate: Decodable {
    let latitude: Double?
    let longitude: Double?
}

struct VBBLine: Decodable {
    let id: String?
    let name: String?
    let publicCode: String?
    let product: String?
    let operatorCode: String?
}

// MARK: - Domain Models

enum TransportMode: String, CaseIterable, Identifiable {
    case train = "Train"
    case bus = "Bus"
    case subway = "Subway"
    case tram = "Tram"

    var id: String { self.rawValue }
}

struct Route {
    let id: String
    let legs: [RouteLeg]
    let totalDuration: TimeInterval
    let departureTime: Date
    let arrivalTime: Date

    var coordinates: [CLLocationCoordinate2D] {
        legs.flatMap { $0.coordinates }
    }

    init(from vbbJourney: VBBJourney) {
        self.id = UUID().uuidString
        self.legs = vbbJourney.legs.compactMap { RouteLeg(from: $0) }

        let dep = self.legs.first?.departureTime ?? Date()
        let arr = self.legs.last?.arrivalTime ?? Date()
        self.departureTime = dep
        self.arrivalTime = arr
        self.totalDuration = max(arr.timeIntervalSince(dep), 0)
    }

    init(id: String, legs: [RouteLeg], totalDuration: TimeInterval, departureTime: Date, arrivalTime: Date) {
        self.id = id
        self.legs = legs
        self.totalDuration = totalDuration
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
    }
}

struct RouteLeg {
    let type: String
    let departureStop: TransportStop?
    let arrivalStop: TransportStop?
    let departureTime: Date?
    let arrivalTime: Date?
    let line: TransportLine?
    let coordinates: [CLLocationCoordinate2D]

    init?(from vbbLeg: VBBJourneyLeg) {
        self.type = (vbbLeg.walking == true) ? "walking" : "publicTransport"

        self.departureStop = vbbLeg.origin.map { stop in
            TransportStop(
                id: stop.id ?? UUID().uuidString,
                name: stop.name ?? "Unknown",
                latitude: stop.location?.latitude ?? 0,
                longitude: stop.location?.longitude ?? 0
            )
        }

        self.arrivalStop = vbbLeg.destination.map { stop in
            TransportStop(
                id: stop.id ?? UUID().uuidString,
                name: stop.name ?? "Unknown",
                latitude: stop.location?.latitude ?? 0,
                longitude: stop.location?.longitude ?? 0
            )
        }

        let depStr = vbbLeg.departure ?? vbbLeg.plannedDeparture
        let arrStr = vbbLeg.arrival ?? vbbLeg.plannedArrival
        self.departureTime = parseISO8601(depStr)
        self.arrivalTime = parseISO8601(arrStr)

        self.line = vbbLeg.line.map { l in
            TransportLine(vbbLineId: l.id, vbbLineName: l.name, vbbLinePublicCode: l.publicCode, vbbLineProduct: l.product)
        }
        self.coordinates = []
    }

    init(type: String, departureTime: Date?, arrivalTime: Date?, coordinates: [CLLocationCoordinate2D]) {
        self.type = type
        self.departureStop = nil
        self.arrivalStop = nil
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.line = nil
        self.coordinates = coordinates
    }
}

// MARK: - Date Parsing

private func parseISO8601(_ string: String?) -> Date? {
    guard let string else { return nil }
    // Try with fractional seconds first, then without
    let withFrac = ISO8601DateFormatter()
    withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFrac.date(from: string) { return date }
    return ISO8601DateFormatter().date(from: string)
}

// MARK: - Errors

enum RouteError: LocalizedError {
    case noRoutesFound
    case networkError(String)
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .noRoutesFound:
            return "No routes found for the selected stops and mode"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidRequest:
            return "Invalid request"
        }
    }
}
