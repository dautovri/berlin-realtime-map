import WidgetKit
import SwiftUI

// MARK: - Shared UserDefaults key (app group)

extension UserDefaults {
    nonisolated(unsafe) static let appGroup = UserDefaults(suiteName: "group.com.dautov.berlintransportmap")!
    static let savedStopsKey = "widget_savedStops"
}

// MARK: - Shared stop model

struct WidgetSavedStop: Codable {
    let id: String
    let name: String
    // Multi-city fields. Older app versions wrote payloads without these,
    // so they decode as nil and are treated as Berlin (apiBaseURL falls back to VBB).
    let cityId: String?
    let apiBaseURL: String?

    var effectiveCityId: String { cityId ?? "berlin" }
    var effectiveAPIBaseURL: String { apiBaseURL ?? "https://v6.vbb.transport.rest" }
}

// MARK: - Widget departure model

struct WidgetDeparture: Identifiable {
    let id = UUID()
    let lineName: String
    let lineColor: String
    let lineForegroundColor: String
    let direction: String
    let scheduledTime: Date
}

// MARK: - Timeline entry

struct DepartureEntry: TimelineEntry {
    let date: Date
    let stopName: String
    let stopId: String
    let cityId: String
    let departures: [WidgetDeparture]
    let noStopsSaved: Bool
    let fetchFailed: Bool
}

// MARK: - Timeline provider

struct DepartureProvider: TimelineProvider {

