//
//  SyncProgressView.swift
//  ColourNote
//
//  Overlay view showing sync progress with status and feedback
//

import UIKit

class SyncProgressView: UIView {

    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = .systemGray5
        progress.progressTintColor = .systemBlue
        return progress
    }()

    private let checkmarkView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let errorView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Properties
    private var dismissTimer: Timer?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        alpha = 0

        addSubview(containerView)
        containerView.addSubview(stackView)

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(checkmarkView)
        stackView.addArrangedSubview(errorView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(progressBar)
        stackView.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),

            progressBar.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    // MARK: - Public Methods

    /// Show the progress view with syncing state
    func showSyncing(in parentView: UIView) {
        frame = parentView.bounds
        parentView.addSubview(self)

        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        checkmarkView.isHidden = true
        errorView.isHidden = true
        progressBar.isHidden = false
        progressBar.progress = 0

        titleLabel.text = "Syncing"
        statusLabel.text = "Starting..."

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    /// Update the progress
    func updateProgress(_ progress: SyncProgress) {
        titleLabel.text = "Syncing"
        statusLabel.text = progress.description

        // Calculate overall progress (4 phases: upload cats, download cats, upload notes, download notes)
        var progressValue: Float = 0
        switch progress.phase {
        case .starting:
            progressValue = 0
        case .uploadingCategories:
            progressValue = 0.1
        case .downloadingCategories:
            progressValue = 0.3
        case .uploadingNotes:
            progressValue = 0.5
        case .downloadingNotes:
            progressValue = 0.7
        case .complete:
            progressValue = 1.0
        case .failed:
            progressValue = progressBar.progress // Keep current progress
        }

        UIView.animate(withDuration: 0.2) {
            self.progressBar.progress = progressValue
        }
    }

    /// Show success state
    func showSuccess(message: String, autoDismissAfter: TimeInterval = 2.0) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        checkmarkView.isHidden = false
        errorView.isHidden = true
        progressBar.isHidden = true

        titleLabel.text = "Sync Complete"
        statusLabel.text = message

        // Animate checkmark
        checkmarkView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
            self.checkmarkView.transform = .identity
        }

        // Auto-dismiss
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissAfter, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    /// Show error state
    func showError(message: String, autoDismissAfter: TimeInterval = 3.0) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        checkmarkView.isHidden = true
        errorView.isHidden = false
        progressBar.isHidden = true

        titleLabel.text = "Sync Failed"
        statusLabel.text = message

        // Shake animation
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: containerView.center.x - 10, y: containerView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: containerView.center.x + 10, y: containerView.center.y))
        containerView.layer.add(animation, forKey: "position")

        // Auto-dismiss
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissAfter, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    /// Hide the progress view
    func hide(completion: (() -> Void)? = nil) {
        dismissTimer?.invalidate()
        dismissTimer = nil

        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Don't dismiss while syncing
        if activityIndicator.isAnimating {
            return
        }

        // Allow tapping outside to dismiss when showing result
        if let touch = touches.first {
            let location = touch.location(in: self)
            if !containerView.frame.contains(location) {
                hide()
            }
        }
    }
}

// MARK: - Convenience Extension for View Controllers
extension UIViewController {

    private static var syncProgressViewKey: UInt8 = 0

    private var syncProgressView: SyncProgressView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.syncProgressViewKey) as? SyncProgressView
        }
        set {
            objc_setAssociatedObject(self, &UIViewController.syncProgressViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Show sync progress overlay
    func showSyncProgress() {
        let progressView = SyncProgressView()
        progressView.showSyncing(in: view)
        syncProgressView = progressView

        // Subscribe to sync progress updates
        SyncEngine.shared.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.syncProgressView?.updateProgress(progress)
            }
        }
    }

    /// Update sync progress with success
    func showSyncSuccess(message: String) {
        syncProgressView?.showSuccess(message: message)
    }

    /// Update sync progress with error
    func showSyncError(message: String) {
        syncProgressView?.showError(message: message)
    }

    /// Hide sync progress overlay
    func hideSyncProgress() {
        syncProgressView?.hide()
        syncProgressView = nil
    }
}
