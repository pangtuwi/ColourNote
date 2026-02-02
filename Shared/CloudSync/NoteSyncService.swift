//
//  NoteSyncService.swift
//  ColourNote
//
//  Handles synchronization of notes with the cloud
//

import Foundation

// MARK: - Note Sync Error
enum NoteSyncError: Error, LocalizedError {
    case uploadFailed(String)
    case downloadFailed(String)
    case mappingFailed
    case categoryNotSynced
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Failed to upload note: \(message)"
        case .downloadFailed(let message):
            return "Failed to download notes: \(message)"
        case .mappingFailed:
            return "Failed to create note mapping"
        case .categoryNotSynced:
            return "Note's category has not been synced yet"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Note Sync Service
class NoteSyncService {

    // MARK: - Singleton
    static let shared = NoteSyncService()

    // MARK: - Properties
    private let networkManager = NetworkManager.shared
    private let syncMapping = SyncMapping.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - Upload Methods

    /// Upload all local notes to the cloud
    func uploadAllNotes(completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        // Get all notes including deleted ones
        let notes = NoteRecords.instance.getAllNotes()
        var uploadedCount = 0
        var lastError: NoteSyncError?

        let group = DispatchGroup()

        for note in notes {
            group.enter()

            // Check if note already has a cloud mapping
            if let cloudId = syncMapping.getCloudId(localId: note.noteId, entityType: .note) {
                // Update existing cloud note
                updateCloudNote(localNote: note, cloudId: cloudId) { result in
                    switch result {
                    case .success:
                        uploadedCount += 1
                    case .failure(let error):
                        lastError = error
                    }
                    group.leave()
                }
            } else {
                // Create new cloud note
                createCloudNote(localNote: note) { result in
                    switch result {
                    case .success:
                        uploadedCount += 1
                    case .failure(let error):
                        lastError = error
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = lastError, uploadedCount == 0 {
                completion(.failure(error))
            } else {
                print("NoteSyncService: Uploaded \(uploadedCount) notes")
                completion(.success(uploadedCount))
            }
        }
    }

    /// Upload a single note to the cloud
    func uploadNote(_ note: Note, completion: @escaping (Result<String, NoteSyncError>) -> Void) {
        if let cloudId = syncMapping.getCloudId(localId: note.noteId, entityType: .note) {
            updateCloudNote(localNote: note, cloudId: cloudId, completion: completion)
        } else {
            createCloudNote(localNote: note, completion: completion)
        }
    }

    private func createCloudNote(localNote: Note, completion: @escaping (Result<String, NoteSyncError>) -> Void) {
        // Skip notes with empty title AND empty content
        if localNote.noteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           localNote.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("NoteSyncService: Skipping empty note \(localNote.noteId)")
            completion(.success("skipped"))
            return
        }

        print("NoteSyncService: Creating cloud note - title: '\(localNote.noteName)', content length: \(localNote.noteText.count)")

        // Get the cloud category ID if the note has a category
        // Server uses integer category IDs, so we can pass the local ID directly
        // or map to cloud category ID if needed
        var cloudCategoryId: Int? = nil
        if localNote.categoryId > 0 {
            // Try to get mapped cloud category ID, or use local ID
            if let cloudIdStr = syncMapping.getCloudId(localId: localNote.categoryId, entityType: .category),
               let cloudId = Int(cloudIdStr) {
                cloudCategoryId = cloudId
            } else {
                cloudCategoryId = localNote.categoryId
            }
        }

        let request = CreateNoteRequest.from(localNote: localNote, cloudCategoryId: cloudCategoryId)

        networkManager.post(
            endpoint: APIConfig.Endpoints.notes,
            body: request,
            requiresAuth: true
        ) { [weak self] (result: Result<CloudNote, NetworkError>) in
            switch result {
            case .success(let cloudNote):
                // Create mapping - server returns the note directly
                let cloudId = cloudNote.id
                self?.syncMapping.createMapping(
                    localId: localNote.noteId,
                    cloudId: cloudId,
                    entityType: .note,
                    status: .synced
                )
                print("NoteSyncService: Created cloud note \(cloudId) for local \(localNote.noteId)")
                completion(.success(cloudId))

            case .failure(let error):
                print("NoteSyncService: Failed to create cloud note - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    private func updateCloudNote(localNote: Note, cloudId: String, completion: @escaping (Result<String, NoteSyncError>) -> Void) {
        // Get the cloud category ID if the note has a category
        var cloudCategoryId: Int? = nil
        if localNote.categoryId > 0 {
            if let cloudIdStr = syncMapping.getCloudId(localId: localNote.categoryId, entityType: .category),
               let cloudIdInt = Int(cloudIdStr) {
                cloudCategoryId = cloudIdInt
            } else {
                cloudCategoryId = localNote.categoryId
            }
        }

        let request = CreateNoteRequest.from(localNote: localNote, cloudCategoryId: cloudCategoryId)

        // Server returns a message response for updates, not the note object
        networkManager.put(
            endpoint: APIConfig.Endpoints.note(id: cloudId),
            body: request,
            requiresAuth: true
        ) { [weak self] (result: Result<SuccessMessageResponse, NetworkError>) in
            switch result {
            case .success:
                self?.syncMapping.updateStatus(
                    localId: localNote.noteId,
                    entityType: .note,
                    status: .synced
                )
                print("NoteSyncService: Updated cloud note \(cloudId)")
                completion(.success(cloudId))

            case .failure(let error):
                print("NoteSyncService: Failed to update cloud note - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Download Methods

    /// Download all notes from the cloud
    func downloadAllNotes(completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        networkManager.get(
            endpoint: APIConfig.Endpoints.notes,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudNote], NetworkError>) in
            switch result {
            case .success(let cloudNotes):
                var downloadedCount = 0

                for cloudNote in cloudNotes {
                    if self?.processCloudNote(cloudNote) == true {
                        downloadedCount += 1
                    }
                }

                print("NoteSyncService: Downloaded \(downloadedCount) notes")
                completion(.success(downloadedCount))

            case .failure(let error):
                print("NoteSyncService: Failed to download notes - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    /// Process a single cloud note (create or update locally)
    private func processCloudNote(_ cloudNote: CloudNote) -> Bool {
        // Check if we already have this cloud note mapped locally
        if let localId = syncMapping.getLocalId(cloudId: cloudNote.id, entityType: .note) {
            // Update existing local note
            return updateLocalNote(cloudNote: cloudNote, localId: localId)
        } else {
            // Create new local note
            return createLocalNote(cloudNote: cloudNote)
        }
    }

    private func createLocalNote(cloudNote: CloudNote) -> Bool {
        // First, check if a note with the same title already exists locally
        let existingNotes = NoteRecords.instance.getAllNotes()
        if let existingNote = existingNotes.first(where: {
            $0.noteName.lowercased() == cloudNote.title.lowercased() &&
            !$0.noteName.isEmpty
        }) {
            // Note with same title exists - just create mapping, don't duplicate
            syncMapping.createMapping(
                localId: existingNote.noteId,
                cloudId: cloudNote.id,
                entityType: .note,
                status: .synced
            )
            print("NoteSyncService: Mapped existing local note \(existingNote.noteId) to cloud \(cloudNote.id)")
            return true
        }

        // Generate a new local ID
        let newLocalId = syncMapping.generateLocalId(entityType: .note)

        // Map cloud category to local category
        var localCategoryId = 0
        if let cloudCatId = cloudNote.categoryId {
            // Try to find local category by cloud mapping, or use the cloud ID directly
            if let localId = syncMapping.getLocalId(cloudId: String(cloudCatId), entityType: .category) {
                localCategoryId = localId
            } else {
                localCategoryId = cloudCatId
            }
        }

        // Create the local note - CloudNote now uses integer timestamps
        let localNote = Note(
            noteId: newLocalId,
            noteName: cloudNote.title,
            editedTime: cloudNote.modifiedDate ?? cloudNote.createdDate,
            noteText: cloudNote.note,
            colorIndex: cloudNote.colorIndex ?? 0,
            categoryId: localCategoryId,
            isDeleted: cloudNote.isDeleted,
            deletedDate: cloudNote.deletedDate,
            contentFormat: cloudNote.contentFormat ?? "markdown"
        )

        // Insert into database
        let result = NoteRecords.instance.insertNote(note: localNote)

        if result > 0 {
            // Set deletion status if needed
            if cloudNote.isDeleted {
                NoteRecords.instance.setNoteDeletionStatus(
                    noteId: newLocalId,
                    isDeleted: true,
                    deletedDate: cloudNote.deletedDate
                )
            }

            // Create mapping
            syncMapping.createMapping(
                localId: newLocalId,
                cloudId: cloudNote.id,
                entityType: .note,
                status: .synced
            )
            print("NoteSyncService: Created local note \(newLocalId) from cloud \(cloudNote.id)")
            return true
        }

        print("NoteSyncService: Failed to create local note from cloud \(cloudNote.id)")
        return false
    }

    private func updateLocalNote(cloudNote: CloudNote, localId: Int) -> Bool {
        // Get the existing local note
        guard let existingNote = NoteRecords.instance.getNote(searchNoteId: localId) else {
            return false
        }

        // Check if cloud is newer using timestamps (both are now integers)
        let cloudModified = cloudNote.modifiedDate ?? cloudNote.createdDate
        let localModified = existingNote.editedTime

        // Only update if cloud is newer (conflict resolution: most recent wins)
        if cloudModified <= localModified {
            print("NoteSyncService: Local note \(localId) is newer or same age, skipping update")
            syncMapping.updateStatus(localId: localId, entityType: .note, status: .synced)
            return true
        }

        // Map cloud category to local category
        var localCategoryId = existingNote.categoryId
        if let cloudCatId = cloudNote.categoryId {
            if let mappedLocalId = syncMapping.getLocalId(cloudId: String(cloudCatId), entityType: .category) {
                localCategoryId = mappedLocalId
            } else {
                localCategoryId = cloudCatId
            }
        }

        // Update the local note
        _ = NoteRecords.instance.updateNoteText(changedNoteId: localId, newText: cloudNote.note)
        _ = NoteRecords.instance.updateNoteTitle(changedNoteId: localId, newTitle: cloudNote.title)
        _ = NoteRecords.instance.updateNoteCategory(changedNoteId: localId, newCategoryId: localCategoryId)

        // Handle deletion status
        if cloudNote.isDeleted != existingNote.isDeleted {
            NoteRecords.instance.setNoteDeletionStatus(
                noteId: localId,
                isDeleted: cloudNote.isDeleted,
                deletedDate: cloudNote.deletedDate
            )
        }

        syncMapping.updateStatus(localId: localId, entityType: .note, status: .synced)
        print("NoteSyncService: Updated local note \(localId) from cloud")
        return true
    }

    // MARK: - Delete Methods

    /// Delete a note from the cloud
    func deleteCloudNote(localId: Int, completion: @escaping (Result<Void, NoteSyncError>) -> Void) {
        guard let cloudId = syncMapping.getCloudId(localId: localId, entityType: .note) else {
            // No cloud mapping, nothing to delete
            completion(.success(()))
            return
        }

        networkManager.delete(
            endpoint: APIConfig.Endpoints.note(id: cloudId),
            requiresAuth: true
        ) { [weak self] result in
            switch result {
            case .success:
                // Remove mapping
                self?.syncMapping.deleteMapping(localId: localId, entityType: .note)
                print("NoteSyncService: Deleted cloud note \(cloudId)")
                completion(.success(()))

            case .failure(let error):
                print("NoteSyncService: Failed to delete cloud note - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Sync Status Methods

    /// Mark a note as needing upload
    func markForUpload(noteId: Int) {
        if syncMapping.isSynced(localId: noteId, entityType: .note) {
            syncMapping.updateStatus(localId: noteId, entityType: .note, status: .pendingUpload)
        }
    }

    /// Get notes that need to be uploaded
    func getNotesPendingUpload() -> [Note] {
        let pendingMappings = syncMapping.getMappings(withStatus: .pendingUpload, entityType: .note)
        var notes: [Note] = []

        for mapping in pendingMappings {
            if let note = NoteRecords.instance.getNote(searchNoteId: mapping.localId) {
                notes.append(note)
            }
        }

        return notes
    }

    /// Get all local notes without cloud mappings (new notes)
    func getUnsyncedNotes() -> [Note] {
        let allNotes = NoteRecords.instance.getAllNotes()
        return allNotes.filter { note in
            !syncMapping.isSynced(localId: note.noteId, entityType: .note)
        }
    }
}
