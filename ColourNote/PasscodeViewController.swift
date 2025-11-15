//
//  PasscodeViewController.swift
//  ColourNote
//
//  Created for passcode entry functionality
//

import UIKit

enum PasscodeMode {
    case setup      // Setting up a new passcode (asks for confirmation)
    case entry      // Entering existing passcode for validation
    case change     // Changing passcode (requires old, then new)
}

class PasscodeViewController: UIViewController {

    var mode: PasscodeMode = .entry
    var titleText: String = "Enter Passcode"
    var onSuccess: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var passcodeDigits: [String] = []
    private var confirmPasscode: String?
    private var isConfirming = false

    // UI Elements
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dotsStackView = UIStackView()
    private let messageLabel = UILabel()
    private let numberPadStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        // Title
        titleLabel.text = titleText
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = mode == .setup ? "Create a 4-digit passcode" : "Enter your 4-digit passcode"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Dots container
        dotsStackView.axis = .horizontal
        dotsStackView.spacing = 20
        dotsStackView.distribution = .fillEqually
        dotsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dotsStackView)

        for _ in 0..<4 {
            let dotView = createDotView()
            dotsStackView.addArrangedSubview(dotView)
        }

        // Message label (for errors)
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .systemRed
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)

        // Number pad
        numberPadStackView.axis = .vertical
        numberPadStackView.spacing = 15
        numberPadStackView.distribution = .fillEqually
        numberPadStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(numberPadStackView)

        createNumberPad()

        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            dotsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            dotsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dotsStackView.widthAnchor.constraint(equalToConstant: 200),
            dotsStackView.heightAnchor.constraint(equalToConstant: 40),

            messageLabel.topAnchor.constraint(equalTo: dotsStackView.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            numberPadStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            numberPadStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            numberPadStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            numberPadStackView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func createDotView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let circle = UIView()
        circle.backgroundColor = .clear
        circle.layer.borderWidth = 2
        circle.layer.borderColor = UIColor.systemGray3.cgColor
        circle.layer.cornerRadius = 15
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.tag = 100 // Tag for filled state

        container.addSubview(circle)

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 30),
            circle.heightAnchor.constraint(equalToConstant: 30)
        ])

        return container
    }

    private func createNumberPad() {
        let rows = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["Cancel", "0", "⌫"]
        ]

        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 15
            rowStack.distribution = .fillEqually

            for number in row {
                let button = createNumberButton(title: number)
                rowStack.addArrangedSubview(button)
            }

            numberPadStackView.addArrangedSubview(rowStack)
        }
    }

    private func createNumberButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 35
        button.addTarget(self, action: #selector(numberButtonTapped(_:)), for: .touchUpInside)

        if title == "Cancel" {
            button.setTitleColor(.systemRed, for: .normal)
        } else if title == "⌫" {
            button.setTitleColor(.systemOrange, for: .normal)
        }

        return button
    }

    @objc private func numberButtonTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }

        messageLabel.text = ""

        if title == "Cancel" {
            onCancel?()
            dismiss(animated: true)
        } else if title == "⌫" {
            if !passcodeDigits.isEmpty {
                passcodeDigits.removeLast()
                updateDots()
            }
        } else if let digit = Int(title), passcodeDigits.count < 4 {
            passcodeDigits.append(title)
            updateDots()

            if passcodeDigits.count == 4 {
                handlePasscodeEntry()
            }
        }
    }

    private func updateDots() {
        for (index, dotContainer) in dotsStackView.arrangedSubviews.enumerated() {
            if let circle = dotContainer.subviews.first {
                if index < passcodeDigits.count {
                    circle.backgroundColor = .systemBlue
                    circle.layer.borderColor = UIColor.systemBlue.cgColor
                } else {
                    circle.backgroundColor = .clear
                    circle.layer.borderColor = UIColor.systemGray3.cgColor
                }
            }
        }
    }

    private func handlePasscodeEntry() {
        let enteredPasscode = passcodeDigits.joined()

        switch mode {
        case .entry:
            // Validate passcode
            if PasscodeManager.shared.validatePasscode(enteredPasscode) {
                onSuccess?(enteredPasscode)
                dismiss(animated: true)
            } else {
                showError("Incorrect passcode")
                clearPasscode()
            }

        case .setup:
            if !isConfirming {
                // First entry - ask for confirmation
                confirmPasscode = enteredPasscode
                isConfirming = true
                subtitleLabel.text = "Confirm your passcode"
                clearPasscode()
            } else {
                // Confirmation entry
                if enteredPasscode == confirmPasscode {
                    if PasscodeManager.shared.setPasscode(enteredPasscode) {
                        onSuccess?(enteredPasscode)
                        dismiss(animated: true)
                    } else {
                        showError("Failed to set passcode")
                        resetSetup()
                    }
                } else {
                    showError("Passcodes don't match")
                    resetSetup()
                }
            }

        case .change:
            // For change mode, validate first then switch to setup mode
            if PasscodeManager.shared.validatePasscode(enteredPasscode) {
                mode = .setup
                titleText = "Set New Passcode"
                titleLabel.text = titleText
                subtitleLabel.text = "Create a 4-digit passcode"
                clearPasscode()
            } else {
                showError("Incorrect current passcode")
                clearPasscode()
            }
        }
    }

    private func clearPasscode() {
        passcodeDigits.removeAll()
        updateDots()
    }

    private func resetSetup() {
        isConfirming = false
        confirmPasscode = nil
        subtitleLabel.text = "Create a 4-digit passcode"
        clearPasscode()
    }

    private func showError(_ message: String) {
        messageLabel.text = message
        shakeAnimation()
    }

    private func shakeAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        dotsStackView.layer.add(animation, forKey: "shake")
    }
}
