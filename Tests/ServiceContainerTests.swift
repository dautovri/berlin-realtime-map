import XCTest
@testable import BerlinTransportMap

@MainActor
final class ServiceContainerTests: XCTestCase {

    func testServiceContainerSharedInstance() {
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        XCTAssertIdentical(container1, container2, "ServiceContainer should be a singleton")
    }

    func testServicesAreNotNil() {
        let services = ServiceContainer.shared
        XCTAssertNotNil(services.transportService)
        XCTAssertNotNil(services.routeService)
        XCTAssertNotNil(services.vehicleRadarService)
        XCTAssertNotNil(services.cacheService)
        XCTAssertNotNil(services.predictionService)
        XCTAssertNotNil(services.networkMonitor)
        XCTAssertNotNil(services.eventsService)
        XCTAssertNotNil(services.predictiveLoader)
    }

    func testTransportServiceAndRouteServiceHaveSameAPIConfig() {
        let container = ServiceContainer.shared
        XCTAssertNotNil(container.transportService)
        XCTAssertNotNil(container.routeService)
    }
}
