import SwiftData
import Foundation

@Model
final class Favorite {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: FavoriteType
    var stopId: String?
    var routeData: Data?
    var createdAt: Date
    
    init(name: String, type: FavoriteType, stopId: String? = nil, routeData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.stopId = stopId
        self.routeData = routeData
        self.createdAt = Date()
    }
}

enum FavoriteType: String, Codable {
    case stop
    case route
}

// For encoding/decoding Route data
extension Favorite {
    func getRoute() -> Route? {
        guard let data = routeData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Route.self, from: data)
    }
    
    func setRoute(_ route: Route) {
        let encoder = JSONEncoder()
        routeData = try? encoder.encode(route)
    }
}