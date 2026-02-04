//
//  NoteBackup.swift
//  ColourNote
//
//  Created for backup/export functionality
//  Supports Iridescence server format (v2) and legacy format (v1)
//

import Foundation

// MARK: - Import Result

struct ImportResult {
    let success: Bool
    let importedCount: Int
    let errorMessage: String?
}

// MARK: - Iridescence Format (v2) - Primary Format

/// User information for backup
struct BackupUser: Codable {
    let user_id: Int
    let username: String
    let email: String
    let created_at: Int  // Milliseconds since epoch
}

/// Summary statistics for backup
struct BackupSummary: Codable {
    let total_categories: Int
    let total_notes: Int
    let active_notes: Int
    let trashed_notes: Int
    let export_date: String  // ISO 8601 format
}

/// Category model for Iridescence backup format
struct IridescenceCategoryBackup: Codable {
    let category_id: Int
    let user_id: Int?
    let uuid: String
    let category_name: String
    let color_hex: String
    let sort_order: Int
    let is_protected: Int  // 0 or 1
    let modified_at: Int?  // Milliseconds since epoch
}

/// Note model for Iridescence backup format
struct IridescenceNoteBackup: Codable {
    let _id: Int
    let user_id: Int?
    let title: String
    let created_date: Int  // Milliseconds since epoch
    let modified_date: Int  // Milliseconds since epoch
    let note: String  // Content
    let category_id: Int?
    let active_state: Int  // 0 = active, 1 = deleted
    let deleted_date: Int?  // Milliseconds since epoch
    let content_format: String
    let uuid: String
}

/// Main container for Iridescence backup format
struct IridescenceBackupContainer: Codable {
    let user: BackupUser?
    let summary: BackupSummary
    let categories: [IridescenceCategoryBackup]
    let notes: [IridescenceNoteBackup]
}

// MARK: - Legacy Format (v1) - For Backwards Compatibility

struct LegacyNoteBackupModel: Codable {
    let id: String
    let uuid: String
    let user_id: String
    let title: String
    let content: String
    let content_format: String
    let timestamp_created: String  // ISO 8601
    let timestamp_modified: String  // ISO 8601
    let metadata: LegacyNoteMetadata
}

struct LegacyNoteMetadata: Codable {
    let tags: [String]
    let archived: Bool
    let pinned: Bool
    let category_id: Int?
    let deleted: Bool
    let deleted_date: String?  // ISO 8601
}

struct LegacyCategoryBackupModel: Codable {
    let category_id: Int
    let uuid: String
    let category_name: String
    let color_hex: String
    let sort_order: Int
}

struct LegacyNoteBackupContainer: Codable {
    let Categories: [LegacyCategoryBackupModel]
    let Notes: [LegacyNoteBackupModel]
}

// MARK: - NoteBackup Class

class NoteBackup {

    // MARK: - Export (Iridescence Format)

    /// Export notes to JSON in Iridescence format
    static func exportNotesToJSON(notes: [Note]) -> String? {
        let categories = CategoryRecords.instance.getCategories()

        // Build category backup models
        let backupCategories = categories.map { category -> IridescenceCategoryBackup in
            return IridescenceCategoryBackup(
                category_id: category.categoryId,
                user_id: nil,  // Local backup, no user_id
                uuid: category.uuid,
                category_name: category.categoryName,
                color_hex: category.colorHex,
                sort_order: category.sortOrder,
                is_protected: category.isProtected ? 1 : 0,
                modified_at: category.modifiedAt
            )
        }

        // Build note backup models
        let backupNotes = notes.map { note -> IridescenceNoteBackup in
            return IridescenceNoteBackup(
                _id: note.noteId,
                user_id: nil,  // Local backup, no user_id
                title: note.noteName,
                created_date: note.editedTime,  // Using editedTime as created_date
                modified_date: note.editedTime,
                note: note.noteText,
                category_id: note.categoryId > 0 ? note.categoryId : nil,
                active_state: note.isDeleted ? 1 : 0,
                deleted_date: note.deletedDate,
                content_format: note.contentFormat,
                uuid: note.uuid
            )
        }

        // Calculate summary statistics
        let activeNotes = notes.filter { !$0.isDeleted }.count
        let trashedNotes = notes.filter { $0.isDeleted }.count

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let exportDateString = formatter.string(from: Date())

        let summary = BackupSummary(
            total_categories: categories.count,
            total_notes: notes.count,
            active_notes: activeNotes,
            trashed_notes: trashedNotes,
            export_date: exportDateString
        )

        // Build container (user is nil for local backups)
        let container = IridescenceBackupContainer(
            user: nil,
            summary: summary,
            categories: backupCategories,
            notes: backupNotes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData = try encoder.encode(container)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding notes to JSON: \(error)")
            return nil
        }
    }

