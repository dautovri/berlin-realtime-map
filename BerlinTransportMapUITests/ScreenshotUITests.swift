//
//  ScreenshotUITests.swift
//  BerlinTransportMapUITests
//
//  Automated screenshot capture for App Store listings.
//  Add this file to the BerlinTransportMapUITests UI Testing Bundle target.
//

import XCTest

@MainActor
final class ScreenshotUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-defaults"]
        setupSnapshot(app)
    }

    func testGenerateScreenshots() throws {
        app.launch()

        // Screenshot 1: Live transit map with Berlin S/U-Bahn overlays
        // The app opens directly to the full-screen map
        sleep(4) // Allow map tiles and transit stops to load
        snapshot("01_TransitMap")

        // Screenshot 2: Stop annotation tapped — shows arrival times popup
        // Tap the first visible stop annotation pin
        let firstPin = app.otherElements.matching(identifier: "stop_annotation").firstMatch
        if firstPin.waitForExistence(timeout: 5) {
            firstPin.tap()
            sleep(2)
            snapshot("02_StopDetail")
            // Dismiss by tapping map
            app.maps.firstMatch.tap()
        }

        // Screenshot 3: Favorites list
        let favoritesButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'favorites' OR label CONTAINS[c] 'favorit'")
        ).firstMatch
        if favoritesButton.waitForExistence(timeout: 3) {
            favoritesButton.tap()
            sleep(1)
            snapshot("03_Favorites")
            // Go back to map
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.waitForExistence(timeout: 2) { backButton.tap() }
        }

        // Screenshot 4: Settings / filter panel
        let settingsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'filter'")
        ).firstMatch
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            sleep(1)
            snapshot("04_Settings")
        }
    }
}
