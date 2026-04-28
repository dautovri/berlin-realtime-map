import XCTest
@testable import BerlinTransportMap

/// Regression tests for the city-switch propagation in ServiceContainer.
/// These guard the race-condition fix and the propagation surface area.
@MainActor
final class ServiceContainerUpdateCityTests: XCTestCase {

    override func setUp() async throws {
        // Reset shared singleton state to Berlin before each test so order-of-test
        // independence is preserved.
        await ServiceContainer.shared.updateCity(.berlin)
    }

    override func tearDown() async throws {
        await ServiceContainer.shared.updateCity(.berlin)
    }

    func testUpdateCityPropagatesToTransportService() async {
        let services = ServiceContainer.shared
        await services.updateCity(.munich)
        XCTAssertEqual(services.transportService.cityId, "munich")
    }

    func testUpdateCityPropagatesToRouteService() async {
        let services = ServiceContainer.shared
        await services.updateCity(.hamburg)
        XCTAssertEqual(services.routeService.cityId, "hamburg")
    }

    func testUpdateCityPropagatesToVehicleRadarService() async {
        let services = ServiceContainer.shared
        await services.updateCity(.frankfurt)
        let radarCity = await services.vehicleRadarService.cityId
        XCTAssertEqual(radarCity, "frankfurt")
    }

    func testUpdateCityPropagatesToOfflineDatabase() async {
        let services = ServiceContainer.shared
        await services.updateCity(.cologne)
        let activeCity = await OfflineStopsDatabase.shared.activeCityId()
        XCTAssertEqual(activeCity, "cologne")
    }

    func testUpdateCityPropagatesToCityManager() async {
        let services = ServiceContainer.shared
        await services.updateCity(.dresden)
        XCTAssertEqual(services.cityManager.currentCity.id, "dresden")
    }

    /// Race regression: the radar update used to be dispatched in an unstructured Task.
    /// Awaiting updateCity must mean the radar service is already on the new city —
    /// no window where a fetch can land on the old baseURL.
    func testUpdateCityIsAtomicAcrossServices() async {
        let services = ServiceContainer.shared
        await services.updateCity(.stuttgart)
        async let transportCity = services.transportService.cityId
        async let routeCity = services.routeService.cityId
        async let radarCity = await services.vehicleRadarService.cityId
        async let offlineCity = await OfflineStopsDatabase.shared.activeCityId()
        let (t, r, v, o) = await (transportCity, routeCity, radarCity, offlineCity)
        XCTAssertEqual(t, "stuttgart")
        XCTAssertEqual(r, "stuttgart")
        XCTAssertEqual(v, "stuttgart")
        XCTAssertEqual(o, "stuttgart")
    }
}
