//
//  TrashViewController.swift
//  ColourNote
//
//  Created for trash/deleted notes functionality
//

import UIKit

class TrashViewController: UITableViewController {

    var deletedNotes: [Note] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Trash"

        // Add Empty Trash button to navigation bar
        let emptyTrashButton = UIBarButtonItem(title: "Empty Trash", style: .plain, target: self, action: #selector(emptyTrashTapped))
        navigationItem.rightBarButtonItem = emptyTrashButton

        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeletedNoteCell")

        loadDeletedNotes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDeletedNotes()
    }

    func loadDeletedNotes() {
        deletedNotes = NoteRecords.instance.getDeletedNotes()
        tableView.reloadData()

        // Update empty trash button state
        navigationItem.rightBarButtonItem?.isEnabled = !deletedNotes.isEmpty
    }

    @objc func emptyTrashTapped() {
        let count = deletedNotes.count

        let alert = UIAlertController(
            title: "Empty Trash",
            message: "Are you sure you want to permanently delete \(count) note\(count == 1 ? "" : "s")? This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Empty Trash", style: .destructive) { [weak self] _ in
            let deletedCount = NoteRecords.instance.emptyTrash()
            print("Emptied trash: \(deletedCount) notes permanently deleted")
            self?.loadDeletedNotes()
        })

        present(alert, animated: true)
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if deletedNotes.isEmpty {
            // Show empty state
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            emptyLabel.text = "Trash is empty"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.font = UIFont.systemFont(ofSize: 17)
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return deletedNotes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeletedNoteCell", for: indexPath)
        let note = deletedNotes[indexPath.row]

        // Configure cell
        cell.textLabel?.text = note.noteName

        // Format deleted date
        if let deletedTimestamp = note.deletedDate {
            let date = Date(timeIntervalSince1970: TimeInterval(deletedTimestamp / 1000))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy, h:mm a"
            cell.detailTextLabel?.text = "Deleted: " + dateFormatter.string(from: date)
        }

        // Use category color if available
        if note.categoryId > 0, let category = CategoryRecords.instance.getCategory(searchCategoryId: note.categoryId) {
            cell.backgroundColor = category.getColor()
            cell.textLabel?.textColor = getContrastingTextColor(for: category.getColor())
            cell.detailTextLabel?.textColor = getContrastingTextColor(for: category.getColor())
        } else {
            let color = Globals.CN_LIGHT_COLORS[note.colorIndex]
            cell.backgroundColor = color
            cell.textLabel?.textColor = getContrastingTextColor(for: color)
            cell.detailTextLabel?.textColor = getContrastingTextColor(for: color)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Could show note preview here in the future
    }

    // MARK: - Swipe Actions

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = deletedNotes[indexPath.row]

        // Restore action
        let restoreAction = UIContextualAction(style: .normal, title: "Restore") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            if NoteRecords.instance.undeleteNote(noteId: note.noteId) {
                self.loadDeletedNotes()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
        restoreAction.image = UIImage(systemName: "arrow.uturn.backward")
        restoreAction.backgroundColor = .systemGreen

        // Delete Forever action
        let deleteForeverAction = UIContextualAction(style: .destructive, title: "Delete Forever") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            let alert = UIAlertController(
                title: "Delete Forever",
                message: "Are you sure you want to permanently delete '\(note.noteName)'? This action cannot be undone.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "Delete Forever", style: .destructive) { _ in
                if NoteRecords.instance.permanentlyDeleteNote(noteId: note.noteId) {
                    self.loadDeletedNotes()
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            })
            self.present(alert, animated: true)
        }
        deleteForeverAction.image = UIImage(systemName: "trash.fill")
        deleteForeverAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteForeverAction, restoreAction])
        return configuration
    }

    // MARK: - Helper Methods

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
}
