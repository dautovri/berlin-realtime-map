import Foundation
import TripKit
import CoreLocation

/// Transport service using TripKit for Berlin public transport data
@Observable
final class TransportService: @unchecked Sendable {
    private let provider: BvgProvider
    private let backgroundQueue = DispatchQueue.global(qos: .background)

    // BVG API authorization - these are public keys used by the BVG app
    nonisolated(unsafe) private static let apiAuthorization: [String: Any] = [
        "type": "AID",
        "aid": "1Rxs112shyHLatUX4fofnmdxK"
    ]

    init() {
        self.provider = BvgProvider(apiAuthorization: Self.apiAuthorization)
    }

    // MARK: - Error Mapping

    private func mapTripKitFailure(_ error: Error) throws -> TransportError {
        if error is CancellationError {
            throw error
        }

        if let urlError = error as? URLError {
            return .networkError("\(urlError.code.rawValue) \(urlError.code)")
        }

        // Prefer a stable/debuggable message over an often-empty localizedDescription.
        let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
        return .networkError(message)
    }

    // MARK: - Query Nearby Stops

    func queryNearbyStops(latitude: Double, longitude: Double, maxDistance: Int = 2000, maxLocations: Int = 50) async throws -> [TransportStop] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        // TripKit uses Int coordinates (lat/lon * 1e6)
                        let lat = Int(latitude * 1_000_000)
                        let lon = Int(longitude * 1_000_000)
                        
                        let location = Location(lat: lat, lon: lon)
                        
                        let (_, result) = await self.provider.queryNearbyLocations(
                            location: location,
                            types: [.station],
                            maxDistance: maxDistance,
                            maxLocations: maxLocations
                        )
                        
