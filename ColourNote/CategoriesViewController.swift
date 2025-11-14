//
//  CategoriesViewController.swift
//  ColourNote
//
//  Created by Claude Code on 14/11/2025.
//

import UIKit

class CategoriesViewController: UITableViewController {

    var categories: [Category] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Categories"
        navigationItem.largeTitleDisplayMode = .never

        // Add button to create new category
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCategoryTapped))
        navigationItem.rightBarButtonItem = addButton

        // Load categories
        loadCategories()
    }

    func loadCategories() {
        categories = CategoryRecords.instance.getCategories()
        tableView.reloadData()
    }

    @objc func addCategoryTapped() {
        showCategoryEditor(category: nil, isNew: true)
    }

    func showCategoryEditor(category: Category?, isNew: Bool) {
        let alert = UIAlertController(title: isNew ? "New Category" : "Edit Category",
                                     message: "Enter category details",
                                     preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Category Name"
            textField.text = category?.categoryName
        }

        alert.addAction(UIAlertAction(title: "Choose Color", style: .default) { [weak self, weak alert] _ in
            guard let nameField = alert?.textFields?.first,
                  let name = nameField.text, !name.isEmpty else {
                self?.showAlert(title: "Error", message: "Please enter a category name first")
                return
            }

            self?.showColorPicker(category: category, categoryName: name, isNew: isNew)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func showColorPicker(category: Category?, categoryName: String, isNew: Bool) {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = category?.getColor() ?? .white

        // Store category info for later use
        colorPicker.view.tag = isNew ? -1 : (category?.categoryId ?? 0)
        colorPicker.title = categoryName

        present(colorPicker, animated: true)
    }

    func saveCategory(categoryId: Int?, name: String, color: UIColor, isNew: Bool) {
        if isNew {
            // Generate new category ID
            let newCategoryId = Int(Date().timeIntervalSince1970 * 1000)
            let maxSortOrder = categories.map { $0.sortOrder }.max() ?? 0
            let newCategory = Category(
                categoryId: newCategoryId,
                categoryName: name,
                colorHex: color.toHexString(),
                sortOrder: maxSortOrder + 1
            )
            _ = CategoryRecords.instance.insertCategory(category: newCategory)
        } else if let categoryId = categoryId,
                  let existingCategory = CategoryRecords.instance.getCategory(searchCategoryId: categoryId) {
            existingCategory.categoryName = name
            existingCategory.colorHex = color.toHexString()
            _ = CategoryRecords.instance.updateCategory(category: existingCategory)
        }

        loadCategories()
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") ?? UITableViewCell(style: .default, reuseIdentifier: "CategoryCell")

        let category = categories[indexPath.row]
        cell.textLabel?.text = category.categoryName
        cell.backgroundColor = category.getColor()
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        showCategoryEditor(category: category, isNew: false)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = categories[indexPath.row]

            let alert = UIAlertController(
                title: "Delete Category",
                message: "Are you sure you want to delete '\(category.categoryName)'? Notes using this category will be uncategorized.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                if CategoryRecords.instance.deleteCategory(categoryId: category.categoryId) {
                    self?.loadCategories()
                }
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            present(alert, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedCategory = categories.remove(at: sourceIndexPath.row)
        categories.insert(movedCategory, at: destinationIndexPath.row)

        // Update sort order for all categories
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
            _ = CategoryRecords.instance.updateCategory(category: category)
        }
    }
}

// MARK: - Color Picker Delegate
extension CategoriesViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let isNew = viewController.view.tag == -1
        let categoryId = isNew ? nil : viewController.view.tag
        let categoryName = viewController.title ?? "Untitled"
        let selectedColor = viewController.selectedColor

        saveCategory(categoryId: categoryId, name: categoryName, color: selectedColor, isNew: isNew)
    }
}
