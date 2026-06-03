//
//  SharedInboxViewController.swift
//  ColourNote
//
//  Inbox for shared notes — shows received (pending/declined/accepted) and sent shares.
//

import UIKit

class SharedInboxViewController: UITableViewController {

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case receivedPending = 0
        case receivedAccepted = 1
        case sent = 2

        var title: String {
            switch self {
            case .receivedPending:  return "Received"
            case .receivedAccepted: return "Accepted"
            case .sent:             return "Sent by Me"
            }
        }
    }

    // MARK: - Cell

    private class SubtitleCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    }

    // MARK: - Data

    private var receivedPending: [InboxShare] = []
    private var receivedAccepted: [InboxShare] = []
    private var sent: [InboxShare] = []

    private var dataForSection: [[InboxShare]] {
        [receivedPending, receivedAccepted, sent]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Shared Notes"
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: "InboxCell")

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.applicationIconBadgeNumber = 0
        loadInbox()
    }

    // MARK: - Data Loading

    private func loadInbox() {
        guard AuthManager.shared.isLoggedIn else {
            showEmptyState("Sign in to see your shared notes.")
            return
        }

        SharingService.shared.fetchInbox { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.tableView.refreshControl?.endRefreshing()
                switch result {
                case .success(let inbox):
                    self.receivedPending  = inbox.receivedPending
                    self.receivedAccepted = inbox.receivedAccepted
                    self.sent             = inbox.sent
                    self.tableView.backgroundView = nil
                    self.tableView.reloadData()
                    if inbox.receivedPending.isEmpty && inbox.receivedAccepted.isEmpty && inbox.sent.isEmpty {
                        self.showEmptyState("No shared notes yet.")
                    }
                case .failure:
                    self.showEmptyState("Could not load inbox. Pull to refresh.")
                }
            }
        }
    }

    @objc private func handleRefresh() {
        loadInbox()
    }

    private func showEmptyState(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        tableView.backgroundView = label
        tableView.reloadData()
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataForSection[section].count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        dataForSection[section].isEmpty ? nil : Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxCell", for: indexPath) as! SubtitleCell
        let share = dataForSection[indexPath.section][indexPath.row]

        cell.textLabel?.text = share.noteTitle ?? "Untitled"

        switch Section(rawValue: indexPath.section) {
        case .receivedPending:
            let ownerText = share.ownerEmail ?? "Unknown"
            let statusText = share.status == "declined" ? "Declined" : (share.isExpired ? "Expired" : "Pending")
            cell.detailTextLabel?.text = "From: \(ownerText) — \(statusText)"
            cell.accessoryType = (share.status == "pending" && !share.isExpired) ? .disclosureIndicator : .none
        case .receivedAccepted:
            cell.detailTextLabel?.text = "From: \(share.ownerEmail ?? "Unknown") — Accepted"
            cell.accessoryType = .none
        case .sent:
            let recipientText = share.recipientEmail ?? "Unknown"
            cell.detailTextLabel?.text = "To: \(recipientText) — \(share.status.capitalized)"
            cell.accessoryType = .none
        case .none:
            break
        }

        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == Section.receivedPending.rawValue else { return }
        let share = receivedPending[indexPath.row]
        guard share.status == "pending", !share.isExpired else { return }
        showAcceptDeclineAlert(for: share, at: indexPath)
    }

    override func tableView(_ tableView: UITableView,
                             trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        guard indexPath.section == Section.receivedPending.rawValue else { return nil }
        let share = receivedPending[indexPath.row]
        guard share.status == "pending", !share.isExpired else { return nil }

        let accept = UIContextualAction(style: .normal, title: "Accept") { [weak self] _, _, done in
            done(true)
            self?.acceptShare(share: share, indexPath: indexPath)
        }
        accept.backgroundColor = .systemGreen

        let decline = UIContextualAction(style: .destructive, title: "Decline") { [weak self] _, _, done in
            done(true)
            self?.declineShare(share: share, indexPath: indexPath)
        }

        return UISwipeActionsConfiguration(actions: [decline, accept])
    }

    // MARK: - Accept / Decline

    private func showAcceptDeclineAlert(for share: InboxShare, at indexPath: IndexPath) {
        let title = share.noteTitle ?? "Shared Note"
        let alert = UIAlertController(
            title: title,
            message: "From: \(share.ownerEmail ?? "Unknown")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
            self?.acceptShare(share: share, indexPath: indexPath)
        })
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
            self?.declineShare(share: share, indexPath: indexPath)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func acceptShare(share: InboxShare, indexPath: IndexPath) {
        SharingService.shared.acceptShare(token: share.token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.showToast("Note added to your library")
                    SyncEngine.shared.syncIfNeeded()
                    self.loadInbox()
                case .failure(let err):
                    self.showAlert(title: "Error", message: err.localizedDescription)
                }
            }
        }
    }

    private func declineShare(share: InboxShare, indexPath: IndexPath) {
        SharingService.shared.declineShare(token: share.token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.loadInbox()
                case .failure(let err):
                    self.showAlert(title: "Error", message: err.localizedDescription)
                }
            }
        }
    }

    // MARK: - UI Helpers

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.numberOfLines = 0
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true

        let maxSize = CGSize(width: view.bounds.width - 60, height: 100)
        let size = toast.sizeThatFits(maxSize)
        let width = min(size.width + 30, view.bounds.width - 60)
        let height = size.height + 20

        toast.frame = CGRect(
            x: (view.bounds.width - width) / 2,
            y: view.bounds.height - 100,
            width: width,
            height: height
        )

        view.addSubview(toast)
        toast.alpha = 0

        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
