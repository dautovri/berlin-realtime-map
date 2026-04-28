import SwiftUI

struct FavoriteRow: View {
    let favorite: Favorite
    let onSelect: () -> Void

    @State private var departures: [RESTDeparture] = []
    @State private var isLoading = true
    @State private var fetchFailed = false
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let services = ServiceContainer.shared

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // Header: stop name + live badge
                HStack(alignment: .center) {
                    Text(favorite.name)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Spacer()
                    if isLoading && departures.isEmpty {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if !fetchFailed {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color(hex: "#00A550"))
                                .frame(width: 6, height: 6)
                                .scaleEffect(isPulsing ? 1.3 : 1.0)
                                .animation(
                                    reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                    value: isPulsing
                                )
                                .onAppear { isPulsing = true }
                            Text("Live")
                                .font(.caption2.bold())
                                .foregroundStyle(Color(hex: "#00A550"))
                        }
                    }
                }

                // Departure rows
                if departures.isEmpty && !isLoading {
                    Text(fetchFailed ? "Couldn't load departures" : "No upcoming departures")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 7) {
                        ForEach(departures.prefix(3)) { dep in
                            FavoriteDepartureRow(departure: dep)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this stop on the map")
        .task(id: favorite.stopId) {
            await fetchAndRefresh()
        }
    }

    private func fetchAndRefresh() async {
        await fetchDepartures()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { break }
            await fetchDepartures()
        }
    }

    private func fetchDepartures() async {
        guard let stopId = favorite.stopId, favorite.type == .stop else {
            isLoading = false
            return
        }
        let stop = TransportStop(
            id: stopId,
            name: favorite.name,
            latitude: favorite.latitude ?? 52.52,
            longitude: favorite.longitude ?? 13.405
        )
        do {
            let deps = try await services.vehicleRadarService.fetchDepartures(stopId: stop.stopId)
            departures = deps
            fetchFailed = false
        } catch {
            fetchFailed = departures.isEmpty
        }
        isLoading = false
    }
}

private struct FavoriteDepartureRow: View {
    let departure: RESTDeparture

    var minutesAway: String {
        guard let date = departure.displayTime else { return "—" }
        let mins = Int(date.timeIntervalSinceNow / 60)
        return mins <= 0 ? "Now" : "\(mins) min"
    }

    var isDelayed: Bool { (departure.delayMinutes ?? 0) > 0 }

    var body: some View {
        HStack(spacing: 8) {
            if let line = departure.line {
                Text(line.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: line.foregroundColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: line.color), in: .rect(cornerRadius: 4))
                    .fixedSize()
            }

            Text(departure.direction ?? "")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 3) {
                Text(minutesAway)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                    .foregroundStyle(isDelayed ? Color(hex: "#E8641A") : Color(hex: "#00A550"))

                if let delay = departure.delayMinutes, delay > 0 {
                    Text("+\(delay)")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#E8641A"))
                }
            }
        }
    }
}
