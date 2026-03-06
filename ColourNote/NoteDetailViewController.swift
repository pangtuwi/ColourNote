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

class NoteDetailViewController: UIViewController, UITextViewDelegate, UIColorPickerViewControllerDelegate {

    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var categoryButton: UIButton!

    private var modeToggleItem: UIBarButtonItem!
    private var bottomToolbar: UIToolbar!
    private let toolbarHeight: CGFloat = 44
    private var toolbarBottomConstraint: NSLayoutConstraint!

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

    // Markdown support
    private enum DisplayMode {
        case edit
        case preview
    }

    private var currentMode: DisplayMode = .edit
    private var markdownContent: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        noteTitle.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
        noteTitle.accessibilityIdentifier = "noteTitleField"
        listButton.accessibilityIdentifier = "listButton"
        textView.accessibilityIdentifier = "noteTextView"

        // Enable copy/paste for text editing
        textView.isEditable = true
        textView.isSelectable = true
        noteTitle.isEnabled = true

        // Drag down on the text view to dismiss the keyboard interactively
        textView.keyboardDismissMode = .interactive

        // Style the list button as a round button
        styleListButton()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        // Add observer for app backgrounding to ensure note is saved
        notificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        // Set up bottom toolbar with delete, share, and mode toggle
        setupBottomToolbar()

        // Set up Markdown editing/preview views
        setupMarkdownViews()

        // Hide storyboard delete button (delete is now in bottom toolbar)
        deleteButton.isHidden = true

