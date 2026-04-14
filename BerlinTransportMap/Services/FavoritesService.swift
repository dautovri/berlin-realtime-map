import SwiftData
import Foundation
import WidgetKit

@MainActor
@Observable
final class FavoritesService {
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveFavorite(_ favorite: Favorite) throws {
        modelContext.insert(favorite)
        try modelContext.save()
        ActivationMetricsService.shared.recordFavoriteSave()
        syncWidgetStops()
    }

    func saveStopFavorite(name: String, stop: TransportStop) throws {
        // Deduplicate: skip if a stop favorite with this stopId already exists.
        let stopId = stop.id
        let existing = try modelContext.fetch(FetchDescriptor<Favorite>(predicate: #Predicate { $0.stopId == stopId }))
        guard existing.isEmpty else { return }
        let favorite = Favorite(name: name, type: .stop, stopId: stop.id, latitude: stop.latitude, longitude: stop.longitude)
        try saveFavorite(favorite)
    }

    func saveRouteFavorite(name: String, route: Route) throws {
        let routeName = route.legs.compactMap { $0.line?.label }.joined(separator: " → ")
        let coordinatesData = try encoder.encode(route.coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] })
        let favorite = Favorite(name: name, type: .route, routeName: routeName, routeCoordinates: coordinatesData)
        try saveFavorite(favorite)
    }

    func loadFavorites() throws -> [Favorite] {
        let descriptor = FetchDescriptor<Favorite>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func deleteFavorite(_ favorite: Favorite) throws {
        modelContext.delete(favorite)
        try modelContext.save()
        syncWidgetStops()
    }

    func deleteFavorite(by id: UUID) throws {
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.id == id })
        let favorites = try modelContext.fetch(descriptor)
        for favorite in favorites {
            modelContext.delete(favorite)
        }
        try modelContext.save()
        syncWidgetStops()
    }

    // MARK: - Widget sync

    /// Write stop favorites to the shared App Group UserDefaults so the widget
    /// extension can read them without accessing the main app's SwiftData store.
    func syncWidgetStops() {
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.stopId != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let stops = try? modelContext.fetch(descriptor) else { return }

        struct WidgetStop: Encodable {
            let id: String
            let name: String
        }
        let widgetStops = stops.compactMap { f -> WidgetStop? in
            guard let sid = f.stopId else { return nil }
            return WidgetStop(id: sid, name: f.name)
        }
        guard let data = try? JSONEncoder().encode(widgetStops) else { return }
        UserDefaults(suiteName: "group.com.dautov.berlintransportmap")?.set(data, forKey: "widget_savedStops")
        WidgetCenter.shared.reloadAllTimelines()
    }
}