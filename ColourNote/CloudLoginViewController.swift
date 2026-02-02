//
//  CloudLoginViewController.swift
//  ColourNote
//
//  Login/Register UI for cloud sync authentication
//

import UIKit

class CloudLoginViewController: UIViewController {

    // MARK: - UI Elements (Programmatic)
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Cloud Sync"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign in to sync your notes across devices"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .emailAddress
        return tf
    }()

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.textContentType = .password
        return tf
    }()

    private let confirmPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        return tf
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()

    private let toggleModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Don't have an account? Register", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties
    private var isLoginMode = true
    var onLoginSuccess: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateUIForMode()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Cloud Sync"

        // Add cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, subtitleLabel, emailTextField, passwordTextField,
         confirmPasswordTextField, errorLabel, actionButton, toggleModeButton, activityIndicator].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Add actions
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        toggleModeButton.addTarget(self, action: #selector(toggleModeButtonTapped), for: .touchUpInside)

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        // Set delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            emailTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),

            errorLabel.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            actionButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -16),

            toggleModeButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            toggleModeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            toggleModeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func updateUIForMode() {
        if isLoginMode {
            actionButton.setTitle("Log In", for: .normal)
            toggleModeButton.setTitle("Don't have an account? Register", for: .normal)
            confirmPasswordTextField.isHidden = true
        } else {
            actionButton.setTitle("Register", for: .normal)
            toggleModeButton.setTitle("Already have an account? Log In", for: .normal)
            confirmPasswordTextField.isHidden = false
        }
        errorLabel.isHidden = true
    }

    // MARK: - Actions
    @objc private func actionButtonTapped(_ sender: UIButton) {
        dismissKeyboard()

        guard validateInput() else { return }

        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!

        setLoading(true)

        if isLoginMode {
            login(email: email, password: password)
        } else {
            register(email: email, password: password)
        }
    }

    @objc private func toggleModeButtonTapped(_ sender: UIButton) {
        isLoginMode.toggle()
        updateUIForMode()
        clearFields()
    }

    @objc private func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Validation
    private func validateInput() -> Bool {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showError("Please enter your email address")
            return false
        }

        guard isValidEmail(email) else {
            showError("Please enter a valid email address")
            return false
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            showError("Please enter your password")
            return false
        }

        guard password.count >= 6 else {
            showError("Password must be at least 6 characters")
            return false
        }

        if !isLoginMode {
            guard let confirmPassword = confirmPasswordTextField.text,
                  confirmPassword == password else {
                showError("Passwords do not match")
                return false
            }
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Authentication
    private func login(email: String, password: String) {
        AuthManager.shared.login(email: email, password: password) { [weak self] result in
            self?.setLoading(false)

            switch result {
            case .success:
                self?.handleLoginSuccess()
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }

    private func register(email: String, password: String) {
        AuthManager.shared.register(email: email, password: password) { [weak self] result in
            self?.setLoading(false)

            switch result {
            case .success:
                self?.handleLoginSuccess()
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }

    private func handleLoginSuccess() {
        onLoginSuccess?()
        dismiss(animated: true)
    }

    // MARK: - UI Helpers
    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            actionButton.isEnabled = false
            toggleModeButton.isEnabled = false
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            confirmPasswordTextField.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            actionButton.isEnabled = true
            toggleModeButton.isEnabled = true
            emailTextField.isEnabled = true
            passwordTextField.isEnabled = true
            confirmPasswordTextField.isEnabled = true
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false

        // Shake animation
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: errorLabel.center.x - 10, y: errorLabel.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: errorLabel.center.x + 10, y: errorLabel.center.y))
        errorLabel.layer.add(animation, forKey: "position")
    }

    private func clearFields() {
        emailTextField.text = ""
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
        errorLabel.isHidden = true
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension CloudLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            if isLoginMode {
                actionButtonTapped(actionButton)
            } else {
                confirmPasswordTextField.becomeFirstResponder()
            }
        } else if textField == confirmPasswordTextField {
            actionButtonTapped(actionButton)
        }
        return true
    }
}
