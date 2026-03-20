import XCTest
import CoreLocation
@testable import BerlinTransportMap

final class PredictiveLoaderTests: XCTestCase {

    func testStartPredictiveLoadingMarksLoaderActive() async {
        await MainActor.run {
            let predictiveLoader = ServiceContainer.shared.predictiveLoader
            predictiveLoader.clearPreloadedData()
            predictiveLoader.stopPredictiveLoading()
            predictiveLoader.startPredictiveLoading()

            XCTAssertTrue(predictiveLoader.isPredictiveLoadingActive)

            predictiveLoader.stopPredictiveLoading()
            predictiveLoader.clearPreloadedData()
        }
    }

    func testStopPredictiveLoadingClearsActivePreloads() async {
        await MainActor.run {
            let predictiveLoader = ServiceContainer.shared.predictiveLoader
            predictiveLoader.clearPreloadedData()
            predictiveLoader.stopPredictiveLoading()
            predictiveLoader.startPredictiveLoading()
            predictiveLoader.stopPredictiveLoading()

            XCTAssertFalse(predictiveLoader.isPredictiveLoadingActive)
            XCTAssertEqual(predictiveLoader.activePreloadCount, 0)

            predictiveLoader.clearPreloadedData()
        }
    }

    func testLocationKeyRoundsNearbyCoordinatesIntoSameBucket() async {
        let first = CLLocationCoordinate2D(latitude: 52.52044, longitude: 13.40944)
        let second = CLLocationCoordinate2D(latitude: 52.52046, longitude: 13.40946)

        await MainActor.run {
            let predictiveLoader = ServiceContainer.shared.predictiveLoader
            predictiveLoader.clearPreloadedData()
            predictiveLoader.stopPredictiveLoading()

            XCTAssertEqual(
                predictiveLoader.makeLocationKey(for: first),
                predictiveLoader.makeLocationKey(for: second)
            )
        }
    }
}