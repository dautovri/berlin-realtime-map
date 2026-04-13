import SwiftUI
import SwiftData
import CoreLocation
import OSLog

// MARK: - Onboarding Data Models

enum OnboardingGoal: String, CaseIterable, Hashable {
    case commuter, tourist, explorer, hurried, multimodal

    var emoji: String {
        switch self {
        case .commuter: return "🚇"
        case .tourist: return "✈️"
        case .explorer: return "🗺️"
        case .hurried: return "🏃"
        case .multimodal: return "🚲"
        }
    }

    var label: String {
        switch self {
        case .commuter: return "Daily commuter — same lines, every day"
        case .tourist: return "Visiting Berlin — exploring the city"
        case .explorer: return "Transit explorer — I love knowing how it all connects"
        case .hurried: return "Always in a hurry — I hate missing trains"
        case .multimodal: return "Multimodal — mix of transit and bike/walk"
        }
    }
}

enum OnboardingPain: String, CaseIterable, Hashable {
    case delays, unknownLocation, missedConnections, wrongSchedule, noSignal, waitingBlind

    var emoji: String {
        switch self {
        case .delays: return "⏱️"
        case .unknownLocation: return "📍"
        case .missedConnections: return "🔀"
        case .wrongSchedule: return "📋"
        case .noSignal: return "📶"
        case .waitingBlind: return "🌧️"
        }
    }

    var label: String {
        switch self {
        case .delays: return "Delays with no explanation"
        case .unknownLocation: return "Not knowing where my bus actually is"
        case .missedConnections: return "Missing connections at transfer points"
        case .wrongSchedule: return "Schedules that don't match reality"
        case .noSignal: return "No signal underground to check apps"
        case .waitingBlind: return "Waiting at the stop not knowing if it's coming"
        }
    }
}

struct OnboardingStop: Identifiable, Hashable {
    let id: String
    let name: String
    let lines: String
    let badgeColor: Color
    let latitude: Double
    let longitude: Double

    static let demos: [OnboardingStop] = [
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
    let current: Int  // 0-based index of progress screens (screens 2-11)
    let total: Int    // = 10

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

// MARK: - Selectable Row

private struct SelectableRow: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title3)
                Text(label)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color(hex: "#115D97") : Color(.systemGray6), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onDismiss: () -> Void

    // Navigation
    @State private var step = 0  // 0 = welcome, 1-11 = questionnaire, 12 = dismissed

    // User selections
    @State private var selectedGoal: OnboardingGoal? = nil
    @State private var selectedPains: Set<OnboardingPain> = []
    @State private var selectedStops: [OnboardingStop] = []
    @State private var locationManager = CLLocationManager()

    // Processing
    @State private var processingProgress: Double = 0
    @State private var processingComplete = false

    private let primaryBlue = Color(hex: "#115D97")
    private let totalProgressScreens = 8

