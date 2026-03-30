import XCTest

@MainActor
final class MapInteractionPerformanceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-defaults"]
    }

    func testMapZoomAndPanRemainComfortable() throws {
        app.launch()

        let map = primaryMapElement()
        XCTAssertTrue(map.waitForExistence(timeout: 20), "Expected the transport map to appear")

        Thread.sleep(forTimeInterval: 3)

        let durations = (0..<3).map { _ in
            measureInteractionCycle(on: map)
        }

        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let worstDuration = durations.max() ?? 0
        let summary = durations
            .map { "\($0.formatted(.number.precision(.fractionLength(2))))s" }
            .joined(separator: ", ")

        let attachment = XCTAttachment(
            string: "Map interaction cycle durations: \(summary)\nAverage: \(averageDuration.formatted(.number.precision(.fractionLength(2))))s\nWorst: \(worstDuration.formatted(.number.precision(.fractionLength(2))))s"
        )
        attachment.name = "Map interaction performance"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertLessThan(averageDuration, 10.8, "Average zoom/pan cycle took too long: \(summary)")
        XCTAssertLessThan(worstDuration, 11.5, "Worst zoom/pan cycle took too long: \(summary)")
    }

    private func primaryMapElement() -> XCUIElement {
        let identifiedMap = app.otherElements["transport_map_canvas"]
        if identifiedMap.exists {
            return identifiedMap
        }

        let map = app.maps.firstMatch
        if map.exists {
            return map
        }

        return app.otherElements.firstMatch
    }

    private func measureInteractionCycle(on map: XCUIElement) -> TimeInterval {
        let start = Date()

        let center = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let upperLeft = map.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.30))
        let lowerRight = map.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.70))
        let rightEdge = map.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.5))
        let leftEdge = map.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.5))

        center.press(forDuration: 0.05, thenDragTo: upperLeft)
        center.press(forDuration: 0.05, thenDragTo: lowerRight)
        map.pinch(withScale: 1.8, velocity: 1.4)
        map.pinch(withScale: 0.65, velocity: -1.2)
        rightEdge.press(forDuration: 0.05, thenDragTo: leftEdge)
        Thread.sleep(forTimeInterval: 0.9)

        return Date().timeIntervalSince(start)
    }
}
