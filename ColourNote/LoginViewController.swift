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

    // MARK: - IBOutlets (storyboard connections — hidden at runtime, replaced by programmatic UI)
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var createBlankButton: UIButton!
    @IBOutlet weak var importButton: UIButton!

    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    // MARK: - UI Setup

    func setupUI() {
        // Hide storyboard elements — UI is built entirely in code below.
        // Also disable interaction so they can never fire even if isHidden somehow fails.
        welcomeLabel?.isHidden = true
        descriptionLabel?.isHidden = true
        logoImageView?.isHidden = true
        createBlankButton?.isHidden = true
        createBlankButton?.isUserInteractionEnabled = false
        importButton?.isHidden = true
        importButton?.isUserInteractionEnabled = false

        // Dark fallback before gradient renders
        view.backgroundColor = UIColor(red: 0.10, green: 0.07, blue: 0.22, alpha: 1)

        setupGradientBackground()
        setupDecorativeOrbs()
        setupGlassCard()
    }

    // MARK: - Background

    private func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.28, green: 0.12, blue: 0.65, alpha: 1).cgColor,  // deep purple
            UIColor(red: 0.15, green: 0.28, blue: 0.85, alpha: 1).cgColor,  // indigo
            UIColor(red: 0.04, green: 0.52, blue: 0.82, alpha: 1).cgColor,  // azure
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint   = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }

    private func setupDecorativeOrbs() {
        // Top-left purple orb
        let orb1 = UIView()
        orb1.translatesAutoresizingMaskIntoConstraints = false
        orb1.backgroundColor = UIColor(red: 0.60, green: 0.20, blue: 1.00, alpha: 0.35)
        orb1.layer.cornerRadius = 130
        view.addSubview(orb1)
        NSLayoutConstraint.activate([
            orb1.widthAnchor.constraint(equalToConstant: 260),
            orb1.heightAnchor.constraint(equalToConstant: 260),
            orb1.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            orb1.topAnchor.constraint(equalTo: view.topAnchor, constant: -40),
        ])

        // Bottom-right cyan orb
        let orb2 = UIView()
        orb2.translatesAutoresizingMaskIntoConstraints = false
        orb2.backgroundColor = UIColor(red: 0.00, green: 0.75, blue: 0.95, alpha: 0.28)
        orb2.layer.cornerRadius = 150
        view.addSubview(orb2)
        NSLayoutConstraint.activate([
            orb2.widthAnchor.constraint(equalToConstant: 300),
            orb2.heightAnchor.constraint(equalToConstant: 300),
            orb2.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: 60),
            orb2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60),
        ])
    }

    // MARK: - Glass Card

    private func setupGlassCard() {
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 28
        card.clipsToBounds = true
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -36),
        ])

        // Header
        let header = makeHeaderView()
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(28, after: header)

        // Separator
        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(sep)
        stack.setCustomSpacing(20, after: sep)

        // Start Fresh
        let startFreshBtn = makeGlassButton(
            title: "Start Fresh",
            subtitle: "Create a new empty notebook",
            systemImage: "doc.badge.plus",
            iconColor: UIColor(red: 0.40, green: 0.80, blue: 1.00, alpha: 1)
        )
        startFreshBtn.accessibilityIdentifier = "startFreshButton"
        startFreshBtn.addTarget(self, action: #selector(createBlankButtonTapped(_:)), for: .touchUpInside)
        stack.addArrangedSubview(startFreshBtn)
        stack.setCustomSpacing(10, after: startFreshBtn)

        // Import Backup
        let importBtn = makeGlassButton(
            title: "Import Backup",
            subtitle: "Restore from a JSON backup file",
            systemImage: "arrow.down.doc.fill",
            iconColor: UIColor(red: 1.00, green: 0.75, blue: 0.30, alpha: 1)
        )
        importBtn.accessibilityIdentifier = "importBackupButton"
        importBtn.addTarget(self, action: #selector(importButtonTapped(_:)), for: .touchUpInside)
        stack.addArrangedSubview(importBtn)

        // Cloud Sync — always visible; lets any user sign in and download their data
        stack.setCustomSpacing(10, after: importBtn)
        let cloudSyncBtn = makeGlassButton(
            title: "Cloud Sync",
            subtitle: "Sign in and download your notes",
            systemImage: "arrow.triangle.2.circlepath.icloud",
            iconColor: UIColor(red: 0.55, green: 0.35, blue: 1.00, alpha: 1)
        )
        cloudSyncBtn.accessibilityIdentifier = "cloudSyncButton"
        cloudSyncBtn.addTarget(self, action: #selector(cloudSyncButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(cloudSyncBtn)

        // Cloud Restore (only when Keychain credentials exist from a prior install)
        if let email = AuthManager.shared.userEmail, AuthManager.shared.userPassword != nil {
            stack.setCustomSpacing(10, after: cloudSyncBtn)
            let cloudBtn = makeGlassButton(
                title: "Cloud Restore",
                subtitle: "Sign in as \(email)",
                systemImage: "icloud.and.arrow.down.fill",
                iconColor: UIColor(red: 0.20, green: 0.95, blue: 0.55, alpha: 1)
            )
            cloudBtn.addTarget(self, action: #selector(cloudRestoreButtonTapped), for: .touchUpInside)
            stack.addArrangedSubview(cloudBtn)
        }
    }

    // MARK: - Header View

    private func makeHeaderView() -> UIView {
        let container = UIView()

        // App icon — rounded corners applied directly to the image view
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        iconView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 72).isActive = true
        if let splash = UIImage(named: "irids_bg") {
            iconView.image = splash
        } else {
            iconView.image = UIImage(systemName: "note.text",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit
        }
        iconView.isUserInteractionEnabled = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "ColourNote"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your notes, beautifully organised"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        subtitleLabel.textAlignment = .center

        let vStack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 10
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.setCustomSpacing(16, after: iconView)

        container.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    // MARK: - Glass Button Factory

    private func makeGlassButton(title: String, subtitle: String, systemImage: String, iconColor: UIColor) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        button.heightAnchor.constraint(equalToConstant: 66).isActive = true

        // Subtle press animation
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)),
                         for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // Icon
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: systemImage, withConfiguration: iconCfg))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = iconColor
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false

        // Labels
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLbl.textColor = .white
        titleLbl.isUserInteractionEnabled = false

        let subtitleLbl = UILabel()
        subtitleLbl.text = subtitle
        subtitleLbl.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLbl.textColor = UIColor.white.withAlphaComponent(0.55)
        subtitleLbl.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.isUserInteractionEnabled = false

        // Trailing chevron
        let chevronCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: chevronCfg))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = UIColor.white.withAlphaComponent(0.35)
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.isUserInteractionEnabled = false

        button.addSubview(icon)
        button.addSubview(textStack)
        button.addSubview(chevron)

        NSLayoutConstraint.activate([
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 18),
            icon.widthAnchor.constraint(equalToConstant: 26),

            textStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -18),
        ])

        return button
    }

    // MARK: - Button Animations

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            sender.alpha = 0.60
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.20, delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            sender.alpha = 1.0
            sender.transform = .identity
        }
    }

    // MARK: - IBActions

    @IBAction func createBlankButtonTapped(_ sender: Any) {
        initializeAppWithDatabase()
    }

    @IBAction func importButtonTapped(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    // MARK: - Database Initialisation

    func initializeAppWithDatabase() {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/colornote.db"

        print("=== Initializing database ===")
        print("Creating blank database")
        print("Destination: \(destinationPath)")

        try? FileManager.default.removeItem(atPath: destinationPath)
        print("Removed existing database")

        createBlankDatabase(at: destinationPath)
        print("Created blank database")

        // createBlankDatabase() now creates the complete v10 schema for both notes and
        // sync_mappings, and the full v3 categories schema. Tell both migration systems
        // to skip their migration chains entirely on this fresh install.
        UserDefaults.standard.set(10, forKey: "DatabaseSchemaVersion")
        UserDefaults.standard.set(3, forKey: "CategoryDatabaseSchemaVersion")
        // Clear sync timestamps so the next sync does a full download (since: null).
        // Without this, a stale lastNoteSyncTime causes a 304 response and notes
        // on the server are never downloaded to the fresh local database.
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)

        let exists = FileManager.default.fileExists(atPath: destinationPath)
        print("Database exists after init: \(exists)")

        Settings.setRegistered(registered: true)

        // SyncMapping.shared (and its syncMapping property in CategorySyncService /
        // NoteSyncService) can be prematurely initialised by the AppDelegate's
        // 1-second SyncEngine timer, which fires even before the user registers.
        // At that point colornote.db doesn't exist yet, so SQLite creates an empty
        // file — meaning SyncMapping.shared.db holds a file descriptor to an empty
        // database with no tables.  createBlankDatabase() then deletes that empty
        // file and creates a fresh one, but the stale connection never sees the new
        // schema.  resetConnection() closes the old handle and opens a fresh one on
        // the newly-created database, exactly as the Cloud Restore path already does.
        SyncMapping.shared.resetConnection()

        navigateToHome()
    }

    func createBlankDatabase(at path: String) {
        guard let db = try? Connection(path) else {
            print("Failed to create blank database")
            return
        }

        // Complete v10 schema — matches the schema that NoteRecords arrives at after
        // running all migrations on a legacy database. Creating it directly here means
        // NoteRecords can skip every migration on fresh installs.
        let createNotesTableSQL = """
        CREATE TABLE IF NOT EXISTS notes (
          _id INTEGER PRIMARY KEY,
          active_state INTEGER DEFAULT 0,
          type INTEGER NOT NULL DEFAULT 0,
          title TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          note_type INTEGER NOT NULL DEFAULT 0,
          created_date INTEGER NOT NULL DEFAULT 0,
          modified_date INTEGER NOT NULL DEFAULT 0,
          color_index INTEGER NOT NULL DEFAULT 0,
          category_id INTEGER DEFAULT 0,
          deleted_date INTEGER DEFAULT NULL,
          content_format TEXT DEFAULT 'markdown',
          uuid TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_note_category ON notes(category_id);
        CREATE INDEX IF NOT EXISTS idx_notes_uuid ON notes(uuid);
        """

        // sync_mappings is created by NoteRecords migration v6; v10 adds the etag column.
        // Build it fully here so migrations can be skipped entirely on fresh installs.
        let createSyncMappingsSQL = """
        CREATE TABLE IF NOT EXISTS sync_mappings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_id INTEGER NOT NULL,
            cloud_id TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            last_synced INTEGER,
            sync_status TEXT DEFAULT 'pending_upload',
            created_at INTEGER NOT NULL,
            modified_at INTEGER NOT NULL,
            etag TEXT DEFAULT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_sync_local ON sync_mappings(local_id, entity_type);
        CREATE INDEX IF NOT EXISTS idx_sync_cloud ON sync_mappings(cloud_id);
        CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_unique ON sync_mappings(local_id, entity_type);
        """

        let createCategoriesTableSQL = """
        CREATE TABLE IF NOT EXISTS categories (
            category_id INTEGER PRIMARY KEY,
            uuid TEXT,
            category_name TEXT NOT NULL DEFAULT '',
            color_hex TEXT NOT NULL DEFAULT '#FFFFFF',
            sort_order INTEGER DEFAULT 0,
            is_protected INTEGER DEFAULT 0,
            modified_at INTEGER DEFAULT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_category_sort ON categories(sort_order);
        CREATE INDEX IF NOT EXISTS idx_categories_uuid ON categories(uuid);
        """

        do {
            try db.execute(createNotesTableSQL)
            try db.execute(createSyncMappingsSQL)
            try db.execute(createCategoriesTableSQL)
            print("Blank database created successfully at v10 schema")
            insertDefaultCategories(db: db)
        } catch {
            print("Error creating blank database: \(error)")
        }
    }

    func insertDefaultCategories(db: Connection) {
        let defaultCategories = Category.getDefaultCategories()
        let now = Int(Date().timeIntervalSince1970 * 1000)
        for category in defaultCategories {
            let sql = """
            INSERT INTO categories (category_id, uuid, category_name, color_hex, sort_order, modified_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """
            do {
                try db.run(sql, category.categoryId, UUID().uuidString, category.categoryName,
                           category.colorHex, category.sortOrder, now)
            } catch {
                print("Error inserting default category: \(error)")
            }
        }
        print("Inserted default categories")
    }

    func navigateToHome() {
        // Initialize database singletons now that the database file exists.
        // AppDelegate only does this when isRegistered() is true at launch,
        // so after a fresh install we must do it here before any sync can run.
        _ = NoteRecords.instance
        _ = CategoryRecords.instance
        _ = SyncMapping.shared

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

            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let destinationPath = documents + "/colornote.db"
            print("Database path: \(destinationPath)")

            try? FileManager.default.removeItem(atPath: destinationPath)
            print("Creating blank database...")
            createBlankDatabase(at: destinationPath)

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
        print("Import cancelled")
    }

    // MARK: - Alert Helper

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // MARK: - Cloud Sync

    @objc private func cloudSyncButtonTapped() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let cloudLoginVC = sb.instantiateViewController(
            withIdentifier: "CloudLoginViewController") as? CloudLoginViewController else { return }

        cloudLoginVC.onLoginSuccess = { [weak self] in
            self?.performCloudSyncRestore()
        }

        present(cloudLoginVC, animated: true)
    }

    private func performCloudSyncRestore() {
        let spinner = showSpinner(message: "Restoring from cloud...")

        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/colornote.db"
        try? FileManager.default.removeItem(atPath: destinationPath)
        createBlankDatabase(at: destinationPath)
        UserDefaults.standard.set(10, forKey: "DatabaseSchemaVersion")
        UserDefaults.standard.set(3, forKey: "CategoryDatabaseSchemaVersion")
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
        Settings.setRegistered(registered: true)

        _ = NoteRecords.instance
        _ = CategoryRecords.instance
        SyncMapping.shared.resetConnection()

        SyncEngine.shared.isAutoSyncEnabled = true
        SyncEngine.shared.downloadCloudChanges { [weak self] result in
            DispatchQueue.main.async {
                self?.hideSpinner(spinner)
                switch result {
                case .failure(let error):
                    self?.showAlert(
                        title: "Restore Incomplete",
                        message: "Signed in but could not download all data: \(error.localizedDescription)\n\nYou can sync again from Settings.",
                        completion: { self?.navigateToHome() }
                    )
                case .success:
                    self?.navigateToHome()
                }
            }
        }
    }

    // MARK: - Cloud Restore

    @objc func cloudRestoreButtonTapped() {
        guard let email = AuthManager.shared.userEmail,
              let password = AuthManager.shared.userPassword else { return }

        let spinner = showSpinner(message: "Signing in...")

        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/colornote.db"
        try? FileManager.default.removeItem(atPath: destinationPath)
        createBlankDatabase(at: destinationPath)
        // createBlankDatabase() now creates the complete v10 schema (notes + sync_mappings)
        // and the full v3 categories schema — skip all migrations on this fresh install.
        UserDefaults.standard.set(10, forKey: "DatabaseSchemaVersion")
        UserDefaults.standard.set(3, forKey: "CategoryDatabaseSchemaVersion")
        // Clear sync timestamps so the restore does a full download (since: null).
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
        Settings.setRegistered(registered: true)

        _ = NoteRecords.instance
        _ = CategoryRecords.instance
        // SyncMapping may have been initialized at launch with a stale connection to
        // the old (now deleted) database file. Reconnect it to the new file.
        SyncMapping.shared.resetConnection()

        AuthManager.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.hideSpinner(spinner)
                    self?.showAlert(title: "Login Failed",
                                   message: error.localizedDescription + "\n\nYou can still start fresh or import a backup.")
                case .success:
                    SyncEngine.shared.isAutoSyncEnabled = true
                    self?.updateSpinner(spinner, message: "Restoring from cloud...")
                    SyncEngine.shared.downloadCloudChanges { downloadResult in
                        DispatchQueue.main.async {
                            self?.hideSpinner(spinner)
                            switch downloadResult {
                            case .failure(let error):
                                self?.showAlert(
                                    title: "Restore Incomplete",
                                    message: "Signed in but could not download all data: \(error.localizedDescription)\n\nYou can sync again from Settings.",
                                    completion: { self?.navigateToHome() }
                                )
                            case .success:
                                self?.navigateToHome()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Spinner Helpers

    private func showSpinner(message: String) -> (UIView, UILabel) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY - 20)
        indicator.startAnimating()
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: indicator.frame.maxY + 8, width: overlay.bounds.width, height: 30)
        overlay.addSubview(indicator)
        overlay.addSubview(label)
        view.addSubview(overlay)
        return (overlay, label)
    }

    private func updateSpinner(_ components: (UIView, UILabel), message: String) {
        components.1.text = message
    }

    private func hideSpinner(_ components: (UIView, UILabel)) {
        components.0.removeFromSuperview()
    }
}
