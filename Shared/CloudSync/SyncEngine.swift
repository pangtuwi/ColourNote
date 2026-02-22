//
//  SyncEngine.swift
//  ColourNote
//
//  Orchestrates full bidirectional sync between local and cloud
//

import Foundation

// MARK: - Sync Error
enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case categorySyncFailed(Error)
    case noteSyncFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not logged in to cloud sync"
        case .categorySyncFailed(let error):
            return "Category sync failed: \(error.localizedDescription)"
        case .noteSyncFailed(let error):
            return "Note sync failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Sync Progress
struct SyncProgress {
    var phase: SyncPhase
    var categoriesUploaded: Int
    var categoriesDownloaded: Int
    var notesUploaded: Int
    var notesDownloaded: Int
    var totalCategories: Int
    var totalNotes: Int

    var isComplete: Bool {
        return phase == .complete
    }

    var description: String {
        switch phase {
        case .starting:
            return "Starting sync..."
        case .uploadingCategories:
            return "Uploading categories..."
        case .downloadingCategories:
            return "Downloading categories..."
        case .uploadingNotes:
            return "Uploading notes..."
        case .downloadingNotes:
            return "Downloading notes..."
        case .processingPermanentDeletes:
            return "Processing deletions..."
        case .complete:
            return "Sync complete"
        case .failed:
            return "Sync failed"
        }
    }

    enum SyncPhase {
        case starting
        case uploadingCategories
        case downloadingCategories
        case uploadingNotes
        case downloadingNotes
        case processingPermanentDeletes
        case complete
        case failed
    }
}

// MARK: - Sync Result
struct SyncResult {
    let success: Bool
    let categoriesUploaded: Int
    let categoriesDownloaded: Int
    let notesUploaded: Int
    let notesDownloaded: Int
    let categoriesAdded: Int
    let categoriesUpdated: Int
    let categoriesDeleted: Int
    let notesAdded: Int
    let notesUpdated: Int
    let notesDeleted: Int
    let resultingCategoryCount: Int
    let resultingNoteCount: Int
    let error: Error?
    let syncedAt: Date

