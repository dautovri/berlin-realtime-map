import SwiftUI
import CoreLocation

// MARK: - Welcome Overlay

/// Three-screen welcome overlay shown on first launch.
/// Screens: Welcome → Features → Location Priming
struct WelcomeOverlayView: View {
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var locationManager = CLLocationManager()

    // Onboarding analytics (lightweight @AppStorage — no model changes needed)
    @AppStorage("welcomeFurthestPage") private var welcomeFurthestPage = 0
    @AppStorage("welcomeLocationRequested") private var welcomeLocationRequested = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Group {
                    switch currentPage {
                    case 0:
                        WelcomePageContent {
                            currentPage = 1
                        }
                    case 1:
                        WelcomeFeaturesContent {
                            currentPage = 2
                        }
                    default:
                        WelcomeLocationContent(
                            authStatus: locationManager.authorizationStatus,
                            onAllow: {
                                onDismiss()
                                requestLocationPermission()
                            },
                            onSkip: {
                                onDismiss()
                            }
                        )
                    }
                }
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                            .frame(
                                width: index == currentPage ? 10 : 8,
                                height: index == currentPage ? 10 : 8
                            )
                    }
                }
                .accessibilityHidden(true)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 560)
            .padding(24)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
            .padding(.horizontal, 20)
        }
        .animation(reduceMotion ? .none : .smooth(duration: 0.4), value: currentPage)
        .onChange(of: currentPage) { _, newPage in
            welcomeFurthestPage = max(welcomeFurthestPage, newPage)
        }
    }

    private func requestLocationPermission() {
        welcomeLocationRequested = true
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePageContent: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            HStack(spacing: 12) {
                transitBadge("U", color: Color(hex: "#115D97"))
                transitBadge("S", color: .haltestelleGreen)
                Image(systemName: "cablecar")
                    .font(.title3)
                    .foregroundStyle(.red)
                Image(systemName: "bus.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
                Image(systemName: "ferry.fill")
                    .font(.title3)
                    .foregroundStyle(.cyan)
            }
            .accessibilityHidden(true)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text("Watch Berlin transit\nmove in real time")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Live positions of U-Bahn, S-Bahn, trams, buses, and ferries across Berlin")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            Spacer(minLength: 0)

            Button("Next") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 400)
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func transitBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(color, in: .rect(cornerRadius: 8))
    }
}

// MARK: - Page 2: Features

private struct WelcomeFeaturesContent: View {
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            VStack(spacing: 24) {
                Text("Here's what you can do")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                VStack(spacing: 24) {
                    featureRow(
                        icon: "hand.tap.fill",
                        title: "Tap any vehicle",
                        subtitle: "See its full route on the map"
                    )
                    featureRow(
                        icon: "clock.badge",
                        title: "Tap any stop",
                        subtitle: "View live departures with delay info"
                    )
                    featureRow(
                        icon: "star.fill",
                        title: "Save favorites",
                        subtitle: "Quick access to your regular stops"
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)

            Button("Next") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 400)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: "#115D97"))
                .frame(width: 44, height: 44)
                .background(Color(hex: "#115D97").opacity(0.12), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Page 3: Location

private struct WelcomeLocationContent: View {
    var authStatus: CLAuthorizationStatus
    var onAllow: () -> Void
    var onSkip: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var isDenied: Bool {
        authStatus == .denied || authStatus == .restricted
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text("See what's near you")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                Text(isDenied
                     ? "Location access was previously denied. Open Settings to enable it."
                     : "Location is used only to center the map on your position. You can always browse Berlin manually.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                if isDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                        onSkip()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: 400)
                } else {
                    Button("Allow Location", action: onAllow)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: 400)
                }

                Button("Not now", action: onSkip)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}