        // Initial text view inset to clear the toolbar
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)

    } //viewDidLoad

    @objc func titleDidChange() {
        titleHasChanged = true
    }

    func styleListButton() {
        guard let button = listButton else { return }

        // Make it circular
        button.layer.cornerRadius = 18  // Half of 36pt height
        button.clipsToBounds = true

        // Add background color
        button.backgroundColor = .systemGray5

        // Set tint color for the chevron icon
        button.tintColor = .label
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25

        if notification.name == UIResponder.keyboardWillHideNotification {
            toolbarBottomConstraint.constant = 0
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
        } else {
            let keyboardOffset = keyboardViewEndFrame.height - view.safeAreaInsets.bottom + 8
            toolbarBottomConstraint.constant = -keyboardOffset
            textView.contentInset = UIEdgeInsets(top: 0, left: 0,
                bottom: keyboardOffset + toolbarHeight, right: 0)
        }

        textView.scrollIndicatorInsets = textView.contentInset

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }

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
        markdownContent = note.noteText  // Store Markdown content
        currentCategoryId = note.categoryId

        // Display content based on current mode
        if currentMode == .edit {
            textView.text = markdownContent
        } else {
            renderMarkdownPreview()
        }

        // Set category button color based on category
        noteTitle.backgroundColor = .systemBackground
        noteTitle.textColor = .label

        if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
            let categoryColor = category.getColor()
            categoryButton?.backgroundColor = categoryColor
            categoryButton?.setTitleColor(getContrastingTextColor(for: categoryColor), for: .normal)
            categoryButton?.setTitle(category.categoryName, for: .normal)
            categoryButton?.layer.cornerRadius = 8
            categoryButton?.clipsToBounds = true
        } else {
            // Use default styling when no category is set
            categoryButton?.backgroundColor = .systemGray5
            categoryButton?.setTitleColor(.label, for: .normal)
            categoryButton?.setTitle("No Category", for: .normal)
            categoryButton?.layer.cornerRadius = 8
            categoryButton?.clipsToBounds = true
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
                // Get content - in edit mode use textView, in preview mode use stored markdownContent
                let currentContent = currentMode == .edit ? textView.text ?? "" : markdownContent
                _ = NoteRecords.instance.updateNoteText(changedNoteId: lastNoteID, newText: currentContent)
            }
            textHasChanged = false
            titleHasChanged = false
            print("Note saved with ID: \(lastNoteID)")
            NoteSyncService.shared.markForUpload(noteId: lastNoteID)
            SyncEngine.shared.syncIfNeeded()
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
            SyncEngine.shared.syncIfNeeded()
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

        // Update category button color
        if categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: categoryId) {
            let categoryColor = category.getColor()
            categoryButton?.backgroundColor = categoryColor
            categoryButton?.setTitleColor(getContrastingTextColor(for: categoryColor), for: .normal)
            categoryButton?.setTitle(category.categoryName, for: .normal)
        } else {
            categoryButton?.backgroundColor = .systemGray5
            categoryButton?.setTitleColor(.label, for: .normal)
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

        // Keep markdownContent in sync when editing
        if currentMode == .edit {
            markdownContent = textView.text
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Keyboard will appear
    }

    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Markdown Support

    /// Set up Markdown edit/preview toggle (minimal stub — toggle is in bottom toolbar)
    private func setupMarkdownViews() {
        currentMode = .edit
    }

    // MARK: - Bottom Toolbar

    private func setupBottomToolbar() {
        bottomToolbar = UIToolbar()
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbar)

        toolbarBottomConstraint = bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarBottomConstraint
        ])

        let deleteItem = UIBarButtonItem(image: UIImage(systemName: "trash"),
                                         style: .plain, target: self,
                                         action: #selector(DeleteButtonPressed(_:)))
        deleteItem.tintColor = .systemRed

        let shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                        style: .plain, target: self,
                                        action: #selector(shareNote))

        let flex1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flex2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        modeToggleItem = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(modeToggleTapped))
        updateToggleButtonIcon()

        bottomToolbar.items = [deleteItem, flex1, shareItem, flex2, modeToggleItem]
    }

    private func updateToggleButtonIcon() {
        let name = currentMode == .edit ? "eye" : "pencil.and.outline"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        modeToggleItem.image = UIImage(systemName: name, withConfiguration: config)
    }

    @objc private func modeToggleTapped() {
        let newMode: DisplayMode = currentMode == .edit ? .preview : .edit
        if currentMode == .edit { markdownContent = textView.text }
        switchMode(to: newMode)
        updateToggleButtonIcon()
    }

    @objc private func shareNote() {
        let content = currentMode == .edit ? (textView.text ?? "") : markdownContent
        let title = noteTitle.text ?? ""
        let shareText = title.isEmpty ? content : "\(title)\n\n\(content)"
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = bottomToolbar
            popover.sourceRect = bottomToolbar.bounds
        }
        present(vc, animated: true)
    }

    /// Switch between edit and preview modes
    private func switchMode(to mode: DisplayMode) {
        // Save current scroll position
        let scrollOffset = textView.contentOffset

        currentMode = mode

        switch mode {
        case .edit:
            // Enable editing
            textView.isEditable = true

            // Show raw markdown text
            textView.text = markdownContent
            textView.font = UIFont(name: "BaiJamjuree-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
            textView.textColor = .label

        case .preview:
            // Save current content
            markdownContent = textView.text

            // Disable editing in preview mode
            textView.isEditable = false

            // Render markdown
            renderMarkdownPreview()
        }

        // Restore scroll position
        textView.contentOffset = scrollOffset
    }

    /// Render Markdown to the text view
    private func renderMarkdownPreview() {
        // Get category color if available
        let categoryColor: UIColor? = {
            if currentCategoryId > 0,
               let category = CategoryRecords.instance.getCategory(searchCategoryId: currentCategoryId) {
                return category.getColor()
            }
            return nil
        }()

        // Render Markdown
        if let rendered = MarkdownRenderer.shared.render(markdown: markdownContent, categoryColor: categoryColor) {
            textView.attributedText = rendered
        } else {
            // Fallback: show plain text
            textView.text = markdownContent
        }
    }

    // MARK: - UIColorPickerViewControllerDelegate

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
