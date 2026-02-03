//
//  SyncMapping.swift
//  ColourNote
//
//  Manages mappings between local IDs and cloud UUIDs for sync
//

import Foundation
import SQLite

// MARK: - Entity Type
enum SyncEntityType: String {
    case note = "note"
    case category = "category"
}

// MARK: - Sync Status
enum SyncStatus: String {
    case synced = "synced"
    case pendingUpload = "pending_upload"
    case pendingDownload = "pending_download"
    case conflict = "conflict"
}

// MARK: - Sync Mapping Model
struct SyncMappingRecord {
    let id: Int
    let localId: Int
    let cloudId: String
    let entityType: SyncEntityType
    var lastSynced: Int?
    var syncStatus: SyncStatus
    let createdAt: Int
    var modifiedAt: Int
}

// MARK: - Sync Mapping Manager
class SyncMapping {

    // MARK: - Singleton
    static let shared = SyncMapping()

    // MARK: - Properties
    private var db: Connection?

    private let concurrentDBQueue = DispatchQueue(
        label: "com.colornote.syncmappingqueue",
        attributes: .concurrent)

    // SQLite table definitions
    private let syncMappings = Table("sync_mappings")
    private let id = SQLite.Expression<Int>("id")
    private let localId = SQLite.Expression<Int>("local_id")
    private let cloudId = SQLite.Expression<String>("cloud_id")
    private let entityType = SQLite.Expression<String>("entity_type")
    private let lastSynced = SQLite.Expression<Int?>("last_synced")
    private let syncStatus = SQLite.Expression<String>("sync_status")
    private let createdAt = SQLite.Expression<Int>("created_at")
    private let modifiedAt = SQLite.Expression<Int>("modified_at")

    // MARK: - Initialization
    private init() {
        openDatabase()
    }

