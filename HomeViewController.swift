//
//  HomeViewController.swift
//  ColourNote
//
//  Created by Paul Williams on 20/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var yourView : RoundUIView!
    @IBOutlet weak var totalNotesLabel : UILabel!
    @IBOutlet weak var categoriesBreakdownLabel : UILabel!
    @IBOutlet weak var recentNotesLabel : UILabel!
    @IBOutlet weak var trashNotesLabel : UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: NotesNotification.contentUpdated,
            object: nil)

        if let navControllerBar = navigationController?.navigationBar {

            navControllerBar.prefersLargeTitles = true

            let logo = UIImage(named: "pw")
            let imageView = UIImageView(image:logo)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit

            navControllerBar.addSubview(imageView)

            imageView.addConstraint(imageView.widthAnchor.constraint(equalToConstant: 80))
            imageView.addConstraint(imageView.heightAnchor.constraint(equalToConstant: 80))
            navControllerBar.addConstraint (navControllerBar.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: 10))
            navControllerBar.addConstraint (navControllerBar.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -5))

            imageView.layer.cornerRadius = 40
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 3.0
            imageView.layer.borderColor = UIColor.white.cgColor
        }
    } //viewDidLoad


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        updateViews()
    }


    func updateViews() {
        // Get all active notes
        let allNotes = NoteRecords.instance.getNotes()
        totalNotesLabel.text = "Total Notes: \(allNotes.count)"

        // Get notes by category
        let categories = NoteRecords.instance.getCategories()
        var categoryBreakdown: [String] = []
        for category in categories.prefix(3) {
            let notesInCategory = allNotes.filter { $0.categoryId == category.categoryId }
            if notesInCategory.count > 0 {
                categoryBreakdown.append("\(category.categoryName): \(notesInCategory.count)")
            }
        }
        categoriesBreakdownLabel.text = categoryBreakdown.isEmpty ? "No categories with notes" : categoryBreakdown.joined(separator: "\n")

        // Get recently modified notes (last 7 days)
        let sevenDaysAgo = Date().timeIntervalSince1970 * 1000 - (7 * 24 * 60 * 60 * 1000)
        let recentNotes = allNotes.filter { $0.editedTime > sevenDaysAgo }
        recentNotesLabel.text = "Modified (Last 7 Days): \(recentNotes.count)"

        // Get notes in trash
        let trashedNotes = NoteRecords.instance.getDeletedNotes()
        trashNotesLabel.text = "In Trash: \(trashedNotes.count)"
    }
}

// MARK: - Notification handlers
extension HomeViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        updateViews()
    }
}
