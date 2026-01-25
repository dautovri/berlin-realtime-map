import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    
    var body: some View {
        LazyVStack {
            TabView {
                TransportMapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                
                RecommendationsView()
                    .tabItem {
                        Label("Recommendations", systemImage: "star")
                    }
            }
        }
        .preferredColorScheme(useSystemTheme ? nil : (darkMode ? .dark : .light))
    }
}

#Preview {
    ContentView()
}
