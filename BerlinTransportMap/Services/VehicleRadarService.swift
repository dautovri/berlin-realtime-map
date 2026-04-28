import Foundation
import CoreLocation

/// Service for fetching real-time vehicle positions from HAFAS REST API (VBB or DB endpoints).
actor VehicleRadarService {
    private var baseURL: String
    private let session: URLSession

    nonisolated(unsafe) private static let dateFormatterFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let dateFormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // Stored once each; avoids rebuilding decoders on every fetch.
    private let isoDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let tripDecoder = JSONDecoder()

    private let vehicleDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = VehicleRadarService.dateFormatterFull.date(from: dateString) {
                return date
            }
            if let date = VehicleRadarService.dateFormatterBasic.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return d
    }()

    private(set) var cityId: String = "berlin"

    init(city: CityConfig = .berlin) {
        self.baseURL = Env.resolvedBaseURL(for: city)
        self.cityId = city.id
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    /// Switch the service to a different city at runtime.
    /// Note: callers own their fetch Tasks and must cancel them on city change.
    func updateCity(_ city: CityConfig) {
        baseURL = Env.resolvedBaseURL(for: city)
        cityId = city.id
    }

    static func parseISO8601(_ string: String) -> Date? {
        if let d = dateFormatterFull.date(from: string) { return d }
        if let d = dateFormatterBasic.date(from: string) { return d }
        return nil
    }

    func fetchVehicles(
        north: Double,
        west: Double,
        south: Double,
        east: Double,
        duration: Int = 30
    ) async throws -> [Vehicle] {
        var components = URLComponents(string: "\(baseURL)/radar")!
        components.queryItems = [
            URLQueryItem(name: "north", value: String(north)),
            URLQueryItem(name: "west", value: String(west)),
            URLQueryItem(name: "south", value: String(south)),
            URLQueryItem(name: "east", value: String(east)),
            URLQueryItem(name: "duration", value: String(duration)),
            URLQueryItem(name: "results", value: "256"),
            URLQueryItem(name: "frames", value: "1"),
            URLQueryItem(name: "polylines", value: "false")
        ]

        guard let url = components.url else {
            throw TransportError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TransportError.networkError("Invalid response")
        }

        let radarResponse = try vehicleDecoder.decode(RadarResponse.self, from: data)

        return radarResponse.movements
    }

    func fetchDepartures(stopId: String, duration: Int = 60) async throws -> [RESTDeparture] {
        guard let encodedStopId = stopId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw TransportError.invalidURL
        }

        var components = URLComponents(string: "\(baseURL)/stops/\(encodedStopId)/departures")!
        components.queryItems = [
            URLQueryItem(name: "duration", value: String(duration)),
            URLQueryItem(name: "results", value: "30"),
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

        let departuresResponse = try isoDecoder.decode(DeparturesResponse.self, from: data)
        return departuresResponse.departures
    }

    func fetchTripRoute(tripId: String) async throws -> TripRoute? {
        guard let encodedTripId = tripId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw TransportError.invalidURL
        }

        var components = URLComponents(string: "\(baseURL)/trips/\(encodedTripId)")!
        components.queryItems = [
            URLQueryItem(name: "polyline", value: "true"),
            URLQueryItem(name: "stopovers", value: "true")
        ]

        guard let url = components.url else {
            throw TransportError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }

        let tripResponse = try tripDecoder.decode(TripResponse.self, from: data)
        return tripResponse.trip
    }
}

// MARK: - Trip Route Models

struct TripResponse: Decodable {
    let trip: TripRoute
}

struct TripRoute: Decodable {
    let id: String?
    let line: VehicleLine?
    let direction: String?
    let polyline: TripPolyline?
    let stopovers: [Stopover]?

    /// Extract coordinates from polyline features (Point geometries for stops)
    var routeCoordinates: [CLLocationCoordinate2D] {
        guard let features = polyline?.features else { return [] }
        return features.compactMap { feature -> CLLocationCoordinate2D? in
            guard let coords = feature.geometry?.coordinates,
                  coords.count >= 2 else { return nil }
            // GeoJSON is [longitude, latitude]
            return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
        }
    }
}

struct TripPolyline: Decodable {
    let type: String?
    let features: [PolylineFeature]?
}

struct PolylineFeature: Decodable {
    let type: String?
    let geometry: PolylineGeometry?
}

struct PolylineGeometry: Decodable {
    let type: String?
    let coordinates: [Double]?
}

struct Stopover: Decodable {
    let stop: RESTStop?
    let arrival: String?
    let departure: String?
}

