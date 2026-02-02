//
//  SettingsViewController.swift
//  ColourNote
//
//  Created by Paul Williams on 05/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var cloudSyncStatusLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Note: Backup/export/import functionality is handled via storyboard actions
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCloudSyncStatus()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    // MARK: - Cloud Sync Status
    private func updateCloudSyncStatus() {
        if AuthManager.shared.isLoggedIn {
            cloudSyncStatusLabel?.text = AuthManager.shared.userEmail ?? "Logged In"
            cloudSyncStatusLabel?.textColor = .systemGreen
        } else {
            cloudSyncStatusLabel?.text = "Not connected"
            cloudSyncStatusLabel?.textColor = .secondaryLabel
        }
    }

    // MARK: - Navigation
    @IBAction func cloudSyncTapped(_ sender: Any) {
        let syncSettingsVC = SyncSettingsViewController(style: .insetGrouped)
        navigationController?.pushViewController(syncSettingsVC, animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Check if this is the Cloud Sync cell (we'll identify by cell's tag or reuse identifier in storyboard)
        if let cell = tableView.cellForRow(at: indexPath), cell.reuseIdentifier == "CloudSyncCell" {
            cloudSyncTapped(cell)
        }
    }
}
