import SwiftData
import Foundation

@Observable
final class FavoritesService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveFavorite(_ favorite: Favorite) throws {
        modelContext.insert(favorite)
        try modelContext.save()
    }
    
    func saveStopFavorite(name: String, stop: TransportStop) throws {
        let favorite = Favorite(name: name, type: .stop, stopId: stop.id)
        try saveFavorite(favorite)
    }
    
    func saveRouteFavorite(name: String, route: Route) throws {
        let favorite = Favorite(name: name, type: .route)
        favorite.setRoute(route)
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