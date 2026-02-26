//
//  ViewController.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import UIKit

final class ViewController: UITableViewController {


    private let topics: [QuizTopic] = [
        QuizTopic(
            title: "Mathematics",
            desc: "Test your math skills with fun problems.",
            iconSystemName: "function",
            questions: [
                QuizQuestion(text: "What is 2 + 2?", answers: ["3", "4", "5"], correctIndex: 1),
                QuizQuestion(text: "What is 10 / 2?", answers: ["2", "5", "10"], correctIndex: 1),
            ]
        ),
        QuizTopic(
            title: "Marvel Super Heroes",
            desc: "How well do you know the Marvel universe?",
            iconSystemName: "bolt.fill",
            questions: [
                QuizQuestion(text: "Who is Iron Man?", answers: ["Steve Rogers", "Tony Stark", "Bruce Banner"], correctIndex: 1),
                QuizQuestion(text: "Thor is the god of…", answers: ["Thunder", "Mischief", "Time"], correctIndex: 0),
            ]
        ),
        QuizTopic(
            title: "Science",
            desc: "Explore physics, chemistry, and biology basics.",
            iconSystemName: "atom",
            questions: [
                QuizQuestion(text: "Water's chemical formula is…", answers: ["CO2", "H2O", "O2"], correctIndex: 1),
                QuizQuestion(text: "Earth revolves around the…", answers: ["Moon", "Mars", "Sun"], correctIndex: 2),
            ]
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "iQuiz"

//        // Register a cell type
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TopicCell")

        // Settings button (top right)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
    }

    @objc private func didTapSettings() {
        let alert = UIAlertController(title: "Settings",
                                      message: "Settings go here",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - TableView Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        topics.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Use subtitle style so we can show subtext
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "TopicCell")

        let topic = topics[indexPath.row]
        cell.textLabel?.text = topic.title
        cell.detailTextLabel?.text = topic.desc
        cell.imageView?.image = UIImage(systemName: topic.iconSystemName)
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.numberOfLines = 2

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let topic = topics[indexPath.row]
        let vc = QuizFlowViewController(topic: topic)
        navigationController?.pushViewController(vc, animated: true)
    }
}
