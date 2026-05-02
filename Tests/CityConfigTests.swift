import XCTest
@testable import BerlinTransportMap

final class CityConfigTests: XCTestCase {

    // MARK: - Identity invariants

    func testAllCitiesHaveUniqueIds() {
        let ids = CityConfig.allCities.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "City ids must be unique across allCities")
    }

    func testAllCitiesCount() {
        XCTAssertEqual(CityConfig.allCities.count, 10, "10 cities are expected (Berlin + 9 expansion)")
    }

    func testCityForIdResolvesEveryListedCity() {
        for city in CityConfig.allCities {
            XCTAssertEqual(CityConfig.city(forId: city.id)?.id, city.id)
        }
    }

    func testCityForIdReturnsNilForUnknown() {
        XCTAssertNil(CityConfig.city(forId: "atlantis"))
    }

    // MARK: - URL invariants

    func testAllCitiesHaveHTTPSAPIBase() {
        for city in CityConfig.allCities {
            XCTAssertTrue(
                city.apiBaseURL.hasPrefix("https://"),
                "\(city.id) apiBaseURL must use HTTPS, got \(city.apiBaseURL)"
            )
        }
    }

    func testBerlinUsesVBBEndpoint() {
        XCTAssertEqual(CityConfig.berlin.apiBaseURL, "https://v6.vbb.transport.rest")
    }

    func testNonBerlinCitiesUseDBEndpoint() {
        for city in CityConfig.allCities where city.id != "berlin" {
            XCTAssertEqual(
                city.apiBaseURL, "https://v6.db.transport.rest",
                "\(city.id) should use the DB transport.rest endpoint until validated otherwise"
            )
        }
    }

    // MARK: - Bounding box invariants

    func testEveryCityBoundingBoxIsNonEmpty() {
        for city in CityConfig.allCities {
            XCTAssertGreaterThan(city.spanLatitude, 0, "\(city.id) spanLatitude must be > 0")
            XCTAssertGreaterThan(city.spanLongitude, 0, "\(city.id) spanLongitude must be > 0")
        }
    }

    func testEveryCityCenterIsOnEarth() {
        for city in CityConfig.allCities {
            XCTAssertGreaterThan(city.centerLatitude, -90)
            XCTAssertLessThan(city.centerLatitude, 90)
            XCTAssertGreaterThan(city.centerLongitude, -180)
            XCTAssertLessThan(city.centerLongitude, 180)
        }
    }

    // MARK: - Capability flag invariants

    func testOnlyBerlinSupportsRadarUntilMatrixRuns() {
        // Only Berlin's endpoints have been validated. Other cities must default to false
        // until scripts/validate-city-endpoints.sh runs and the data is recorded here.
        XCTAssertTrue(CityConfig.berlin.supportsRadar)
        for city in CityConfig.allCities where city.id != "berlin" {
            XCTAssertFalse(
                city.supportsRadar,
                "\(city.id) supportsRadar must stay false until API endpoint matrix is validated"
            )
        }
    }

    func testOnlyBerlinSupportsEvents() {
        XCTAssertTrue(CityConfig.berlin.supportsEvents)
        for city in CityConfig.allCities where city.id != "berlin" {
            XCTAssertFalse(
                city.supportsEvents,
                "\(city.id) supportsEvents must be false — api.berlin.de has no equivalent for other cities"
            )
        }
    }

    func testEveryCitySupportsRoutes() {
        for city in CityConfig.allCities {
            XCTAssertTrue(
                city.supportsRoutes,
                "\(city.id) supportsRoutes should be true — /journeys is the shared HAFAS endpoint"
            )
        }
    }

    // MARK: - supportsDepartures (per-city HAFAS departures health)

    func testCitiesWithBrokenDeparturesAreFlagged() {
        // Verified 2026-05-02 via scripts/validate-city-endpoints.sh:
        // VVS (Stuttgart), VRR (Düsseldorf), DVB (Dresden) return HTTP 500
        // on every /stops/{id}/departures call. Flip these to true once the
        // upstream community API recovers + the script confirms.
        let brokenCityIds = Set(["stuttgart", "dusseldorf", "dresden"])
        for city in CityConfig.allCities where brokenCityIds.contains(city.id) {
            XCTAssertFalse(
                city.supportsDepartures,
                "\(city.id) must stay supportsDepartures=false — backend was returning HTTP 500. Re-validate via scripts/validate-city-endpoints.sh before flipping."
            )
        }
    }

    func testAvailableCitiesFiltersOutDisabledBackends() {
        let available = CityConfig.availableCities
        XCTAssertFalse(available.isEmpty, "availableCities must include at least Berlin")
        for city in available {
            XCTAssertTrue(
                city.supportsDepartures,
                "\(city.id) is in availableCities but has supportsDepartures=false"
            )
        }
        // Specifically: known-broken cities must be excluded
        XCTAssertNil(available.first { $0.id == "stuttgart" })
        XCTAssertNil(available.first { $0.id == "dusseldorf" })
        XCTAssertNil(available.first { $0.id == "dresden" })
    }

    func testCityForIdStillResolvesDisabledCities() {
        // Lookups must succeed even for disabled cities — legacy favorites and
        // commute alerts may reference them. Caller checks supportsDepartures
        // before showing a UI affordance.
        XCTAssertNotNil(CityConfig.city(forId: "stuttgart"))
        XCTAssertNotNil(CityConfig.city(forId: "dusseldorf"))
        XCTAssertNotNil(CityConfig.city(forId: "dresden"))
    }

    // MARK: - Color hex invariants

    func testEveryCityHasSixDigitHexAccent() {
        for city in CityConfig.allCities {
            let trimmed = city.accentColorHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            XCTAssertEqual(
                trimmed.count, 6,
                "\(city.id) accentColorHex must be 6 hex digits, got \(city.accentColorHex)"
            )
            XCTAssertNotNil(
                UInt32(trimmed, radix: 16),
                "\(city.id) accentColorHex must parse as hex, got \(city.accentColorHex)"
            )
        }
    }
}
