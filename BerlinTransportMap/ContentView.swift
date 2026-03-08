import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true

#if DEBUG
    private var isAboutVerificationMode: Bool {
        ProcessInfo.processInfo.environment["VERIFY_ABOUT_SCREENSHOT"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-verifyAboutScreenshot")
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
        } else {
            TransportMapView()
                .preferredColorScheme(activeColorScheme)
        }
#else
        TransportMapView()
            .preferredColorScheme(activeColorScheme)
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