    func placeholder(in context: Context) -> DepartureEntry {
        DepartureEntry(
            date: Date(),
            stopName: "U Alexanderplatz",
            stopId: "",
            cityId: "berlin",
            departures: [
                WidgetDeparture(lineName: "U2", lineColor: "#005CA9", lineForegroundColor: "#FFFFFF",
                                direction: "Pankow", scheduledTime: Date().addingTimeInterval(300)),
                WidgetDeparture(lineName: "U5", lineColor: "#7D4F9E", lineForegroundColor: "#FFFFFF",
                                direction: "Hönow", scheduledTime: Date().addingTimeInterval(600)),
                WidgetDeparture(lineName: "S5", lineColor: "#008C3C", lineForegroundColor: "#FFFFFF",
                                direction: "Strausberg Nord", scheduledTime: Date().addingTimeInterval(120))
            ],
            noStopsSaved: false,
            fetchFailed: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (DepartureEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { @Sendable in
            let entry = await buildEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<DepartureEntry>) -> Void) {
        Task { @Sendable in
            let entry = await buildEntry()
            // Refresh every 30 minutes — WidgetKit throttles more aggressively than configured,
            // so we show scheduled times (HH:mm) rather than relative minutes to avoid staleness.
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    // MARK: - Data fetching

    private func buildEntry() async -> DepartureEntry {
        let data = UserDefaults.appGroup.data(forKey: UserDefaults.savedStopsKey)
        let stops = (try? JSONDecoder().decode([WidgetSavedStop].self, from: data ?? Data())) ?? []

        guard let top = stops.first else {
            return DepartureEntry(date: Date(), stopName: "", stopId: "", cityId: "berlin",
                                  departures: [], noStopsSaved: true, fetchFailed: false)
        }

        do {
            let departures = try await fetchDepartures(stopId: top.id, apiBaseURL: top.effectiveAPIBaseURL)
            return DepartureEntry(date: Date(), stopName: top.name, stopId: top.id, cityId: top.effectiveCityId,
                                  departures: departures, noStopsSaved: false, fetchFailed: false)
        } catch {
            return DepartureEntry(date: Date(), stopName: top.name, stopId: top.id, cityId: top.effectiveCityId,
                                  departures: [], noStopsSaved: false, fetchFailed: true)
        }
    }

    private func fetchDepartures(stopId: String, apiBaseURL: String) async throws -> [WidgetDeparture] {
        guard let encodedId = stopId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(apiBaseURL)/stops/\(encodedId)/departures?duration=60&results=6&linesOfStops=false&remarks=false")
        else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VBBDepsResponse.self, from: data)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = Date()

        return response.departures
            .compactMap { dep -> WidgetDeparture? in
                guard let line = dep.line,
                      let timeStr = dep.when ?? dep.plannedWhen,
                      let date = formatter.date(from: timeStr),
                      date > now
                else { return nil }

                let color = line.colorBg ?? "#555555"
                let fg = line.colorFg ?? "#FFFFFF"
                return WidgetDeparture(
                    lineName: line.name ?? "?",
                    lineColor: color,
                    lineForegroundColor: fg,
                    direction: dep.direction ?? "",
                    scheduledTime: date
                )
            }
    }
}

// MARK: - VBB API models (widget-local)

private struct VBBDepsResponse: Decodable {
    let departures: [VBBDep]
}

private struct VBBDep: Decodable {
    let when: String?
    let plannedWhen: String?
    let direction: String?
    let line: VBBWidgetLine?
}

private struct VBBWidgetLine: Decodable {
    let name: String?
    let color: VBBColor?

    var colorBg: String? { color?.bg }
    var colorFg: String? { color?.fg }
}

private struct VBBColor: Decodable {
    let bg: String?
    let fg: String?
}

// MARK: - Widget views

struct DepartureWidgetEntryView: View {
    let entry: DepartureEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.noStopsSaved {
            emptyStateView
        } else {
            switch family {
            case .systemSmall:
                smallView
            default:
                mediumView
            }
        }
    }

    // MARK: Empty state

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No saved stops")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("Open the app to save stops")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: Small (1 stop, up to 3 departures)

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            stopHeader
            Spacer(minLength: 0)
            if entry.fetchFailed {
                Text("Couldn't load")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if entry.departures.isEmpty {
                Text("No departures")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.departures.prefix(3)) { dep in
                        DepartureRowView(departure: dep, compact: true)
                    }
                }
            }
        }
        .padding(12)
        .widgetURL(deepLinkURL(for: entry))
    }

    // MARK: Medium (1 stop, up to 5 departures)

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            stopHeader
            Spacer(minLength: 0)
            if entry.fetchFailed {
                Text("Couldn't load departures")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if entry.departures.isEmpty {
                Text("No upcoming departures")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entry.departures.prefix(5)) { dep in
                        DepartureRowView(departure: dep, compact: false)
                    }
                }
            }
        }
        .padding(14)
        .widgetURL(deepLinkURL(for: entry))
    }

    // MARK: Shared subviews

    private var stopHeader: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "tram.fill")
                .font(.caption2.bold())
                .foregroundStyle(Color(hex: "#005CA9"))
            Text(entry.stopName)
                .font(.caption.bold())
                .fontDesign(.rounded)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }

    private func deepLinkURL(for entry: DepartureEntry) -> URL? {
        var components = URLComponents()
        components.scheme = "berlintransportmap"
        components.host = "departures"
        components.path = "/\(entry.stopId)"
        components.queryItems = [
            URLQueryItem(name: "name", value: entry.stopName),
            URLQueryItem(name: "city", value: entry.cityId)
        ]
        return components.url
    }
}

struct DepartureRowView: View {
    let departure: WidgetDeparture
    let compact: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var timeString: String {
        Self.timeFormatter.string(from: departure.scheduledTime)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Line badge
            Text(departure.lineName)
                .font(compact ? .system(size: 10, weight: .bold) : .caption.bold())
                .foregroundStyle(Color(hex: departure.lineForegroundColor))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(hex: departure.lineColor), in: .rect(cornerRadius: 3))
                .fixedSize()

            // Direction
            Text(departure.direction)
                .font(compact ? .system(size: 10) : .caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Scheduled time — always HH:mm (never relative minutes)
            Text(timeString)
                .font(compact ? .system(size: 10, weight: .semibold) : .caption.bold())
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Color helper (widget-local copy)

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: Double
        switch h.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0.4; g = 0.4; b = 0.4
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget configuration

struct DepartureWidget: Widget {
    let kind = "DepartureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DepartureProvider()) { entry in
            DepartureWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Stop")
        .description("Live departures from your saved stop.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
