import XCTest
import SwiftData
@testable import BerlinTransportMap

/// Verifies the additive cityId migration on `Favorite`:
/// - Legacy nil cityId reads as Berlin
/// - Per-(stopId, cityId) deduplication: the same stopId can exist in multiple cities
@MainActor
final class FavoriteCityIdMigrationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var cityManager: CityManager!

    override func setUp() async throws {
        let schema = Schema([Favorite.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        UserDefaults.standard.removeObject(forKey: "selectedCityId")
        cityManager = CityManager()
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        UserDefaults.standard.removeObject(forKey: "selectedCityId")
    }

    func testNilCityIdIsReadAsBerlin() {
        let f = Favorite(name: "Hauptbahnhof", type: .stop, stopId: "900003201", cityId: nil)
        XCTAssertEqual(f.effectiveCityId, "berlin")
    }

    func testExplicitCityIdIsPreserved() {
        let f = Favorite(name: "Hauptbahnhof", type: .stop, stopId: "8000261", cityId: "munich")
        XCTAssertEqual(f.effectiveCityId, "munich")
    }

    func testSavingSameStopInDifferentCitiesProducesTwoFavorites() throws {
        let service = FavoritesService(modelContext: context, cityManager: cityManager)

        // Save in Berlin (default)
        cityManager.selectCity(.berlin)
        try service.saveStopFavorite(
            name: "Hauptbahnhof",
            stop: TransportStop(id: "hbf", name: "Hauptbahnhof", latitude: 52.52, longitude: 13.37)
        )

        // Switch to Munich and save what looks like the same stop id
        cityManager.selectCity(.munich)
        try service.saveStopFavorite(
            name: "Hauptbahnhof",
            stop: TransportStop(id: "hbf", name: "Hauptbahnhof", latitude: 48.14, longitude: 11.56)
        )

        let all = try service.loadFavorites().filter { $0.stopId == "hbf" }
        XCTAssertEqual(all.count, 2, "Same stopId in different cities must persist as 2 favorites")
        XCTAssertEqual(Set(all.map { $0.effectiveCityId }), Set(["berlin", "munich"]))
    }

    func testSavingSameStopInSameCityIsDeduplicated() throws {
        let service = FavoritesService(modelContext: context, cityManager: cityManager)
        cityManager.selectCity(.berlin)
        let stop = TransportStop(id: "alex", name: "Alexanderplatz", latitude: 52.52, longitude: 13.41)
        try service.saveStopFavorite(name: "Alexanderplatz", stop: stop)
        try service.saveStopFavorite(name: "Alexanderplatz", stop: stop)
        let all = try service.loadFavorites().filter { $0.stopId == "alex" }
        XCTAssertEqual(all.count, 1, "Same stopId in same city must dedupe")
    }
}
