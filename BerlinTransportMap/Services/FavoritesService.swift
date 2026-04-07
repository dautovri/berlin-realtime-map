import SwiftData
import Foundation

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
    }
    
    func saveStopFavorite(name: String, stop: TransportStop) throws {
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
    }
    
    func deleteFavorite(by id: UUID) throws {
        let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.id == id })
        let favorites = try modelContext.fetch(descriptor)
        for favorite in favorites {
            modelContext.delete(favorite)
        }
        try modelContext.save()
    }
}