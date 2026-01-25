import SwiftUI
import SwiftData

@main
struct BerlinTransportMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Favorite.self)
        }
    }
}
