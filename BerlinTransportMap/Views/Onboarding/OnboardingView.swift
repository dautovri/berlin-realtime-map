import SwiftUI
import SwiftData
import CoreLocation
import OSLog

// MARK: - Onboarding Data Models

struct OnboardingStop: Identifiable, Hashable {
    let id: String
    let name: String
    let lines: String
    let badgeColor: Color
    let latitude: Double
    let longitude: Double

    /// Demo stops for the user's current city. Berlin has a curated list of 8
    /// landmark stops with known-good VBB IDs. Other cities currently fall back
    /// to a single Hauptbahnhof entry — populating their picks is v1.8 work
    /// (see TODOS.md "v1.8 onboarding polish").
    static func demos(for cityId: String) -> [OnboardingStop] {
        switch cityId {
        case "berlin":
            return berlinDemos
        case "munich":
            return [OnboardingStop(id: "8000261", name: "München Hauptbahnhof",
                                   lines: "S · U · Tram · Bus", badgeColor: Color(hex: "#0d5c2e"),
                                   latitude: 48.140229, longitude: 11.558339)]
        case "hamburg":
            return [OnboardingStop(id: "8002549", name: "Hamburg Hauptbahnhof",
                                   lines: "S · U · Bus", badgeColor: Color(hex: "#e2001a"),
                                   latitude: 53.552736, longitude: 10.006909)]
        case "frankfurt":
            return [OnboardingStop(id: "8000105", name: "Frankfurt (Main) Hbf",
                                   lines: "S · U · Tram · Bus", badgeColor: Color(hex: "#00428a"),
                                   latitude: 50.107149, longitude: 8.663785)]
        case "cologne":
            return [OnboardingStop(id: "8000207", name: "Köln Hauptbahnhof",
                                   lines: "S · Stadtbahn · Bus", badgeColor: Color(hex: "#ed1c24"),
                                   latitude: 50.943029, longitude: 6.958749)]
        case "leipzig":
            return [OnboardingStop(id: "8010205", name: "Leipzig Hauptbahnhof",
                                   lines: "S · Tram · Bus", badgeColor: Color(hex: "#004e9e"),
                                   latitude: 51.345172, longitude: 12.381541)]
        case "nuremberg":
            return [OnboardingStop(id: "8000284", name: "Nürnberg Hauptbahnhof",
                                   lines: "S · U · Tram · Bus", badgeColor: Color(hex: "#e30613"),
                                   latitude: 49.445544, longitude: 11.082813)]
        default:
            return berlinDemos
        }
    }

    private static let berlinDemos: [OnboardingStop] = [
        OnboardingStop(id: "900100003", name: "Alexanderplatz", lines: "U2 · U5 · S5 · S7 · S9", badgeColor: Color(hex: "#005A99"), latitude: 52.5219, longitude: 13.4132),
        OnboardingStop(id: "900003201", name: "Hauptbahnhof", lines: "S5 · S7 · S9 · RE1 · RE2", badgeColor: Color(hex: "#006F35"), latitude: 52.5251, longitude: 13.3694),
        OnboardingStop(id: "900012104", name: "Hermannplatz", lines: "U7 · U8", badgeColor: Color(hex: "#005A99"), latitude: 52.4872, longitude: 13.4249),
        OnboardingStop(id: "900058101", name: "Warschauer Str.", lines: "U1 · S3 · S5 · Tram", badgeColor: Color(hex: "#C0392B"), latitude: 52.5083, longitude: 13.4488),
        OnboardingStop(id: "900100022", name: "Potsdamer Platz", lines: "U2 · S1 · S25 · S26", badgeColor: Color(hex: "#005A99"), latitude: 52.5096, longitude: 13.3761),
        OnboardingStop(id: "900120005", name: "Ostbahnhof", lines: "S3 · S5 · S7 · S9", badgeColor: Color(hex: "#006F35"), latitude: 52.5106, longitude: 13.4344),
        OnboardingStop(id: "900110006", name: "Schönhauser Allee", lines: "U2 · S8 · S41 · S42", badgeColor: Color(hex: "#006F35"), latitude: 52.5496, longitude: 13.4142),
        OnboardingStop(id: "900023201", name: "Zoologischer Garten", lines: "S5 · S7 · S9 · Bus", badgeColor: Color(hex: "#006F35"), latitude: 52.5068, longitude: 13.3329),
    ]
}

