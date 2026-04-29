import XCTest
@testable import BerlinTransportMap

@MainActor
final class CityManagerTests: XCTestCase {

    private static let savedCityKey = "selectedCityId"

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: Self.savedCityKey)
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: Self.savedCityKey)
    }

    func testDefaultsToBerlinWhenNoSavedKey() {
        let manager = CityManager()
        XCTAssertEqual(manager.currentCity.id, "berlin")
    }

    func testRestoresSavedCity() {
        UserDefaults.standard.set("munich", forKey: Self.savedCityKey)
        let manager = CityManager()
        XCTAssertEqual(manager.currentCity.id, "munich")
    }

    func testInvalidSavedIdFallsBackToBerlin() {
        UserDefaults.standard.set("atlantis", forKey: Self.savedCityKey)
        let manager = CityManager()
        XCTAssertEqual(manager.currentCity.id, "berlin")
    }

    func testSelectCityPersistsToUserDefaults() {
        let manager = CityManager()
        manager.selectCity(.hamburg)
        XCTAssertEqual(UserDefaults.standard.string(forKey: Self.savedCityKey), "hamburg")
    }

    func testAvailableCitiesMatchesAllCities() {
        let manager = CityManager()
        XCTAssertEqual(
            manager.availableCities.map { $0.id },
            CityConfig.allCities.map { $0.id }
        )
    }
}
