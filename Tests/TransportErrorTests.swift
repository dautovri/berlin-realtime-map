import XCTest
@testable import BerlinTransportMap

final class TransportErrorTests: XCTestCase {

    func testInvalidLocationErrorDescription() {
        let error = TransportError.invalidLocation
        XCTAssertEqual(error.errorDescription, "Invalid location coordinates")
    }

    func testInvalidStationErrorDescription() {
        let error = TransportError.invalidStation
        XCTAssertEqual(error.errorDescription, "Station not found")
    }

    func testInvalidURLErrorDescription() {
        let error = TransportError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testNetworkErrorWithMessage() {
        let error = TransportError.networkError("Connection timeout")
        XCTAssertEqual(error.errorDescription, "Network error: Connection timeout")
    }

    func testNetworkErrorRecoverySuggestion() {
        let error = TransportError.networkError("No internet")
        XCTAssertEqual(error.recoverySuggestion, "Check your internet connection and try again")
    }

    func testInvalidLocationRecoverySuggestion() {
        let error = TransportError.invalidLocation
        XCTAssertEqual(error.recoverySuggestion, "Try searching for a different location")
    }

    func testFromCancellationError() {
        let cancellationError = CancellationError()
        let error = TransportError.from(cancellationError)
        XCTAssertEqual(error, TransportError.cancelled)
    }

    func testFromURLError() {
        let urlError = URLError(.notConnectedToInternet)
        let error = TransportError.from(urlError)
        XCTAssertEqual(error, TransportError.networkError(urlError.localizedDescription))
    }

    func testFromTransportErrorPassesThrough() {
        let original = TransportError.invalidLocation
        let error = TransportError.from(original)
        XCTAssertEqual(error, original)
    }

    func testFromUnknownError() {
        struct CustomError: Error {}
        let customError = CustomError()
        let error = TransportError.from(customError)
        if case .unknown = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Should be unknown error")
        }
    }
}
