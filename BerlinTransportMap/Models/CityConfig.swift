import CoreLocation
import MapKit
import SwiftUI

// MARK: - CityConfig

/// Configuration for a supported German transit city.
/// Each city defines its transit authority, API endpoint, map region, accent color,
/// and the transport products available in that city.
struct CityConfig: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let transitAuthority: String
    let apiBaseURL: String
    let centerLatitude: Double
    let centerLongitude: Double
    let defaultZoom: Double
    let spanLatitude: Double
    let spanLongitude: Double
    let accentColorHex: String
    let supportedProducts: [TransportProduct]

    // Per-city capability flags.
    // True means the endpoint has been validated for this city; false means the
    // service must short-circuit and the UI must hide the corresponding affordance.
    // Only Berlin is validated until the API endpoint matrix runs (see scripts/validate-city-endpoints.sh).
    let supportsRadar: Bool
    let supportsEvents: Bool
    let supportsRoutes: Bool

    // MARK: - Computed properties

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var boundingBox: MKCoordinateRegion {
        MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude)
        )
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, name, transitAuthority, apiBaseURL
        case centerLatitude, centerLongitude, defaultZoom
        case spanLatitude, spanLongitude
        case accentColorHex, supportedProducts
        case supportsRadar, supportsEvents, supportsRoutes
    }

    init(
        id: String,
        name: String,
        transitAuthority: String,
        apiBaseURL: String,
        centerLatitude: Double,
        centerLongitude: Double,
        defaultZoom: Double,
        spanLatitude: Double,
        spanLongitude: Double,
        accentColorHex: String,
        supportedProducts: [TransportProduct],
        supportsRadar: Bool = false,
        supportsEvents: Bool = false,
        supportsRoutes: Bool = true
    ) {
        self.id = id
        self.name = name
        self.transitAuthority = transitAuthority
        self.apiBaseURL = apiBaseURL
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.defaultZoom = defaultZoom
        self.spanLatitude = spanLatitude
        self.spanLongitude = spanLongitude
        self.accentColorHex = accentColorHex
        self.supportedProducts = supportedProducts
        self.supportsRadar = supportsRadar
        self.supportsEvents = supportsEvents
        self.supportsRoutes = supportsRoutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.transitAuthority = try c.decode(String.self, forKey: .transitAuthority)
        self.apiBaseURL = try c.decode(String.self, forKey: .apiBaseURL)
        self.centerLatitude = try c.decode(Double.self, forKey: .centerLatitude)
        self.centerLongitude = try c.decode(Double.self, forKey: .centerLongitude)
        self.defaultZoom = try c.decode(Double.self, forKey: .defaultZoom)
        self.spanLatitude = try c.decode(Double.self, forKey: .spanLatitude)
        self.spanLongitude = try c.decode(Double.self, forKey: .spanLongitude)
        self.accentColorHex = try c.decode(String.self, forKey: .accentColorHex)
        self.supportedProducts = try c.decode([TransportProduct].self, forKey: .supportedProducts)
        self.supportsRadar = try c.decodeIfPresent(Bool.self, forKey: .supportsRadar) ?? false
        self.supportsEvents = try c.decodeIfPresent(Bool.self, forKey: .supportsEvents) ?? false
        self.supportsRoutes = try c.decodeIfPresent(Bool.self, forKey: .supportsRoutes) ?? true
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CityConfig, rhs: CityConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - All Supported Cities

extension CityConfig {

    /// Berlin — BVG/VBB, uses the VBB-specific API
    static let berlin = CityConfig(
        id: "berlin",
        name: "Berlin",
        transitAuthority: "BVG/VBB",
        apiBaseURL: "https://v6.vbb.transport.rest",
        centerLatitude: 52.520008,
        centerLongitude: 13.404954,
        defaultZoom: 0.15,
        spanLatitude: 0.25,
        spanLongitude: 0.35,
        accentColorHex: "#115D97",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .ferry, .regionalTrain],
        supportsRadar: true,
        supportsEvents: true,
        supportsRoutes: true
    )

    /// Munich — MVG
    static let munich = CityConfig(
        id: "munich",
        name: "München",
        transitAuthority: "MVG",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 48.137154,
        centerLongitude: 11.576124,
        defaultZoom: 0.12,
        spanLatitude: 0.20,
        spanLongitude: 0.25,
        accentColorHex: "#0d5c2e",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain]
    )

    /// Hamburg — HVV
    static let hamburg = CityConfig(
        id: "hamburg",
        name: "Hamburg",
        transitAuthority: "HVV",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 53.551086,
        centerLongitude: 9.993682,
        defaultZoom: 0.12,
        spanLatitude: 0.22,
        spanLongitude: 0.30,
        accentColorHex: "#e2001a",
        supportedProducts: [.suburbanTrain, .subway, .bus, .ferry, .regionalTrain]
    )

    /// Frankfurt — RMV
    static let frankfurt = CityConfig(
        id: "frankfurt",
        name: "Frankfurt",
        transitAuthority: "RMV",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 50.110924,
        centerLongitude: 8.682127,
        defaultZoom: 0.10,
        spanLatitude: 0.18,
        spanLongitude: 0.22,
        accentColorHex: "#00428a",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain]
    )

    /// Cologne — KVB
    static let cologne = CityConfig(
        id: "cologne",
        name: "Köln",
        transitAuthority: "KVB",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 50.937531,
        centerLongitude: 6.960279,
        defaultZoom: 0.10,
        spanLatitude: 0.18,
        spanLongitude: 0.22,
        accentColorHex: "#ed1c24",
        supportedProducts: [.suburbanTrain, .tram, .bus, .regionalTrain]
    )

    /// Stuttgart — VVS
    static let stuttgart = CityConfig(
        id: "stuttgart",
        name: "Stuttgart",
        transitAuthority: "VVS",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 48.775846,
        centerLongitude: 9.182932,
        defaultZoom: 0.10,
        spanLatitude: 0.18,
        spanLongitude: 0.22,
        accentColorHex: "#ffc20e",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain]
    )

    /// Düsseldorf — VRR
    static let dusseldorf = CityConfig(
        id: "dusseldorf",
        name: "Düsseldorf",
        transitAuthority: "VRR",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 51.227741,
        centerLongitude: 6.773456,
        defaultZoom: 0.10,
        spanLatitude: 0.16,
        spanLongitude: 0.20,
        accentColorHex: "#009fe3",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain]
    )

    /// Dresden — DVB
    static let dresden = CityConfig(
        id: "dresden",
        name: "Dresden",
        transitAuthority: "DVB",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 51.050407,
        centerLongitude: 13.737262,
        defaultZoom: 0.10,
        spanLatitude: 0.16,
        spanLongitude: 0.20,
        accentColorHex: "#fdc500",
        supportedProducts: [.suburbanTrain, .tram, .bus, .ferry, .regionalTrain]
    )

    /// Leipzig — LVB
    static let leipzig = CityConfig(
        id: "leipzig",
        name: "Leipzig",
        transitAuthority: "LVB",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 51.339695,
        centerLongitude: 12.373075,
        defaultZoom: 0.10,
        spanLatitude: 0.16,
        spanLongitude: 0.20,
        accentColorHex: "#004e9e",
        supportedProducts: [.suburbanTrain, .tram, .bus, .regionalTrain]
    )

    /// Nürnberg — VAG
    static let nuremberg = CityConfig(
        id: "nuremberg",
        name: "Nürnberg",
        transitAuthority: "VAG",
        apiBaseURL: "https://v6.db.transport.rest",
        centerLatitude: 49.452030,
        centerLongitude: 11.076750,
        defaultZoom: 0.10,
        spanLatitude: 0.16,
        spanLongitude: 0.20,
        accentColorHex: "#e30613",
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain]
    )

    /// All supported cities, sorted by population (largest first).
    static let allCities: [CityConfig] = [
        .berlin, .hamburg, .munich, .cologne, .frankfurt,
        .stuttgart, .dusseldorf, .leipzig, .dresden, .nuremberg
    ]

    /// Look up a city by its `id`.
    static func city(forId id: String) -> CityConfig? {
        allCities.first { $0.id == id }
    }
}
