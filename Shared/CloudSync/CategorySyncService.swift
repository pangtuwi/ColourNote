//
//  CategorySyncService.swift
//  ColourNote
//
//  Handles synchronization of categories with the cloud
//

import Foundation

// MARK: - Category Sync Error
enum CategorySyncError: Error, LocalizedError {
    case uploadFailed(String)
    case downloadFailed(String)
    case mappingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Failed to upload category: \(message)"
        case .downloadFailed(let message):
            return "Failed to download categories: \(message)"
        case .mappingFailed:
            return "Failed to create category mapping"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Category Sync Service
class CategorySyncService {

    // MARK: - Singleton
    static let shared = CategorySyncService()

    // MARK: - Properties
    private let networkManager = NetworkManager.shared
    private let syncMapping = SyncMapping.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - Upload Methods

    /// Upload all local categories to the cloud
    func uploadAllCategories(completion: @escaping (Result<Int, CategorySyncError>) -> Void) {
        let categories = CategoryRecords.instance.getCategories()
        var uploadedCount = 0
        var lastError: CategorySyncError?

        let group = DispatchGroup()

        for category in categories {
            group.enter()

            // Check if category already has a cloud mapping
            if let cloudId = syncMapping.getCloudId(localId: category.categoryId, entityType: .category) {
                // Update existing cloud category
                updateCloudCategory(localCategory: category, cloudId: cloudId) { result in
                    switch result {
                    case .success:
                        uploadedCount += 1
                    case .failure(let error):
                        lastError = error
                    }
                    group.leave()
                }
            } else {
                // Create new cloud category
                createCloudCategory(localCategory: category) { result in
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
                print("CategorySyncService: Uploaded \(uploadedCount) categories")
                completion(.success(uploadedCount))
            }
        }
    }

    /// Upload a single category to the cloud
    func uploadCategory(_ category: Category, completion: @escaping (Result<String, CategorySyncError>) -> Void) {
        if let cloudId = syncMapping.getCloudId(localId: category.categoryId, entityType: .category) {
            updateCloudCategory(localCategory: category, cloudId: cloudId, completion: completion)
        } else {
            createCloudCategory(localCategory: category, completion: completion)
        }
    }

    private func createCloudCategory(localCategory: Category, completion: @escaping (Result<String, CategorySyncError>) -> Void) {
        print("CategorySyncService: Creating cloud category - name: '\(localCategory.categoryName)', colorHex: '\(localCategory.colorHex)', sortOrder: \(localCategory.sortOrder)")
        let request = CreateCategoryRequest.from(localCategory: localCategory)

        networkManager.post(
            endpoint: APIConfig.Endpoints.categories,
            body: request,
            requiresAuth: true
        ) { [weak self] (result: Result<CloudCategory, NetworkError>) in
            switch result {
            case .success(let cloudCategory):
                // Create mapping - server returns the category directly
                let cloudId = cloudCategory.id
                self?.syncMapping.createMapping(
                    localId: localCategory.categoryId,
                    cloudId: cloudId,
                    entityType: .category,
                    status: .synced
                )
                print("CategorySyncService: Created cloud category \(cloudId) for local \(localCategory.categoryId)")
                completion(.success(cloudId))

            case .failure(let error):
                print("CategorySyncService: Failed to create cloud category - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    private func updateCloudCategory(localCategory: Category, cloudId: String, completion: @escaping (Result<String, CategorySyncError>) -> Void) {
        let request = CreateCategoryRequest.from(localCategory: localCategory)

        // Server returns a message response for updates, not the category object
        networkManager.put(
            endpoint: APIConfig.Endpoints.category(id: cloudId),
            body: request,
            requiresAuth: true
        ) { [weak self] (result: Result<SuccessMessageResponse, NetworkError>) in
            switch result {
            case .success:
                self?.syncMapping.updateStatus(
                    localId: localCategory.categoryId,
                    entityType: .category,
                    status: .synced
                )
                print("CategorySyncService: Updated cloud category \(cloudId)")
                completion(.success(cloudId))

            case .failure(let error):
                print("CategorySyncService: Failed to update cloud category - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Download Methods

    /// Download all categories from the cloud
    func downloadAllCategories(completion: @escaping (Result<Int, CategorySyncError>) -> Void) {
        networkManager.get(
            endpoint: APIConfig.Endpoints.categories,
            requiresAuth: true
        ) { [weak self] (result: Result<[CloudCategory], NetworkError>) in
            switch result {
            case .success(let cloudCategories):
                var downloadedCount = 0

                for cloudCategory in cloudCategories {
                    if self?.processCloudCategory(cloudCategory) == true {
                        downloadedCount += 1
                    }
                }

                print("CategorySyncService: Downloaded \(downloadedCount) categories")
                completion(.success(downloadedCount))

            case .failure(let error):
                print("CategorySyncService: Failed to download categories - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    /// Process a single cloud category (create or update locally)
    private func processCloudCategory(_ cloudCategory: CloudCategory) -> Bool {
        print("CategorySyncService: Processing cloud category - id: \(cloudCategory.id), name: '\(cloudCategory.categoryName)', colorHex: '\(cloudCategory.colorHex ?? "nil")'")

        // Check if we already have this cloud category mapped locally
        if let localId = syncMapping.getLocalId(cloudId: cloudCategory.id, entityType: .category) {
            // Update existing local category
            return updateLocalCategory(cloudCategory: cloudCategory, localId: localId)
        } else {
            // Create new local category
            return createLocalCategory(cloudCategory: cloudCategory)
        }
    }

    private func createLocalCategory(cloudCategory: CloudCategory) -> Bool {
        // First, check if a category with the same name already exists locally
        let existingCategories = CategoryRecords.instance.getCategories()
        if let existingCategory = existingCategories.first(where: {
            $0.categoryName.lowercased() == cloudCategory.categoryName.lowercased()
        }) {
            // Category with same name exists - create mapping and update with cloud data
            syncMapping.createMapping(
                localId: existingCategory.categoryId,
                cloudId: cloudCategory.id,
                entityType: .category,
                status: .synced
            )

            // Update the existing category with cloud data (including color)
            let updatedCategory = Category(
                categoryId: existingCategory.categoryId,
                categoryName: cloudCategory.categoryName,
                colorHex: cloudCategory.colorHex ?? existingCategory.colorHex,
                sortOrder: cloudCategory.sortOrder ?? existingCategory.sortOrder,
                isProtected: (cloudCategory.isProtected ?? 0) != 0 ? true : existingCategory.isProtected
            )
            _ = CategoryRecords.instance.updateCategory(category: updatedCategory)

            print("CategorySyncService: Mapped and updated existing local category \(existingCategory.categoryId) to cloud \(cloudCategory.id)")
            return true
        }

        // Generate a new local ID
        let newLocalId = syncMapping.generateLocalId(entityType: .category)

        // Create the local category
        let localCategory = Category(
            categoryId: newLocalId,
            categoryName: cloudCategory.categoryName,
            colorHex: cloudCategory.colorHex ?? "#FFFFFF",
            sortOrder: cloudCategory.sortOrder ?? 0,
            isProtected: (cloudCategory.isProtected ?? 0) != 0
        )

        // Insert into database
        let result = CategoryRecords.instance.insertCategory(category: localCategory)

        if result > 0 {
            // Create mapping
            syncMapping.createMapping(
                localId: newLocalId,
                cloudId: cloudCategory.id,
                entityType: .category,
                status: .synced
            )
            print("CategorySyncService: Created local category \(newLocalId) from cloud \(cloudCategory.id)")
            return true
        }

        print("CategorySyncService: Failed to create local category from cloud \(cloudCategory.id)")
        return false
    }

    private func updateLocalCategory(cloudCategory: CloudCategory, localId: Int) -> Bool {
        // Get the existing local category
        guard let _ = CategoryRecords.instance.getCategory(searchCategoryId: localId) else {
            return false
        }

        // For categories, we don't have a modified timestamp locally, so always update
        // In a production app, you'd add a modified_at column to categories table

        // Update the local category
        let updatedCategory = Category(
            categoryId: localId,
            categoryName: cloudCategory.categoryName,
            colorHex: cloudCategory.colorHex ?? "#FFFFFF",
            sortOrder: cloudCategory.sortOrder ?? 0,
            isProtected: (cloudCategory.isProtected ?? 0) != 0
        )

        let result = CategoryRecords.instance.updateCategory(category: updatedCategory)

        if result > 0 {
            syncMapping.updateStatus(localId: localId, entityType: .category, status: .synced)
            print("CategorySyncService: Updated local category \(localId) from cloud")
            return true
        }

        return false
    }

    // MARK: - Delete Methods

    /// Delete a category from the cloud
    func deleteCloudCategory(localId: Int, completion: @escaping (Result<Void, CategorySyncError>) -> Void) {
        guard let cloudId = syncMapping.getCloudId(localId: localId, entityType: .category) else {
            // No cloud mapping, nothing to delete
            completion(.success(()))
            return
        }

        networkManager.delete(
            endpoint: APIConfig.Endpoints.category(id: cloudId),
            requiresAuth: true
        ) { [weak self] result in
            switch result {
            case .success:
                // Remove mapping
                self?.syncMapping.deleteMapping(localId: localId, entityType: .category)
                print("CategorySyncService: Deleted cloud category \(cloudId)")
                completion(.success(()))

            case .failure(let error):
                print("CategorySyncService: Failed to delete cloud category - \(error)")
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Sync Status Methods

    /// Mark a category as needing upload
    func markForUpload(categoryId: Int) {
        if syncMapping.isSynced(localId: categoryId, entityType: .category) {
            syncMapping.updateStatus(localId: categoryId, entityType: .category, status: .pendingUpload)
        }
    }

    /// Get categories that need to be uploaded
    func getCategoriesPendingUpload() -> [Category] {
        let pendingMappings = syncMapping.getMappings(withStatus: .pendingUpload, entityType: .category)
        var categories: [Category] = []

        for mapping in pendingMappings {
            if let category = CategoryRecords.instance.getCategory(searchCategoryId: mapping.localId) {
                categories.append(category)
            }
        }

        return categories
    }

    /// Get all local categories without cloud mappings (new categories)
    func getUnsyncedCategories() -> [Category] {
        let allCategories = CategoryRecords.instance.getCategories()
        return allCategories.filter { category in
            !syncMapping.isSynced(localId: category.categoryId, entityType: .category)
        }
    }
}
