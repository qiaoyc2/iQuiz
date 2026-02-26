//
//  QuizFlowViewController.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import UIKit

final class QuizFlowViewController: UIViewController {

    // MARK: - State

    private enum Mode {
        case question
        case answer(isCorrect: Bool)
        case finished
    }

    private let topic: QuizTopic
    private var index: Int = 0
    private var score: Int = 0
    private var selectedIndex: Int? = nil
    private var mode: Mode = .question

    // MARK: - UI

    private let titleLabel = UILabel()
    private let questionLabel = UILabel()
    private let hintLabel = UILabel()

    private let optionsStack = UIStackView()
    private var optionButtons: [UIButton] = []

    private let feedbackLabel = UILabel()      // Correct / Wrong
    private let correctAnswerLabel = UILabel() // Correct answer: ...

    private let primaryButton = UIButton(type: .system) // Submit / Next

    // MARK: - Init

    init(topic: QuizTopic) {
        self.topic = topic
        super.init(nibName: nil, bundle: nil)
        self.title = topic.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupGestures()
        render()
    }

    // MARK: - Setup

    private func setupUI() {
        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 1

        questionLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        questionLabel.numberOfLines = 0

        feedbackLabel.font = .systemFont(ofSize: 20, weight: .bold)
        feedbackLabel.numberOfLines = 0

        correctAnswerLabel.font = .systemFont(ofSize: 16, weight: .regular)
        correctAnswerLabel.textColor = .secondaryLabel
        correctAnswerLabel.numberOfLines = 0
        
        hintLabel.font = .systemFont(ofSize: 13, weight: .regular)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0

        // Options stack
        optionsStack.axis = .vertical
        optionsStack.spacing = 12
        optionsStack.alignment = .fill
        optionsStack.distribution = .fill

        // Primary button
        primaryButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        primaryButton.layer.cornerRadius = 12
        primaryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        primaryButton.addTarget(self, action: #selector(didTapPrimary), for: .touchUpInside)

        // Layout stack
        let content = UIStackView(arrangedSubviews: [
            titleLabel,
            questionLabel,
            optionsStack,
            feedbackLabel,
            correctAnswerLabel,
            hintLabel,
            primaryButton
        ])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }
    
    private func setupGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
    }

    @objc private func didSwipeRight() {
        switch mode {
        case .question:
            guard selectedIndex != nil else { return }
            handleSubmit()
        case .answer:
            handleNext()
        case .finished:
            navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc private func didSwipeLeft() {
        // abandon quiz + discard score
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Render

    private func render() {
        switch mode {
        case .question:
            renderQuestion()
        case .answer(let isCorrect):
            renderAnswer(isCorrect: isCorrect)
        case .finished:
            renderFinished()
        }
    }

    private func renderQuestion() {
        let q = topic.questions[index]

        titleLabel.text = "Question \(index + 1) of \(topic.questions.count)"
        questionLabel.text = q.text
        hintLabel.text = "Tip: Swipe → to Submit • Swipe ← to Quit"
        feedbackLabel.isHidden = true
        correctAnswerLabel.isHidden = true

        // reset selection
        selectedIndex = nil
        primaryButton.setTitle("Submit", for: .normal)
        primaryButton.isEnabled = false

        // build options
        rebuildOptions(answers: q.answers, enabled: true)
        updateOptionStyles()
    }

    private func renderAnswer(isCorrect: Bool) {
        let q = topic.questions[index]

        titleLabel.text = "Answer"
        questionLabel.text = q.text
        hintLabel.text = "Tip: Swipe → for Next • Swipe ← to Quit"

        feedbackLabel.isHidden = false
        correctAnswerLabel.isHidden = false

        feedbackLabel.text = isCorrect ? "✅ Correct!" : "❌ Wrong"
        feedbackLabel.textColor = isCorrect ? .systemGreen : .systemRed

        correctAnswerLabel.text = "Correct answer: \(q.answers[q.correctIndex])"

        primaryButton.setTitle("Next", for: .normal)
        primaryButton.isEnabled = true

        // show options but disable taps
        rebuildOptions(answers: q.answers, enabled: false)
        updateOptionStyles(showCorrect: true)
    }

    private func renderFinished() {
        let total = topic.questions.count

        titleLabel.text = "Finished"
        questionLabel.text = performanceText(score: score, total: total)
        hintLabel.text = "Tip: Tap Next to return"
        // hide options + answer labels
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionButtons = []

        feedbackLabel.isHidden = true
        correctAnswerLabel.isHidden = false
        correctAnswerLabel.text = "Score: \(score) of \(total) correct"
        correctAnswerLabel.textColor = .secondaryLabel

        primaryButton.setTitle("Next", for: .normal) // rubric says Next to continue
        primaryButton.isEnabled = true
    }

    private func performanceText(score: Int, total: Int) -> String {
        if score == total { return "Perfect! 🎉" }
        if score == total - 1 { return "Almost! 👍" }
        return "Good try! 💪"
    }

    // MARK: - Options

    private func rebuildOptions(answers: [String], enabled: Bool) {
        // clear old
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionButtons = []

        for (i, ans) in answers.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(ans, for: .normal)
            btn.tag = i
            btn.isEnabled = enabled
            btn.contentHorizontalAlignment = .left
            btn.titleLabel?.numberOfLines = 0
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray4.cgColor
            btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            btn.addTarget(self, action: #selector(didTapOption(_:)), for: .touchUpInside)

            optionsStack.addArrangedSubview(btn)
            optionButtons.append(btn)
        }
    }

    private func updateOptionStyles(showCorrect: Bool = false) {
        let q = topic.questions[index]

        for btn in optionButtons {
            let isSelected = (btn.tag == selectedIndex)
            let isCorrect = (btn.tag == q.correctIndex)

            btn.backgroundColor = .clear
            btn.layer.borderColor = UIColor.systemGray4.cgColor

            if isSelected {
                btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
                btn.layer.borderColor = UIColor.systemBlue.cgColor
            }

            if showCorrect && isCorrect {
                btn.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
                btn.layer.borderColor = UIColor.systemGreen.cgColor
            }
        }
    }

    // MARK: - Actions

    @objc private func didTapOption(_ sender: UIButton) {
        selectedIndex = sender.tag
        primaryButton.isEnabled = true
        updateOptionStyles()
    }

    @objc private func didTapPrimary() {
        switch mode {
        case .question:
            handleSubmit()
        case .answer:
            handleNext()
        case .finished:
            // "Next" to continue -> go back to main list
            navigationController?.popToRootViewController(animated: true)
        }
    }

    private func handleSubmit() {
        guard let chosen = selectedIndex else { return }
        let q = topic.questions[index]
        let isCorrect = (chosen == q.correctIndex)
        if isCorrect { score += 1 }
        mode = .answer(isCorrect: isCorrect)
        render()
    }

    private func handleNext() {
        index += 1
        if index < topic.questions.count {
            mode = .question
        } else {
            mode = .finished
        }
        render()
    }
}
