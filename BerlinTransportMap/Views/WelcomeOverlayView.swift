import SwiftUI
import CoreLocation

// MARK: - Welcome Overlay

/// Three-screen welcome overlay shown on first launch.
/// Screens: Welcome → Features → Location Priming
struct WelcomeOverlayView: View {
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Group {
                    switch currentPage {
                    case 0:
                        WelcomePageContent(appeared: $appeared) {
                            currentPage = 1
                        }
                    case 1:
                        WelcomeFeaturesContent {
                            currentPage = 2
                        }
                    default:
                        WelcomeLocationContent(onAllow: {
                            requestLocationPermission()
                            onDismiss()
                        }, onSkip: {
                            onDismiss()
                        })
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
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.lg)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
            .padding(.horizontal, 20)
        }
        .animation(reduceMotion ? .none : .smooth(duration: 0.4), value: currentPage)
    }

    private func requestLocationPermission() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePageContent: View {
    @Binding var appeared: Bool
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            HStack(spacing: AppTheme.Spacing.sm) {
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
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: AppTheme.Spacing.sm) {
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

            Spacer()

            Button("Next") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
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

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
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
            .padding(.horizontal, AppTheme.Spacing.xs)

            Spacer()

            Button("Next") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.12), in: .circle)

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
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
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

                Text("See what's near you")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Location is used only to center the map on your position. You can always browse Berlin manually.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                Button("Allow Location", action: onAllow)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button("Browse Berlin", action: onSkip)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - AppTheme shim for Berlin Transit Map

/// Minimal spacing/corner-radius tokens matching the MyStop Berlin design system,
/// scoped locally so this file compiles without importing DesignSystem.swift.
private enum AppTheme {
    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 16
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }
    enum CornerRadius {
        static let lg: CGFloat = 16
    }
}
