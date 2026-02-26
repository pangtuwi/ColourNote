//
//  NoteDetailTests.swift
//  ColourNoteXCUITests
//

import XCTest

final class NoteDetailTests: UITestCase {

    override func setUp() {
        super.setUp()
        tapStartFresh()
        app.navigationBars["ColourNote"].buttons["Add"].tap()
        XCTAssertTrue(app.textFields["noteTitleField"].waitForExistence(timeout: 5),
                      "Note editor should open after tapping Add")
    }

    func testNoteTitleCanBeEdited() {
        let titleField = app.textFields["noteTitleField"]
        titleField.tap()
        titleField.typeText("Hello UI Test")
        XCTAssertEqual(titleField.value as? String, "Hello UI Test")
    }

    func testNoteContentCanBeEdited() {
        let content = "UI test note content"
        let noteTextView = app.textViews["noteTextView"]
        XCTAssertTrue(noteTextView.waitForExistence(timeout: 5))
        noteTextView.tap()
        noteTextView.typeText(content)
        XCTAssertTrue((noteTextView.value as? String ?? "").contains(content))
    }

    func testBackButtonReturnsToList() {
        // The circular back/list button is the first button in the view (not in a nav bar)
        let listBtn = app.buttons["listButton"]
        if listBtn.waitForExistence(timeout: 3) {
            listBtn.tap()
        } else {
            // Fall back to first non-nav-bar button if identifier isn't set
            app.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.navigationBars["ColourNote"].waitForExistence(timeout: 5),
                      "Should return to notes list after tapping back button")
    }

    func testNewNoteTitleAppearsInList() {
        let noteTitle = "My Note"
        let titleField = app.textFields["noteTitleField"]
        titleField.tap()
        titleField.typeText(noteTitle)

        // Return to list
        let listBtn = app.buttons["listButton"]
        if listBtn.waitForExistence(timeout: 3) {
            listBtn.tap()
        } else {
            app.buttons.element(boundBy: 0).tap()
        }

        XCTAssertTrue(app.navigationBars["ColourNote"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[noteTitle].waitForExistence(timeout: 5),
                      "Note with title '\(noteTitle)' should appear in the notes list")
    }
}
