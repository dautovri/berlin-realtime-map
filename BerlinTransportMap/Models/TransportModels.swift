import Foundation
import TripKit

// MARK: - Models

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

struct TransportLine: Codable {
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