    var summary: String {
        if success {
            return "Categories: \(resultingCategoryCount) (added \(categoriesAdded), updated \(categoriesUpdated), deleted \(categoriesDeleted))\nNotes: \(resultingNoteCount) (added \(notesAdded), updated \(notesUpdated), deleted \(notesDeleted))"
        } else {
            return "Sync failed: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - Sync Engine
class SyncEngine {

    // MARK: - Singleton
    static let shared = SyncEngine()

    // MARK: - Properties
    private let categorySyncService = CategorySyncService.shared
    private let noteSyncService = NoteSyncService.shared
    private let authManager = AuthManager.shared

    private var isSyncing = false
    private var currentProgress: SyncProgress?

    // Progress callback
    var onProgressUpdate: ((SyncProgress) -> Void)?

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Perform a full bidirectional sync
    func syncAll(completion: @escaping (Result<SyncResult, SyncError>) -> Void) {
        // Check if already syncing
        guard !isSyncing else {
            print("SyncEngine: Sync already in progress")
            return
        }

        // Check authentication
        guard authManager.isLoggedIn else {
            completion(.failure(.notAuthenticated))
            return
        }

        isSyncing = true

        // Initialize progress
        var progress = SyncProgress(
            phase: .starting,
            categoriesUploaded: 0,
            categoriesDownloaded: 0,
            notesUploaded: 0,
            notesDownloaded: 0,
            totalCategories: 0,
            totalNotes: 0
        )
        currentProgress = progress
        notifyProgress(progress)

        // Variables to capture detailed breakdowns
        var categoriesAdded = 0
        var categoriesUpdated = 0
        var notesAdded = 0
        var notesUpdated = 0
        var notesDeletedCount = 0

        // Start sync chain: Categories first (notes depend on them), then Notes
        syncCategories { [weak self] categoryResult in
            guard let self = self else { return }

            switch categoryResult {
            case .success(let (uploaded, downloaded)):
                progress.categoriesUploaded = uploaded
                progress.categoriesDownloaded = downloaded
                // We approximate categoriesAdded as 0 and categoriesUpdated as downloaded as before
                categoriesAdded = 0
                categoriesUpdated = downloaded

                // Now sync notes with updated breakdown including deletions
                self.syncNotesWithBreakdown { noteResult in
                    switch noteResult {
                    case .success(let (uploaded, added, updated, deleted)):
                        progress.notesUploaded = uploaded
                        progress.notesDownloaded = updated

                        notesAdded = added
                        notesUpdated = updated
                        notesDeletedCount = deleted

                        // Process pending permanent deletes
                        progress.phase = .processingPermanentDeletes
                        self.notifyProgress(progress)

                        self.processPendingPermanentDeletes { deleteResult in
                            // Continue regardless of delete result (non-critical)
                            if case .success(let count) = deleteResult {
                                if count > 0 {
                                    print("SyncEngine: Processed \(count) pending permanent deletes")
                                }
                            }
                            if case .failure(let error) = deleteResult {
                                print("SyncEngine: Pending permanent deletes failed - \(error)")
                            }

                            progress.phase = .complete
                            self.notifyProgress(progress)

                            // Save last sync time
                            self.saveLastSyncTime()

                            // Post notification
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NotesNotification.contentUpdated, object: nil)
                            }

                            // Compute resulting counts
                            let resultingCategoryCount = CategoryRecords.instance.getCategories().count
                            let resultingNoteCount = NoteRecords.instance.getAllNotes().count

                            let categoriesDeleted = 0

                            let result = SyncResult(
                                success: true,
                                categoriesUploaded: progress.categoriesUploaded,
                                categoriesDownloaded: progress.categoriesDownloaded,
                                notesUploaded: progress.notesUploaded,
                                notesDownloaded: progress.notesDownloaded,
                                categoriesAdded: categoriesAdded,
                                categoriesUpdated: categoriesUpdated,
                                categoriesDeleted: categoriesDeleted,
                                notesAdded: notesAdded,
                                notesUpdated: notesUpdated,
                                notesDeleted: notesDeletedCount,
                                resultingCategoryCount: resultingCategoryCount,
                                resultingNoteCount: resultingNoteCount,
                                error: nil,
                                syncedAt: Date()
                            )

                            self.isSyncing = false
                            completion(.success(result))
                        }

                    case .failure(let error):
                        progress.phase = .failed
                        self.notifyProgress(progress)
                        self.isSyncing = false
                        completion(.failure(.noteSyncFailed(error)))
                    }
                }

            case .failure(let error):
                progress.phase = .failed
                self.notifyProgress(progress)
                self.isSyncing = false
                completion(.failure(.categorySyncFailed(error)))
            }
        }
    }

    /// Upload only local changes to cloud
    func uploadLocalChanges(completion: @escaping (Result<Int, SyncError>) -> Void) {
        guard authManager.isLoggedIn else {
            completion(.failure(.notAuthenticated))
            return
        }

        var totalUploaded = 0
        let group = DispatchGroup()
        var lastError: Error?

        // Upload categories first
        group.enter()
        categorySyncService.uploadAllCategories { result in
            switch result {
            case .success(let count):
                totalUploaded += count
            case .failure(let error):
                lastError = error
            }
            group.leave()
        }

        // Upload notes after categories
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            self.noteSyncService.uploadAllNotes { result in
                switch result {
                case .success(let count):
                    totalUploaded += count
                    self.saveLastSyncTime()
                    completion(.success(totalUploaded))
                case .failure(let error):
                    if lastError != nil {
                        completion(.failure(.categorySyncFailed(lastError!)))
                    } else {
                        completion(.failure(.noteSyncFailed(error)))
                    }
                }
            }
        }
    }

