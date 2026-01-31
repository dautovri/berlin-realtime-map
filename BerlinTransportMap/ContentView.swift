import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true

    var body: some View {
        TransportMapView()
            .preferredColorScheme(activeColorScheme)
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
