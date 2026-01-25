import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        TransportMapView()
            .preferredColorScheme(darkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
