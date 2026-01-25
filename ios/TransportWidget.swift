import WidgetKit
import SwiftUI
import TripKit

struct TransportEntry: TimelineEntry {
    let date: Date
    let stops: [TransportStop]
    let vehicles: [Vehicle]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TransportEntry {
        TransportEntry(date: Date(), stops: [], vehicles: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TransportEntry) -> ()) {
        let entry = TransportEntry(date: Date(), stops: [], vehicles: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransportEntry>) -> ()) {
        // Fetch nearby stops and vehicles using TripKit
        let stops = TransportService.shared.getNearbyStops()
        let vehicles = VehicleRadarService.shared.getVehicles()

        let entry = TransportEntry(date: Date(), stops: stops, vehicles: vehicles)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct TransportWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Berlin Transport")
                .font(.headline)
            if entry.stops.isEmpty {
                Text("No nearby stops")
            } else {
                ForEach(entry.stops.prefix(2)) { stop in
                    Text(stop.name)
                        .font(.caption)
                }
            }
        }
    }
}

struct TransportWidget: Widget {
    let kind: String = "TransportWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TransportWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Berlin Transport Widget")
        .description("Shows nearby transport information")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TransportWidget_Previews: PreviewProvider {
    static var previews: some View {
        TransportWidgetEntryView(entry: TransportEntry(date: Date(), stops: [], vehicles: []))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}