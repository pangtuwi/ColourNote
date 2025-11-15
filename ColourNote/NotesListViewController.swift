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

    var selectedCategoryFilter: Int? = nil // nil means show all categories
    var cachedCategories: [Category] = [] // Cache categories to avoid slow database calls

    @IBOutlet weak var StatusLabel : UILabel!
    @IBOutlet weak var SearchTextEditor: UITextField!
    @IBOutlet weak var FilterButton: UIButton!
    
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

        // Setup filter button
        FilterButton?.setTitle("All", for: .normal)
        FilterButton?.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)

        // Load categories in background
        loadCategoriesAsync()

        //updateTrainingList()
        updateNotesList()
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(true)
        // Refresh the list when returning from note detail view
        updateNotesList()
        // Refresh categories cache in case they were modified
        loadCategoriesAsync()
    } //viewDidAppear

    func loadCategoriesAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let categories = CategoryRecords.instance.getCategories()
            DispatchQueue.main.async {
                self?.cachedCategories = categories
            }
        }
    }
    
    func updateNotesList() -> Void {
        notes = NoteRecords.instance.getNotes()
        notes.sort { $0.editedTime > $1.editedTime }
        applyFilters()
    }

    func applyFilters() {
        var filtered = notes

        // Apply category filter
        if let categoryId = selectedCategoryFilter {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }

        // Apply search text filter if there's text in the search field
        if let searchText = SearchTextEditor.text, !searchText.isEmpty {
            filtered = filtered.filter { $0.noteName.range(of: searchText, options: .caseInsensitive) != nil }
        }

        filteredNotes = filtered
        tableView.reloadData()
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
                self!.StatusLabel.text = ""
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
                self.StatusLabel.text = ""
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

            // Add lock icon if category is protected
            var displayText = note.noteName
            if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId), category.isProtected {
                displayText = "🔒 \(note.noteName)"
            }
            cell.textLabel?.text = displayText
           // }

            // Format the edited time as human-readable
            let date = Date(timeIntervalSince1970: TimeInterval(note.editedTime / 1000))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy, h:mm a"
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
        let note = filteredNotes[indexPath.row]

        // Check if note's category is protected
        if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId), category.isProtected {
            // Category is protected - check if already unlocked
            if !PasscodeManager.shared.isCategoryUnlocked(note.categoryId) {
                // Need to enter passcode
                showPasscodeEntry(for: note.categoryId) { [weak self] success in
                    if success {
                        self?.openNote(note)
                    }
                }
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
        }

        // Not protected or already unlocked - open directly
        openNote(note)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func openNote(_ note: Note) {
        Globals.sharedInstance.noteIDToDisplay = note.noteId
        let NoteViewController = storyboard?.instantiateViewController(withIdentifier: "NoteViewController")
        NoteViewController!.modalPresentationStyle = .fullScreen
        NoteViewController?.modalTransitionStyle = .crossDissolve
        present(NoteViewController!, animated: true, completion: nil)
    }

    func showPasscodeEntry(for categoryId: Int, completion: @escaping (Bool) -> Void) {
        let passcodeVC = PasscodeViewController()
        passcodeVC.mode = .entry
        passcodeVC.titleText = "Enter Passcode"
        passcodeVC.onSuccess = { _ in
            PasscodeManager.shared.unlockCategory(categoryId)
            completion(true)
        }
        passcodeVC.onCancel = {
            completion(false)
        }
        present(passcodeVC, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = filteredNotes[indexPath.row]

        // Delete action (moves to trash)
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            // Move to trash immediately without confirmation
            _ = NoteRecords.instance.softDeleteNote(noteId: note.noteId)

            // Remove the note from the arrays without reloading everything
            if let noteIndex = self.notes.firstIndex(where: { $0.noteId == note.noteId }) {
                self.notes.remove(at: noteIndex)
            }
            self.applyFilters()

            completionHandler(true)

            // Show brief notification on main thread after a short delay to allow swipe UI to dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showToast(message: "Note moved to Trash")
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed

        // Share action
        let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            let textToShare = "\(note.noteName)\n\n\(note.noteText)"
            let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)

            // For iPad - set popover source
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = tableView
                popoverController.sourceRect = tableView.rectForRow(at: indexPath)
            }

            self.present(activityViewController, animated: true)
            completionHandler(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue

        // Category action
        let categoryAction = UIContextualAction(style: .normal, title: "Category") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            let alert = UIAlertController(title: "Change Category", message: nil, preferredStyle: .actionSheet)

            // "No Category" option
            let noCategoryAction = UIAlertAction(title: "No Category", style: .default) { _ in
                _ = NoteRecords.instance.updateNoteCategory(changedNoteId: note.noteId, newCategoryId: 0)
                // Update the note in the arrays without reloading everything
                if let noteIndex = self.notes.firstIndex(where: { $0.noteId == note.noteId }) {
                    self.notes[noteIndex].categoryId = 0
                }
                self.applyFilters()
            }
            alert.addAction(noCategoryAction)

            // All categories
            for category in self.cachedCategories {
                let action = UIAlertAction(title: category.categoryName, style: .default) { _ in
                    _ = NoteRecords.instance.updateNoteCategory(changedNoteId: note.noteId, newCategoryId: category.categoryId)
                    // Update the note in the arrays without reloading everything
                    if let noteIndex = self.notes.firstIndex(where: { $0.noteId == note.noteId }) {
                        self.notes[noteIndex].categoryId = category.categoryId
                    }
                    self.applyFilters()
                }
                alert.addAction(action)
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            // For iPad - set popover source
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = tableView
                popoverController.sourceRect = tableView.rectForRow(at: indexPath)
            }

            self.present(alert, animated: true)
            completionHandler(true)
        }
        categoryAction.image = UIImage(systemName: "folder")
        categoryAction.backgroundColor = .systemOrange

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction, categoryAction])
        return configuration
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Delay to allow text field to update
        DispatchQueue.main.async { [weak self] in
            self?.applyFilters()
        }
        return true
    }

    @objc func filterButtonTapped() {
        let alert = UIAlertController(title: "Filter by Category", message: nil, preferredStyle: .actionSheet)

        // "All" option to clear filter
        let allAction = UIAlertAction(title: "All", style: .default) { [weak self] _ in
            self?.selectedCategoryFilter = nil
            self?.updateFilterButton(title: "All", color: nil)
            self?.applyFilters()
        }
        alert.addAction(allAction)

        // "Uncategorized" option
        let uncategorizedAction = UIAlertAction(title: "Uncategorized", style: .default) { [weak self] _ in
            self?.selectedCategoryFilter = 0
            self?.updateFilterButton(title: "Unca", color: .systemGray)
            self?.applyFilters()
        }
        alert.addAction(uncategorizedAction)

        // Use cached categories instead of querying database on main thread
        for category in cachedCategories {
            let action = UIAlertAction(title: category.categoryName, style: .default) { [weak self] _ in
                self?.selectedCategoryFilter = category.categoryId
                let shortName = String(category.categoryName.prefix(4))
                self?.updateFilterButton(title: shortName, color: category.getColor())
                self?.applyFilters()
            }
            alert.addAction(action)
        }

        // Cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = FilterButton
            popoverController.sourceRect = FilterButton.bounds
        }

        present(alert, animated: true)
    }

    func updateFilterButton(title: String, color: UIColor?) {
        FilterButton?.setTitle(title, for: .normal)
        if let color = color {
            FilterButton?.backgroundColor = color
            // Set text color to black or white based on background brightness
            FilterButton?.setTitleColor(getContrastingTextColor(for: color), for: .normal)
        } else {
            // Default appearance for "All" - gray background with black text
            FilterButton?.backgroundColor = .systemGray
            FilterButton?.setTitleColor(.black, for: .normal)
        }
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

    func showToast(message: String, duration: TimeInterval = 2.0) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showToast(message: message, duration: duration)
            }
            return
        }

        // Create toast label
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 15)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0

        // Size the label
        let maxSize = CGSize(width: view.bounds.width - 40, height: 100)
        let expectedSize = toastLabel.sizeThatFits(maxSize)
        let toastWidth = expectedSize.width + 20
        let toastHeight = expectedSize.height + 20

        // Position above tab bar using safe area
        let bottomPadding = view.safeAreaInsets.bottom + 20
        toastLabel.frame = CGRect(
            x: (view.bounds.width - toastWidth) / 2,
            y: view.bounds.height - toastHeight - bottomPadding,
            width: toastWidth,
            height: toastHeight
        )

        // Add to the window to ensure it appears above everything
        if let window = view.window {
            window.addSubview(toastLabel)
        } else {
            view.addSubview(toastLabel)
        }

        // Animate in
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            // Animate out after duration
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }

    @objc func menuButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Categories action
        let categoriesAction = UIAlertAction(title: "Manage Categories", style: .default) { [weak self] _ in
            self?.showCategories()
        }

        // Trash action
        let trashAction = UIAlertAction(title: "Trash", style: .default) { [weak self] _ in
            self?.showTrash()
        }

        // Backup action
        let backupAction = UIAlertAction(title: "Backup", style: .default) { [weak self] _ in
            self?.performBackup()
        }

        // Import action
        let importAction = UIAlertAction(title: "Import", style: .default) { [weak self] _ in
            self?.performImport()
        }

        // Passcode Settings action
        let passcodeAction = UIAlertAction(title: "Passcode Settings", style: .default) { [weak self] _ in
            self?.showPasscodeSettings()
        }

        // About action
        let aboutAction = UIAlertAction(title: "About", style: .default) { [weak self] _ in
            self?.showAbout()
        }

        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(categoriesAction)
        alertController.addAction(trashAction)
        alertController.addAction(backupAction)
        alertController.addAction(importAction)
        alertController.addAction(passcodeAction)
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
        // Check if there are any protected categories with notes
        let allNotes = NoteRecords.instance.getAllNotes()
        let protectedCategoryIds = Set(allNotes.filter { note in
            if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
                return category.isProtected
            }
            return false
        }.map { $0.categoryId })

        if !protectedCategoryIds.isEmpty && PasscodeManager.shared.isPasscodeSet {
            // There are protected notes - ask for passcode
            showPasscodeForExport(protectedCategoryIds: protectedCategoryIds)
        } else {
            // No protected notes or no passcode set - export all
            executeBackup(skipProtected: false)
        }
    }

    func showPasscodeForExport(protectedCategoryIds: Set<Int>) {
        let passcodeVC = PasscodeViewController()
        passcodeVC.mode = .entry
        passcodeVC.titleText = "Export Protected Notes"
        passcodeVC.onSuccess = { [weak self] _ in
            // Passcode correct - export all notes
            self?.executeBackup(skipProtected: false)
        }
        passcodeVC.onCancel = { [weak self] in
            // User cancelled - ask if they want to export without protected notes
            let alert = UIAlertController(
                title: "Skip Protected Notes?",
                message: "Export without protected notes?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Export Without Protected", style: .default) { _ in
                self?.executeBackup(skipProtected: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self?.present(alert, animated: true)
        }
        present(passcodeVC, animated: true)
    }

    func executeBackup(skipProtected: Bool) {
        StatusLabel.text = "Exporting notes..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let fileURL = NoteBackup.exportAllNotes(skipProtected: skipProtected) else {
                DispatchQueue.main.async {
                    self?.StatusLabel.text = ""
                    self?.showAlert(title: "Export Failed", message: "Could not create backup file")
                }
                return
            }

            DispatchQueue.main.async {
                self?.StatusLabel.text = ""

                if skipProtected {
                    // Show message about skipped notes
                    let allNotes = NoteRecords.instance.getAllNotes()
                    let protectedCount = allNotes.filter { note in
                        if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
                            return category.isProtected
                        }
                        return false
                    }.count

                    self?.showToast(message: "Exported (\(protectedCount) protected notes skipped)")
                }

                self?.shareBackupFile(fileURL: fileURL)
            }
        }
    }

    func performImport() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func showCategories() {
        let categoriesVC = CategoriesViewController(style: .insetGrouped)
        navigationController?.pushViewController(categoriesVC, animated: true)
    }

    func showTrash() {
        let trashVC = TrashViewController(style: .plain)
        navigationController?.pushViewController(trashVC, animated: true)
    }

    func showPasscodeSettings() {
        let alert = UIAlertController(title: "Passcode Settings", message: nil, preferredStyle: .actionSheet)

        if PasscodeManager.shared.isPasscodeSet {
            // Passcode is set - show change and remove options
            alert.addAction(UIAlertAction(title: "Change Passcode", style: .default) { [weak self] _ in
                self?.changePasscode()
            })

            alert.addAction(UIAlertAction(title: "Remove Passcode", style: .destructive) { [weak self] _ in
                self?.removePasscode()
            })

            // Show which categories are protected
            let protectedCategories = CategoryRecords.instance.getCategories().filter { $0.isProtected }
            if !protectedCategories.isEmpty {
                let categoryNames = protectedCategories.map { $0.categoryName }.joined(separator: ", ")
                alert.message = "Protected categories: \(categoryNames)"
            }
        } else {
            // No passcode set - show setup option
            alert.addAction(UIAlertAction(title: "Set Up Passcode", style: .default) { [weak self] _ in
                self?.setupPasscode()
            })
            alert.message = "No passcode is currently set"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(alert, animated: true)
    }

    func setupPasscode() {
        let passcodeVC = PasscodeViewController()
        passcodeVC.mode = .setup
        passcodeVC.titleText = "Set Passcode"
        passcodeVC.onSuccess = { [weak self] _ in
            self?.showAlert(title: "Success", message: "Passcode has been set. You can now protect categories in Category Settings.")
        }
        passcodeVC.onCancel = { }
        present(passcodeVC, animated: true)
    }

    func changePasscode() {
        let passcodeVC = PasscodeViewController()
        passcodeVC.mode = .change
        passcodeVC.titleText = "Change Passcode"
        passcodeVC.onSuccess = { [weak self] _ in
            self?.showAlert(title: "Success", message: "Passcode has been changed")
        }
        passcodeVC.onCancel = { }
        present(passcodeVC, animated: true)
    }

    func removePasscode() {
        // First verify current passcode
        let passcodeVC = PasscodeViewController()
        passcodeVC.mode = .entry
        passcodeVC.titleText = "Verify Passcode"
        passcodeVC.onSuccess = { [weak self] _ in
            // Passcode verified - show confirmation
            let confirmAlert = UIAlertController(
                title: "Remove Passcode",
                message: "This will remove protection from all categories. Are you sure?",
                preferredStyle: .alert
            )

            confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
                // Remove protection from all categories
                let categories = CategoryRecords.instance.getCategories()
                for category in categories where category.isProtected {
                    category.isProtected = false
                    _ = CategoryRecords.instance.updateCategory(category: category)
                }

                // Remove passcode
                PasscodeManager.shared.removePasscode()

                self?.showAlert(title: "Success", message: "Passcode removed and all categories unprotected")
            })

            confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self?.present(confirmAlert, animated: true)
        }
        passcodeVC.onCancel = { }
        present(passcodeVC, animated: true)
    }

    func showAbout() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let message = """
        ColourNote
        A simple and elegant notes app

        Designed and developed by Paul, for Debi, with love. Xxx.

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
                        self?.StatusLabel.text = ""
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
                    self?.StatusLabel.text = ""
                    if result.success {
                        self?.showAlert(title: "Import Successful", message: "Imported \(result.importedCount) notes")
                        self?.updateNotesList()
                    } else {
                        self?.showAlert(title: "Import Failed", message: result.errorMessage ?? "Unknown error")
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    self?.StatusLabel.text = ""
                    self?.showAlert(title: "Import Failed", message: "Error reading file: \(error.localizedDescription)")
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled the import
        StatusLabel.text = ""
    }
}



