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

    func testAvailableCitiesMatchesPickerEligibleCities() {
        // availableCities filters out cities whose backend is broken
        // (supportsDepartures=false). This is intentional per the v1.7 QA finding —
        // see CityConfigTests.testCitiesWithBrokenDeparturesAreFlagged.
        let manager = CityManager()
        XCTAssertEqual(
            manager.availableCities.map { $0.id },
            CityConfig.availableCities.map { $0.id }
        )
        // Sanity: no disabled city leaks through
        for city in manager.availableCities {
            XCTAssertTrue(city.supportsDepartures, "\(city.id) should not be in picker list")
        }
    }

    func testInitFallsBackToBerlinIfSavedCityNowDisabled() {
        // User picked Stuttgart in a prior version (when it worked), then v1.7
        // disabled it. New launch should NOT keep Stuttgart selected — fall back
        // to Berlin so the app's primary feature isn't broken on launch.
        UserDefaults.standard.set("stuttgart", forKey: Self.savedCityKey)
        let manager = CityManager()
        XCTAssertEqual(manager.currentCity.id, "berlin", "Disabled saved city should fall back to Berlin")
    }
}