    /// Save backup string to file
    static func saveBackupToFile(jsonString: String, filename: String = "notes_backup.json") -> URL? {
        let fileManager = FileManager.default

        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not find documents directory")
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Backup saved to: \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving backup file: \(error)")
            return nil
        }
    }

    /// Export all notes to a backup file
    static func exportAllNotes(skipProtected: Bool = false) -> URL? {
        // Get ALL notes including deleted ones
        var notes = NoteRecords.instance.getAllNotes()

        if skipProtected {
            // Filter out notes in protected categories
            notes = notes.filter { note in
                if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
                    return !category.isProtected
                }
                return true // Include notes without categories
            }
        }

        guard let jsonString = exportNotesToJSON(notes: notes) else {
            print("Failed to convert notes to JSON")
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "colornote_backup_\(timestamp).json"

        return saveBackupToFile(jsonString: jsonString, filename: filename)
    }

    // MARK: - Import (Supports Both Formats)

    /// Import notes from JSON data (auto-detects format)
    static func importNotesFromJSON(jsonData: Data) -> ImportResult {
        // Try to detect format by parsing as generic JSON first
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return ImportResult(success: false, importedCount: 0, errorMessage: "Invalid JSON format")
        }

        // Detect format: Iridescence format uses lowercase "categories" and "notes"
        // Legacy format uses uppercase "Categories" and "Notes"
        if jsonObject["categories"] != nil || jsonObject["notes"] != nil {
            return importIridescenceFormat(jsonData: jsonData)
        } else if jsonObject["Categories"] != nil || jsonObject["Notes"] != nil {
            return importLegacyFormat(jsonData: jsonData)
        } else {
            return ImportResult(success: false, importedCount: 0, errorMessage: "Unrecognized backup format")
        }
    }

    // MARK: - Import Iridescence Format (v2)

    private static func importIridescenceFormat(jsonData: Data) -> ImportResult {
        let decoder = JSONDecoder()

        do {
            let container = try decoder.decode(IridescenceBackupContainer.self, from: jsonData)
            let backupCategories = container.categories
            let backupNotes = container.notes

            if backupNotes.isEmpty {
                return ImportResult(success: false, importedCount: 0, errorMessage: "No notes found in backup file")
            }

            // Import categories first
            for backupCategory in backupCategories {
                let category = Category()
                category.categoryId = backupCategory.category_id
                category.uuid = backupCategory.uuid
                category.categoryName = backupCategory.category_name
                category.colorHex = backupCategory.color_hex
                category.sortOrder = backupCategory.sort_order
                category.isProtected = backupCategory.is_protected != 0
                category.modifiedAt = backupCategory.modified_at

                // Check if category already exists
                if CategoryRecords.instance.getCategory(searchCategoryId: category.categoryId) == nil {
                    _ = CategoryRecords.instance.insertCategory(category: category)
                } else {
                    _ = CategoryRecords.instance.updateCategory(category: category)
                }
            }

            var importedCount = 0

            for backupNote in backupNotes {
                // Parse deleted date
                let deletedTimestamp: Int? = backupNote.deleted_date

                // Create Note object
                let note = Note(
                    noteId: backupNote._id,
                    uuid: backupNote.uuid,
                    noteName: backupNote.title,
                    editedTime: backupNote.modified_date,
                    noteText: backupNote.note,
                    categoryId: backupNote.category_id ?? 0,
                    isDeleted: backupNote.active_state != 0,
                    deletedDate: deletedTimestamp,
                    contentFormat: backupNote.content_format
                )

                // Check if note already exists
                if NoteRecords.instance.noteExists(searchId: note.noteId) {
                    // Update existing note
                    _ = NoteRecords.instance.updateNoteText(changedNoteId: note.noteId, newText: note.noteText)
                    _ = NoteRecords.instance.updateNoteTitle(changedNoteId: note.noteId, newTitle: note.noteName)
                    _ = NoteRecords.instance.updateNoteCategory(changedNoteId: note.noteId, newCategoryId: note.categoryId)
                    _ = NoteRecords.instance.setNoteDeletionStatus(noteId: note.noteId, isDeleted: note.isDeleted, deletedDate: deletedTimestamp)
                    // Update UUID if different
                    if let existingNote = NoteRecords.instance.getNote(searchNoteId: note.noteId), existingNote.uuid != note.uuid {
                        _ = NoteRecords.instance.updateNoteUUID(noteId: note.noteId, uuid: note.uuid)
                    }
                } else {
                    // Add new note
                    _ = NoteRecords.instance.insertNote(note: note)
                    // Set deletion status if needed
                    if note.isDeleted {
                        _ = NoteRecords.instance.setNoteDeletionStatus(noteId: note.noteId, isDeleted: true, deletedDate: deletedTimestamp)
                    }
                }

                importedCount += 1
            }

            print("NoteBackup: Imported \(importedCount) notes using Iridescence format")
            return ImportResult(success: true, importedCount: importedCount, errorMessage: nil)

        } catch {
            print("Error decoding Iridescence format JSON: \(error)")
            return ImportResult(success: false, importedCount: 0, errorMessage: "Invalid Iridescence backup format: \(error.localizedDescription)")
        }
    }

    // MARK: - Import Legacy Format (v1)

    private static func importLegacyFormat(jsonData: Data) -> ImportResult {
        let decoder = JSONDecoder()

        do {
            let container = try decoder.decode(LegacyNoteBackupContainer.self, from: jsonData)
            let backupCategories = container.Categories
            let backupNotes = container.Notes

            if backupNotes.isEmpty {
                return ImportResult(success: false, importedCount: 0, errorMessage: "No notes found in backup file")
            }

            // Import categories first
            for backupCategory in backupCategories {
                let category = Category()
                category.categoryId = backupCategory.category_id
                category.uuid = backupCategory.uuid
                category.categoryName = backupCategory.category_name
                category.colorHex = backupCategory.color_hex
                category.sortOrder = backupCategory.sort_order

                // Check if category already exists
                if CategoryRecords.instance.getCategory(searchCategoryId: category.categoryId) == nil {
                    _ = CategoryRecords.instance.insertCategory(category: category)
                } else {
                    _ = CategoryRecords.instance.updateCategory(category: category)
                }
            }

            var importedCount = 0
            let formatter = ISO8601DateFormatter()

            for backupNote in backupNotes {
                // Parse timestamp (ISO 8601 string to milliseconds)
                let modifiedDate = formatter.date(from: backupNote.timestamp_modified) ?? Date()
                let modifiedTimestamp = Int(modifiedDate.timeIntervalSince1970 * 1000)

                // Parse deleted date if present
                var deletedTimestamp: Int? = nil
                if let deletedDateString = backupNote.metadata.deleted_date {
                    if let deletedDate = formatter.date(from: deletedDateString) {
                        deletedTimestamp = Int(deletedDate.timeIntervalSince1970 * 1000)
                    }
                }

                // Create Note object
                let note = Note(
                    noteId: Int(backupNote.id) ?? 0,
                    uuid: backupNote.uuid,
                    noteName: backupNote.title,
                    editedTime: modifiedTimestamp,
                    noteText: backupNote.content,
                    categoryId: backupNote.metadata.category_id ?? 0,
                    isDeleted: backupNote.metadata.deleted,
                    deletedDate: deletedTimestamp,
                    contentFormat: backupNote.content_format
                )

                // Check if note already exists
                if NoteRecords.instance.noteExists(searchId: note.noteId) {
                    // Update existing note
                    _ = NoteRecords.instance.updateNoteText(changedNoteId: note.noteId, newText: note.noteText)
                    _ = NoteRecords.instance.updateNoteCategory(changedNoteId: note.noteId, newCategoryId: note.categoryId)
                    _ = NoteRecords.instance.setNoteDeletionStatus(noteId: note.noteId, isDeleted: note.isDeleted, deletedDate: deletedTimestamp)
                } else {
                    // Add new note
                    _ = NoteRecords.instance.insertNote(note: note)
                    // Set deletion status if needed
                    if note.isDeleted {
                        _ = NoteRecords.instance.setNoteDeletionStatus(noteId: note.noteId, isDeleted: true, deletedDate: deletedTimestamp)
                    }
                }

                importedCount += 1
            }

            print("NoteBackup: Imported \(importedCount) notes using legacy format")
            return ImportResult(success: true, importedCount: importedCount, errorMessage: nil)

        } catch {
            print("Error decoding legacy format JSON: \(error)")
            return ImportResult(success: false, importedCount: 0, errorMessage: "Invalid legacy backup format: \(error.localizedDescription)")
        }
    }
}
