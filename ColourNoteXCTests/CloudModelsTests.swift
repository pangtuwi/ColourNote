//
//  CloudModelsTests.swift
//  ColourNoteXCTests
//
//  Tests for CloudModels Codable conformance, conversion extensions, and TimestampConverter.
//

import Testing
import Foundation
@testable import ColourNote

struct CloudModelsTests {

    // MARK: - CloudNote

    @Test func cloudNoteDecodesFromJSON() throws {
        let json = """
        {
            "_id": 42,
            "uuid": "note-uuid-abc",
            "user_id": 1,
            "title": "My Note",
            "note": "Hello world",
            "created_date": 1700000000000,
            "modified_date": 1700000001000,
            "color_index": null,
            "category_id": 3,
            "active_state": 0,
            "deleted_date": null,
            "content_format": "markdown"
        }
        """.data(using: .utf8)!

        let note = try JSONDecoder().decode(CloudNote.self, from: json)
        #expect(note.noteId == 42)
        #expect(note.uuid == "note-uuid-abc")
        #expect(note.title == "My Note")
        #expect(note.note == "Hello world")
        #expect(note.createdDate == 1_700_000_000_000)
        #expect(note.modifiedDate == 1_700_000_001_000)
        #expect(note.categoryId == 3)
        #expect(note.activeState == 0)
        #expect(note.id == "42")
    }

    @Test func cloudNoteIsDeletedWhenActiveStateIs1() {
        let note = TestFixtures.makeCloudNote(noteId: 1, uuid: "x", title: "T", note: "N",
                                              createdDate: 0, modifiedDate: 0)
        let deletedNote = CloudNote(
            noteId: 1, uuid: "x", userId: nil, title: "T", note: "N",
            createdDate: 0, modifiedDate: 0, colorIndex: nil, categoryId: nil,
            activeState: 1, deletedDate: nil, contentFormat: nil
        )
        #expect(note.isDeleted == false)
        #expect(deletedNote.isDeleted == true)
    }

    @Test func cloudNoteContentPropertyReturnsEmptyWhenNoteIsNil() {
        let note = CloudNote(
            noteId: 1, uuid: nil, userId: nil, title: "T", note: nil,
            createdDate: 0, modifiedDate: nil, colorIndex: nil, categoryId: nil,
            activeState: 0, deletedDate: nil, contentFormat: nil
        )
        #expect(note.content == "")
    }

    @Test func cloudNoteToLocalNoteConversion() {
        let cloud = TestFixtures.makeCloudNote(
            noteId: 5, uuid: "n-uuid", title: "Work Note", note: "Details", modifiedDate: 1_700_000_002_000
        )
        let local = cloud.toLocalNote(localCategoryId: 2)
        #expect(local.noteId == 0)
        #expect(local.uuid == "n-uuid")
        #expect(local.noteName == "Work Note")
        #expect(local.noteText == "Details")
        #expect(local.categoryId == 2)
        #expect(local.editedTime == 1_700_000_002_000)
        #expect(local.isDeleted == false)
        #expect(local.contentFormat == "markdown")
    }

    // MARK: - CloudCategory

    @Test func cloudCategoryDecodesFromJSON() throws {
        let json = """
        {
            "category_id": 10,
            "uuid": "cat-uuid-xyz",
            "user_id": 1,
            "category_name": "Work",
            "color_hex": "#87CEEB",
            "sort_order": 2,
            "is_protected": 0,
            "modified_at": 1700000000000
        }
        """.data(using: .utf8)!

        let cat = try JSONDecoder().decode(CloudCategory.self, from: json)
        #expect(cat.categoryId == 10)
        #expect(cat.uuid == "cat-uuid-xyz")
        #expect(cat.categoryName == "Work")
        #expect(cat.colorHex == "#87CEEB")
        #expect(cat.sortOrder == 2)
        #expect(cat.isProtected == 0)
        #expect(cat.id == "10")
    }

    @Test func cloudCategoryToLocalCategoryConversion() {
        let cloud = TestFixtures.makeCloudCategory(
            categoryId: 10, uuid: "c-uuid", categoryName: "Personal", colorHex: "#FFD700"
        )
        let local = cloud.toLocalCategory()
        #expect(local.categoryId == 0)
        #expect(local.uuid == "c-uuid")
        #expect(local.categoryName == "Personal")
        #expect(local.colorHex == "#FFD700")
        #expect(local.isProtected == false)
    }

    // MARK: - Request Builders

    @Test func createNoteRequestBuilderMapsFields() {
        let note = TestFixtures.makeNote(noteId: 3, uuid: "req-uuid", noteName: "Title", noteText: "Body")
        let req = CreateNoteRequest.from(localNote: note, cloudCategoryId: 7)
        #expect(req.uuid == "req-uuid")
        #expect(req.title == "Title")
        #expect(req.note == "Body")
        #expect(req.categoryId == 7)
        #expect(req.activeState == 0)
        #expect(req.contentFormat == "markdown")
    }

    @Test func createCategoryRequestBuilderMapsFields() {
        let cat = TestFixtures.makeCategory(categoryId: 2, categoryName: "Ideas", colorHex: "#98FB98", sortOrder: 3)
        let req = CreateCategoryRequest.from(localCategory: cat)
        #expect(req.name == "Ideas")
        #expect(req.colorHex == "#98FB98")
        #expect(req.sortOrder == 3)
        #expect(req.isProtected == 0)
    }

    // MARK: - TimestampConverter

    @Test func timestampConverterRoundTrip() {
        let ms = 1_700_000_000_000
        let isoString = TimestampConverter.localToCloud(ms)
        let converted = TimestampConverter.cloudToLocal(isoString)
        #expect(abs(converted - ms) < 1000)
    }

    @Test func timestampConverterHandlesNilInputs() {
        let nilStr: Int? = nil
        #expect(TimestampConverter.localToCloud(nilStr) == nil)

        let nilIso: String? = nil
        #expect(TimestampConverter.cloudToLocal(nilIso) == nil)
    }

    // MARK: - Sharing Models

    @Test func shareNoteRequestEncodesRecipientEmail() throws {
        let request = ShareNoteRequest(recipientEmail: "bob@example.com")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(json?["recipientEmail"] == "bob@example.com")
    }

    @Test func shareNoteResponseDecodesShareUrlAndToken() throws {
        let json = """
        {
            "shareUrl": "https://irids.co.uk/share/abc123",
            "token": "abc123"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ShareNoteResponse.self, from: json)
        #expect(response.shareUrl == "https://irids.co.uk/share/abc123")
        #expect(response.token == "abc123")
    }
}
