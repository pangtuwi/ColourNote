//
//  CloudModels.swift
//  ColourNote
//
//  Data models for cloud sync API communication
//

import Foundation

// MARK: - Authentication Models

struct AuthRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let userId: String?
    let email: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case token
        case userId = "user_id"
        case email
        case message
    }
}

struct ErrorResponse: Codable {
    let error: String?
    let message: String?
}

// Generic success response (for updates that return message only)
struct SuccessMessageResponse: Codable {
    let message: String?
}

// MARK: - Cloud Note Model

struct CloudNote: Codable {
    let noteId: Int  // Server uses _id
    let uuid: String?  // UUID for cross-device identification
    let userId: Int?
    let title: String
    let note: String  // Server uses "note" for content
    let createdDate: Int  // Milliseconds since epoch
    let modifiedDate: Int?  // Milliseconds since epoch
    let colorIndex: Int?
    let categoryId: Int?  // Server uses integer category_id
    let activeState: Int?  // 0 = active, 1 = deleted
    let deletedDate: Int?  // Milliseconds since epoch
    let contentFormat: String?

    enum CodingKeys: String, CodingKey {
        case noteId = "_id"
        case uuid
        case userId = "user_id"
        case title
        case note
        case createdDate = "created_date"
        case modifiedDate = "modified_date"
        case colorIndex = "color_index"
        case categoryId = "category_id"
        case activeState = "active_state"
        case deletedDate = "deleted_date"
        case contentFormat = "content_format"
    }

    // Convenience property to get string ID for mapping
    var id: String {
        return String(noteId)
    }

    // Convenience property for content
    var content: String {
        return note
    }

    // Convenience property for isDeleted
    var isDeleted: Bool {
        return (activeState ?? 0) != 0
    }
}

// MARK: - Cloud Category Model

struct CloudCategory: Codable {
    let categoryId: Int
    let uuid: String?  // UUID for cross-device identification
    let userId: Int?
    let categoryName: String
    let colorHex: String?
    let sortOrder: Int?
    let isProtected: Int?

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case uuid
        case userId = "user_id"
        case categoryName = "category_name"
        case colorHex = "color_hex"
        case sortOrder = "sort_order"
        case isProtected = "is_protected"
    }

    // Convenience property to get string ID for mapping
    var id: String {
        return String(categoryId)
    }
}

// MARK: - Sync Response Models

struct SyncResponse: Codable {
    let success: Bool
    let message: String?
    let syncedAt: String?  // ISO 8601 timestamp

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case syncedAt = "synced_at"
    }
}

// Note: Server returns arrays directly, not wrapped
// Use [CloudNote] and [CloudCategory] directly instead of wrapper types

// For backwards compatibility, keep these as typealiases
typealias NotesListResponse = [CloudNote]
typealias CategoriesListResponse = [CloudCategory]

// Server returns objects directly, not wrapped
typealias NoteResponse = CloudNote
typealias CategoryResponse = CloudCategory

// MARK: - Create/Update Request Models

struct CreateNoteRequest: Codable {
    let uuid: String  // UUID for cross-device identification
    let title: String
    let note: String  // Server uses "note" for content
    let createdDate: Int  // Milliseconds since epoch
    let modifiedDate: Int?  // Milliseconds since epoch
    let categoryId: Int?  // Server uses integer category_id
    let activeState: Int?  // 0 = active, 1 = deleted
    let deletedDate: Int?  // Milliseconds since epoch
    let contentFormat: String?

    enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case note
        case createdDate = "created_date"
        case modifiedDate = "modified_date"
        case categoryId = "category_id"
        case activeState = "active_state"
        case deletedDate = "deleted_date"
        case contentFormat = "content_format"
    }
}

struct CreateCategoryRequest: Codable {
    let uuid: String  // UUID for cross-device identification
    let name: String  // Server might expect 'name' for input
    let colorHex: String?
    let sortOrder: Int?
    let isProtected: Int?

    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case colorHex = "color_hex"
        case sortOrder = "sort_order"
        case isProtected = "is_protected"
    }
}

// MARK: - Timestamp Conversion Utilities

struct TimestampConverter {

