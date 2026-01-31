import SwiftData
import Foundation

@Model
final class Favorite {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: FavoriteType
    var stopId: String?
    var latitude: Double?
    var longitude: Double?
    var routeName: String?
    var routeCoordinates: Data?
    var createdAt: Date
    
    init(name: String, type: FavoriteType, stopId: String? = nil, latitude: Double? = nil, longitude: Double? = nil, routeName: String? = nil, routeCoordinates: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.stopId = stopId
        self.latitude = latitude
        self.longitude = longitude
        self.routeName = routeName
        self.routeCoordinates = routeCoordinates
        self.createdAt = Date()
    }
}

enum FavoriteType: String, Codable {
    case stop
    case route
}