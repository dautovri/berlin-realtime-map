import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

#if DEBUG
    private var isAboutVerificationMode: Bool {
        ProcessInfo.processInfo.environment["VERIFY_ABOUT_SCREENSHOT"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-verifyAboutScreenshot")
    }

    private var isSettingsVerificationMode: Bool {
        ProcessInfo.processInfo.environment["VERIFY_SETTINGS_SCREENSHOT"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-verifySettingsScreenshot")
    }
#endif

    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.environment["VERIFY_DONATION_SCREENSHOT"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-verifyDonationScreenshot") {
            NavigationStack {
                TipJarView()
            }
            .preferredColorScheme(activeColorScheme)
        } else if isAboutVerificationMode {
            NavigationStack {
                BerlinTransportMapAboutView()
            }
            .preferredColorScheme(activeColorScheme)
        } else if isSettingsVerificationMode {
            SettingsView()
                .preferredColorScheme(activeColorScheme)
        } else {
            TransportMapView()
                .preferredColorScheme(activeColorScheme)
#if !os(tvOS)
                .overlay {
                    if !hasSeenWelcome {
                        OnboardingView { hasSeenWelcome = true }
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: hasSeenWelcome)
#endif
        }
#else
        TransportMapView()
            .preferredColorScheme(activeColorScheme)
#if !os(tvOS)
            .overlay {
                if !hasSeenWelcome {
                    OnboardingView { hasSeenWelcome = true }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasSeenWelcome)
#endif
#endif
    }

    private var activeColorScheme: ColorScheme? {
        guard !useSystemTheme else {
            return nil
        }

        return darkMode ? .dark : .light
    }
}

#Preview {
    ContentView()
}
