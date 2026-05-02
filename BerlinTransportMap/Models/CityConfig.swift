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
    // True means /stops/{id}/departures returns valid data on the v6.db.transport.rest
    // proxy. Some HAFAS backends (VVS for Stuttgart, VRR for Düsseldorf, DVB for
    // Dresden) currently return HTTP 500 for every stop. Cities with this flag false
    // must be hidden from the city picker — there is no graceful UX for an app whose
    // primary feature ("see live departures") is broken.
    // Re-validate via scripts/validate-city-endpoints.sh and flip when backends recover.
    let supportsDepartures: Bool

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
        case supportsRadar, supportsEvents, supportsRoutes, supportsDepartures
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
        supportsRoutes: Bool = true,
        supportsDepartures: Bool = true
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
        self.supportsDepartures = supportsDepartures
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
        self.supportsDepartures = try c.decodeIfPresent(Bool.self, forKey: .supportsDepartures) ?? true
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

    /// Stuttgart — VVS. /stops/{id}/departures returns HTTP 500 universally on
    /// v6.db.transport.rest as of v1.7 QA (2026-05-02). Hidden from city picker
    /// via supportsDepartures=false until upstream backend recovers.
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
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain],
        supportsDepartures: false
    )

    /// Düsseldorf — VRR. Same as Stuttgart — backend currently broken.
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
        supportedProducts: [.suburbanTrain, .subway, .tram, .bus, .regionalTrain],
        supportsDepartures: false
    )

    /// Dresden — DVB. Same as Stuttgart — backend currently broken.
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
        supportedProducts: [.suburbanTrain, .tram, .bus, .ferry, .regionalTrain],
        supportsDepartures: false
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

    /// Every defined city, including ones currently disabled by capability flags.
    /// Used for `city(forId:)` lookups that must succeed even for disabled cities
    /// (legacy favorite restoration, deep links written before a flag flipped, etc.)
    /// — the lookup tells you the city is still real even if the picker hides it.
    static let allCities: [CityConfig] = [
        .berlin, .hamburg, .munich, .cologne, .frankfurt,
        .stuttgart, .dusseldorf, .leipzig, .dresden, .nuremberg
    ]

    /// Cities that the user can actually pick today. A city is excluded when its
    /// HAFAS departures endpoint is broken upstream — the app's primary feature
    /// ("see live departures") would 500 for every stop, which is worse than
    /// pretending the city doesn't exist yet.
    /// Re-validate via `scripts/validate-city-endpoints.sh` and flip
    /// `supportsDepartures` on the affected `CityConfig` to re-enable.
    static var availableCities: [CityConfig] {
        allCities.filter { $0.supportsDepartures }
    }

    /// Look up a city by its `id`. Returns even cities currently hidden from the
    /// picker (callers that need only-pickable cities should check `supportsDepartures`).
    static func city(forId id: String) -> CityConfig? {
        allCities.first { $0.id == id }
    }
}