                        switch result {
                        case .success(let locations):
                            try Task.checkCancellation()
                            let stops = locations.compactMap { TransportStop(from: $0) }
                            continuation.resume(returning: stops)
                        case .invalidId:
                            continuation.resume(throwing: TransportError.invalidLocation)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Query Departures

    func queryDepartures(stationId: String, maxDepartures: Int = 20) async throws -> [TransportDeparture] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        let (_, result) = await self.provider.queryDepartures(
                            stationId: stationId,
                            departures: true,
                            time: nil,
                            maxDepartures: maxDepartures,
                            equivs: false
                        )
                        
                        switch result {
                        case .success(let stationDepartures):
                            try Task.checkCancellation()
                            let departures = stationDepartures.flatMap { stationDep in
                                stationDep.departures.compactMap { TransportDeparture(from: $0, stop: stationDep.stopLocation) }
                            }
                            continuation.resume(returning: departures)
                        case .invalidStation:
                            continuation.resume(throwing: TransportError.invalidStation)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Search Locations

    func searchLocations(query: String, maxLocations: Int = 20) async throws -> [TransportStop] {
        try await withCheckedThrowingContinuation { continuation in
            backgroundQueue.async {
                Task {
                    do {
                        try Task.checkCancellation()
                        
                        let (_, result) = await self.provider.suggestLocations(
                            constraint: query,
                            types: [.station],
                            maxLocations: maxLocations
                        )
                        
                        switch result {
                        case .success(let suggestions):
                            try Task.checkCancellation()
                            let stops = suggestions.compactMap { TransportStop(from: $0.location) }
                            continuation.resume(returning: stops)
                        case .failure(let error):
                            continuation.resume(throwing: try self.mapTripKitFailure(error))
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Batch query nearby stops and their departures for efficient data fetching
    func queryNearbyStopsAndDepartures(latitude: Double, longitude: Double, maxDistance: Int = 2000, maxStops: Int = 10, maxDeparturesPerStop: Int = 10) async throws -> ([TransportStop], [TransportDeparture]) {
        let stops = try await queryNearbyStops(latitude: latitude, longitude: longitude, maxDistance: maxDistance, maxLocations: maxStops)
        
        let departures = try await withThrowingTaskGroup(of: [TransportDeparture].self) { group in
            for stop in stops.prefix(5) { // Limit to top 5 stops to batch efficiently
                group.addTask {
                    try await self.queryDepartures(stationId: stop.vbbStopId, maxDepartures: maxDeparturesPerStop)
                }
            }
            var allDepartures: [TransportDeparture] = []
            for try await deps in group {
                allDepartures.append(contentsOf: deps)
            }
            return allDepartures
        }
        
        return (stops, departures)
    }
}
}

// MARK: - Models

struct TransportStop: Identifiable, Hashable {
    let id: String
    let name: String
    let place: String?
    let latitude: Double
    let longitude: Double
    let products: [TransportProduct]

    init(
        id: String,
        name: String,
        place: String?,
        latitude: Double,
        longitude: Double,
        products: [TransportProduct] = []
    ) {
        self.id = id
        self.name = name
        self.place = place
        self.latitude = latitude
        self.longitude = longitude
        self.products = products
    }

    /// The VBB REST API compatible stop ID (IBNR format like 900110011)
    var vbbStopId: String {
        // TripKit returns IDs in HAFAS format like:
        // "A=1@O=Station Name@X=13404953@Y=52520008@U=86@L=900100003@"
        // We need to extract the IBNR from "L=900100003"

        if let lRange = id.range(of: "L=") {
            let startIndex = lRange.upperBound
            let remaining = id[startIndex...]
            if let endIndex = remaining.firstIndex(of: "@") {
                return String(remaining[..<endIndex])
            } else {
                return String(remaining)
            }
        }

        // Fallback: if format is "de:11000:900140016" -> extract "900140016"
        if id.contains(":") {
            return id.components(separatedBy: ":").last ?? id
        }

        // Fallback: return as-is
        return id
    }

    init?(from location: Location) {
        guard let id = location.id,
              let coord = location.coord else {
            return nil
        }

        self.id = id
        self.name = location.name ?? "Unknown"
        self.place = location.place
        self.latitude = Double(coord.lat) / 1_000_000
        self.longitude = Double(coord.lon) / 1_000_000
        self.products = location.products ?? []
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TransportStop, rhs: TransportStop) -> Bool {
        lhs.id == rhs.id
    }
}

struct TransportDeparture: Identifiable {
    let id: String
    let line: TransportLine
    let destination: String
    let plannedTime: Date?
    let predictedTime: Date?
    let delay: TimeInterval?
    let platform: String?
    let isCancelled: Bool
    let stopId: String
    let stopName: String
    let stopLatitude: Double
    let stopLongitude: Double

    var displayTime: Date? {
        predictedTime ?? plannedTime
    }

    var delayMinutes: Int? {
        guard let delay = delay else { return nil }
        return Int(delay / 60)
    }

    init?(from departure: Departure, stop: Location) {
        guard let coord = stop.coord else {
            return nil
        }

        let line = departure.line

        let uniqueId = "\(departure.plannedTime.timeIntervalSince1970)_\(line.label ?? "")_\(stop.id ?? "")"
        self.id = uniqueId
        self.line = TransportLine(from: line)
        self.destination = departure.destination?.name ?? departure.destination?.place ?? "Unknown"
        self.plannedTime = departure.plannedTime
        self.predictedTime = departure.predictedTime
        self.delay = departure.predictedTime != nil
            ? departure.predictedTime!.timeIntervalSince(departure.plannedTime)
            : nil
        self.platform = departure.predictedPlatform ?? departure.plannedPlatform
        self.isCancelled = departure.cancelled
        self.stopId = stop.id ?? ""
        self.stopName = stop.name ?? "Unknown"
        self.stopLatitude = Double(coord.lat) / 1_000_000
        self.stopLongitude = Double(coord.lon) / 1_000_000
    }
}

struct TransportLine {
    let id: String?
    let label: String
    let name: String?
    let product: TransportProduct
    let style: LineStyle?

    var displayName: String {
        label
    }

    var color: String {
        if let style = style, let bg = style.backgroundColor {
            return String(format: "#%06X", bg & 0xFFFFFF)
        }

        switch product {
        case .suburbanTrain: return "#008C3C"
        case .subway: return "#0066CC"
        case .tram: return "#CC0000"
        case .bus: return "#993399"
        case .ferry: return "#0099CC"
        case .regionalTrain, .highSpeedTrain: return "#EC192E"
        default: return "#666666"
        }
    }

    var foregroundColor: String {
        if let style = style, let fg = style.foregroundColor {
            return String(format: "#%06X", fg & 0xFFFFFF)
        }
        return "#FFFFFF"
    }

    init(from line: Line) {
        self.id = line.id
        self.label = line.label ?? line.name ?? "?"
        self.name = line.name
        self.product = line.product ?? .bus
        self.style = line.style
    }
}

typealias TransportProduct = Product

// MARK: - Errors

enum TransportError: LocalizedError {
    case invalidLocation
    case invalidStation
    case networkError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Invalid location"
        case .invalidStation:
            return "Invalid station"
        case .networkError(let message):
            return "Network error: \(message)"
        case .noData:
            return "No data available"
        }
    }
}
