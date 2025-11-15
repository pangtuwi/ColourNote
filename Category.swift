//
//  Category.swift
//  ColourNote
//
//  Created by Claude Code on 14/11/2025.
//

import Foundation
import UIKit

class Category {
    var categoryId: Int
    var categoryName: String
    var colorHex: String
    var sortOrder: Int
    var isProtected: Bool

    init() {
        categoryId = 0
        categoryName = ""
        colorHex = "#FFFFFF"
        sortOrder = 0
        isProtected = false
    }

    init(categoryId: Int, categoryName: String, colorHex: String, sortOrder: Int, isProtected: Bool = false) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isProtected = isProtected
    }

    // Helper to convert hex string to UIColor
    func getColor() -> UIColor {
        return UIColor(hexString: colorHex) ?? .white
    }

    // Default categories
    static func getDefaultCategories() -> [Category] {
        return [
            Category(categoryId: 1, categoryName: "Personal", colorHex: "#FFD700", sortOrder: 1),
            Category(categoryId: 2, categoryName: "Work", colorHex: "#87CEEB", sortOrder: 2),
            Category(categoryId: 3, categoryName: "Ideas", colorHex: "#98FB98", sortOrder: 3),
            Category(categoryId: 4, categoryName: "Todo", colorHex: "#FFB6C1", sortOrder: 4),
            Category(categoryId: 5, categoryName: "Important", colorHex: "#FFA07A", sortOrder: 5)
        ]
    }
}

// Extension to create UIColor from hex string
extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }

        guard hex.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255)
        return String(format: "#%06X", rgb)
    }
}
