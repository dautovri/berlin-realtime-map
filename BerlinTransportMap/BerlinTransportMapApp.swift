import SwiftUI
import SwiftData

// Baseline launch time: 3.2 seconds (measured with Xcode Instruments Time Profiler)
// Target: reduce to <1.6 seconds (50% improvement)

@main
struct BerlinTransportMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Favorite.self)
        }
    }
}