    /// ISO 8601 date formatter
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Fallback ISO 8601 formatter without fractional seconds
    static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Convert milliseconds since epoch (local) to ISO 8601 string (cloud)
    static func localToCloud(_ milliseconds: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(milliseconds) / 1000.0)
        return iso8601Formatter.string(from: date)
    }

    /// Convert optional milliseconds since epoch to optional ISO 8601 string
    static func localToCloud(_ milliseconds: Int?) -> String? {
        guard let ms = milliseconds else { return nil }
        return localToCloud(ms)
    }

    /// Convert ISO 8601 string (cloud) to milliseconds since epoch (local)
    static func cloudToLocal(_ isoString: String) -> Int {
        // Try with fractional seconds first
        if let date = iso8601Formatter.date(from: isoString) {
            return Int(date.timeIntervalSince1970 * 1000)
        }
        // Fallback to without fractional seconds
        if let date = iso8601FormatterNoFraction.date(from: isoString) {
            return Int(date.timeIntervalSince1970 * 1000)
        }
        // Return current time as fallback
        print("TimestampConverter: Failed to parse ISO 8601 string: \(isoString)")
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    /// Convert optional ISO 8601 string to optional milliseconds
    static func cloudToLocal(_ isoString: String?) -> Int? {
        guard let str = isoString else { return nil }
        return cloudToLocal(str)
    }
}

// MARK: - Model Conversion Extensions

extension CloudNote {

    /// Create a CloudNote from a local Note and optional cloud category ID
    static func from(localNote: Note, cloudCategoryId: Int?) -> CloudNote {
        return CloudNote(
            noteId: 0, // Will be assigned by server
            uuid: localNote.uuid,
            userId: nil,
            title: localNote.noteName,
            note: localNote.noteText,
            createdDate: localNote.editedTime,
            modifiedDate: localNote.editedTime,
            colorIndex: nil,  // No longer used - color comes from category
            categoryId: cloudCategoryId,
            activeState: localNote.isDeleted ? 1 : 0,
            deletedDate: localNote.deletedDate,
            contentFormat: localNote.contentFormat
        )
    }

    /// Convert to a local Note (without noteId - must be set separately)
    func toLocalNote(localCategoryId: Int) -> Note {
        return Note(
            noteId: 0, // Must be set by caller
            uuid: uuid,
            noteName: title,
            editedTime: modifiedDate ?? createdDate,
            noteText: note,
            categoryId: localCategoryId,
            isDeleted: isDeleted,
            deletedDate: deletedDate,
            contentFormat: contentFormat ?? "markdown"
        )
    }
}

extension CloudCategory {

    /// Create a CloudCategory from a local Category
    static func from(localCategory: Category) -> CloudCategory {
        return CloudCategory(
            categoryId: 0, // Will be assigned by server
            uuid: localCategory.uuid,
            userId: nil,
            categoryName: localCategory.categoryName,
            colorHex: localCategory.colorHex,
            sortOrder: localCategory.sortOrder,
            isProtected: localCategory.isProtected ? 1 : 0
        )
    }

    /// Convert to a local Category (without categoryId - must be set separately)
    func toLocalCategory() -> Category {
        return Category(
            categoryId: 0, // Must be set by caller
            uuid: uuid,
            categoryName: categoryName,
            colorHex: colorHex ?? "#FFFFFF",
            sortOrder: sortOrder ?? 0,
            isProtected: (isProtected ?? 0) != 0
        )
    }
}

// MARK: - Create Request Builders

extension CreateNoteRequest {

    /// Create a request from a local Note
    static func from(localNote: Note, cloudCategoryId: Int?) -> CreateNoteRequest {
        return CreateNoteRequest(
            uuid: localNote.uuid,
            title: localNote.noteName,
            note: localNote.noteText,
            createdDate: localNote.editedTime,
            modifiedDate: localNote.editedTime,
            categoryId: cloudCategoryId,
            activeState: localNote.isDeleted ? 1 : 0,
            deletedDate: localNote.deletedDate,
            contentFormat: localNote.contentFormat
        )
    }
}

extension CreateCategoryRequest {

    /// Create a request from a local Category
    static func from(localCategory: Category) -> CreateCategoryRequest {
        return CreateCategoryRequest(
            uuid: localCategory.uuid,
            name: localCategory.categoryName,
            colorHex: localCategory.colorHex,
            sortOrder: localCategory.sortOrder,
            isProtected: localCategory.isProtected ? 1 : 0
        )
    }
}
