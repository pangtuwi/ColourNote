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
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var categoryButton: UIButton!

    @IBAction func doneButtonClick(_ sender: Any) {
        self.view.endEditing(true)
        saveNote()
        doneButton.isHidden = true
    }

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

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)


    } //viewDidLoad

    @objc func titleDidChange() {
        titleHasChanged = true
        doneButton.isHidden = false
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

        // Always use light grey for text area
        textView.backgroundColor = UIColor.systemGray6

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
        doneButton.isHidden = true
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

        // Update UI - text area always stays light grey
        textView.backgroundColor = UIColor.systemGray6

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

    func textViewDidChange(_ textView: UITextView) {
        textHasChanged = true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        doneButton.isHidden = false
    }
    


// MARK: - Notification handlers
/*extension AnalysisDetailViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
       // displayData()
    }
} */

}
