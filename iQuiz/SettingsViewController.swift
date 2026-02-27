//
//  SettingsViewController.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import UIKit

final class SettingsViewController: UIViewController {

    private let urlField = UITextField()
    private let checkNowButton = UIButton(type: .system)
    private let intervalField = UITextField()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Settings"
        setupUI()
        urlField.text = SettingsStore.quizURL
        intervalField.text = "\(SettingsStore.refreshIntervalSeconds)"
    }

    private func setupUI() {
        urlField.borderStyle = .roundedRect
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.keyboardType = .URL
        urlField.placeholder = "Quiz JSON URL"
        
        intervalField.borderStyle = .roundedRect
        intervalField.keyboardType = .numberPad
        intervalField.placeholder = "Auto-refresh interval (seconds, 0 = off)"

        saveButton.setTitle("Save Refreshing Setting", for: .normal)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        
        checkNowButton.setTitle("Check Now", for: .normal)
        checkNowButton.addTarget(self, action: #selector(didTapCheckNow), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [urlField, intervalField, saveButton, checkNowButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }

    @objc private func didTapCheckNow() {
        didTapSave() // save first so download uses the new URL/interval

        guard NetworkMonitor.shared.isConnected else {
            showAlert(title: "Network Error", message: "Network is not available.")
            return
        }

        QuizDataStore.shared.refresh { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(title: "Updated", message: "Downloaded latest quiz data.")
            case .failure:
                self?.showAlert(title: "Download Failed", message: "Could not download or decode quiz data.")
            }
        }
    }

    @objc private func didTapSave() {
        // Save URL
        let urlText = (urlField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlText.isEmpty { SettingsStore.quizURL = urlText }

        // Save interval
        let intervalText = (intervalField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let interval = Int(intervalText) ?? 0
        SettingsStore.refreshIntervalSeconds = max(0, interval)

        // Notify list screen to reconfigure timer
        NotificationCenter.default.post(name: .settingsChanged, object: nil)

        showAlert(title: "Saved", message: "Settings updated.")
    }
    
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
