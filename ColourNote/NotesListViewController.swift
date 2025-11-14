//
//  SecondViewController.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://www.raywenderlich.com/464-storyboards-tutorial-for-ios-part-1
// https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
// https://developer.apple.com/library/archive/documentation/ToolsLanguages/Conceptual/Xcode_Overview/ConnectingObjectstoCode.html
// https://stackoverflow.com/questions/56662886/how-to-filter-array-model-data-based-on-user-input-in-text-field


import UIKit
//import SwiftyDropbox

class NotesListViewController: UITableViewController, UITextFieldDelegate {
    
    var notes : [Note] = []
   // let array : Array<String> = ["1", "2", "3"];
    var filteredNotes = [Note]() {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    @IBOutlet weak var StatusLabel : UILabel!
    @IBOutlet weak var SearchTextEditor: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        SearchTextEditor.delegate = self
       // filteredNotes = notes

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)

       // _ = ActivityRecords.instance.deleteActivity(cActivityId : 3923275188)
       //    DataLoader.sharedInstance.deleteFromCache(ActivityId: 3923275188)

        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pulll to refresh")
        refreshControl!.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        // Set navigation bar title
        title = "ColourNote"
        navigationItem.largeTitleDisplayMode = .never

        // Add hamburger menu button to navigation bar (left side)
        let menuButton = UIBarButtonItem(title: "≡", style: .plain, target: self, action: #selector(menuButtonTapped))
        menuButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28)], for: .normal)
        navigationItem.leftBarButtonItem = menuButton

        // Add new note button to navigation bar (right side)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNoteButtonTapped))
        navigationItem.rightBarButtonItem = addButton

        //updateTrainingList()
        updateNotesList()
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(true)
        // Refresh the list when returning from note detail view
        updateNotesList()
    } //viewDidAppear
    
    func updateNotesList() -> Void {
        notes = NoteRecords.instance.getNotes()
        notes.sort { $0.editedTime > $1.editedTime }
        filteredNotes = notes
        
        tableView.reloadData()
       // StatusLabel.text = "\(notes.count) Notes"
        StatusLabel.text = "\(filteredNotes.count) Notes"
    }
    
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        DispatchQueue.main.async {
            self.StatusLabel.text = "Checking Server for new files..."
        }

        DispatchQueue.global(qos: .utility).async {
            // DataLoader.sharedInstance.requestSync() // Legacy fitness tracking
        }


        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                return
            }
            // DataLoader.sharedInstance.loadNewActivityList(whenDone: self.gotList) // Legacy fitness tracking
            // 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  [weak self] in
                self!.refreshControl!.endRefreshing()
                self!.StatusLabel.text = "\(self!.notes.count) Notes"
            }
        }
    } //handleRefresh
        

    
   // func gotList (hasNewFiles : Bool) -> Void {
    func gotList (newActivityList : [Int]) -> Void {
        //ToDo: Add message for when Server not available
        if newActivityList.count > 0 {
            DispatchQueue.main.async {
                self.StatusLabel.text = "Found \(newActivityList.count) new activities on Server.  Updating..."
            }
            if newActivityList.count <= 10 {
                // DataLoader.sharedInstance.downloadEFRTFromList(list: newActivityList) // Legacy fitness tracking
            } else {
                // DataLoader.sharedInstance.downloadMissingEFRT() // Legacy fitness tracking
            }
         /*   var delaycounter = 0
            var newActivityList2 = newActivityList
            newActivityList2.reverse()
            for newActivityId in newActivityList2 {
                //ToDo : Change this to work off a scheduler with stack?
                //https://gist.github.com/Thomvis/b378f926b6e1a48973f694419ed73aca
                delaycounter += 1
                let newDespatchTime =  DispatchTime.now() + DispatchTimeInterval.seconds(delaycounter/4)
                DispatchQueue.main.asyncAfter(deadline: newDespatchTime) {  [weak self] in
                    DataLoader.sharedInstance.getEfrt(whenDone: self!.gotNewActivity, ActivityId: newActivityId)
                }
 
            } */
        } else {
            DispatchQueue.main.async {
                self.StatusLabel.text = "No new activities on EFRT server"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.StatusLabel.text = "Checking on connect.garmin.com"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.StatusLabel.text = "\(self.notes.count) notes"
            }
        }
    } //gotList
    
    
    func gotNewActivity (efrt : Any) -> Void {
        DispatchQueue.main.async {
            self.StatusLabel.text =  "Activity downloaded"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateNotesList()
        }
    } //gotNewActivity
    

}  //TrainingViewController


