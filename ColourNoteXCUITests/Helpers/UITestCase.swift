//
//  UITestCase.swift
//  ColourNoteXCUITests
//

import XCTest

class UITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["UI_TESTING_FRESH_INSTALL"]
        app.launchEnvironment["API_BASE_URL"] = "http://localhost:3002"
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    /// Tap "Start Fresh" and wait for the notes list navigation bar to appear.
    func tapStartFresh() {
        let btn = app.buttons["startFreshButton"]
        XCTAssertTrue(btn.waitForExistence(timeout: 5), "Start Fresh button not found")
        btn.tap()
        XCTAssertTrue(app.navigationBars["ColourNote"].waitForExistence(timeout: 5),
                      "Notes list nav bar did not appear after tapping Start Fresh")
    }
}
