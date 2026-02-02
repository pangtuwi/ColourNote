//
//  SyncSettingsViewController.swift
//  ColourNote
//
//  Settings screen for cloud sync configuration
//

import UIKit

class SyncSettingsViewController: UITableViewController {

    // MARK: - Section & Row Enums
    private enum Section: Int, CaseIterable {
        case account = 0
        case sync = 1
        case settings = 2
    }

    private enum AccountRow: Int, CaseIterable {
        case status = 0
        case loginLogout = 1
    }

    private enum SyncRow: Int, CaseIterable {
        case lastSync = 0
        case syncNow = 1
    }

    private enum SettingsRow: Int, CaseIterable {
        case autoSync = 0
    }

    // MARK: - Properties
    private let syncEngine = SyncEngine.shared
    private let authManager = AuthManager.shared

    private var isSyncing = false
    private var syncProgressCell: UITableViewCell?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSyncProgressCallback()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Cloud Sync"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
    }

    private func setupSyncProgressCallback() {
        syncEngine.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateSyncProgress(progress)
            }
        }
    }

    // MARK: - Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .account:
            return AccountRow.allCases.count
        case .sync:
            return authManager.isLoggedIn ? SyncRow.allCases.count : 0
        case .settings:
            return authManager.isLoggedIn ? SettingsRow.allCases.count : 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }

        switch sectionType {
        case .account:
            return "Account"
        case .sync:
            return authManager.isLoggedIn ? "Sync" : nil
        case .settings:
            return authManager.isLoggedIn ? "Settings" : nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch sectionType {
        case .account:
            return configureAccountCell(for: indexPath)
        case .sync:
            return configureSyncCell(for: indexPath)
        case .settings:
            return configureSettingsCell(for: indexPath)
        }
    }

    // MARK: - Cell Configuration
    private func configureAccountCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = AccountRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none

        switch row {
        case .status:
            if authManager.isLoggedIn {
                cell.textLabel?.text = authManager.userEmail ?? "Logged In"
                cell.textLabel?.textColor = .label
                cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
                cell.imageView?.tintColor = .systemGreen
            } else {
                cell.textLabel?.text = "Not logged in"
                cell.textLabel?.textColor = .secondaryLabel
                cell.imageView?.image = UIImage(systemName: "xmark.circle")
                cell.imageView?.tintColor = .systemRed
            }

        case .loginLogout:
            cell.selectionStyle = .default
            if authManager.isLoggedIn {
                cell.textLabel?.text = "Log Out"
                cell.textLabel?.textColor = .systemRed
                cell.imageView?.image = nil
            } else {
                cell.textLabel?.text = "Log In or Register"
                cell.textLabel?.textColor = .systemBlue
                cell.imageView?.image = nil
                cell.accessoryType = .disclosureIndicator
            }
        }

        return cell
    }

    private func configureSyncCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = SyncRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none

        switch row {
        case .lastSync:
            cell.textLabel?.text = "Last Sync: \(syncEngine.getLastSyncTimeString())"
            cell.textLabel?.textColor = .secondaryLabel

        case .syncNow:
            cell.selectionStyle = .default

            if isSyncing {
                cell.textLabel?.text = "Syncing..."
                cell.textLabel?.textColor = .secondaryLabel

                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                cell.accessoryView = spinner
                syncProgressCell = cell
            } else {
                cell.textLabel?.text = "Sync Now"
                cell.textLabel?.textColor = .systemBlue
                cell.accessoryView = nil
            }
        }

        return cell
    }

    private func configureSettingsCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let row = SettingsRow(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        switch row {
        case .autoSync:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            cell.textLabel?.text = "Auto-Sync"
            cell.switchControl.isOn = syncEngine.isAutoSyncEnabled
            cell.onSwitchChanged = { [weak self] isOn in
                self?.syncEngine.isAutoSyncEnabled = isOn
            }
            return cell
        }
    }

    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .account:
            handleAccountRowSelection(indexPath)
        case .sync:
            handleSyncRowSelection(indexPath)
        case .settings:
            break // Settings rows use switches
        }
    }

    private func handleAccountRowSelection(_ indexPath: IndexPath) {
        guard let row = AccountRow(rawValue: indexPath.row) else { return }

        switch row {
        case .status:
            break
        case .loginLogout:
            if authManager.isLoggedIn {
                showLogoutConfirmation()
            } else {
                showLoginScreen()
            }
        }
    }

    private func handleSyncRowSelection(_ indexPath: IndexPath) {
        guard let row = SyncRow(rawValue: indexPath.row) else { return }

        switch row {
        case .lastSync:
            break
        case .syncNow:
            if !isSyncing {
                startSync()
            }
        }
    }

    // MARK: - Actions
    private func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "CloudLoginViewController") as? CloudLoginViewController {
            loginVC.onLoginSuccess = { [weak self] in
                self?.tableView.reloadData()
            }
            let navController = UINavigationController(rootViewController: loginVC)
            present(navController, animated: true)
        }
    }

    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out? Your local data will be preserved.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })

        present(alert, animated: true)
    }

    private func performLogout() {
        authManager.logout()
        syncEngine.clearSyncData()
        tableView.reloadData()
    }

    private func startSync() {
        isSyncing = true
        tableView.reloadData()

        syncEngine.syncAll { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                self?.tableView.reloadData()

                switch result {
                case .success(let syncResult):
                    self?.showSyncResult(syncResult)
                case .failure(let error):
                    self?.showSyncError(error)
                }
            }
        }
    }

    private func updateSyncProgress(_ progress: SyncProgress) {
        syncProgressCell?.textLabel?.text = progress.description
    }

    private func showSyncResult(_ result: SyncResult) {
        let alert = UIAlertController(
            title: "Sync Complete",
            message: result.summary,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSyncError(_ error: SyncError) {
        let alert = UIAlertController(
            title: "Sync Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Switch Table View Cell
class SwitchTableViewCell: UITableViewCell {

    let switchControl = UISwitch()
    var onSwitchChanged: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSwitch()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwitch()
    }

    private func setupSwitch() {
        accessoryView = switchControl
        selectionStyle = .none
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }

    @objc private func switchValueChanged() {
        onSwitchChanged?(switchControl.isOn)
    }
}
