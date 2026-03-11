import SwiftUI
import SwiftData
import MapKit

@main
struct BerlinTransportMapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Favorite.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Eagerly preload stops database on app launch
        Task(priority: .userInitiated) {
            await OfflineStopsDatabase.shared.loadIfNeeded()
        }
        // Warm up MapKit tile cache for Berlin's core area
        Task { @MainActor in
            MapTilePreloader.shared.preloadBerlinTiles()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Map Tile Preloader

/// Preloads MapKit tiles for Berlin's core area at common zoom levels
/// so the map appears instantly without white tiles on first launch
@MainActor
final class MapTilePreloader {
    static let shared = MapTilePreloader()
    private var hasPreloaded = false

    private init() {}

    func preloadBerlinTiles() {
        guard !hasPreloaded else { return }
        hasPreloaded = true

        let berlinCenter = CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954)

        // Preload at two zoom levels: city overview and neighborhood
        let regions: [(MKCoordinateRegion, CGSize)] = [
            // City overview (~10km span)
            (MKCoordinateRegion(
                center: berlinCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ), CGSize(width: 512, height: 512)),
            // Neighborhood level (~2km span)
            (MKCoordinateRegion(
                center: berlinCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ), CGSize(width: 512, height: 512))
        ]

        for (region, size) in regions {
            let options = MKMapSnapshotter.Options()
            options.region = region
            options.size = size
            options.mapType = .standard

            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start { _, _ in
                // We don't need the snapshot image — just triggering
                // the download caches the tiles for MapKit to reuse
            }
        }
    }
}