    /// Download only cloud changes locally
    func downloadCloudChanges(completion: @escaping (Result<Int, SyncError>) -> Void) {
        guard authManager.isLoggedIn else {
            completion(.failure(.notAuthenticated))
            return
        }

        var totalDownloaded = 0
        let group = DispatchGroup()
        var lastError: Error?

        // Download categories first
        group.enter()
        categorySyncService.downloadAllCategories { result in
            switch result {
            case .success(let count):
                totalDownloaded += count
            case .failure(let error):
                lastError = error
            }
            group.leave()
        }

        // Download notes after categories (using deletion-aware download)
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Use deletion-aware download to handle server-side deletions
            self.noteSyncService.downloadAllNotesWithDeletionHandling(since: nil) { result in
                switch result {
                case .success(let count):
                    totalDownloaded += count
                    self.saveLastSyncTime()

                    // Post notification
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NotesNotification.contentUpdated, object: nil)
                    }

                    completion(.success(totalDownloaded))
                case .failure(let error):
                    if lastError != nil {
                        completion(.failure(.categorySyncFailed(lastError!)))
                    } else {
                        completion(.failure(.noteSyncFailed(error)))
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func syncCategories(completion: @escaping (Result<(Int, Int), Error>) -> Void) {
        var progress = currentProgress ?? SyncProgress(
            phase: .uploadingCategories,
            categoriesUploaded: 0,
            categoriesDownloaded: 0,
            notesUploaded: 0,
            notesDownloaded: 0,
            totalCategories: 0,
            totalNotes: 0
        )

        progress.phase = .uploadingCategories
        notifyProgress(progress)

        // Get last category sync time for delta sync
        let lastCategorySyncTime = getLastCategorySyncTime()

        // Upload local categories first
        categorySyncService.uploadAllCategories { [weak self] uploadResult in
            guard let self = self else { return }

            var uploaded = 0
            switch uploadResult {
            case .success(let count):
                uploaded = count
            case .failure(let error):
                print("SyncEngine: Category upload failed - \(error)")
                // Continue with download even if upload fails
            }

            progress.categoriesUploaded = uploaded
            progress.phase = .downloadingCategories
            self.notifyProgress(progress)

            // Then download cloud categories with delta sync using new breakdown API
            self.categorySyncService.downloadAllCategoriesWithBreakdown(since: lastCategorySyncTime) { downloadResult in
                switch downloadResult {
                case .success(let breakdown):
                    // Save current time as last sync time for categories
                    let now = Int(Date().timeIntervalSince1970 * 1000)
                    self.saveLastCategorySyncTime(now)
                    completion(.success((uploaded, breakdown.added + breakdown.updated)))
                case .failure(let error):
                    // If upload succeeded but download failed, still return partial success
                    if uploaded > 0 {
                        completion(.success((uploaded, 0)))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func syncNotes(completion: @escaping (Result<(Int, Int), Error>) -> Void) {
        var progress = currentProgress ?? SyncProgress(
            phase: .uploadingNotes,
            categoriesUploaded: 0,
            categoriesDownloaded: 0,
            notesUploaded: 0,
            notesDownloaded: 0,
            totalCategories: 0,
            totalNotes: 0
        )

        progress.phase = .uploadingNotes
        notifyProgress(progress)

        // Get last note sync time for delta sync
        let lastNoteSyncTime = getLastNoteSyncTime()

        // Upload local notes first
        noteSyncService.uploadAllNotes { [weak self] uploadResult in
            guard let self = self else { return }

            var uploaded = 0
            switch uploadResult {
            case .success(let count):
                uploaded = count
            case .failure(let error):
                print("SyncEngine: Note upload failed - \(error)")
                // Continue with download even if upload fails
            }

            progress.notesUploaded = uploaded
            progress.phase = .downloadingNotes
            self.notifyProgress(progress)

            // Use deletion-aware download for full sync (when no lastNoteSyncTime)
            // This detects notes that were permanently deleted on the server
            self.noteSyncService.downloadAllNotesWithDeletionHandling(since: lastNoteSyncTime) { downloadResult in
                switch downloadResult {
                case .success(let count):
                    // Save current time as last sync time for notes
                    let now = Int(Date().timeIntervalSince1970 * 1000)
                    self.saveLastNoteSyncTime(now)
                    completion(.success((uploaded, count)))
                case .failure(let error):
                    // If upload succeeded but download failed, still return partial success
                    if uploaded > 0 {
                        completion(.success((uploaded, 0)))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func notifyProgress(_ progress: SyncProgress) {
        currentProgress = progress
        DispatchQueue.main.async { [weak self] in
            self?.onProgressUpdate?(progress)
        }
    }

    /// Process pending permanent deletes from the queue
    private func processPendingPermanentDeletes(completion: @escaping (Result<Int, Error>) -> Void) {
        noteSyncService.processPendingPermanentDeletes { result in
            switch result {
            case .success(let count):
                if count > 0 {
                    print("SyncEngine: Processed \(count) pending permanent deletes")
                }
                completion(.success(count))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - New Sync Notes with Breakdown including deletions

    private func syncNotesWithBreakdown(completion: @escaping (Result<(uploaded: Int, added: Int, updated: Int, deleted: Int), Error>) -> Void) {
        var progress = currentProgress ?? SyncProgress(
            phase: .uploadingNotes,
            categoriesUploaded: 0,
            categoriesDownloaded: 0,
            notesUploaded: 0,
            notesDownloaded: 0,
            totalCategories: 0,
            totalNotes: 0
        )

        progress.phase = .uploadingNotes
        notifyProgress(progress)

        let lastNoteSyncTime = getLastNoteSyncTime()

        noteSyncService.uploadAllNotes { [weak self] uploadResult in
            guard let self = self else { return }
            var uploaded = 0
            switch uploadResult {
            case .success(let count): uploaded = count
            case .failure(let error): print("SyncEngine: Note upload failed - \(error)")
            }

            progress.notesUploaded = uploaded
            progress.phase = .downloadingNotes
            self.notifyProgress(progress)

            self.noteSyncService.downloadAllNotesWithDeletionHandlingAndBreakdown(since: lastNoteSyncTime) { result in
                switch result {
                case .success(let breakdown):
                    let now = Int(Date().timeIntervalSince1970 * 1000)
                    self.saveLastNoteSyncTime(now)
                    completion(.success((uploaded: uploaded, added: breakdown.added, updated: breakdown.updated, deleted: breakdown.deleted)))
                case .failure(let error):
                    if uploaded > 0 {
                        completion(.success((uploaded: uploaded, added: 0, updated: 0, deleted: 0)))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Sync Time Management

    private func saveLastSyncTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: APIConfig.UserDefaultsKeys.lastSyncTime)
    }

    func getLastSyncTime() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: APIConfig.UserDefaultsKeys.lastSyncTime)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    func getLastSyncTimeString() -> String {
        guard let lastSync = getLastSyncTime() else {
            return "Never"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter.string(from: lastSync)
    }

    // MARK: - Per-Entity Sync Timestamps

    /// Get last sync time for categories (milliseconds since epoch)
    private func getLastCategorySyncTime() -> Int? {
        let timestamp = UserDefaults.standard.integer(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
        return timestamp > 0 ? timestamp : nil
    }

    /// Save last sync time for categories
    private func saveLastCategorySyncTime(_ timestamp: Int) {
        UserDefaults.standard.set(timestamp, forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
    }

    /// Get last sync time for notes (milliseconds since epoch)
    private func getLastNoteSyncTime() -> Int? {
        let timestamp = UserDefaults.standard.integer(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
        return timestamp > 0 ? timestamp : nil
    }

    /// Save last sync time for notes
    private func saveLastNoteSyncTime(_ timestamp: Int) {
        UserDefaults.standard.set(timestamp, forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
    }

    // MARK: - Auto Sync Settings

    var isAutoSyncEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: APIConfig.UserDefaultsKeys.autoSyncEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: APIConfig.UserDefaultsKeys.autoSyncEnabled)
        }
    }

    /// Called when app launches or enters foreground
    func syncIfNeeded() {
        guard isAutoSyncEnabled else {
            print("SyncEngine: Skipping sync — auto-sync is disabled")
            return
        }
        guard authManager.isLoggedIn else {
            print("SyncEngine: Skipping sync — user is not logged in")
            return
        }
        guard !isSyncing else {
            print("SyncEngine: Skipping sync — sync already in progress")
            return
        }

        print("SyncEngine: Starting auto-sync")
        syncAll { result in
            switch result {
            case .success(let syncResult):
                print("SyncEngine: Auto-sync completed - \(syncResult.summary)")
            case .failure(let error):
                print("SyncEngine: Auto-sync failed - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Reset

    /// Clear all sync data (for logout)
    func clearSyncData() {
        SyncMapping.shared.clearAllMappings()
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastSyncTime)
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
        print("SyncEngine: Cleared all sync data")
    }
}

