//
//  LaunchTests.swift
//  ColourNoteXCUITests
//

import XCTest

final class LaunchTests: UITestCase {

    func testFreshInstallShowsLoginScreen() {
        let btn = app.buttons["startFreshButton"]
        XCTAssertTrue(btn.waitForExistence(timeout: 5),
                      "Login screen should show Start Fresh button on a fresh install")
    }

    func testStartFreshNavigatesToNotesList() {
        tapStartFresh()
        XCTAssertTrue(app.navigationBars["ColourNote"].exists,
                      "Notes list navigation bar should be visible after tapping Start Fresh")
    }
}
