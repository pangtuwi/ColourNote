//
//  NoteViewController.swift
//  ColourNoteProj
//
//  Created by Paul Williams on 10/10/2021.
//  Copyright © 2021 Paul Williams. All rights reserved.
//


//https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift?page=2&tab=modifieddesc#tab-top
//https://www.hackingwithswift.com/read/19/7/fixing-the-keyboard-notificationcenter

import UIKit

class NoteDetailViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var categoryButton: UIButton!

    @IBAction func DeleteButtonPressed(_ sender: Any) {
        showDeleteConfirmation()
    }

    @IBAction func listButtonPressed(_ sender: Any) {
        saveNote()
        dismiss(animated: true)
    }

    @IBAction func categoryButtonPressed(_ sender: Any) {
        showCategoryPicker()
    }

    private var displayedNoteID : Int = 0
    private var textHasChanged : Bool = false
    private var titleHasChanged : Bool = false
    private var currentCategoryId: Int = 0

    var lastNoteID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        noteTitle.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)

        // Enable copy/paste for text editing
        textView.isEditable = true
        textView.isSelectable = true
        noteTitle.isEnabled = true

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        // Add observer for app backgrounding to ensure note is saved
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

    } //viewDidLoad

    @objc func titleDidChange() {
        titleHasChanged = true
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        textView.scrollIndicatorInsets = textView.contentInset

        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }

    @objc func appWillResignActive(notification: Notification) {
        // Save note when app is about to background to prevent data loss
        saveNote()
        print("Note auto-saved before app backgrounding")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        saveNote()
    } //touchesBegan
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if let note = NoteRecords.instance.getNote(searchNoteId:
            Globals.sharedInstance.noteIDToDisplay) ?? NoteRecords.instance.getLatestNote() {
            lastNoteID = note.noteId
            displayData(note: note)
        }
    }//viewDidAppear
        
    override func viewWillDisappear(_ animated: Bool) {
        saveNote()
    } //viewWillDisappear
    
    func displayData (note : Note) {
        noteTitle.text = note.noteName
        textView.text = note.noteText
        currentCategoryId = note.categoryId

        // Set title background and navigation bar color based on category
        if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
            let categoryColor = category.getColor()
            noteTitle.backgroundColor = categoryColor
            noteTitle.textColor = getContrastingTextColor(for: categoryColor)
            setNavigationBarColor(categoryColor)
            categoryButton?.setTitle(category.categoryName, for: .normal)
        } else {
            // Use old colorIndex for title and navigation bar if no category
            let color = Globals.CN_LIGHT_COLORS[note.colorIndex]
            noteTitle.backgroundColor = color
            noteTitle.textColor = getContrastingTextColor(for: color)
            setNavigationBarColor(color)
            categoryButton?.setTitle("No Category", for: .normal)
        }

        textHasChanged = false
        titleHasChanged = false
    }//displayData

    func setNavigationBarColor(_ color: UIColor) {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = color

        // Set title text color based on background brightness
        let textColor = getContrastingTextColor(for: color)
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: textColor]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // Set bar button items color
        navigationBar.tintColor = textColor
    }

    func getContrastingTextColor(for backgroundColor: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        // Return black for light backgrounds, white for dark backgrounds
        return luminance > 0.5 ? .black : .white
    }

    func saveNote() {
        if textHasChanged || titleHasChanged {
            if titleHasChanged {
                _ = NoteRecords.instance.updateNoteTitle(changedNoteId: lastNoteID, newTitle: noteTitle.text ?? "")
            }
            if textHasChanged {
                _ = NoteRecords.instance.updateNoteText(changedNoteId: lastNoteID, newText: textView.text)
            }
            textHasChanged = false
            titleHasChanged = false
            print("Note saved with ID: \(lastNoteID)")
        }
    }

    func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Delete Note",
            message: "Are you sure you want to delete this note? This action cannot be undone.",
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteNote()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func deleteNote() {
        if NoteRecords.instance.deleteNote(noteId: lastNoteID) {
            print("Note deleted with ID: \(lastNoteID)")
            dismiss(animated: true)
        } else {
            let alert = UIAlertController(
                title: "Delete Failed",
                message: "Could not delete note",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        textView.setNeedsDisplay()
        print("scrolling")
    }

    func showCategoryPicker() {
        let alert = UIAlertController(title: "Select Category", message: nil, preferredStyle: .actionSheet)

        // Get all categories
        let categories = CategoryRecords.instance.getCategories()

        // Add "No Category" option
        let noCategoryAction = UIAlertAction(title: "No Category", style: .default) { [weak self] _ in
            self?.updateCategory(categoryId: 0)
        }
        alert.addAction(noCategoryAction)

        // Add "Create New Category..." option
        let createNewAction = UIAlertAction(title: "Create New Category...", style: .default) { [weak self] _ in
            self?.showCreateCategoryFlow()
        }
        alert.addAction(createNewAction)

        // Add each category as an option
        for category in categories {
            let action = UIAlertAction(title: category.categoryName, style: .default) { [weak self] _ in
                self?.updateCategory(categoryId: category.categoryId)
            }
            alert.addAction(action)
        }

        // Add cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = categoryButton
            popoverController.sourceRect = categoryButton.bounds
        }

        present(alert, animated: true)
    }

    func updateCategory(categoryId: Int) {
        currentCategoryId = categoryId
        _ = NoteRecords.instance.updateNoteCategory(changedNoteId: lastNoteID, newCategoryId: categoryId)

        // Update title background, navigation bar color and category button
        if categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: categoryId) {
            let categoryColor = category.getColor()
            noteTitle.backgroundColor = categoryColor
            noteTitle.textColor = getContrastingTextColor(for: categoryColor)
            setNavigationBarColor(categoryColor)
            categoryButton?.setTitle(category.categoryName, for: .normal)
        } else {
            noteTitle.backgroundColor = .white
            noteTitle.textColor = .black
            setNavigationBarColor(.white)
            categoryButton?.setTitle("No Category", for: .normal)
        }
    }

    func showCreateCategoryFlow() {
        let alert = UIAlertController(
            title: "New Category",
            message: "Enter a name for the new category",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Category Name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
        }

        let nextAction = UIAlertAction(title: "Next", style: .default) { [weak self, weak alert] _ in
            guard let textField = alert?.textFields?.first,
                  let categoryName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !categoryName.isEmpty else {
                self?.showAlert(title: "Error", message: "Please enter a category name")
                return
            }

            // Validate name doesn't already exist
            let existingCategories = CategoryRecords.instance.getCategories()
            if existingCategories.contains(where: { $0.categoryName.lowercased() == categoryName.lowercased() }) {
                self?.showAlert(title: "Error", message: "A category with this name already exists")
                return
            }

            // Proceed to color selection
            self?.showColorPickerForNewCategory(categoryName: categoryName)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(nextAction)
        alert.addAction(cancelAction)

        present(alert, animated: true) {
            // Auto-focus on text field
            alert.textFields?.first?.becomeFirstResponder()
        }
    }

    func showColorPickerForNewCategory(categoryName: String) {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = .white

        // Store category name in title for later retrieval
        colorPicker.title = categoryName

        // Use tag = -1 to indicate this is a new category
        colorPicker.view.tag = -1

        present(colorPicker, animated: true)
    }

    func saveNewCategoryAndSelect(categoryName: String, color: UIColor) {
        // Generate unique category ID using timestamp
        let newCategoryId = Int(Date().timeIntervalSince1970 * 1000)

        // Calculate sort order (max + 1)
        let existingCategories = CategoryRecords.instance.getCategories()
        let maxSortOrder = existingCategories.map { $0.sortOrder }.max() ?? 0

        // Create category object
        let newCategory = Category(
            categoryId: newCategoryId,
            categoryName: categoryName,
            colorHex: color.toHexString(),
            sortOrder: maxSortOrder + 1
        )

        // Insert into database
        let result = CategoryRecords.instance.insertCategory(category: newCategory)

        if result > 0 {
            print("Successfully created category '\(categoryName)' with ID \(newCategoryId)")

            // Post notification to refresh other views
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NotesNotification.contentUpdated, object: nil)
            }

            // Auto-select the newly created category for this note
            updateCategory(categoryId: newCategoryId)

            // Show success feedback
            showSuccessToast(message: "Category '\(categoryName)' created")
        } else {
            print("Failed to create category '\(categoryName)'")
            showAlert(title: "Error", message: "Failed to create category. Please try again.")
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showSuccessToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.numberOfLines = 0
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true

        // Calculate size and position
        let maxSize = CGSize(width: view.bounds.width - 60, height: 100)
        let size = toast.sizeThatFits(maxSize)
        let width = min(size.width + 30, view.bounds.width - 60)
        let height = size.height + 20

        toast.frame = CGRect(
            x: (view.bounds.width - width) / 2,
            y: view.bounds.height - 100,
            width: width,
            height: height
        )

        view.addSubview(toast)
        toast.alpha = 0

        // Animate in
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1.0
        }) { _ in
            // Auto-dismiss after 2 seconds
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        textHasChanged = true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Keyboard will appear
    }

    // MARK: - Copy/Paste Support

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Enable copy, cut, paste, select, and select all actions
        if action == #selector(UIResponderStandardEditActions.copy(_:)) ||
           action == #selector(UIResponderStandardEditActions.cut(_:)) ||
           action == #selector(UIResponderStandardEditActions.paste(_:)) ||
           action == #selector(UIResponderStandardEditActions.select(_:)) ||
           action == #selector(UIResponderStandardEditActions.selectAll(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }


// MARK: - Notification handlers
/*extension AnalysisDetailViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
       // displayData()
    }
} */

}

// MARK: - UIColorPickerViewControllerDelegate
extension NoteDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // Only handle new category creation (tag == -1)
        guard viewController.view.tag == -1 else { return }

        guard let categoryName = viewController.title else {
            print("Error: Category name not found in color picker")
            return
        }

        let selectedColor = viewController.selectedColor

        // Save category and auto-select it
        saveNewCategoryAndSelect(categoryName: categoryName, color: selectedColor)
    }
}
