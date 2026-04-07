import XCTest
@testable import BerlinTransportMap

final class ActivationMetricsServiceTests: XCTestCase {
    func testRecordSessionDeduplicatesRapidForegroundEvents() {
        let service = ActivationMetricsService(fileURL: temporaryFileURL(), loadExisting: false)
        let start = Date(timeIntervalSince1970: 1_000)

        service.recordSession(at: start)
        service.recordSession(at: start.addingTimeInterval(5 * 60))

        let summary = service.summary(referenceDate: start)
        XCTAssertEqual(summary.sessionCount, 1)
        XCTAssertEqual(summary.activeDays, 1)
        XCTAssertEqual(summary.recentSessionCount7Days, 1)
    }

    func testRecordSessionCountsSeparatedSessionsAndEngagement() {
        let service = ActivationMetricsService(fileURL: temporaryFileURL(), loadExisting: false)
        let firstDay = Date(timeIntervalSince1970: 10_000)
        let secondDay = firstDay.addingTimeInterval(24 * 60 * 60)

        service.recordSession(at: firstDay)
        service.recordFavoriteSave(at: firstDay)
        service.recordStopDetailOpen(at: firstDay)
        service.recordSession(at: secondDay)

        let summary = service.summary(referenceDate: secondDay)
        XCTAssertEqual(summary.sessionCount, 2)
        XCTAssertEqual(summary.activeDays, 2)
        XCTAssertEqual(summary.favoriteSaveCount, 1)
        XCTAssertEqual(summary.stopDetailOpenCount, 1)
        XCTAssertTrue(summary.hasRepeatUsage)
        XCTAssertEqual(summary.recentSessionCount7Days, 2)
        XCTAssertEqual(summary.recentFavoriteSaveCount7Days, 1)
        XCTAssertEqual(summary.recentStopDetailOpenCount7Days, 1)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension("json")
    }
}