//
//  TestFixtures.swift
//  ColourNoteXCTests
//
//  Factory methods for building pre-configured test instances.
//

import Foundation
@testable import ColourNote

enum TestFixtures {

    // MARK: - Local Models

    static func makeNote(
        noteId: Int = 1,
        uuid: String = "test-note-uuid-1234",
        noteName: String = "Test Note",
        noteText: String = "Test content",
        categoryId: Int = 1,
        isDeleted: Bool = false
    ) -> Note {
        return Note(
            noteId: noteId,
            uuid: uuid,
            noteName: noteName,
            editedTime: 1_700_000_000_000,
            noteText: noteText,
            categoryId: categoryId,
            isDeleted: isDeleted,
            deletedDate: nil,
            contentFormat: "markdown"
        )
    }

    static func makeCategory(
        categoryId: Int = 1,
        categoryName: String = "Test Category",
        colorHex: String = "#FFD700",
        sortOrder: Int = 1,
        isProtected: Bool = false
    ) -> ColourNote.Category {
        return ColourNote.Category(
            categoryId: categoryId,
            uuid: "test-category-uuid-5678",
            categoryName: categoryName,
            colorHex: colorHex,
            sortOrder: sortOrder,
            isProtected: isProtected,
            modifiedAt: 1_700_000_000_000
        )
    }

    // MARK: - Cloud Models

    static func makeCloudNote(
        noteId: Int = 42,
        uuid: String = "cloud-note-uuid-abcd",
        title: String = "Cloud Note",
        note: String = "Cloud content",
        createdDate: Int = 1_700_000_000_000,
        modifiedDate: Int = 1_700_000_000_000
    ) -> CloudNote {
        return CloudNote(
            noteId: noteId,
            uuid: uuid,
            userId: 1,
            title: title,
            note: note,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            colorIndex: nil,
            categoryId: nil,
            activeState: 0,
            deletedDate: nil,
            contentFormat: "markdown"
        )
    }

    static func makeCloudCategory(
        categoryId: Int = 10,
        uuid: String = "cloud-cat-uuid-efgh",
        categoryName: String = "Cloud Category",
        colorHex: String = "#87CEEB"
    ) -> CloudCategory {
        return CloudCategory(
            categoryId: categoryId,
            uuid: uuid,
            userId: 1,
            categoryName: categoryName,
            colorHex: colorHex,
            sortOrder: 1,
            isProtected: 0,
            modifiedAt: 1_700_000_000_000
        )
    }

    static func makeAuthResponse(token: String = "eyJtest.token") -> AuthResponse {
        return AuthResponse(token: token, userId: "user-1", email: "test@example.com", message: nil)
    }

    // MARK: - Helpers

    static func encode<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        return (try? encoder.encode(value)) ?? Data()
    }

    static func httpResponse(
        status: Int,
        url: URL = URL(string: "http://localhost:3002/test")!,
        headers: [String: String] = [:]
    ) -> HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers)!
    }
}
