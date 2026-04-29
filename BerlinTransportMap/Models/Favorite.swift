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
    // City the favorite belongs to. nil = legacy pre-multi-city data, treated as Berlin.
    var cityId: String?

    init(name: String, type: FavoriteType, stopId: String? = nil, latitude: Double? = nil, longitude: Double? = nil, routeName: String? = nil, routeCoordinates: Data? = nil, cityId: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.stopId = stopId
        self.latitude = latitude
        self.longitude = longitude
        self.routeName = routeName
        self.routeCoordinates = routeCoordinates
        self.cityId = cityId
        self.createdAt = Date()
    }

    /// Effective city id, treating nil (legacy data) as Berlin.
    var effectiveCityId: String { cityId ?? "berlin" }
}

enum FavoriteType: String, Codable {
    case stop
    case route
}