//
//  NotesListTests.swift
//  ColourNoteXCUITests
//

import XCTest

final class NotesListTests: UITestCase {

    override func setUp() {
        super.setUp()
        tapStartFresh()
    }

    func testNotesListNavigationBarVisible() {
        XCTAssertTrue(app.navigationBars["ColourNote"].exists,
                      "ColourNote navigation bar should be visible on notes list")
    }

    func testSearchFieldVisible() {
        let searchField = app.textFields["noteSearchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5),
                      "Search field should be visible on notes list")
    }

    func testAddButtonVisible() {
        XCTAssertTrue(app.navigationBars["ColourNote"].buttons["Add"].exists,
                      "Add (+) button should be visible in the navigation bar")
    }

    func testTappingAddButtonShowsNoteEditor() {
        app.navigationBars["ColourNote"].buttons["Add"].tap()
        let titleField = app.textFields["noteTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5),
                      "Note title field should appear after tapping Add")
    }
}