    private func openDatabase() {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("colornote.db")
                .path

            db = try Connection(fileURL)
            // Enable WAL mode for better concurrent access
            try db?.execute("PRAGMA journal_mode = WAL")
            print("SyncMapping: Database opened successfully with WAL mode")
        } catch {
            db = nil
            print("SyncMapping: Error opening database - \(error)")
        }
    }

    // MARK: - Query Methods

    /// Get cloud ID for a local entity
    func getCloudId(localId: Int, entityType: SyncEntityType) -> String? {
        guard let db = db else { return nil }

        do {
            let query = syncMappings.filter(self.localId == localId && self.entityType == entityType.rawValue)
            for row in try db.prepare(query) {
                return row[cloudId]
            }
        } catch {
            print("SyncMapping: Error getting cloud ID - \(error)")
        }

        return nil
    }

    /// Get local ID for a cloud entity
    func getLocalId(cloudId: String, entityType: SyncEntityType) -> Int? {
        guard let db = db else { return nil }

        do {
            let query = syncMappings.filter(self.cloudId == cloudId && self.entityType == entityType.rawValue)
            for row in try db.prepare(query) {
                return row[localId]
            }
        } catch {
            print("SyncMapping: Error getting local ID - \(error)")
        }

        return nil
    }

    /// Get mapping record for a local entity
    func getMapping(localId: Int, entityType: SyncEntityType) -> SyncMappingRecord? {
        guard let db = db else { return nil }

        do {
            let query = syncMappings.filter(self.localId == localId && self.entityType == entityType.rawValue)
            for row in try db.prepare(query) {
                return SyncMappingRecord(
                    id: row[id],
                    localId: row[self.localId],
                    cloudId: row[self.cloudId],
                    entityType: SyncEntityType(rawValue: row[self.entityType]) ?? entityType,
                    lastSynced: row[lastSynced],
                    syncStatus: SyncStatus(rawValue: row[syncStatus]) ?? .pendingUpload,
                    createdAt: row[createdAt],
                    modifiedAt: row[modifiedAt]
                )
            }
        } catch {
            print("SyncMapping: Error getting mapping - \(error)")
        }

        return nil
    }

    /// Get all mappings for an entity type
    func getAllMappings(entityType: SyncEntityType) -> [SyncMappingRecord] {
        guard let db = db else { return [] }

        var mappings: [SyncMappingRecord] = []

        do {
            let query = syncMappings.filter(self.entityType == entityType.rawValue)
            for row in try db.prepare(query) {
                mappings.append(SyncMappingRecord(
                    id: row[id],
                    localId: row[localId],
                    cloudId: row[cloudId],
                    entityType: SyncEntityType(rawValue: row[self.entityType]) ?? entityType,
                    lastSynced: row[lastSynced],
                    syncStatus: SyncStatus(rawValue: row[syncStatus]) ?? .pendingUpload,
                    createdAt: row[createdAt],
                    modifiedAt: row[modifiedAt]
                ))
            }
        } catch {
            print("SyncMapping: Error getting all mappings - \(error)")
        }

        return mappings
    }

    /// Get all mappings with a specific sync status
    func getMappings(withStatus status: SyncStatus, entityType: SyncEntityType) -> [SyncMappingRecord] {
        guard let db = db else { return [] }

        var mappings: [SyncMappingRecord] = []

        do {
            let query = syncMappings.filter(self.entityType == entityType.rawValue && self.syncStatus == status.rawValue)
            for row in try db.prepare(query) {
                mappings.append(SyncMappingRecord(
                    id: row[id],
                    localId: row[localId],
                    cloudId: row[cloudId],
                    entityType: SyncEntityType(rawValue: row[self.entityType]) ?? entityType,
                    lastSynced: row[lastSynced],
                    syncStatus: SyncStatus(rawValue: row[self.syncStatus]) ?? status,
                    createdAt: row[createdAt],
                    modifiedAt: row[modifiedAt]
                ))
            }
        } catch {
            print("SyncMapping: Error getting mappings by status - \(error)")
        }

        return mappings
    }

    /// Check if a local entity has been synced
    func isSynced(localId: Int, entityType: SyncEntityType) -> Bool {
        return getCloudId(localId: localId, entityType: entityType) != nil
    }

    /// Check if a cloud entity exists locally
    func existsLocally(cloudId: String, entityType: SyncEntityType) -> Bool {
        return getLocalId(cloudId: cloudId, entityType: entityType) != nil
    }

    // MARK: - UUID-based Lookup Methods

    /// Find a local note by UUID
    func findLocalNoteByUUID(_ uuid: String) -> Note? {
        let allNotes = NoteRecords.instance.getAllNotes()
        return allNotes.first { $0.uuid == uuid }
    }

    /// Find a local category by UUID
    func findLocalCategoryByUUID(_ uuid: String) -> Category? {
        let allCategories = CategoryRecords.instance.getCategories()
        return allCategories.first { $0.uuid == uuid }
    }

    /// Check if a note with the given UUID exists locally
    func noteExistsLocally(uuid: String) -> Bool {
        return findLocalNoteByUUID(uuid) != nil
    }

    /// Check if a category with the given UUID exists locally
    func categoryExistsLocally(uuid: String) -> Bool {
        return findLocalCategoryByUUID(uuid) != nil
    }

    // MARK: - Write Methods

    /// Create a new mapping
    @discardableResult
    func createMapping(localId: Int, cloudId: String, entityType: SyncEntityType, status: SyncStatus = .synced) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            let now = Int(Date().timeIntervalSince1970 * 1000)

            do {
                let sql = """
                INSERT OR REPLACE INTO sync_mappings (local_id, cloud_id, entity_type, last_synced, sync_status, created_at, modified_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """
                try db.run(sql, localId, cloudId, entityType.rawValue, now, status.rawValue, now, now)
                print("SyncMapping: Created mapping local:\(localId) <-> cloud:\(cloudId) for \(entityType.rawValue)")
                result = true
            } catch {
                print("SyncMapping: Error creating mapping - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    /// Update sync status for a mapping
    @discardableResult
    func updateStatus(localId: Int, entityType: SyncEntityType, status: SyncStatus) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            let now = Int(Date().timeIntervalSince1970 * 1000)

            do {
                let sql = """
                UPDATE sync_mappings SET sync_status = ?, modified_at = ?, last_synced = ?
                WHERE local_id = ? AND entity_type = ?
                """
                try db.run(sql, status.rawValue, now, status == .synced ? now : nil, localId, entityType.rawValue)
                print("SyncMapping: Updated status to \(status.rawValue) for local:\(localId)")
                result = true
            } catch {
                print("SyncMapping: Error updating status - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    /// Delete a mapping
    @discardableResult
    func deleteMapping(localId: Int, entityType: SyncEntityType) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            do {
                let sql = "DELETE FROM sync_mappings WHERE local_id = ? AND entity_type = ?"
                try db.run(sql, localId, entityType.rawValue)
                print("SyncMapping: Deleted mapping for local:\(localId)")
                result = true
            } catch {
                print("SyncMapping: Error deleting mapping - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    /// Delete a mapping by cloud ID
    @discardableResult
    func deleteMapping(cloudId: String, entityType: SyncEntityType) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            do {
                let sql = "DELETE FROM sync_mappings WHERE cloud_id = ? AND entity_type = ?"
                try db.run(sql, cloudId, entityType.rawValue)
                print("SyncMapping: Deleted mapping for cloud:\(cloudId)")
                result = true
            } catch {
                print("SyncMapping: Error deleting mapping - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    /// Clear all mappings (for logout/reset)
    @discardableResult
    func clearAllMappings() -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            do {
                let sql = "DELETE FROM sync_mappings"
                try db.run(sql)
                print("SyncMapping: Cleared all mappings")
                result = true
            } catch {
                print("SyncMapping: Error clearing mappings - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    // MARK: - Batch Operations

    /// Mark all entities of a type as pending upload
    func markAllPendingUpload(entityType: SyncEntityType) {
        guard let db = db else { return }

        let now = Int(Date().timeIntervalSince1970 * 1000)

        do {
            let sql = """
            UPDATE sync_mappings SET sync_status = ?, modified_at = ?
            WHERE entity_type = ?
            """
            try db.run(sql, SyncStatus.pendingUpload.rawValue, now, entityType.rawValue)
            print("SyncMapping: Marked all \(entityType.rawValue) as pending upload")
        } catch {
            print("SyncMapping: Error marking pending upload - \(error)")
        }
    }

    // MARK: - ID Generation

    /// Generate the next available local ID for an entity type
    func generateLocalId(entityType: SyncEntityType) -> Int {
        // This finds the maximum existing local ID and adds 1
        // For notes and categories, we need to check their respective tables too

        switch entityType {
        case .note:
            let existingNotes = NoteRecords.instance.getAllNotes()
            let maxNoteId = existingNotes.map { $0.noteId }.max() ?? 0
            return maxNoteId + 1

        case .category:
            let existingCategories = CategoryRecords.instance.getCategories()
            let maxCategoryId = existingCategories.map { $0.categoryId }.max() ?? 0
            return maxCategoryId + 1
        }
    }
}
