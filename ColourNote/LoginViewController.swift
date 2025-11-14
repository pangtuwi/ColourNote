//
//  LoginViewController.swift
//  ColourNote
//
//  Created by Paul Williams on 13/08/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import UIKit
import SQLite

class LoginViewController: UIViewController, UIDocumentPickerDelegate {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var loadDefaultButton: UIButton!
    @IBOutlet weak var createBlankButton: UIButton!
    @IBOutlet weak var importButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        // Set welcome text
        welcomeLabel?.text = "Welcome to ColourNote"
        descriptionLabel?.text = "A simple and elegant notes app.\n\nChoose how to get started:"

        // Style buttons
        styleButton(loadDefaultButton, title: "Load Sample Notes")
        styleButton(createBlankButton, title: "Start Fresh")
        styleButton(importButton, title: "Import Backup")
    }

    func styleButton(_ button: UIButton?, title: String) {
        button?.setTitle(title, for: .normal)
        button?.layer.cornerRadius = 8
        button?.backgroundColor = UIColor.systemBlue
        button?.setTitleColor(.white, for: .normal)
    }

    @IBAction func loadDefaultButtonTapped(_ sender: Any) {
        // Load the default database with sample notes
        initializeAppWithDatabase(useDefault: true, createBlank: false)
    }

    @IBAction func createBlankButtonTapped(_ sender: Any) {
        // Create a blank database
        initializeAppWithDatabase(useDefault: false, createBlank: true)
    }

    @IBAction func importButtonTapped(_ sender: Any) {
        // Show document picker to import JSON backup
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func initializeAppWithDatabase(useDefault: Bool, createBlank: Bool) {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/colornote.db"

        print("=== Initializing database ===")
        print("useDefault: \(useDefault), createBlank: \(createBlank)")
        print("Destination: \(destinationPath)")

        // Remove existing database if any
        try? FileManager.default.removeItem(atPath: destinationPath)
        print("Removed existing database")

        if useDefault {
            // Copy default database from bundle
            if let bundlePath = Bundle.main.url(forResource: "colornote", withExtension: "db")?.path {
                try? FileManager.default.copyItem(atPath: bundlePath, toPath: destinationPath)
                print("Loaded default database with sample notes")
                // Set database version to prevent auto-copy
                UserDefaults.standard.set(2, forKey: "DatabaseVersion")
            }
        } else if createBlank {
            // Create blank database
            createBlankDatabase(at: destinationPath)
            print("Created blank database")
            // Set database version to prevent auto-copy
            UserDefaults.standard.set(2, forKey: "DatabaseVersion")
        }

        let exists = FileManager.default.fileExists(atPath: destinationPath)
        print("Database exists after init: \(exists)")

        // Mark as registered and navigate to home
        Settings.setRegistered(registered: true)
        navigateToHome()
    }

    func createBlankDatabase(at path: String) {
        // Create a new blank SQLite database
        guard let db = try? Connection(path) else {
            print("Failed to create blank database")
            return
        }

        // Create the notes table
        let createNotesTableSQL = """
        CREATE TABLE IF NOT EXISTS notes (
          _id INTEGER PRIMARY KEY,
          active_state INTEGER DEFAULT 0,
          account_id INTEGER DEFAULT 0,
          folder_id INTEGER DEFAULT 0,
          status INTEGER DEFAULT 0,
          space INTEGER DEFAULT 0,
          type INTEGER NOT NULL DEFAULT 0,
          title TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          note_ext TEXT DEFAULT '',
          note_type INTEGER NOT NULL DEFAULT 0,
          tags TEXT DEFAULT '',
          importance INTEGER DEFAULT 0,
          created_date INTEGER NOT NULL DEFAULT 0,
          modified_date INTEGER NOT NULL DEFAULT 0,
          minor_modified_date INTEGER DEFAULT 0,
          reminder_type INTEGER DEFAULT 0,
          reminder_option INTEGER DEFAULT 0,
          reminder_date INTEGER DEFAULT 0,
          reminder_base INTEGER DEFAULT 0,
          reminder_last INTEGER DEFAULT 0,
          reminder_duration INTEGER DEFAULT 0,
          reminder_repeat INTEGER DEFAULT 0,
          reminder_repeat_ends INTEGER DEFAULT 0,
          latitude DOUBLE DEFAULT 0,
          longitude DOUBLE DEFAULT 0,
          color_index INTEGER NOT NULL DEFAULT 0,
          category_id INTEGER DEFAULT 0,
          encrypted INTEGER DEFAULT 0,
          dirty INTEGER DEFAULT 1,
          staged INTEGER DEFAULT 0,
          uuid TEXT,
          revision INTEGER DEFAULT 0
        );
        CREATE INDEX idx_note1 ON notes(active_state,account_id,folder_id,space);
        CREATE INDEX idx_note2 ON notes(reminder_type,reminder_date);
        CREATE INDEX idx_note3 ON notes(reminder_repeat,reminder_base);
        CREATE INDEX idx_note4 ON notes(title);
        CREATE INDEX idx_note_s1 ON notes(dirty);
        CREATE INDEX idx_note_s2 ON notes(staged);
        CREATE INDEX idx_note_category ON notes(category_id);
        """

        // Create the categories table
        let createCategoriesTableSQL = """
        CREATE TABLE IF NOT EXISTS categories (
            category_id INTEGER PRIMARY KEY,
            category_name TEXT NOT NULL DEFAULT '',
            color_hex TEXT NOT NULL DEFAULT '#FFFFFF',
            sort_order INTEGER DEFAULT 0
        );
        CREATE INDEX idx_category_sort ON categories(sort_order);
        """

        do {
            try db.execute(createNotesTableSQL)
            try db.execute(createCategoriesTableSQL)
            print("Blank database created successfully with categories table")

            // Insert default categories
            insertDefaultCategories(db: db)
        } catch {
            print("Error creating blank database: \(error)")
        }
    }

    func insertDefaultCategories(db: Connection) {
        let defaultCategories = Category.getDefaultCategories()

        for category in defaultCategories {
            let sql = """
            INSERT INTO categories (category_id, category_name, color_hex, sort_order)
            VALUES (?, ?, ?, ?)
            """
            do {
                try db.run(sql, category.categoryId, category.categoryName, category.colorHex, category.sortOrder)
            } catch {
                print("Error inserting default category: \(error)")
            }
        }
        print("Inserted default categories")
    }

    func navigateToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "ColorNoteHomeID")
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let window = appDelegate.window {
            window.rootViewController = homeViewController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
        }
    }

    // MARK: - Document Picker Delegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("=== Import started ===")
        guard let selectedFileURL = urls.first else {
            print("Error: No file selected")
            showAlert(title: "Import Failed", message: "No file selected")
            return
        }

        print("Selected file: \(selectedFileURL.path)")

        // Try to start accessing security-scoped resource (may not be needed for Inbox files)
        let needsScopedAccess = selectedFileURL.startAccessingSecurityScopedResource()
        print("Security-scoped access: \(needsScopedAccess)")

        defer {
            if needsScopedAccess {
                selectedFileURL.stopAccessingSecurityScopedResource()
                print("Released security-scoped resource")
            }
        }

        do {
            print("Reading JSON data...")
            let jsonData = try Data(contentsOf: selectedFileURL)
            print("JSON data size: \(jsonData.count) bytes")

            // Create blank database first
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let destinationPath = documents + "/colornote.db"
            print("Database path: \(destinationPath)")

            try? FileManager.default.removeItem(atPath: destinationPath)
            print("Creating blank database...")
            createBlankDatabase(at: destinationPath)

            // Import notes from JSON
            print("Importing notes from JSON...")
            let result = NoteBackup.importNotesFromJSON(jsonData: jsonData)
            print("Import result - success: \(result.success), count: \(result.importedCount)")

            if result.success {
                Settings.setRegistered(registered: true)
                print("Navigating to home with \(result.importedCount) notes")
                showAlert(title: "Import Successful", message: "Imported \(result.importedCount) notes") { [weak self] in
                    self?.navigateToHome()
                }
            } else {
                print("Import failed: \(result.errorMessage ?? "Unknown error")")
                showAlert(title: "Import Failed", message: result.errorMessage ?? "Unknown error")
            }
        } catch {
            print("Exception during import: \(error)")
            showAlert(title: "Import Failed", message: "Error reading file: \(error.localizedDescription)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled the import
        print("Import cancelled")
    }

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