// MARK: - Sample Departures for Demo
struct SampleDeparture: Identifiable {
    let id = UUID()
    let line: String
    let lineColor: Color
    let direction: String
    let minutesAway: Int
    let delay: Int // 0 = on time
}

extension OnboardingStop {
    var sampleDepartures: [SampleDeparture] {
        switch id {
        case "900100003": // Alexanderplatz
            return [
                SampleDeparture(line: "U2", lineColor: Color(hex: "#DA291C"), direction: "Ruhleben", minutesAway: 2, delay: 0),
                SampleDeparture(line: "S7", lineColor: Color(hex: "#006F35"), direction: "Ahrensfelde", minutesAway: 4, delay: 1),
                SampleDeparture(line: "U5", lineColor: Color(hex: "#7D4F9E"), direction: "Hönow", minutesAway: 6, delay: 0),
            ]
        case "900003201": // Hauptbahnhof
            return [
                SampleDeparture(line: "S5", lineColor: Color(hex: "#006F35"), direction: "Strausberg Nord", minutesAway: 1, delay: 0),
                SampleDeparture(line: "RE1", lineColor: Color(hex: "#C0392B"), direction: "Frankfurt (Oder)", minutesAway: 8, delay: 3),
                SampleDeparture(line: "S7", lineColor: Color(hex: "#006F35"), direction: "Potsdam Hbf", minutesAway: 11, delay: 0),
            ]
        // Other-city Hauptbahnhof fallback — generic plausible departures
        case "8000261", "8002549", "8000105", "8000207", "8010205", "8000284":
            return [
                SampleDeparture(line: "S1", lineColor: Color(hex: "#006F35"), direction: "City centre", minutesAway: 2, delay: 0),
                SampleDeparture(line: "U2", lineColor: Color(hex: "#005A99"), direction: "Outbound", minutesAway: 5, delay: 1),
                SampleDeparture(line: "Bus", lineColor: Color(hex: "#8B0000"), direction: "Local", minutesAway: 7, delay: 0),
            ]
        default:
            return [
                SampleDeparture(line: "U7", lineColor: Color(hex: "#005A99"), direction: "Spandau", minutesAway: 3, delay: 0),
                SampleDeparture(line: "U7", lineColor: Color(hex: "#005A99"), direction: "Rudow", minutesAway: 8, delay: 2),
                SampleDeparture(line: "Bus 104", lineColor: Color(hex: "#8B0000"), direction: "Mitte", minutesAway: 5, delay: 0),
            ]
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let current: Int  // 1..total — the position of the current screen in the progress arc
    let total: Int    // total number of progress screens (Location, Demo, Value)

    var progress: Double { Double(current) / Double(total) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(duration: 0.4), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onDismiss: () -> Void

    /// Lean 5-screen flow:
    ///   0 = Welcome
    ///   1 = Location priming
    ///   2 = Demo (pick 3 stops)
    ///   3 = Value delivery (live departures preview)
    ///   4 = Tip nudge → finish()
    @State private var step = 0

    @State private var selectedStops: [OnboardingStop] = []
    @State private var locationManager = CLLocationManager()
    @State private var saveSucceeded = true

    private let primaryBlue = Color(hex: "#115D97")
    /// Progress arc spans Location / Demo / Value (steps 1..3). Welcome and Tip
    /// don't count toward progress.
    private let totalProgressScreens = 3

    var body: some View {
        ZStack {
            // Background
            primaryBlue.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar visible on Location, Demo, Value Delivery (steps 1-3)
                if step >= 1 && step <= totalProgressScreens {
                    OnboardingProgressBar(current: step, total: totalProgressScreens)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                // Page content
                Group {
                    switch step {
                    case 0:  WelcomeScreen(onNext: { advance() })
                    case 1:  LocationPrimingScreen(locationManager: locationManager, onNext: { advance() })
                    case 2:  DemoScreen(selected: $selectedStops, onNext: { advance() })
                    case 3:  ValueDeliveryScreen(stops: selectedStops, saveSucceeded: saveSucceeded, onNext: { advance() })
                    default: TipNudgeScreen(onDismiss: { finish() })
                    }
                }
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            // Back button — shown on all steps except Welcome
            if step > 0 {
                VStack {
                    HStack {
                        Button {
                            withAnimation { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(12)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .animation(reduceMotion ? .none : .smooth(duration: 0.35), value: step)
    }

    private func advance() {
        withAnimation { step += 1 }
        // Save demo stops to Favorites when advancing to ValueDeliveryScreen
        if step == 3 {
            saveSucceeded = saveSelectedStops()
        }
    }

    private func finish() {
        onDismiss()
    }

    @discardableResult
    private func saveSelectedStops() -> Bool {
        let service = FavoritesService(modelContext: modelContext, cityManager: ServiceContainer.shared.cityManager)
        let logger = Logger(subsystem: "BerlinTransportMap", category: "Onboarding")
        var allSucceeded = true
        for stop in selectedStops {
            let stop3 = TransportStop(
                id: stop.id,
                name: stop.name,
                latitude: stop.latitude,
                longitude: stop.longitude
            )
            do {
                try service.saveStopFavorite(name: stop.name, stop: stop3)
            } catch {
                logger.error("Failed to save onboarding stop '\(stop.name)': \(error)")
                allSucceeded = false
            }
        }
        return allSucceeded
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    let onNext: () -> Void
    private var cityName: String { ServiceContainer.shared.cityManager.currentCity.name }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Live map preview (stylised)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#0E4A78"))
                    .frame(height: 260)

                // Stylised vehicle dots
                ZStack {
                    ForEach(Array(liveDots.enumerated()), id: \.offset) { idx, dot in
                        Circle()
                            .fill(dot.color)
                            .frame(width: 12, height: 12)
                            .offset(x: dot.x, y: dot.y)
                            .shadow(color: dot.color.opacity(0.8), radius: 4)
                    }
                    // Station markers
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: -20, y: 10)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: 40, y: -30)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: -60, y: -40)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 32)

            VStack(spacing: 12) {
                Text("See your bus.\nBefore it arrives.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fontDesign(.rounded)

                Text("Live positions for every U-Bahn, S-Bahn,\ntram, and bus in \(cityName).")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 40)

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#115D97"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(.white, in: .rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var liveDots: [(color: Color, x: CGFloat, y: CGFloat)] {
        [
            (Color(hex: "#DA291C"), -50, 20),   // U-Bahn red
            (Color(hex: "#006F35"), 30, -50),   // S-Bahn green
            (Color(hex: "#DA291C"), 70, 30),
            (Color(hex: "#8B0000"), -30, -60),  // Tram dark red
            (Color(hex: "#006F35"), -80, 0),
            (Color(hex: "#005A99"), 10, 60),    // U-Bahn blue
        ]
    }
}

// MARK: - Screen 2: Location Priming

private struct LocationPrimingScreen: View {
    let locationManager: CLLocationManager
    let onNext: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    Text("Find stops near\nyou instantly.")
                        .font(.system(size: 30, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Your location centers the map on where you actually are — so your stop is always front and centre.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    LocationBullet(icon: "mappin.circle.fill", text: "Map starts centered on your current location")
                    LocationBullet(icon: "tram.circle.fill", text: "Nearby stops shown automatically")
                    LocationBullet(icon: "figure.walk.circle.fill", text: "Walking distance to each stop")
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                guard !isRequesting else { return }
                isRequesting = true
                locationManager.requestWhenInUseAuthorization()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    onNext()
                }
            } label: {
                Text(isRequesting ? "Requesting…" : "Continue")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#115D97"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(.white, in: .rect(cornerRadius: 16))
            }
            .disabled(isRequesting)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

private struct LocationBullet: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Screen 3: App Demo

private struct DemoScreen: View {
    @Binding var selected: [OnboardingStop]
    let onNext: () -> Void
    private let targetCount = 3

    private var cityId: String { ServiceContainer.shared.cityManager.currentCity.id }
    private var availableStops: [OnboardingStop] { OnboardingStop.demos(for: cityId) }
    private var minimumPickable: Int { min(targetCount, availableStops.count) }

    var remaining: Int { max(0, minimumPickable - selected.count) }
    var isDone: Bool { selected.count >= minimumPickable }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(headlineText)
                    .font(.system(size: 30, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text(subheadlineText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .animation(.spring(duration: 0.3), value: remaining)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(availableStops) { stop in
                        let isSelected = selected.contains(stop)
                        Button {
                            if isSelected {
                                selected.removeAll { $0.id == stop.id }
                            } else if selected.count < minimumPickable {
                                selected.append(stop)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(stop.badgeColor)
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stop.name)
                                        .font(.headline)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(isSelected ? .white : .primary)
                                    Text(stop.lines)
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundStyle(isSelected ? .white : Color(hex: "#115D97"))
                                    .font(.title3)
                            }
                            .padding(16)
                            .background(
                                isSelected ? Color(hex: "#115D97") : Color(.systemBackground),
                                in: .rect(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(duration: 0.25), value: isSelected)
                        .disabled(!isSelected && selected.count >= minimumPickable)
                        .opacity(!isSelected && selected.count >= minimumPickable ? 0.45 : 1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            if isDone {
                Button(action: onNext) {
                    Text("See live departures →")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#115D97"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white, in: .rect(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: isDone)
    }

    private var headlineText: String {
        minimumPickable == 1 ? "Pick your stop." : "Pick \(minimumPickable) stops to track."
    }

    private var subheadlineText: String {
        if isDone { return "These go straight to your Favorites." }
        if selected.isEmpty {
            return minimumPickable == 1
                ? "Tap one to continue"
                : "Pick \(minimumPickable) stops to continue"
        }
        return "Pick \(remaining) more \(remaining == 1 ? "stop" : "stops")"
    }
}

// MARK: - Screen 4: Value Delivery

private struct ValueDeliveryScreen: View {
    let stops: [OnboardingStop]
    let saveSucceeded: Bool
    let onNext: () -> Void

    private var cityName: String { ServiceContainer.shared.cityManager.currentCity.name }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your stops are live. 🎉")
                    .font(.system(size: 30, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text(saveSucceeded
                    ? "Stops saved to Favorites ✓ — live data loads in the app."
                    : "Couldn't save your stops — re-add them in Favorites.")
                    .font(.subheadline)
                    .foregroundStyle(saveSucceeded ? .white.opacity(0.75) : Color(hex: "#E8641A"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(stops) { stop in
                        MiniDepartureBoard(stop: stop)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            VStack(spacing: 12) {
                ShareLink(
                    item: "Tracking \(cityName) transit live",
                    subject: Text("My \(cityName) Transit Map"),
                    message: Text("I set up live tracking for \(stops.map(\.name).joined(separator: ", ")) — check it out!")
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share my transit map")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2), in: .rect(cornerRadius: 14))
                }

                Button(action: onNext) {
                    Text("Open my map →")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#115D97"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white, in: .rect(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct MiniDepartureBoard: View {
    let stop: OnboardingStop

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(stop.badgeColor)
                    .frame(width: 10, height: 10)
                Text(stop.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 6) {
                ForEach(stop.sampleDepartures.prefix(3)) { dep in
                    HStack {
                        Text(dep.line)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(dep.lineColor, in: .rect(cornerRadius: 5))
                            .foregroundStyle(.white)

                        Text(dep.direction)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(dep.minutesAway) min")
                                .font(.subheadline.bold())
                                .monospacedDigit()
                                .foregroundStyle(dep.delay > 0 ? Color(hex: "#E8641A") : Color(hex: "#00A550"))
                            if dep.delay > 0 {
                                Text("+\(dep.delay)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(hex: "#E8641A"))
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 14))
    }
}

// MARK: - Screen 5: Tip Nudge

private struct TipNudgeScreen: View {
    let onDismiss: () -> Void
    @State private var store = TipJarStore()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    Text("Keep this app free.")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("No ads. No subscription. No data collection.\nJust one developer keeping the lights on.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(store.tipOptions) { option in
                        Button {
                            Task {
                                await store.purchaseTip(option)
                                // Only dismiss on confirmed purchase; cancelled/failed stays on screen
                                if store.state == .completed {
                                    onDismiss()
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(option.emoji) \(option.displayName)")
                                    .font(.body.bold())
                                    .foregroundStyle(Color(hex: "#115D97"))
                                Spacer()
                                Text(store.product(for: option)?.displayPrice ?? option.displayPrice)
                                    .font(.body.bold())
                                    .foregroundStyle(Color(hex: "#115D97"))
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 15)
                            .background(.white, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.state == .loading)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onDismiss) {
                Text("Maybe later")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.bottom, 48)
        }
        .task { await store.loadProducts() }
    }
}
