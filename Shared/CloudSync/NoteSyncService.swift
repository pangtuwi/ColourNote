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
    case notModified
    case conflictDetected(localId: Int, cloudId: String)

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
        case .notModified:
            return "Notes not modified since last sync"
        case .conflictDetected(let localId, let cloudId):
            return "Conflict detected for note local:\(localId) cloud:\(cloudId)"
        }
    }
}

// MARK: - Apply Outcome for Notes
enum NoteApplyOutcome {
    case added
    case updated
    case unchanged
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

        // Get stored ETag for optimistic concurrency control
        let storedEtag = syncMapping.getEtag(localId: localNote.noteId, entityType: .note)

        // Server returns a message response for updates, not the note object
        networkManager.put(
            endpoint: APIConfig.Endpoints.note(id: cloudId),
            body: request,
            eTag: storedEtag,
            requiresAuth: true
        ) { [weak self] (result: Result<ResponseWithETag<SuccessMessageResponse>, NetworkError>) in
            switch result {
            case .success(let response):
                // Update sync status and store new ETag
                self?.syncMapping.updateStatus(
                    localId: localNote.noteId,
                    entityType: .note,
                    status: .synced
                )
                if let newEtag = response.etag {
                    self?.syncMapping.updateEtag(
                        localId: localNote.noteId,
                        entityType: .note,
                        newEtag: newEtag
                    )
                }
                print("NoteSyncService: Updated cloud note \(cloudId)")
                completion(.success(cloudId))

            case .failure(let error):
                if case .preconditionFailed(let responseData) = error {
                    // ETag mismatch - conflict detected, try to resolve using response body
                    print("NoteSyncService: Conflict detected for note \(cloudId), attempting resolution")
                    self?.handleNoteConflict(localNote: localNote, cloudId: cloudId, responseData: responseData, completion: completion)
                } else {
                    print("NoteSyncService: Failed to update cloud note - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }

    /// Handle conflict when ETag mismatch (412) occurs
    /// Uses the current_version from the 412 response body to avoid an extra GET request
    private func handleNoteConflict(localNote: Note, cloudId: String, responseData: Data?, completion: @escaping (Result<String, NoteSyncError>) -> Void) {
        // Try to parse the current version from the 412 response body
        var cloudNote: CloudNote? = nil
        if let data = responseData {
            do {
                let decoder = JSONDecoder()
                let conflictResponse = try decoder.decode(NoteConflictResponse.self, from: data)
                cloudNote = conflictResponse.currentVersion
                if cloudNote != nil {
                    print("NoteSyncService: Using current_version from 412 response body")
                }
            } catch {
                print("NoteSyncService: Could not parse 412 response body: \(error)")
            }
        }

        // If we couldn't get the current version from response body, fall back to GET request
        if cloudNote == nil {
            print("NoteSyncService: Falling back to GET request for current version")
            networkManager.get(
                endpoint: APIConfig.Endpoints.note(id: cloudId),
                requiresAuth: true
            ) { [weak self] (result: Result<CloudNote, NetworkError>) in
                switch result {
                case .success(let fetchedNote):
                    self?.resolveNoteConflict(localNote: localNote, cloudNote: fetchedNote, cloudId: cloudId, completion: completion)
                case .failure(let error):
                    print("NoteSyncService: Failed to fetch cloud note for conflict resolution - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
            return
        }

        // We have the current version from response body, resolve directly
        resolveNoteConflict(localNote: localNote, cloudNote: cloudNote!, cloudId: cloudId, completion: completion)
    }

    /// Resolve note conflict by comparing timestamps
    private func resolveNoteConflict(localNote: Note, cloudNote: CloudNote, cloudId: String, completion: @escaping (Result<String, NoteSyncError>) -> Void) {
        // Compare timestamps - most recent wins
        let cloudModified = cloudNote.modifiedDate ?? cloudNote.createdDate
        let localModified = localNote.editedTime

        if localModified > cloudModified {
            // Local is newer, force update (without ETag)
            print("NoteSyncService: Local note is newer (\(localModified) > \(cloudModified)), forcing update")
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
                    print("NoteSyncService: Conflict resolved - local wins")
                    completion(.success(cloudId))
                case .failure(let error):
                    completion(.failure(.networkError(error)))
                }
            }
        } else {
            // Cloud is newer or same age, accept cloud version
            print("NoteSyncService: Cloud note is newer (\(cloudModified) >= \(localModified)), accepting cloud version")
            _ = updateLocalNote(cloudNote: cloudNote, localId: localNote.noteId)
            completion(.success(cloudId))
        }
    }

    // MARK: - Download Methods

    /// Download all notes from the cloud (with optional delta sync)
    /// - Parameters:
    ///   - since: Optional timestamp in milliseconds. If provided, only returns notes modified after this time.
    ///   - completion: Result with count of downloaded notes or error
    func downloadAllNotes(since: Int? = nil, completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        // Build query parameters for delta sync
        var queryParams: [String: String]? = nil
        if let sinceTimestamp = since {
            queryParams = ["since": String(sinceTimestamp)]
        }

        networkManager.get(
            endpoint: APIConfig.Endpoints.notes,
            queryParams: queryParams,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudNote], NetworkError>) in
            switch result {
            case .success(let cloudNotes):
                let receivedCount = cloudNotes.count
                var appliedCount = 0

                for cloudNote in cloudNotes {
                    let applied = self?.processCloudNote(cloudNote) ?? false
                    if applied {
                        appliedCount += 1
                    } else {
                        print("NoteSyncService: Skipped applying cloud note id=\(cloudNote.id) title='\(cloudNote.title)'")
                    }
                }

                print("NoteSyncService: Downloaded \(receivedCount) notes, applied \(appliedCount) (delta: \(since != nil))")
                completion(.success(appliedCount))

            case .failure(let error):
                // Handle 304 Not Modified as success with 0 changes
                if case .notModified = error {
                    print("NoteSyncService: Notes not modified since last sync")
                    completion(.success(0))
                } else {
                    print("NoteSyncService: Failed to download notes - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }

    /// Download all notes with breakdown of added vs updated
    func downloadAllNotesWithBreakdown(since: Int? = nil, completion: @escaping (Result<(added: Int, updated: Int), NoteSyncError>) -> Void) {
        var queryParams: [String: String]? = nil
        if let sinceTimestamp = since {
            queryParams = ["since": String(sinceTimestamp)]
        }

        networkManager.get(
            endpoint: APIConfig.Endpoints.notes,
            queryParams: queryParams,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudNote], NetworkError>) in
            switch result {
            case .success(let cloudNotes):
                var added = 0
                var updated = 0
                for cloudNote in cloudNotes {
                    let outcome = self?.applyCloudNote(cloudNote) ?? .unchanged
                    switch outcome {
                    case .added: added += 1
                    case .updated: updated += 1
                    case .unchanged: break
                    }
                }
                print("NoteSyncService: Downloaded notes — added=\(added), updated=\(updated) (delta: \(since != nil))")
                completion(.success((added: added, updated: updated)))
            case .failure(let error):
                if case .notModified = error {
                    print("NoteSyncService: Notes not modified since last sync")
                    completion(.success((added: 0, updated: 0)))
                } else {
                    print("NoteSyncService: Failed to download notes - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }

    /// Apply a single cloud note and return outcome
    private func applyCloudNote(_ cloudNote: CloudNote) -> NoteApplyOutcome {
        // Try UUID first
        if let cloudUUID = cloudNote.uuid, let existingNote = syncMapping.findLocalNoteByUUID(cloudUUID) {
            if syncMapping.getCloudId(localId: existingNote.noteId, entityType: .note) == nil {
                syncMapping.createMapping(localId: existingNote.noteId, cloudId: cloudNote.id, entityType: .note, status: .synced)
            }
            let changed = updateLocalNote(cloudNote: cloudNote, localId: existingNote.noteId)
            return changed ? .updated : .unchanged
        }

        // Check mapping by cloud ID
        if let localId = syncMapping.getLocalId(cloudId: cloudNote.id, entityType: .note) {
            let changed = updateLocalNote(cloudNote: cloudNote, localId: localId)
            return changed ? .updated : .unchanged
        }

        // Create new local note
        let created = createLocalNote(cloudNote: cloudNote)
        return created ? .added : .unchanged
    }

    /// Process a single cloud note (create or update locally)
    private func processCloudNote(_ cloudNote: CloudNote) -> Bool {
        print("NoteSyncService: Processing cloud note - id: \(cloudNote.id), uuid: '\(cloudNote.uuid ?? "nil")', title: '\(cloudNote.title)'")

        // PRIMARY: Check by UUID first (cross-device identification)
        if let cloudUUID = cloudNote.uuid,
           let existingNote = syncMapping.findLocalNoteByUUID(cloudUUID) {
            print("NoteSyncService: Found local note by UUID: \(existingNote.noteId)")
            // Ensure mapping exists
            if syncMapping.getCloudId(localId: existingNote.noteId, entityType: .note) == nil {
                syncMapping.createMapping(
                    localId: existingNote.noteId,
                    cloudId: cloudNote.id,
                    entityType: .note,
                    status: .synced
                )
            }
            return updateLocalNote(cloudNote: cloudNote, localId: existingNote.noteId)
        }

        // SECONDARY: Check if we already have this cloud note mapped by cloud ID
        if let localId = syncMapping.getLocalId(cloudId: cloudNote.id, entityType: .note) {
            // Update existing local note
            return updateLocalNote(cloudNote: cloudNote, localId: localId)
        }

        // TERTIARY: Create new local note (no UUID or cloud ID match)
        return createLocalNote(cloudNote: cloudNote)
    }

    private func createLocalNote(cloudNote: CloudNote) -> Bool {
        // UUID matching is now done in processCloudNote, so if we get here,
        // we have a truly new note from the cloud

        // FALLBACK: Check if a note with the same title already exists locally
        // (for backwards compatibility with data that doesn't have UUIDs yet)
        let existingNotes = NoteRecords.instance.getAllNotes()
        if let existingNote = existingNotes.first(where: {
            $0.noteName.lowercased() == cloudNote.title.lowercased() &&
            !$0.noteName.isEmpty
        }) {
            // Note with same title exists - create mapping and update UUID if needed
            syncMapping.createMapping(
                localId: existingNote.noteId,
                cloudId: cloudNote.id,
                entityType: .note,
                status: .synced
            )
            // Update the local note's UUID if it doesn't have one from cloud
            if let cloudUUID = cloudNote.uuid, existingNote.uuid != cloudUUID {
                _ = NoteRecords.instance.updateNoteUUID(noteId: existingNote.noteId, uuid: cloudUUID)
            }
            print("NoteSyncService: Mapped existing local note \(existingNote.noteId) to cloud \(cloudNote.id) (matched by title)")
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

        // Create the local note with UUID from cloud
        let localNote = Note(
            noteId: newLocalId,
            uuid: cloudNote.uuid,
            noteName: cloudNote.title,
            editedTime: cloudNote.modifiedDate ?? cloudNote.createdDate,
            noteText: cloudNote.note ?? "",
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
                _ = NoteRecords.instance.setNoteDeletionStatus(
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
            print("NoteSyncService: Created local note \(newLocalId) from cloud \(cloudNote.id) with UUID \(cloudNote.uuid ?? "nil")")
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

        // Determine mapped local category id from cloud category
        var mappedCategoryId = existingNote.categoryId
        if let cloudCatId = cloudNote.categoryId {
            if let mappedLocalId = syncMapping.getLocalId(cloudId: String(cloudCatId), entityType: .category) {
                mappedCategoryId = mappedLocalId
            } else {
                mappedCategoryId = cloudCatId
            }
        }

        // Compute desired target values from cloud
        let targetTitle = cloudNote.title
        let targetText = cloudNote.note ?? ""
        let targetUUID = cloudNote.uuid ?? existingNote.uuid
        let targetIsDeleted = cloudNote.isDeleted
        let targetDeletedDate = cloudNote.deletedDate
        
        // Detect differences
        let titleDiffers = existingNote.noteName != targetTitle
        let textDiffers = existingNote.noteText != targetText
        let categoryDiffers = existingNote.categoryId != mappedCategoryId
        let uuidDiffers = existingNote.uuid != targetUUID
        let deletionDiffers = existingNote.isDeleted != targetIsDeleted || existingNote.deletedDate != targetDeletedDate

        let hasChanges = titleDiffers || textDiffers || categoryDiffers || uuidDiffers || deletionDiffers

        if !hasChanges {
            // No changes; ensure status is synced and return unchanged
            syncMapping.updateStatus(localId: localId, entityType: .note, status: .synced)
            print("NoteSyncService: Local note \(localId) already up-to-date; skipping update")
            return false
        }

        // Apply updates
        if textDiffers { _ = NoteRecords.instance.updateNoteText(changedNoteId: localId, newText: targetText) }
        if titleDiffers { _ = NoteRecords.instance.updateNoteTitle(changedNoteId: localId, newTitle: targetTitle) }
        if categoryDiffers { _ = NoteRecords.instance.updateNoteCategory(changedNoteId: localId, newCategoryId: mappedCategoryId) }
        if uuidDiffers { _ = NoteRecords.instance.updateNoteUUID(noteId: localId, uuid: targetUUID) }

        if deletionDiffers {
            _ = NoteRecords.instance.setNoteDeletionStatus(
                noteId: localId,
                isDeleted: targetIsDeleted,
                deletedDate: targetDeletedDate
            )
        }

        // Removed updateNoteEditedTime call as per instruction

        syncMapping.updateStatus(localId: localId, entityType: .note, status: .synced)
        print("NoteSyncService: Updated local note \(localId) from cloud with UUID \(targetUUID)")
        return true
    }

    // MARK: - Delete Methods

    /// Delete a note from the cloud (soft delete - moves to trash)
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

    /// Permanently delete a note from the cloud (hard delete)
    /// - Parameters:
    ///   - localId: The local note ID
    ///   - completion: Result with success or error
    func permanentlyDeleteCloudNote(localId: Int, completion: @escaping (Result<Void, NoteSyncError>) -> Void) {
        guard let cloudId = syncMapping.getCloudId(localId: localId, entityType: .note) else {
            // No cloud mapping - note was never synced, can safely delete locally
            print("NoteSyncService: No cloud mapping for note \(localId), nothing to delete from cloud")
            completion(.success(()))
            return
        }

        print("NoteSyncService: Permanently deleting cloud note \(cloudId)")

        networkManager.delete(
            endpoint: APIConfig.Endpoints.notePermanent(id: cloudId),
            requiresAuth: true
        ) { [weak self] result in
            switch result {
            case .success:
                // Remove the sync mapping
                self?.syncMapping.deleteMapping(localId: localId, entityType: .note)
                print("NoteSyncService: Permanently deleted cloud note \(cloudId)")
                completion(.success(()))

            case .failure(let error):
                // Handle 404 (already deleted on server) as success
                if case .httpError(statusCode: 404, _) = error {
                    print("NoteSyncService: Cloud note \(cloudId) already deleted on server (404)")
                    self?.syncMapping.deleteMapping(localId: localId, entityType: .note)
                    completion(.success(()))
                } else {
                    print("NoteSyncService: Failed to permanently delete cloud note - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }

    /// Permanently delete multiple notes from the cloud
    /// - Parameters:
    ///   - localIds: Array of local note IDs to permanently delete
    ///   - completion: Result with count of successfully deleted notes or error
    func permanentlyDeleteCloudNotes(localIds: [Int], completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        guard !localIds.isEmpty else {
            completion(.success(0))
            return
        }

        var deletedCount = 0
        var lastError: NoteSyncError?
        let group = DispatchGroup()

        for localId in localIds {
            group.enter()
            permanentlyDeleteCloudNote(localId: localId) { result in
                switch result {
                case .success:
                    deletedCount += 1
                case .failure(let error):
                    lastError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = lastError, deletedCount == 0 {
                completion(.failure(error))
            } else {
                print("NoteSyncService: Permanently deleted \(deletedCount) notes from cloud")
                completion(.success(deletedCount))
            }
        }
    }

    /// Get notes that are pending permanent deletion from the cloud
    func getNotesPendingPermanentDelete() -> [SyncMappingRecord] {
        return syncMapping.getMappings(withStatus: .pendingPermanentDelete, entityType: .note)
    }

    /// Mark a note for pending permanent deletion (when offline)
    func markForPermanentDelete(localId: Int) {
        if syncMapping.isSynced(localId: localId, entityType: .note) {
            syncMapping.updateStatus(localId: localId, entityType: .note, status: .pendingPermanentDelete)
            print("NoteSyncService: Marked note \(localId) for pending permanent delete")
        }
    }

    /// Process all pending permanent deletes
    /// - Parameter completion: Result with count of processed deletes or error
    func processPendingPermanentDeletes(completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        let pendingDeletes = getNotesPendingPermanentDelete()

        guard !pendingDeletes.isEmpty else {
            print("NoteSyncService: No pending permanent deletes")
            completion(.success(0))
            return
        }

        print("NoteSyncService: Processing \(pendingDeletes.count) pending permanent deletes")

        var processedCount = 0
        var lastError: NoteSyncError?
        let group = DispatchGroup()

        for mapping in pendingDeletes {
            group.enter()

            // Call permanent delete on the cloud
            networkManager.delete(
                endpoint: APIConfig.Endpoints.notePermanent(id: mapping.cloudId),
                requiresAuth: true
            ) { [weak self] result in
                switch result {
                case .success:
                    // Delete the sync mapping and local note
                    self?.syncMapping.deleteMapping(localId: mapping.localId, entityType: .note)
                    _ = NoteRecords.instance.permanentlyDeleteNoteWithoutSync(noteId: mapping.localId)
                    processedCount += 1
                    print("NoteSyncService: Processed pending delete for note \(mapping.localId)")

                case .failure(let error):
                    // Handle 404 (already deleted on server) as success
                    if case .httpError(statusCode: 404, _) = error {
                        self?.syncMapping.deleteMapping(localId: mapping.localId, entityType: .note)
                        _ = NoteRecords.instance.permanentlyDeleteNoteWithoutSync(noteId: mapping.localId)
                        processedCount += 1
                        print("NoteSyncService: Cloud note already deleted (404), cleaned up local")
                    } else {
                        // Network error - keep in pending state for retry
                        print("NoteSyncService: Failed to process pending delete - \(error)")
                        lastError = .networkError(error)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if processedCount > 0 {
                completion(.success(processedCount))
            } else if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(0))
            }
        }
    }

    // MARK: - Server-Side Deletion Handling

    /// Handle notes that were permanently deleted on the server
    /// This should only be called during a full sync (not delta sync)
    /// - Parameter cloudNoteIds: Set of cloud note IDs returned from the server
    /// - Returns: Count of locally deleted notes
    func handleServerSideDeletions(cloudNoteIds: Set<String>) -> Int {
        // Get all note mappings
        let allMappings = syncMapping.getAllMappings(entityType: .note)
        var deletedCount = 0

        for mapping in allMappings {
            // Skip notes that are pending permanent delete (we're handling those)
            if mapping.syncStatus == .pendingPermanentDelete {
                continue
            }

            // If a synced note isn't in the server response, it was permanently deleted on server
            if !cloudNoteIds.contains(mapping.cloudId) {
                print("NoteSyncService: Note \(mapping.localId) (cloud: \(mapping.cloudId)) was permanently deleted on server")

                // Delete the local note
                _ = NoteRecords.instance.permanentlyDeleteNoteWithoutSync(noteId: mapping.localId)

                // Delete the sync mapping
                syncMapping.deleteMapping(localId: mapping.localId, entityType: .note)

                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            print("NoteSyncService: Deleted \(deletedCount) notes that were permanently deleted on server")
        }

        return deletedCount
    }

    /// Deletion-aware download with breakdown of added/updated/deleted
    func downloadAllNotesWithDeletionHandlingAndBreakdown(since: Int? = nil, completion: @escaping (Result<(added: Int, updated: Int, deleted: Int), NoteSyncError>) -> Void) {
        var queryParams: [String: String]? = nil
        if let sinceTimestamp = since {
            queryParams = ["since": String(sinceTimestamp)]
        }

        networkManager.get(
            endpoint: APIConfig.Endpoints.notes,
            queryParams: queryParams,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudNote], NetworkError>) in
            guard let self = self else {
                completion(.failure(.downloadFailed("Service deallocated")))
                return
            }
            switch result {
            case .success(let cloudNotes):
                var addedCount = 0
                var updatedCount = 0

                for cloudNote in cloudNotes {
                    let outcome = self.applyCloudNote(cloudNote)
                    switch outcome {
                    case .added: addedCount += 1
                    case .updated: updatedCount += 1
                    case .unchanged: break
                    }
                }

                var deletedCount = 0
                if since == nil {
                    let cloudNoteIds = Set(cloudNotes.map { $0.id })
                    deletedCount = self.handleServerSideDeletions(cloudNoteIds: cloudNoteIds)
                    print("NoteSyncService: Full sync (breakdown) - added=\(addedCount), updated=\(updatedCount), server-deleted=\(deletedCount)")
                } else {
                    print("NoteSyncService: Delta sync (breakdown) - added=\(addedCount), updated=\(updatedCount)")
                }

                completion(.success((added: addedCount, updated: updatedCount, deleted: deletedCount)))
            case .failure(let error):
                if case .notModified = error {
                    print("NoteSyncService: Notes not modified since last sync")
                    completion(.success((added: 0, updated: 0, deleted: 0)))
                } else {
                    print("NoteSyncService: Failed to download notes (breakdown) - \(error)")
                    completion(.failure(.networkError(error)))
                }
            }
        }
    }

    /// Download all notes from the cloud with server-side deletion handling
    /// - Parameters:
    ///   - since: Optional timestamp in milliseconds. If nil, performs full sync with deletion detection.
    ///   - completion: Result with count of downloaded notes or error
    func downloadAllNotesWithDeletionHandling(since: Int? = nil, completion: @escaping (Result<Int, NoteSyncError>) -> Void) {
        // Build query parameters for delta sync
        var queryParams: [String: String]? = nil
        if let sinceTimestamp = since {
            queryParams = ["since": String(sinceTimestamp)]
        }

        networkManager.get(
            endpoint: APIConfig.Endpoints.notes,
            queryParams: queryParams,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudNote], NetworkError>) in
            guard let self = self else {
                completion(.failure(.downloadFailed("Service deallocated")))
                return
            }

            switch result {
            case .success(let cloudNotes):
                let receivedCount = cloudNotes.count
                var addedCount = 0
                var updatedCount = 0

                // Process each cloud note
                for cloudNote in cloudNotes {
                    let outcome = self.applyCloudNote(cloudNote)
                    switch outcome {
                    case .added: addedCount += 1
                    case .updated: updatedCount += 1
                    case .unchanged: break
                    }
                }

                // Only handle server-side deletions during full sync (not delta)
                if since == nil {
                    let cloudNoteIds = Set(cloudNotes.map { $0.id })
                    let serverDeletedCount = self.handleServerSideDeletions(cloudNoteIds: cloudNoteIds)
                    print("NoteSyncService: Full sync completed - received=\(receivedCount), added=\(addedCount), updated=\(updatedCount), server-deleted=\(serverDeletedCount)")
                } else {
                    print("NoteSyncService: Delta sync completed - received=\(receivedCount), added=\(addedCount), updated=\(updatedCount)")
                }

                completion(.success(addedCount + updatedCount))

            case .failure(let error):
                // Handle 304 Not Modified as success with 0 changes
                if case .notModified = error {
                    print("NoteSyncService: Notes not modified since last sync")
                    completion(.success(0))
                } else {
                    print("NoteSyncService: Failed to download notes - \(error)")
                    completion(.failure(.networkError(error)))
                }
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

