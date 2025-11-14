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

    private var displayedNoteID : Int = 0
    private var textHasChanged : Bool = false
    private var titleHasChanged : Bool = false

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
        textView.backgroundColor = Globals.CN_LIGHT_COLORS[note.colorIndex]
        textHasChanged = false
        titleHasChanged = false
        doneButton.isHidden = true
    }//displayData

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
