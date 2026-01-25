import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    
    var body: some View {
        TransportMapView()
            .preferredColorScheme(useSystemTheme ? nil : (darkMode ? .dark : .light))
    }
}

#Preview {
    ContentView()
}
