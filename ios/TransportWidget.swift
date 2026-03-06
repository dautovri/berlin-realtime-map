import WidgetKit
import SwiftUI
import TripKit

struct TransportEntry: TimelineEntry {
    let date: Date
    let stops: [WidgetStop]
    let vehicles: [WidgetVehicle]
}

struct WidgetStop: Codable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

struct WidgetVehicle: Codable, Identifiable {
    let id: String
    let lineName: String?
    let lineColor: String?
    let direction: String?
    let latitude: Double?
    let longitude: Double?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TransportEntry {
        TransportEntry(
            date: Date(),
            stops: [
                WidgetStop(id: "1", name: "Alexanderplatz", latitude: 52.5218, longitude: 13.4135),
                WidgetStop(id: "2", name: "Hauptbahnhof", latitude: 52.5251, longitude: 13.3694)
            ],
            vehicles: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TransportEntry) -> ()) {
        if context.isPreview {
            let entry = TransportEntry(
                date: Date(),
                stops: [
                    WidgetStop(id: "1", name: "Alexanderplatz", latitude: 52.5218, longitude: 13.4135)
                ],
                vehicles: []
            )
            completion(entry)
            return
        }

        Task {
            let entry = await fetchCurrentData()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransportEntry>) -> ()) {
        Task {
            let currentEntry = await fetchCurrentData()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchCurrentData() async -> TransportEntry {
        let berlinCenter = CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954)
        var stops: [WidgetStop] = []
        var vehicles: [WidgetVehicle] = []

        if let aid = ProcessInfo.processInfo.environment["VBB_API_AID"], !aid.isEmpty {
            let apiAuthorization: [String: Any] = [
                "type": "AID",
                "aid": aid
            ]
            let provider = BvgProvider(apiAuthorization: apiAuthorization)

            let lat = Int(berlinCenter.latitude * 1_000_000)
            let lon = Int(berlinCenter.longitude * 1_000_000)
            let location = Location(lat: lat, lon: lon)

            let (_, result) = await provider.queryNearbyLocations(
                location: location,
                types: [.station],
                maxDistance: 2000,
                maxLocations: 10
            )

            if case .success(let locations) = result {
                stops = locations.compactMap { loc in
                    guard let stop = TransportStop(from: loc) else { return nil }
                    return WidgetStop(
                        id: stop.id,
                        name: stop.name,
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )
                }
            }

            let baseURL = "https://v6.vbb.transport.rest"
            let north = berlinCenter.latitude + 0.02
            let west = berlinCenter.longitude - 0.02
            let south = berlinCenter.latitude - 0.02
            let east = berlinCenter.longitude + 0.02

            var components = URLComponents(string: "\(baseURL)/radar")!
            components.queryItems = [
                URLQueryItem(name: "north", value: String(north)),
                URLQueryItem(name: "west", value: String(west)),
                URLQueryItem(name: "south", value: String(south)),
                URLQueryItem(name: "east", value: String(east)),
                URLQueryItem(name: "duration", value: "30"),
                URLQueryItem(name: "results", value: "50"),
                URLQueryItem(name: "frames", value: "1"),
                URLQueryItem(name: "polylines", value: "false")
            ]

            if let url = components.url {
                let (data, _) = try? await URLSession.shared.data(from: url)
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(RadarResponse.self, from: data) {
                        vehicles = response.movements.compactMap { vehicle in
                            guard let location = vehicle.location else { return nil }
                            return WidgetVehicle(
                                id: vehicle.tripId,
                                lineName: vehicle.line?.displayName,
                                lineColor: vehicle.line?.color,
                                direction: vehicle.direction,
                                latitude: location.latitude,
                                longitude: location.longitude
                            )
                        }
                    }
                }
            }
        }

        return TransportEntry(date: Date(), stops: stops, vehicles: vehicles)
    }
}

struct RadarResponse: Decodable {
    let movements: [Vehicle]
}

struct Vehicle: Decodable {
    let tripId: String
    let line: VehicleLine?
    let direction: String?
    let location: VehicleLocation?
}

struct VehicleLine: Decodable {
    let name: String?
    let colorData: LineColor?

    enum CodingKeys: String, CodingKey {
        case name, color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.colorData = try container.decodeIfPresent(LineColor.self, forKey: .color)
    }

    var displayName: String {
        name ?? "?"
    }

    var color: String {
        if let bg = colorData?.bg, !bg.isEmpty {
            return bg
        }
        return "#666666"
    }
}

struct LineColor: Decodable {
    let fg: String?
    let bg: String?
}

struct VehicleLocation: Decodable {
    let latitude: Double
    let longitude: Double
}

struct TransportWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tram.fill")
                    .foregroundStyle(.blue)
                Text("Berlin Transport")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.stops.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "location.slash")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("No stops nearby")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.stops.prefix(3)) { stop in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(.green)
                        Text(stop.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                if !entry.vehicles.isEmpty {
                    Divider()
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption2)
                        Text("\(entry.vehicles.count) vehicles")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct TransportWidget: Widget {
    let kind: String = "TransportWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TransportWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Berlin Transport")
        .description("Shows nearby transport stops and vehicles")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TransportWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TransportWidgetEntryView(entry: TransportEntry(
                date: Date(),
                stops: [
                    WidgetStop(id: "1", name: "Alexanderplatz", latitude: 52.5218, longitude: 13.4135),
                    WidgetStop(id: "2", name: "Hauptbahnhof", latitude: 52.5251, longitude: 13.3694)
                ],
                vehicles: [
                    WidgetVehicle(id: "v1", lineName: "U2", lineColor: "#0066CC", direction: "Pankow", latitude: 52.52, longitude: 13.41)
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            TransportWidgetEntryView(entry: TransportEntry(
                date: Date(),
                stops: [
                    WidgetStop(id: "1", name: "Alexanderplatz", latitude: 52.5218, longitude: 13.4135),
                    WidgetStop(id: "2", name: "Hauptbahnhof", latitude: 52.5251, longitude: 13.3694),
                    WidgetStop(id: "3", name: "Brandenburger Tor", latitude: 52.5163, longitude: 13.3777)
                ],
                vehicles: []
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
        }
    }
}
