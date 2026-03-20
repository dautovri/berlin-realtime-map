import XCTest
import SwiftUI
import UIKit
@testable import BerlinTransportMap

final class ThemeTests: XCTestCase {

    func testColorFromHexWith3DigitsExpandsCorrectly() {
        assertColor(Color(hex: "FFF"), matches: "#FFFFFF")
    }

    func testColorFromHexWith6DigitsPreservesComponents() {
        assertColor(Color(hex: "FF0000"), matches: "#FF0000")
    }

    func testColorFromHexWithInvalidInputFallsBackToNeutralGray() {
        assertColor(Color(hex: "INVALID"), matches: "#808080")
    }

    func testStopThemeColorsUseExpectedPalette() {
        assertColor(TransportTheme.Stop.haltestelleYellow, matches: "#FFD800")
        assertColor(TransportTheme.Stop.haltestelleGreen, matches: "#006F3C")
    }

    private func assertColor(
        _ color: Color,
        matches hex: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = UIColor(color)
        let expected = UIColor(Color(hex: hex))

        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0

        XCTAssertTrue(actual.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha), file: file, line: line)
        XCTAssertTrue(expected.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha), file: file, line: line)

        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: 0.001, file: file, line: line)
    }
}