// MARK: - Models

struct RadarResponse: Decodable {
    let movements: [Vehicle]
}

// MARK: - Departures Models

struct DeparturesResponse: Decodable {
    let departures: [RESTDeparture]
}

struct RESTDeparture: Identifiable, Decodable {
    let tripId: String
    let stop: RESTStop?
    let when: String?
    let plannedWhen: String?
    let delay: Int?
    let platform: String?
    let direction: String?
    let line: VehicleLine?
    let cancelled: Bool?

    var id: String { tripId }

    var displayTime: Date? {
        if let whenStr = when, let date = VehicleRadarService.parseISO8601(whenStr) {
            return date
        }
        if let plannedStr = plannedWhen, let date = VehicleRadarService.parseISO8601(plannedStr) {
            return date
        }
        return nil
    }

    var delayMinutes: Int? {
        guard let d = delay else { return nil }
        return d / 60
    }
}

struct RESTStop: Decodable {
    let id: String?
    let name: String?
}

struct VehicleStopInfo: Codable {
    let id: String?
    let name: String?
    let location: VehicleLocation?
}

struct VehicleStopoverEntry: Codable {
    let stop: VehicleStopInfo?
    let arrival: String?
    let plannedArrival: String?
    let departure: String?
    let plannedDeparture: String?

    /// Parsed arrival time (real-time if available, else scheduled).
    var arrivalDate: Date? {
        let s = arrival ?? plannedArrival
        guard let str = s else { return nil }
        return VehicleRadarService.parseISO8601(str)
    }

    /// Parsed departure time.
    var departureDate: Date? {
        let s = departure ?? plannedDeparture
        guard let str = s else { return nil }
        return VehicleRadarService.parseISO8601(str)
    }
}

struct Vehicle: Identifiable, Codable {
    let tripId: String
    let line: VehicleLine?
    let direction: String?
    let location: VehicleLocation?
    let when: String?
    let nextStopovers: [VehicleStopoverEntry]?

    var id: String { tripId }

    var currentLocation: CLLocationCoordinate2D? {
        guard let loc = location else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    private var nextAnchoredStopover: VehicleStopoverEntry? {
        let now = Date.now.addingTimeInterval(5)

        if let arrivalStop = nextStopovers?.first(where: {
            guard $0.stop?.location != nil, let arrival = $0.arrivalDate else { return false }
            return arrival > now
        }) {
            return arrivalStop
        }

        return nextStopovers?.first(where: {
            guard $0.stop?.location != nil else { return false }
            if let departure = $0.departureDate {
                return departure > now
            }
            if let arrival = $0.arrivalDate {
                return arrival > now
            }
            return false
        })
    }

    /// The next stop the vehicle is heading toward, with its arrival time and coordinates.
    var nextStopCoordinate: CLLocationCoordinate2D? {
        guard let stop = nextAnchoredStopover?.stop?.location else { return nil }
        return CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
    }

    var nextStopArrival: Date? {
        nextAnchoredStopover?.arrivalDate ?? nextAnchoredStopover?.departureDate
    }
}

struct LineColor: Codable {
    let fg: String?
    let bg: String?
}

struct VehicleLine: Codable {
    let id: String?
    let name: String?
    let mode: String?
    let product: String?
    let fahrtNr: String?
    let colorData: LineColor?

    enum CodingKeys: String, CodingKey {
        case id, name, mode, product, fahrtNr
        case colorData = "color"
    }

    var displayName: String {
        name ?? id ?? "?"
    }

    var productType: VehicleProduct {
        switch product?.lowercased() {
        case "suburban": return .suburbanTrain
        case "subway": return .subway
        case "tram": return .tram
        case "bus": return .bus
        case "ferry": return .ferry
        case "regional", "express": return .regionalTrain
        default: return .bus
        }
    }

    var color: String {
        if let bg = colorData?.bg, !bg.isEmpty {
            return bg
        }
        switch productType {
        case .suburbanTrain: return "#008C3C"
        case .subway: return "#0066CC"
        case .tram: return "#D8232A"
        case .bus: return "#993399"
        case .ferry: return "#0099CC"
        case .regionalTrain: return "#EC192E"
        }
    }

    var foregroundColor: String {
        if let fg = colorData?.fg, !fg.isEmpty {
            return fg
        }
        return "#FFFFFF"
    }
}

enum VehicleProduct: String {
    case suburbanTrain, subway, tram, bus, ferry, regionalTrain
}

struct VehicleLocation: Codable {
    let latitude: Double
    let longitude: Double
}
