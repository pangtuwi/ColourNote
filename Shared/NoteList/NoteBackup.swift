//
//  NoteBackup.swift
//  ColourNote
//
//  Created for backup/export functionality
//

import Foundation

struct NoteBackupModel: Codable {
    let id: String
    let user_id: String
    let title: String
    let content: String
    let content_format: String
    let timestamp_created: String
    let timestamp_modified: String
    let metadata: NoteMetadata
}

struct NoteMetadata: Codable {
    let tags: [String]
    let archived: Bool
    let pinned: Bool
    let color_index: Int
    let category_id: Int?
    let deleted: Bool
    let deleted_date: String?
}

struct CategoryBackupModel: Codable {
    let category_id: Int
    let category_name: String
    let color_hex: String
    let sort_order: Int
}

struct NoteBackupContainer: Codable {
    let Categories: [CategoryBackupModel]
    let Notes: [NoteBackupModel]
}

struct ImportResult {
    let success: Bool
    let importedCount: Int
    let errorMessage: String?
}

class NoteBackup {

    static func exportNotesToJSON(notes: [Note]) -> String? {
        // Export categories first
        let categories = CategoryRecords.instance.getCategories()
        let backupCategories = categories.map { category -> CategoryBackupModel in
            return CategoryBackupModel(
                category_id: category.categoryId,
                category_name: category.categoryName,
                color_hex: category.colorHex,
                sort_order: category.sortOrder
            )
        }

        // Export notes with category and deletion information
        let backupNotes = notes.map { note -> NoteBackupModel in
            // Convert Unix timestamp (milliseconds) to ISO 8601 format
            let createdDate = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))
            let modifiedDate = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            // Format deleted date if present
            var deletedDateString: String? = nil
            if let deletedTimestamp = note.deletedDate {
                let deletedDate = Date(timeIntervalSince1970: TimeInterval(deletedTimestamp / 1000))
                deletedDateString = formatter.string(from: deletedDate)
            }

            let metadata = NoteMetadata(
                tags: [],
                archived: false,
                pinned: false,
                color_index: note.colorIndex,
                category_id: note.categoryId > 0 ? note.categoryId : nil,
                deleted: note.isDeleted,
                deleted_date: deletedDateString
            )

            return NoteBackupModel(
                id: String(note.noteId),
                user_id: "local_user",
                title: note.noteName,
                content: note.noteText,
                content_format: "plaintext",
                timestamp_created: formatter.string(from: createdDate),
                timestamp_modified: formatter.string(from: modifiedDate),
                metadata: metadata
            )
        }

        let container = NoteBackupContainer(Categories: backupCategories, Notes: backupNotes)

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

    static func exportAllNotes() -> URL? {
        // Get ALL notes including deleted ones
        let notes = NoteRecords.instance.getAllNotes()

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

    static func importNotesFromJSON(jsonData: Data) -> ImportResult {
        let decoder = JSONDecoder()

        do {
            let container = try decoder.decode(NoteBackupContainer.self, from: jsonData)
            let backupCategories = container.Categories
            let backupNotes = container.Notes

            if backupNotes.isEmpty {
                return ImportResult(success: false, importedCount: 0, errorMessage: "No notes found in backup file")
            }

            // Import categories first
            for backupCategory in backupCategories {
                let category = Category()
                category.categoryId = backupCategory.category_id
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
                // Parse timestamp
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
                    noteName: backupNote.title,
                    editedTime: modifiedTimestamp,
                    noteText: backupNote.content,
                    colorIndex: backupNote.metadata.color_index,
                    categoryId: backupNote.metadata.category_id ?? 0,
                    isDeleted: backupNote.metadata.deleted,
                    deletedDate: deletedTimestamp
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

            return ImportResult(success: true, importedCount: importedCount, errorMessage: nil)

        } catch {
            print("Error decoding JSON: \(error)")
            return ImportResult(success: false, importedCount: 0, errorMessage: "Invalid JSON format: \(error.localizedDescription)")
        }
    }
}
