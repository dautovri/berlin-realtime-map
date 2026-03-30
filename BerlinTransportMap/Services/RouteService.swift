import Foundation
import CoreLocation

@MainActor
@Observable
final class RouteService {
    private let baseURL = "https://v6.vbb.transport.rest"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func planRoute(start: TransportStop, end: TransportStop, mode: TransportMode, includeBikes: Bool = false) async throws -> Route {
        try Task.checkCancellation()

        guard let fromEncoded = start.id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let toEncoded = end.id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw RouteError.invalidRequest
        }

        var components = URLComponents(string: "\(baseURL)/trips")!
        components.queryItems = [
            URLQueryItem(name: "from", value: fromEncoded),
            URLQueryItem(name: "to", value: toEncoded),
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
        decoder.dateDecodingStrategy = .iso8601
        let tripsResponse = try decoder.decode(VBBTripsResponse.self, from: data)

        guard let firstTrip = tripsResponse.trips.first else {
            throw RouteError.noRoutesFound
        }

        return Route(from: firstTrip)
    }
}

struct VBBTripsResponse: Decodable {
    let trips: [VBBTrip]
}

struct VBBTrip: Decodable {
    let id: String?
    let startTime: Date?
    let endTime: Date?
    let duration: Int?
    let legs: [VBBLeg]?
}

struct VBBLeg: Decodable {
    let line: VBBLine?
    let departure: VBBStopTime?
    let arrival: VBBStopTime?
    let distance: Int?
    let polyline: String?
}

struct VBBLine: Decodable {
    let id: String?
    let name: String?
    let publicCode: String?
    let product: String?
    let operatorCode: String?
}

struct VBBStop: Decodable {
    let id: String?
    let name: String?
}

struct VBBStopTime: Decodable {
    let stop: VBBStop?
    let time: String?
}

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

    init(from vbbTrip: VBBTrip) {
        self.id = vbbTrip.id ?? UUID().uuidString
        self.totalDuration = TimeInterval(vbbTrip.duration ?? 0)
        self.departureTime = vbbTrip.startTime ?? Date()
        self.arrivalTime = vbbTrip.endTime ?? Date()
        self.legs = vbbTrip.legs?.compactMap { RouteLeg(from: $0) } ?? []
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

    init?(from vbbLeg: VBBLeg) {
        self.type = vbbLeg.line != nil ? "publicTransport" : "walking"

        if let depStop = vbbLeg.departure?.stop {
            self.departureStop = TransportStop(
                id: depStop.id ?? UUID().uuidString,
                name: depStop.name ?? "Unknown",
                latitude: 0,
                longitude: 0
            )
        } else {
            self.departureStop = nil
        }

        if let arrStop = vbbLeg.arrival?.stop {
            self.arrivalStop = TransportStop(
                id: arrStop.id ?? UUID().uuidString,
                name: arrStop.name ?? "Unknown",
                latitude: 0,
                longitude: 0
            )
        } else {
            self.arrivalStop = nil
        }

        self.line = vbbLeg.line.map { line in
            TransportLine(vbbLineId: line.id, vbbLineName: line.name, vbbLinePublicCode: line.publicCode, vbbLineProduct: line.product)
        }
        self.departureTime = nil
        self.arrivalTime = nil
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
