//
//  CategoryRecords.swift
//  ColourNote
//
//  Created by Claude Code on 14/11/2025.
//

import Foundation
import SQLite

class CategoryRecords {

    static let instance = CategoryRecords()

    private var db: Connection?

    private let concurrentDBQueue = DispatchQueue(
        label: "com.colornote.categoryqueue",
        attributes: .concurrent)

    let categories = Table("categories")
    let categoryId = SQLite.Expression<Int>("category_id")
    let categoryUUID = SQLite.Expression<String?>("uuid")
    let categoryName = SQLite.Expression<String>("category_name")
    let colorHex = SQLite.Expression<String>("color_hex")
    let sortOrder = SQLite.Expression<Int>("sort_order")
    let isProtected = SQLite.Expression<Int>("is_protected")
    let modifiedAt = SQLite.Expression<Int?>("modified_at")

    private let categorySchemaVersionKey = "CategoryDatabaseSchemaVersion"
    private let currentCategorySchemaVersion = 3

    private init() {
        openDatabase()
        migrateCategorySchemaIfNeeded()
    }

    func openDatabase() {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("colornote.db")
                .path

            db = try Connection(fileURL)
            // Enable WAL mode for better concurrent access
            try db?.execute("PRAGMA journal_mode = WAL")
            print("CategoryRecords: Database opened successfully with WAL mode")
        } catch {
            db = nil
            print("CategoryRecords: Error opening database - \(error)")
        }
    }

    func createCategoriesTable() {
        guard let db = db else {
            print("CategoryRecords: Database not available")
            return
        }

        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS categories (
            category_id INTEGER PRIMARY KEY,
            uuid TEXT,
            category_name TEXT NOT NULL DEFAULT '',
            color_hex TEXT NOT NULL DEFAULT '#FFFFFF',
            sort_order INTEGER DEFAULT 0,
            is_protected INTEGER DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_category_sort ON categories(sort_order);
        """

        do {
            try db.execute(createTableSQL)
            print("CategoryRecords: Categories table created successfully")
        } catch {
            print("CategoryRecords: Error creating categories table - \(error)")
        }
    }

    func migrateCategorySchemaIfNeeded() {
        guard let db = db else {
            print("CategoryRecords: Database not available for migration")
            return
        }

        let savedSchemaVersion = UserDefaults.standard.integer(forKey: categorySchemaVersionKey)

        if savedSchemaVersion < currentCategorySchemaVersion {
            print("CategoryRecords: Running migration from version \(savedSchemaVersion) to \(currentCategorySchemaVersion)")

            // Migration v1: Add is_protected column
            if savedSchemaVersion < 1 {
                print("CategoryRecords: Running migration to version 1: Adding is_protected column")
                do {
                    try db.execute("ALTER TABLE categories ADD COLUMN is_protected INTEGER DEFAULT 0")
                    print("CategoryRecords: Added is_protected column to categories table")
                } catch {
                    print("CategoryRecords: is_protected column may already exist or error: \(error)")
                }
                UserDefaults.standard.set(1, forKey: categorySchemaVersionKey)
                print("CategoryRecords: Migration to version 1 completed")
            }
            // Migration v2: Add uuid column
            if savedSchemaVersion < 2 {
                print("CategoryRecords: Running migration to version 2: Adding uuid column")
                do {
                    try db.execute("ALTER TABLE categories ADD COLUMN uuid TEXT")
                    print("CategoryRecords: Added uuid column to categories table")

                    // Backfill UUIDs for existing rows with NULL uuid
                    do {
                        for row in try db.prepare("SELECT category_id FROM categories WHERE uuid IS NULL") {
                            if let idValue = row[0] as? Int64 {
                                let newUUID = UUID().uuidString
                                try db.run("UPDATE categories SET uuid = ? WHERE category_id = ?", newUUID, idValue)
                            }
                        }
                        print("CategoryRecords: Backfilled UUIDs for existing categories")
                    } catch {
                        print("CategoryRecords: Error backfilling UUIDs - \(error)")
                    }
                } catch {
                    print("CategoryRecords: uuid column may already exist or error: \(error)")
                }
                UserDefaults.standard.set(2, forKey: categorySchemaVersionKey)
                print("CategoryRecords: Migration to version 2 completed")
            }

            // Migration v3: Add modified_at column and UUID index
            if savedSchemaVersion < 3 {
                print("CategoryRecords: Running migration to version 3: Adding modified_at column and UUID index")
                do {
                    // Add modified_at column
                    try db.execute("ALTER TABLE categories ADD COLUMN modified_at INTEGER DEFAULT NULL")
                    print("CategoryRecords: Added modified_at column to categories table")

                    // Backfill modified_at with current timestamp for existing rows
                    let now = Int(Date().timeIntervalSince1970 * 1000)
                    try db.run("UPDATE categories SET modified_at = ? WHERE modified_at IS NULL", now)
                    print("CategoryRecords: Backfilled modified_at for existing categories")
                } catch {
                    print("CategoryRecords: modified_at column may already exist or error: \(error)")
                }

                do {
                    // Create index on uuid for faster lookups
                    try db.execute("CREATE INDEX IF NOT EXISTS idx_categories_uuid ON categories(uuid)")
                    print("CategoryRecords: Created index on uuid column")
                } catch {
                    print("CategoryRecords: Error creating uuid index: \(error)")
                }

                UserDefaults.standard.set(3, forKey: categorySchemaVersionKey)
                print("CategoryRecords: Migration to version 3 completed")
            }
        } else {
            print("CategoryRecords: Schema is up to date at version \(savedSchemaVersion)")
        }
    }

    func getCategories() -> [Category] {
        var categoriesList = [Category]()

        guard let db = db else {
            print("CategoryRecords: Database not available")
            return categoriesList
        }

        do {
            for category in try db.prepare(categories.order(sortOrder)) {
                categoriesList.append(Category(
                    categoryId: category[categoryId],
                    uuid: category[categoryUUID] ?? "",
                    categoryName: category[categoryName],
                    colorHex: category[colorHex],
                    sortOrder: category[sortOrder],
                    isProtected: category[isProtected] != 0,
                    modifiedAt: category[modifiedAt]
                ))
            }
        } catch {
            print("CategoryRecords: Select failed in getCategories() - \(error)")
        }

        print("CategoryRecords: Got \(categoriesList.count) categories")
        return categoriesList
    }

    func getCategory(searchCategoryId: Int) -> Category? {
        guard let db = db else {
            print("CategoryRecords: Database not available")
            return nil
        }

        var categoriesFound = [Category]()

        do {
            for category in try db.prepare(categories.filter(categoryId == searchCategoryId)) {
                categoriesFound.append(Category(
                    categoryId: category[categoryId],
                    uuid: category[categoryUUID] ?? "",
                    categoryName: category[categoryName],
                    colorHex: category[colorHex],
                    sortOrder: category[sortOrder],
                    isProtected: category[isProtected] != 0,
                    modifiedAt: category[modifiedAt]
                ))
            }
        } catch {
            print("CategoryRecords: Select failed in getCategory() - \(error)")
        }

        return categoriesFound.first
    }

    func categoryExists(searchId: Int) -> Bool {
        guard let db = db else {
            print("CategoryRecords: Database not available")
            return false
        }

        do {
            for _ in try db.prepare(categories.filter(categoryId == searchId)) {
                return true
            }
        } catch {
            print("CategoryRecords: Search failed in categoryExists - \(error)")
        }

        return false
    }

    func insertCategory(category: Category) -> Int64 {
        var result: Int64 = -1
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            do {
                let now = category.modifiedAt ?? Int(Date().timeIntervalSince1970 * 1000)
                let sql = """
                INSERT INTO categories (category_id, uuid, category_name, color_hex, sort_order, is_protected, modified_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """
                try db.run(sql, category.categoryId, category.uuid, category.categoryName, category.colorHex, category.sortOrder, category.isProtected ? 1 : 0, now)
                print("CategoryRecords: Inserted category with ID \(category.categoryId), UUID \(category.uuid)")
                result = Int64(category.categoryId)
            } catch {
                print("CategoryRecords: Insert failed in insertCategory - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func updateCategory(category: Category) -> Int {
        var result: Int = -1
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            if self.categoryExists(searchId: category.categoryId) {
                do {
                    let now = Int(Date().timeIntervalSince1970 * 1000)
                    let sql = """
                    UPDATE categories SET category_name = ?, color_hex = ?, sort_order = ?, is_protected = ?, uuid = ?, modified_at = ? WHERE category_id = ?
                    """
                    try db.run(sql, category.categoryName, category.colorHex, category.sortOrder, category.isProtected ? 1 : 0, category.uuid, now, category.categoryId)
                    print("CategoryRecords: Updated category with ID \(category.categoryId), UUID \(category.uuid)")
                    result = category.categoryId
                } catch {
                    print("CategoryRecords: Update failed in updateCategory - \(error)")
                }
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func deleteCategory(categoryId: Int) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                semaphore.signal()
                return
            }

            do {
                let sql = "DELETE FROM categories WHERE category_id = ?"
                try db.run(sql, categoryId)
                print("CategoryRecords: Deleted category with ID \(categoryId)")
                result = true
            } catch {
                print("CategoryRecords: Delete failed in deleteCategory - \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }

    func insertDefaultCategories() {
        let defaultCategories = Category.getDefaultCategories()

        for category in defaultCategories {
            if !categoryExists(searchId: category.categoryId) {
                _ = insertCategory(category: category)
            }
        }

        print("CategoryRecords: Inserted default categories")
    }
}