extension NotesListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      //  return notes.count
        return filteredNotes.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        // ToDo : Fix occasional Fatal error : Index out of range
        //print ("Training View Table View loading \(indexPath.row) of \(filteredNotes.count)")
        if (indexPath.row <= notes.count) {
           // let activity = activities[indexPath.row]
            let note = filteredNotes[indexPath.row]
           /* if (activity.tss == -1) {
                cell.textLabel?.text = "...pending download"
            } else { */
            cell.textLabel?.text = "\(note.noteName)"
           // }

            // Format the edited time as human-readable
            let date = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM, h:mm a"
            cell.detailTextLabel?.text = dateFormatter.string(from: date)

            // Use category color if categoryId is set, otherwise use old colorIndex
            if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
                cell.backgroundColor = category.getColor()
            } else {
                cell.backgroundColor = Globals.CN_LIGHT_COLORS[note.colorIndex]
            }

         /*   if activity.ignore {
                cell.textLabel?.textColor = Globals.EFRT_LTGREY
            } else {
                cell.textLabel?.textColor = Globals.EFRT_DKGREY
            } */
        } else {
            cell.textLabel?.text = "Loading..."
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        Globals.sharedInstance.activityIDToDisplay = activities[indexPath.row].activityId
        Globals.sharedInstance.noteIDToDisplay = filteredNotes[indexPath.row].noteId
        //tabBarController!.selectedIndex = 2
        let NoteViewController = storyboard?.instantiateViewController(withIdentifier: "NoteViewController")
        NoteViewController!.modalPresentationStyle = .fullScreen
        NoteViewController?.modalTransitionStyle = .crossDissolve
              
        present(NoteViewController!, animated: true, completion: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //ACTION to IGNORE an Activity
    /*    let ignoreAction = UIContextualAction(style: .normal, title: "ignore",
                                              handler: { (action, view, completionHandler) in
            if (self.activities[indexPath.row].ignore == false) {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: true)
                self.activities[indexPath.row].ignore = true
            } else {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: false)
                self.activities[indexPath.row].ignore = false
            }
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
                        
        })
        ignoreAction.image = UIImage(named: "medal")
        ignoreAction.backgroundColor = Globals.EFRT_ORANGE */
        
        //Action to re-DOWNLOAD an Activity
        let downloadAction = UIContextualAction(style: .normal, title: "download",
                                              handler: { (action, view, completionHandler) in
            // DataLoader.sharedInstance.deleteFromCache(ActivityId: self.notes[indexPath.row].noteId ) // Legacy fitness tracking
            // DataLoader.sharedInstance.getEfrt(whenDone: self.gotNewActivity, ActivityId: self.notes[indexPath.row].noteId ) // Legacy fitness tracking
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
        })
        downloadAction.image = UIImage(named: "download")
        downloadAction.backgroundColor = Globals.EFRT_BLUE
        
        //let configuration = UISwipeActionsConfiguration(actions: [ignoreAction, downloadAction])
        let configuration = UISwipeActionsConfiguration(actions: [downloadAction])
        return configuration
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //print("input text is : \(string)")
        //print (" text Field is now : \(textField.text)")
        let searchText = textField.text!

        filteredNotes = notes.filter( { $0.noteName.range(of: searchText, options: .caseInsensitive) != nil})
        tableView.reloadData()
        return true
    }

    @objc func menuButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Categories action
        let categoriesAction = UIAlertAction(title: "Manage Categories", style: .default) { [weak self] _ in
            self?.showCategories()
        }

        // Backup action
        let backupAction = UIAlertAction(title: "Backup", style: .default) { [weak self] _ in
            self?.performBackup()
        }

        // Import action
        let importAction = UIAlertAction(title: "Import", style: .default) { [weak self] _ in
            self?.performImport()
        }

        // About action
        let aboutAction = UIAlertAction(title: "About", style: .default) { [weak self] _ in
            self?.showAbout()
        }

        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(categoriesAction)
        alertController.addAction(backupAction)
        alertController.addAction(importAction)
        alertController.addAction(aboutAction)
        alertController.addAction(cancelAction)

        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(alertController, animated: true)
    }

    @objc func addNoteButtonTapped() {
        // Generate a new unique note ID (using current timestamp in milliseconds)
        let newNoteId = Int(Date().timeIntervalSince1970 * 1000)
        let newTimestamp = newNoteId

        // Create a new note
        let newNote = Note(
            noteId: newNoteId,
            noteName: "New Note",
            editedTime: newTimestamp,
            noteText: "",
            colorIndex: 0
        )

        // Insert the note into the database
        _ = NoteRecords.instance.insertNote(note: newNote)

        // Set the global note ID to display
        Globals.sharedInstance.noteIDToDisplay = newNoteId

        // Open the note detail view
        let noteViewController = storyboard?.instantiateViewController(withIdentifier: "NoteViewController")
        noteViewController?.modalPresentationStyle = .fullScreen
        noteViewController?.modalTransitionStyle = .crossDissolve

        present(noteViewController!, animated: true, completion: nil)

        // Refresh the list when returning
        updateNotesList()
    }

    func performBackup() {
        StatusLabel.text = "Exporting notes..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let fileURL = NoteBackup.exportAllNotes() else {
                DispatchQueue.main.async {
                    self?.StatusLabel.text = "\(self?.filteredNotes.count ?? 0) Notes"
                    self?.showAlert(title: "Export Failed", message: "Could not create backup file")
                }
                return
            }

            DispatchQueue.main.async {
                self?.StatusLabel.text = "\(self?.filteredNotes.count ?? 0) Notes"
                self?.shareBackupFile(fileURL: fileURL)
            }
        }
    }

    func performImport() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func showCategories() {
        let categoriesVC = CategoriesViewController(style: .insetGrouped)
        navigationController?.pushViewController(categoriesVC, animated: true)
    }

    func showAbout() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let message = """
        ColourNote
        A simple and elegant notes app

        Version: \(appVersion) (\(buildNumber))

        © 2024 ColourNote
        """

        let alert = UIAlertController(title: "About", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func shareBackupFile(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        // For iPad support
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(activityViewController, animated: true, completion: nil)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

// MARK: - Notification handlers
extension NotesListViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        updateNotesList()
        let app = UIApplication.shared
        app.applicationIconBadgeNumber = 0
       // print ("Content Change notification recieved in TrainingViewController")
    }
}

