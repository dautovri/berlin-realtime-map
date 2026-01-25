import Foundation
import TripKit
import CoreLocation

/// Service for planning routes between stops using TripKit VBB provider
@Observable
final class RouteService: @unchecked Sendable {
    private let provider: BvgProvider
    
    var lastWeather: Weather?
    
    // BVG API authorization - same as TransportService
    nonisolated(unsafe) private static let apiAuthorization: [String: Any] = [
        "type": "AID",
        "aid": "1Rxs112shyHLatUX4fofnmdxK"
    ]
    
    init() {
        self.provider = BvgProvider(apiAuthorization: Self.apiAuthorization)
    }
    
    /// Plan a route between two stops with specified transport mode
    func planRoute(start: TransportStop, end: TransportStop, mode: TransportMode, weather: Weather? = nil, includeBikes: Bool = false) async throws -> Route {
        try Task.checkCancellation()
        
        // Convert TransportMode to TripKit products
        let products = transportModeToProducts(mode)
        
        // Adjust optimization based on weather and bikes
        let optimize: Optimize
        let maxWalkDistance: Int
        if includeBikes {
            // Include bikes: prefer walking/biking
            optimize = .leastWalking
            maxWalkDistance = 3000
        } else if let weather = weather, weather.temperature > 15, weather.precipitationProbability < 0.1 {
            // Good weather: prefer walking
            optimize = .leastWalking
            maxWalkDistance = 2000
        } else {
            // Bad or unknown weather: quick routes
            optimize = .quick
            maxWalkDistance = 1000
        }
        
        // Create TripRequest
        let request = TripRequest(
            from: start.tripKitLocation,
            to: end.tripKitLocation,
            via: nil,
            date: Date(),
            departure: true,
            products: products,
            optimize: optimize,
            options: [:],
            accessibility: .neutral,
            maxChanges: -1,
            walkingSpeed: .normal,
            maxWalkDistance: maxWalkDistance
        )
        
        self.lastWeather = weather
        
        let (_, result) = await provider.planTrip(request: request)
        
        switch result {
        case .success(let trips):
            try Task.checkCancellation()
            guard let firstTrip = trips.first else {
                throw RouteError.noRoutesFound
            }
            return Route(from: firstTrip)
        case .failure(let error):
            throw try mapTripKitFailure(error)
        }
    }
    
    private func transportModeToProducts(_ mode: TransportMode) -> [Product] {
        switch mode {
        case .train:
            return [.suburbanTrain, .regionalTrain, .highSpeedTrain]
        case .bus:
            return [.bus]
        case .subway:
            return [.subway]
        case .tram:
            return [.tram]
        }
    }
    
    private func mapTripKitFailure(_ error: Error) throws -> RouteError {
        if error is CancellationError {
            throw error
        }
        
        if let urlError = error as? URLError {
            return .networkError("\(urlError.code.rawValue) \(urlError.code)")
        }
        
        let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
        return .networkError(message)
    }
}

// MARK: - Models

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
    
    /// All coordinates for drawing the route on map
    var coordinates: [CLLocationCoordinate2D] {
        legs.flatMap { $0.coordinates }
    }
    
    init(from trip: Trip) {
        self.id = trip.id ?? UUID().uuidString
        self.legs = trip.legs?.compactMap { RouteLeg(from: $0) } ?? []
        self.totalDuration = TimeInterval(trip.duration ?? 0)
        self.departureTime = trip.departureTime ?? Date()
        self.arrivalTime = trip.arrivalTime ?? Date()
    }
}

struct RouteLeg {
    let type: LegType
    let departureStop: TransportStop?
    let arrivalStop: TransportStop?
    let departureTime: Date?
    let arrivalTime: Date?
    let line: TransportLine?
    let coordinates: [CLLocationCoordinate2D]
    
    init?(from leg: Leg) {
        guard let type = LegType(from: leg.type) else { return nil }
        self.type = type
        self.departureStop = leg.departure?.location.flatMap { TransportStop(from: $0) }
        self.arrivalStop = leg.arrival?.location.flatMap { TransportStop(from: $0) }
        self.departureTime = leg.departure?.time
        self.arrivalTime = leg.arrival?.time
        self.line = leg.line.flatMap { TransportLine(from: $0) }
        
        // Extract coordinates from path
        self.coordinates = leg.path?.compactMap { point -> CLLocationCoordinate2D? in
            guard let coord = point.coord else { return nil }
            return CLLocationCoordinate2D(latitude: Double(coord.lat) / 1_000_000, longitude: Double(coord.lon) / 1_000_000)
        } ?? []
    }
}

enum LegType {
    case walking
    case publicTransport
    
    init?(from legType: LegTypeEnum?) {
        guard let legType = legType else { return nil }
        switch legType {
        case .publicTransport:
            self = .publicTransport
        case .walking:
            self = .walking
        default:
            return nil
        }
    }
}

// MARK: - Extensions

extension TransportStop {
    var tripKitLocation: Location {
        Location(
            id: id,
            name: name,
            place: place,
            coord: Coord(lat: Int(latitude * 1_000_000), lon: Int(longitude * 1_000_000)),
            products: products,
            type: .station,
            weight: nil
        )
    }
}

// MARK: - Errors

enum RouteError: LocalizedError {
    case noRoutesFound
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .noRoutesFound:
            return "No routes found for the selected stops and mode"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}