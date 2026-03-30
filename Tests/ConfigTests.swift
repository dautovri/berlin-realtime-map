import XCTest
@testable import BerlinTransportMap

final class ConfigTests: XCTestCase {

    func testEnvOverrideBaseURLReturnsNilWhenNotSet() {
        // VBB_BASE_URL is not set in the test environment
        XCTAssertNil(Env.overrideBaseURL)
    }
}
