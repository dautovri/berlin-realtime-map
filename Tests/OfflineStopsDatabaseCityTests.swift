import XCTest
@testable import BerlinTransportMap

/// Verifies the per-city actor behavior of `OfflineStopsDatabase`.
/// We use the shared singleton (it's the only public surface) and rely on
/// the in-memory state being scoped per active city — switching drops the
/// previous city's stops.
final class OfflineStopsDatabaseCityTests: XCTestCase {

    private let db = OfflineStopsDatabase.shared

    override func setUp() async throws {
        // Reset to Berlin before each test so order independence holds.
        await db.switchCity(.berlin)
    }

    override func tearDown() async throws {
        await db.switchCity(.berlin)
    }

    func testActiveCityIdReportsBerlinByDefault() async {
        let id = await db.activeCityId()
        XCTAssertEqual(id, "berlin")
    }

    func testSwitchCityChangesActiveCity() async {
        await db.switchCity(.munich)
        let id = await db.activeCityId()
        XCTAssertEqual(id, "munich")
    }

    func testSwitchToSameCityIsIdempotent() async {
        await db.switchCity(.berlin)
        await db.switchCity(.berlin)
        let id = await db.activeCityId()
        XCTAssertEqual(id, "berlin")
    }

    /// After switching cities, in-memory stops are cleared. We can't assert
    /// the previous city's full data set without network or bundle, so we
    /// verify the post-switch state is empty until `loadIfNeeded` runs.
    func testSwitchCityClearsInMemoryStops() async {
        await db.switchCity(.hamburg)
        let stops = await db.getAllStops()
        XCTAssertTrue(stops.isEmpty, "In-memory stops must be empty immediately after switching cities")
    }
}
