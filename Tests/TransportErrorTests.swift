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
        if case .cancelled = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected cancellation to map to .cancelled")
        }
    }

    func testFromURLError() {
        let urlError = URLError(.notConnectedToInternet)
        let error = TransportError.from(urlError)
        if case let .networkError(message) = error {
            XCTAssertEqual(message, urlError.localizedDescription)
        } else {
            XCTFail("Expected URLError to map to .networkError")
        }
    }

    func testFromTransportErrorPassesThrough() {
        let original = TransportError.invalidLocation
        let error = TransportError.from(original)
        if case .invalidLocation = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected TransportError.from to pass through existing TransportError values")
        }
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
