//
//  SharingUITests.swift
//  ColourNoteXCUITests
//
//  UI tests for the note sharing flow: swipe action, action sheet options,
//  and sign-in guard when the user is not logged in to cloud sync.
//

import XCTest

final class SharingUITests: UITestCase {

    override func setUp() {
        super.setUp()
        tapStartFresh()

        // Create a note so there is a row to swipe on
        app.navigationBars["ColourNote"].buttons["Add"].tap()
        let titleField = app.textFields["noteTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5),
                      "Note editor should open after tapping Add")
        titleField.tap()
        titleField.typeText("Note to Share")

        let listBtn = app.buttons["listButton"]
        if listBtn.waitForExistence(timeout: 3) {
            listBtn.tap()
        } else {
            app.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.navigationBars["ColourNote"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 5),
                      "Note cell should appear in list before swipe tests run")
    }

    // Swiping left on a note cell reveals a "Share" contextual action button.
    func testSwipeRevealShareButton() {
        app.cells.firstMatch.swipeLeft()
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 3),
                      "Share swipe action should appear after swiping left on a note")
    }

    // Tapping the "Share" swipe button presents an action sheet with both share options.
    func testShareActionSheetShowsBothOptions() {
        app.cells.firstMatch.swipeLeft()
        app.buttons["Share"].tap()

        XCTAssertTrue(app.buttons["Send note contents"].waitForExistence(timeout: 3),
                      "'Send note contents' option should appear in the share action sheet")
        XCTAssertTrue(app.buttons["Share access with another user"].waitForExistence(timeout: 3),
                      "'Share access with another user' option should appear in the share action sheet")
    }

    // Tapping "Share access with another user" when not signed in shows a sign-in alert.
    func testShareAccessRequiresSignIn() {
        app.cells.firstMatch.swipeLeft()
        app.buttons["Share"].tap()
        app.buttons["Share access with another user"].tap()

        XCTAssertTrue(app.alerts["Sign in required"].waitForExistence(timeout: 3),
                      "A 'Sign in required' alert should appear when the user is not logged in to cloud sync")

        app.alerts["Sign in required"].buttons["OK"].tap()
    }
}
