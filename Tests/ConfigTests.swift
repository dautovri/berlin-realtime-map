import XCTest
@testable import BerlinTransportMap

final class ConfigTests: XCTestCase {

    func testApiAuthorizationUsesEnvironmentVariable() {
        let apiAuth = Config.apiAuthorization

        XCTAssertEqual(apiAuth["type"] as? String, "AID")
        XCTAssertNotNil(apiAuth["aid"] as? String)
    }

    func testApiAuthorizationFormat() {
        let apiAuth = Config.apiAuthorization

        guard let aid = apiAuth["aid"] as? String else {
            XCTFail("API AID should be a string")
            return
        }

        XCTAssertFalse(aid.isEmpty, "API AID should not be empty")
        XCTAssertTrue(aid.hasPrefix("1"), "API AID should start with '1'")
    }

    func testApiAuthorizationUsesEnvironmentWhenAvailableOtherwiseFallsBack() {
        let apiAuth = Config.apiAuthorization
        let resolvedAid = apiAuth["aid"] as? String

        if let environmentAid = Env.apiAid {
            XCTAssertEqual(resolvedAid, environmentAid)
        } else {
            XCTAssertEqual(resolvedAid, "1Rxs112shyHLatUX4fofnmdxK")
        }
    }
}
