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
}

struct NoteBackupContainer: Codable {
    let Notes: [NoteBackupModel]
}

struct ImportResult {
    let success: Bool
    let importedCount: Int
    let errorMessage: String?
}

class NoteBackup {

    static func exportNotesToJSON(notes: [Note]) -> String? {
        let backupNotes = notes.map { note -> NoteBackupModel in
            // Convert Unix timestamp (milliseconds) to ISO 8601 format
            let createdDate = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))
            let modifiedDate = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            let metadata = NoteMetadata(
                tags: [],
                archived: false,
                pinned: false,
                color_index: note.colorIndex
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

        let container = NoteBackupContainer(Notes: backupNotes)

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
        let notes = NoteRecords.instance.getNotes()

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
            let backupNotes = container.Notes

            if backupNotes.isEmpty {
                return ImportResult(success: false, importedCount: 0, errorMessage: "No notes found in backup file")
            }

            var importedCount = 0
            let formatter = ISO8601DateFormatter()

            for backupNote in backupNotes {
                // Parse timestamp
                let modifiedDate = formatter.date(from: backupNote.timestamp_modified) ?? Date()
                let modifiedTimestamp = Int(modifiedDate.timeIntervalSince1970 * 1000)

                // Create Note object
                let note = Note(
                    noteId: Int(backupNote.id) ?? 0,
                    noteName: backupNote.title,
                    editedTime: modifiedTimestamp,
                    noteText: backupNote.content,
                    colorIndex: backupNote.metadata.color_index
                )

                // Check if note already exists
                if NoteRecords.instance.noteExists(searchId: note.noteId) {
                    // Update existing note
                    _ = NoteRecords.instance.updateNoteText(changedNoteId: note.noteId, newText: note.noteText)
                } else {
                    // Add new note (we need to add an insert method)
                    _ = NoteRecords.instance.insertNote(note: note)
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
