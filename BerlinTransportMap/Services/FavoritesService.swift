import SwiftData
import Foundation
import WidgetKit

@MainActor
@Observable
final class FavoritesService {
    private let modelContext: ModelContext
    private let cityManager: CityManager
    private let encoder = JSONEncoder()

    init(modelContext: ModelContext, cityManager: CityManager) {
        self.modelContext = modelContext
        self.cityManager = cityManager
    }

    func saveFavorite(_ favorite: Favorite) throws {
        modelContext.insert(favorite)
        try modelContext.save()
        ActivationMetricsService.shared.recordFavoriteSave()
        syncWidgetStops()
    }

    func saveStopFavorite(name: String, stop: TransportStop) throws {
        let stopId = stop.id
        let cityId = cityManager.currentCity.id
        // Deduplicate per (stopId, cityId). Same stop in two cities is rare but possible
        // ("Hauptbahnhof" exists in both Berlin and Munich with different APIs/IDs).
        // Treat legacy nil cityId as berlin for the comparison.
        let existing = try modelContext.fetch(FetchDescriptor<Favorite>(predicate: #Predicate<Favorite> { f in
            f.stopId == stopId && (f.cityId == cityId || (f.cityId == nil && cityId == "berlin"))
        }))
        guard existing.isEmpty else { return }
        let favorite = Favorite(name: name, type: .stop, stopId: stop.id, latitude: stop.latitude, longitude: stop.longitude, cityId: cityId)
        try saveFavorite(favorite)
    }

    func saveRouteFavorite(name: String, route: Route) throws {
        let routeName = route.legs.compactMap { $0.line?.label }.joined(separator: " → ")
        let coordinatesData = try encoder.encode(route.coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] })
        let favorite = Favorite(name: name, type: .route, routeName: routeName, routeCoordinates: coordinatesData, cityId: cityManager.currentCity.id)
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
    /// Each entry carries its city's apiBaseURL so the widget hits the right endpoint
    /// per-stop (favorites can span cities).
    func syncWidgetStops() {
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.stopId != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let stops = try? modelContext.fetch(descriptor) else { return }

        struct WidgetStop: Encodable {
            let id: String
            let name: String
            let cityId: String
            let apiBaseURL: String
        }
        let widgetStops = stops.compactMap { f -> WidgetStop? in
            guard let sid = f.stopId else { return nil }
            let cityId = f.effectiveCityId
            let apiBaseURL = CityConfig.city(forId: cityId)?.apiBaseURL ?? CityConfig.berlin.apiBaseURL
            return WidgetStop(id: sid, name: f.name, cityId: cityId, apiBaseURL: apiBaseURL)
        }
        guard let data = try? JSONEncoder().encode(widgetStops) else { return }
        UserDefaults(suiteName: "group.com.dautov.berlintransportmap")?.set(data, forKey: "widget_savedStops")
        WidgetCenter.shared.reloadAllTimelines()
    }
}