    var body: some View {
        ZStack {
            // Background
            primaryBlue.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (screens 1–10, i.e. steps 1–10)
                if step > 0 && step <= 8 {
                    OnboardingProgressBar(current: step, total: totalProgressScreens)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                // Page content
                Group {
                    switch step {
                    case 0:  WelcomeScreen(onNext: { advance() })
                    case 1:  GoalScreen(selected: $selectedGoal, onNext: { advance() })
                    case 2:  PainScreen(selected: $selectedPains, onNext: { advance() })
                    case 3:  SocialProofScreen(onNext: { advance() })
                    case 4:  SolutionScreen(pains: selectedPains, onNext: { advance() })
                    case 5:  LocationPrimingScreen(locationManager: locationManager, onNext: { advance() })
                    case 6:  ProcessingScreen(isComplete: $processingComplete, onComplete: { advance() }, locationManager: locationManager)
                    case 7:  DemoScreen(selected: $selectedStops, onNext: { advance() })
                    case 8:  ValueDeliveryScreen(stops: selectedStops, onNext: { advance() })
                    default: TipNudgeScreen(onDismiss: { finish() })
                    }
                }
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            // Back button — shown on all steps except Welcome (0) and Processing (6)
            if step > 0 && step != 6 {
                VStack {
                    HStack {
                        Button {
                            withAnimation {
                                if step == 7 {
                                    // Skip step 6 (ProcessingScreen) going back, and reset so it
                                    // re-runs the 2.5s auto-advance next time step 6 is entered.
                                    step = 5
                                    processingComplete = false
                                } else {
                                    step -= 1
                                }
                            }
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
        .task(id: step) {
            if step == 6 && !processingComplete {
                try? await Task.sleep(for: .seconds(2.5))
                processingComplete = true
            }
        }
    }

    private func advance() {
        withAnimation {
            step += 1
        }
        // Save demo stops to Favorites when leaving demo screen
        if step == 9 {
            saveSelectedStops()
        }
    }

    private func finish() {
        onDismiss()
    }

    private func saveSelectedStops() {
        let service = FavoritesService(modelContext: modelContext)
        let logger = Logger(subsystem: "BerlinTransportMap", category: "Onboarding")
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
            }
        }
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    let onNext: () -> Void

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

                Text("Live positions for every U-Bahn, S-Bahn,\ntram, and bus in Berlin.")
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

// MARK: - Screen 2: Goal

private struct GoalScreen: View {
    @Binding var selected: OnboardingGoal?
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you get\naround Berlin?")
                        .font(.system(size: 30, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    Text("We'll set up your map to match.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                        SelectableRow(
                            emoji: goal.emoji,
                            label: goal.label,
                            isSelected: selected == goal
                        ) {
                            selected = goal
                        }
                    }
                }

                if selected != nil {
                    Button(action: onNext) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(Color(hex: "#115D97"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(.white, in: .rect(cornerRadius: 16))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .animation(.spring(duration: 0.3), value: selected)
    }
}

// MARK: - Screen 3: Pain Points

private struct PainScreen: View {
    @Binding var selected: Set<OnboardingPain>
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What drives you\ncrazy about\nBerlin transit?")
                        .font(.system(size: 30, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    Text("Pick everything that applies.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    ForEach(OnboardingPain.allCases, id: \.self) { pain in
                        SelectableRow(
                            emoji: pain.emoji,
                            label: pain.label,
                            isSelected: selected.contains(pain)
                        ) {
                            if selected.contains(pain) {
                                selected.remove(pain)
                            } else {
                                selected.insert(pain)
                            }
                        }
                    }
                }

                Button(action: onNext) {
                    Text("Continue")
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

// MARK: - Screen 4: Social Proof

private struct SocialProofScreen: View {
    let onNext: () -> Void
    private let testimonials = [
        (name: "Mia K.", tag: "Daily commuter · Prenzlauer Berg",
         quote: "I used to guess when to leave the house. Now I check the map and walk out at exactly the right moment."),
        (name: "James T.", tag: "Tourist · Visiting from London",
         quote: "I had no idea how to navigate Berlin transit. This showed me exactly where every bus and train was."),
        (name: "Farrukh D.", tag: "Commuter · Mitte → Kreuzberg",
         quote: "The delay info is the best part. I know before I reach the stop if something's running late."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Berliner approved.")
                            .font(.system(size: 30, weight: .bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                        Text("From commuters who switched to live tracking.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(testimonials, id: \.name) { t in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text(String(t.name.prefix(1)))
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                        Text(t.tag)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }
                                }
                                Text("\u{201C}\(t.quote)\u{201D}")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.12), in: .rect(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#115D97"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(.white, in: .rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Screen 5: Solution

private struct SolutionScreen: View {
    let pains: Set<OnboardingPain>
    let onNext: () -> Void

    private var solutions: [(pain: String, fix: String)] {
        var items: [(String, String)] = []
        if pains.contains(.unknownLocation) || pains.isEmpty {
            items.append(("I don't know where my bus is", "Live dot on the map. Every vehicle. Updated every second."))
        }
        if pains.contains(.wrongSchedule) || pains.isEmpty {
            items.append(("The board never matches reality", "Departure data pulled directly from BVG — not timetables. Live."))
        }
        if pains.contains(.missedConnections) || pains.isEmpty {
            items.append(("I miss connections", "Tap any stop, anywhere. See what's coming in the next 20 minutes."))
        }
        if pains.contains(.delays) || pains.isEmpty {
            items.append(("Delays with no warning", "Delay info appears the second BVG knows. You always know first."))
        }
        return Array(items.prefix(4))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Berlin Transit\nfixes all of that.")
                            .font(.system(size: 30, weight: .bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                        Text("Here's exactly how.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(solutions, id: \.0) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.pain)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(item.fix)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.12), in: .rect(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Button(action: onNext) {
                Text("That's what I need →")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#115D97"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(.white, in: .rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Screen 6: Location Priming

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

            VStack(spacing: 12) {
                Button {
                    guard !isRequesting else { return }
                    isRequesting = true
                    locationManager.requestWhenInUseAuthorization()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.5))
                        onNext()
                    }
                } label: {
                    Text(isRequesting ? "Requesting…" : "Enable Location")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#115D97"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white, in: .rect(cornerRadius: 16))
                }
                .disabled(isRequesting)

                Button(action: onNext) {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
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

// MARK: - Screen 9: Processing

private struct ProcessingScreen: View {
    @Binding var isComplete: Bool
    let onComplete: () -> Void
    let locationManager: CLLocationManager

    private let steps = [
        "Loading Berlin transit network",
        "Applying your preferences",
        "Fetching live departures",
    ]
    @State private var completedSteps: Set<Int> = []
    @State private var pulse = false
    @State private var animationTask: Task<Void, Never>?

    private var locationDenied: Bool {
        locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(pulse ? 0.15 : 0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.15 : 1.0)

                    Image(systemName: "tram.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }

                VStack(spacing: 0) {
                    Text("Building your personal\ntransit map…")
                        .font(.system(size: 26, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: 12) {
                            Image(systemName: completedSteps.contains(idx) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(completedSteps.contains(idx) ? .white : .white.opacity(0.4))
                                .animation(.spring(duration: 0.3), value: completedSteps.contains(idx))
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(completedSteps.contains(idx) ? .white : .white.opacity(0.5))
                        }
                    }
                }

                if locationDenied {
                    HStack(spacing: 8) {
                        Image(systemName: "location.slash.fill")
                            .font(.subheadline)
                        Text("Location off — map starts at Alexanderplatz.\nEnable in Settings → Privacy anytime.")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.12), in: .rect(cornerRadius: 10))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: locationDenied)
        .onAppear { animateSteps() }
        .onDisappear { animationTask?.cancel() }
        .onChange(of: isComplete) { _, done in
            if done { onComplete() }
        }
    }

    private func animateSteps() {
        animationTask = Task { @MainActor in
            for idx in 0..<steps.count {
                try? await Task.sleep(for: .seconds(Double(idx) * 0.7 + 0.3))
                guard !Task.isCancelled else { return }
                withAnimation { _ = completedSteps.insert(idx) }
            }
        }
    }
}

// MARK: - Screen 10: App Demo

private struct DemoScreen: View {
    @Binding var selected: [OnboardingStop]
    let onNext: () -> Void
    private let targetCount = 3

    var remaining: Int { max(0, targetCount - selected.count) }
    var isDone: Bool { selected.count >= targetCount }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick 3 stops to track.")
                    .font(.system(size: 30, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text(isDone ? "These go straight to your Favorites. ✓" : (selected.isEmpty ? "Pick 3 stops to continue" : "Pick \(remaining) more \(remaining == 1 ? "stop" : "stops")"))
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
                    ForEach(OnboardingStop.demos) { stop in
                        let isSelected = selected.contains(stop)
                        Button {
                            if isSelected {
                                selected.removeAll { $0.id == stop.id }
                            } else if selected.count < targetCount {
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
                        .disabled(!isSelected && selected.count >= targetCount)
                        .opacity(!isSelected && selected.count >= targetCount ? 0.45 : 1)
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
}

// MARK: - Screen 11: Value Delivery

private struct ValueDeliveryScreen: View {
    let stops: [OnboardingStop]
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your stops are live. 🎉")
                    .font(.system(size: 30, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text("Example departures — your live data loads in the app.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
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
                    item: "Tracking Berlin transit live with Berlin Transport Map",
                    subject: Text("My Berlin Transit Map"),
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

// MARK: - Screen 12: Tip Nudge

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
                    Text("Keep Berlin Transit free.")
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

