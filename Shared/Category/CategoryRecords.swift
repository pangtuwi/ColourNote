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
    let categoryName = SQLite.Expression<String>("category_name")
    let colorHex = SQLite.Expression<String>("color_hex")
    let sortOrder = SQLite.Expression<Int>("sort_order")

    private init() {
        openDatabase()
    }

    func openDatabase() {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("colornote.db")
                .path

            db = try Connection(fileURL)
            print("CategoryRecords: Database opened successfully")
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
            category_name TEXT NOT NULL DEFAULT '',
            color_hex TEXT NOT NULL DEFAULT '#FFFFFF',
            sort_order INTEGER DEFAULT 0
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
                    categoryName: category[categoryName],
                    colorHex: category[colorHex],
                    sortOrder: category[sortOrder]
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
                    categoryName: category[categoryName],
                    colorHex: category[colorHex],
                    sortOrder: category[sortOrder]
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
                let sql = """
                INSERT INTO categories (category_id, category_name, color_hex, sort_order)
                VALUES (?, ?, ?, ?)
                """
                try db.run(sql, category.categoryId, category.categoryName, category.colorHex, category.sortOrder)
                print("CategoryRecords: Inserted category with ID \(category.categoryId)")
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

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, let db = self.db else {
                return
            }

            if self.categoryExists(searchId: category.categoryId) {
                do {
                    let sql = """
                    UPDATE categories SET category_name = ?, color_hex = ?, sort_order = ? WHERE category_id = ?
                    """
                    try db.run(sql, category.categoryName, category.colorHex, category.sortOrder, category.categoryId)
                    print("CategoryRecords: Updated category with ID \(category.categoryId)")
                    result = category.categoryId
                } catch {
                    print("CategoryRecords: Update failed in updateCategory - \(error)")
                }
            }
        }

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
