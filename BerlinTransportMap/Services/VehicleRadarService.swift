import Foundation
import CoreLocation

/// Service for fetching real-time vehicle positions from VBB REST API (Berlin-Brandenburg region)
actor VehicleRadarService {
    private let baseURL = "https://v6.vbb.transport.rest"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
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
            URLQueryItem(name: "results", value: "500"),
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        let radarResponse = try decoder.decode(RadarResponse.self, from: data)

        var vehicles = radarResponse.movements

        for i in vehicles.indices {
            await vehicles[i].updateSpeed()
        }

        return vehicles
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let departuresResponse = try decoder.decode(DeparturesResponse.self, from: data)
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

        let decoder = JSONDecoder()
        let tripResponse = try decoder.decode(TripResponse.self, from: data)
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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        if let whenStr = when, let date = formatter.date(from: whenStr) {
            return date
        }
        if let plannedStr = plannedWhen, let date = formatter.date(from: plannedStr) {
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

struct Vehicle: Identifiable, Codable {
    let tripId: String
    let line: VehicleLine?
    let direction: String?
    let location: VehicleLocation?
    let when: String?

    var id: String { tripId }

    var currentLocation: CLLocationCoordinate2D? {
        guard let loc = location else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    var speedKPH: Double? {
        cachedSpeeds[tripId]
    }

    mutating func updateSpeed() async {
        guard let whenStr = when else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let timestamp = formatter.date(from: whenStr) {
            if let speed = await positionTracker.updatePosition(for: self, timestamp: timestamp) {
                cachedSpeeds[tripId] = speed
            }
        }
    }
}

private var cachedSpeeds: [String: Double] = [:]

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

// MARK: - Speed Tracking

actor VehiclePositionTracker {
    private var lastPositions: [String: (coordinate: CLLocationCoordinate2D, timestamp: Date, speed: Double)] = [:]
    private let maxAge: TimeInterval = 60

    func updatePosition(for vehicle: Vehicle, timestamp: Date) -> Double? {
        guard let coordinate = vehicle.currentLocation else { return nil }
        let now = timestamp

        if let last = lastPositions[vehicle.id] {
            let age = now.timeIntervalSince(last.timestamp)
            if age > 0 && age < maxAge {
                let oldLocation = CLLocation(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
                let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = newLocation.distance(from: oldLocation)
                let speedMPS = distance / age
                let speedKPH = speedMPS * 3.6

                lastPositions[vehicle.id] = (coordinate, now, speedKPH)
                return speedKPH
            }
        }

        lastPositions[vehicle.id] = (coordinate, now, 0)
        return nil
    }

    func getSpeed(for vehicleId: String) -> Double? {
        return lastPositions[vehicleId]?.speed
    }

    func cleanup() {
        let now = Date()
        lastPositions = lastPositions.filter { now.timeIntervalSince($0.value.timestamp) < maxAge }
    }
}

let positionTracker = VehiclePositionTracker()
