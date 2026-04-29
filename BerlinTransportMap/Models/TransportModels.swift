import Foundation

// MARK: - Transport Models

struct TransportStop: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let place: String?
    let latitude: Double
    let longitude: Double
    let products: [TransportProduct]

    init(
        id: String,
        name: String,
        place: String? = nil,
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

    /// Extracts a usable stop ID from various API ID formats.
    var stopId: String {
        if let lRange = id.range(of: "L=") {
            let startIndex = lRange.upperBound
            let remaining = id[startIndex...]
            if let endIndex = remaining.firstIndex(of: "@") {
                return String(remaining[..<endIndex])
            } else {
                return String(remaining)
            }
        }

        if id.contains(":") {
            return id.components(separatedBy: ":").last ?? id
        }

        return id
    }

    /// Backward-compatible alias for `stopId`.
    @available(*, deprecated, renamed: "stopId")
    var vbbStopId: String { stopId }

    init(from location: TransitLocation) {
        self.id = location.id ?? UUID().uuidString
        self.name = location.name ?? "Unknown"
        self.place = nil
        self.latitude = location.location?.latitude ?? 0
        self.longitude = location.location?.longitude ?? 0
        self.products = []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case place
        case latitude
        case longitude
        case products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        place = try container.decodeIfPresent(String.self, forKey: .place)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        let productStrings = try container.decodeIfPresent([String].self, forKey: .products) ?? []
        products = productStrings.map { TransportProductCoding.decode($0) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(place, forKey: .place)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        let productStrings = products.map { TransportProductCoding.encode($0) }
        try container.encode(productStrings, forKey: .products)
    }
}

struct TransportDeparture: Identifiable, Codable {
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

    init(from vbbDeparture: VBBDeparture) {
        self.id = vbbDeparture.tripId ?? UUID().uuidString
        self.line = TransportLine(from: vbbDeparture.line)
        self.destination = vbbDeparture.direction ?? "Unknown"
        self.stopId = vbbDeparture.stop?.id ?? ""
        self.stopName = vbbDeparture.stop?.name ?? "Unknown"
        self.stopLatitude = 0
        self.stopLongitude = 0

        if let whenString = vbbDeparture.when {
            self.plannedTime = VehicleRadarService.parseISO8601(whenString)
        } else if let plannedString = vbbDeparture.plannedWhen {
            self.plannedTime = VehicleRadarService.parseISO8601(plannedString)
        } else {
            self.plannedTime = nil
        }

        self.predictedTime = nil
        self.delay = nil
        self.platform = vbbDeparture.platform
        self.isCancelled = false
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case line
        case destination
        case plannedTime
        case predictedTime
        case delay
        case platform
        case isCancelled
        case stopId
        case stopName
        case stopLatitude
        case stopLongitude
    }
}

struct TransportLine: Codable {
    let id: String?
    let label: String
    let name: String?
    let product: TransportProduct
    let color: String?
    let foregroundColor: String?

    var displayName: String {
        label
    }

    init(from transitLine: TransitDepartureRaw.TransitLine?) {
        self.id = transitLine?.id
        self.label = transitLine?.publicCode ?? transitLine?.name ?? "?"
        self.name = transitLine?.name
        self.product = TransportProductCoding.decode(transitLine?.product ?? "")
        self.color = nil
        self.foregroundColor = nil
    }

    init(vbbLineId: String?, vbbLineName: String?, vbbLinePublicCode: String?, vbbLineProduct: String?) {
        self.id = vbbLineId
        self.label = vbbLinePublicCode ?? vbbLineName ?? "?"
        self.name = vbbLineName
        self.product = TransportProductCoding.decode(vbbLineProduct ?? "")
        self.color = nil
        self.foregroundColor = nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case name
        case product
        case color
        case foregroundColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        let productString = try container.decodeIfPresent(String.self, forKey: .product) ?? ""
        product = TransportProductCoding.decode(productString)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        foregroundColor = try container.decodeIfPresent(String.self, forKey: .foregroundColor)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(TransportProductCoding.encode(product), forKey: .product)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(foregroundColor, forKey: .foregroundColor)
    }
}

enum TransportProduct: String, Codable {
    case suburbanTrain = "suburban"
    case subway = "subway"
    case tram = "tram"
    case bus = "bus"
    case ferry = "ferry"
    case regionalTrain = "regional"
    case highSpeedTrain = "express"
    case unknown

    var displayName: String {
        switch self {
        case .suburbanTrain: return "S-Bahn"
        case .subway: return "U-Bahn"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .ferry: return "Fähre"
        case .regionalTrain: return "RE/RB"
        case .highSpeedTrain: return "ICE/IC"
        case .unknown: return "Other"
        }
    }

    var color: String {
        switch self {
        case .suburbanTrain: return "#008C3C"
        case .subway: return "#0066CC"
        case .tram: return "#D8232A"
        case .bus: return "#993399"
        case .ferry: return "#0099CC"
        case .regionalTrain, .highSpeedTrain: return "#EC192E"
        case .unknown: return "#666666"
        }
    }
}

private enum TransportProductCoding {
    static func encode(_ product: TransportProduct) -> String {
        return product.rawValue
    }

    static func decode(_ raw: String) -> TransportProduct {
        return TransportProduct(rawValue: raw.lowercased()) ?? .unknown
    }
}

// MARK: - Events

struct Event: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let location: String
    let latitude: Double
    let longitude: Double
    let date: Date
    let description: String?
}

// MARK: - Parking

struct ParkingFacility: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let availableSpaces: Int
    let totalSpaces: Int
}

// MARK: - Transport Error

enum TransportError: LocalizedError {
    case invalidLocation
    case invalidStation
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case apiError(String)
    case cancelled
    case noData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Invalid location coordinates"
        case .invalidStation:
            return "Station not found"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .cancelled:
            return "Request was cancelled"
        case .noData:
            return "No data available"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .invalidLocation, .invalidStation:
            return "Try searching for a different location"
        default:
            return nil
        }
    }
}

extension TransportError {
    static func from(_ error: Error) -> TransportError {
        if let transportError = error as? TransportError {
            return transportError
        }

        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError {
            return .networkError(urlError.localizedDescription)
        }

        return .unknown(error)
    }
}

// MARK: - Transit API Types (generic, works with both VBB and DB REST APIs)

struct TransitLocation: Decodable {
    let id: String?
    let name: String?
    let location: TransitCoordinate?

    struct TransitCoordinate: Decodable {
        let latitude: Double
        let longitude: Double
    }
}

/// Backward-compatible alias.
typealias VBBSimpleLocation = TransitLocation

struct TransitCoordinate: Decodable {
    let latitude: Double
    let longitude: Double
}

/// Backward-compatible alias.
typealias VBBLocation = TransitCoordinate

struct TransitDepartureRaw: Decodable {
    let tripId: String?
    let line: TransitLine?
    let direction: String?
    let plannedWhen: String?
    let when: String?
    let platform: String?
    let stop: TransitStop?
    let delay: Int?
    let remarks: [TransitRemark]?

    struct TransitLine: Decodable {
        let id: String?
        let name: String?
        let publicCode: String?
        let product: String?
        let operatorCode: String?
        let type: String?
        let mode: String?
    }

    struct TransitStop: Decodable {
        let id: String?
        let name: String?
        let location: TransitCoordinate?
    }

    struct TransitRemark: Decodable {
        let id: String?
        let type: String?
        let summary: String?
        let content: String?
    }
}

/// Backward-compatible alias.
typealias VBBDeparture = TransitDepartureRaw