// MARK: - Document Picker Delegate
extension NotesListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            showAlert(title: "Import Failed", message: "No file selected")
            return
        }

        StatusLabel.text = "Importing notes..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Start accessing a security-scoped resource
                guard selectedFileURL.startAccessingSecurityScopedResource() else {
                    DispatchQueue.main.async {
                        self?.StatusLabel.text = "\(self?.filteredNotes.count ?? 0) Notes"
                        self?.showAlert(title: "Import Failed", message: "Could not access file")
                    }
                    return
                }

                defer {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }

                let jsonData = try Data(contentsOf: selectedFileURL)
                let result = NoteBackup.importNotesFromJSON(jsonData: jsonData)

                DispatchQueue.main.async {
                    self?.StatusLabel.text = "\(self?.filteredNotes.count ?? 0) Notes"
                    if result.success {
                        self?.showAlert(title: "Import Successful", message: "Imported \(result.importedCount) notes")
                        self?.updateNotesList()
                    } else {
                        self?.showAlert(title: "Import Failed", message: result.errorMessage ?? "Unknown error")
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    self?.StatusLabel.text = "\(self?.filteredNotes.count ?? 0) Notes"
                    self?.showAlert(title: "Import Failed", message: "Error reading file: \(error.localizedDescription)")
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled the import
        StatusLabel.text = "\(filteredNotes.count) Notes"
    }
}



