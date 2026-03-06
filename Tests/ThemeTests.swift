import XCTest
@testable import BerlinTransportMap

final class ThemeTests: XCTestCase {

    func testVehicleColorForTram() {
        let color = TransportTheme.Vehicle.color(for: .tram)
        XCTAssertEqual(color, Color(hex: "#D8232A"))
    }

    func testVehicleColorForSubway() {
        let color = TransportTheme.Vehicle.color(for: .subway)
        XCTAssertEqual(color, Color(hex: "#0066CC"))
    }

    func testVehicleColorForSuburbanTrain() {
        let color = TransportTheme.Vehicle.color(for: .suburbanTrain)
        XCTAssertEqual(color, Color(hex: "#008C3C"))
    }

    func testVehicleColorForBus() {
        let color = TransportTheme.Vehicle.color(for: .bus)
        XCTAssertEqual(color, Color(hex: "#993399"))
    }

    func testVehicleColorForFerry() {
        let color = TransportTheme.Vehicle.color(for: .ferry)
        XCTAssertEqual(color, Color(hex: "#0099CC"))
    }

    func testVehicleColorForRegionalTrain() {
        let color = TransportTheme.Vehicle.color(for: .regionalTrain)
        XCTAssertEqual(color, Color(hex: "#EC192E"))
    }

    func testColorFromHexWith3Digits() {
        let color = Color(hex: "FFF")
        XCTAssertEqual(color, Color(hex: "#FFFFFF"))
    }

    func testColorFromHexWith6Digits() {
        let color = Color(hex: "FF0000")
        XCTAssertEqual(color, Color(hex: "#FF0000"))
    }

    func testColorFromHexWithInvalidInput() {
        let color = Color(hex: "INVALID")
        XCTAssertEqual(color, Color(hex: "#808080"))
    }

    func testHaltestelleYellowColor() {
        let color = TransportTheme.Stop.haltestelleYellow
        XCTAssertEqual(color, Color(hex: "#FFD800"))
    }

    func testHaltestelleGreenColor() {
        let color = TransportTheme.Stop.haltestelleGreen
        XCTAssertEqual(color, Color(hex: "#006F3C"))
    }
}
