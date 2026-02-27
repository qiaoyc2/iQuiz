//
//  ViewController.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import UIKit

final class ViewController: UITableViewController {


    private var topics: [QuizTopic] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "iQuiz"

        topics = QuizDataStore.shared.topics

        NotificationCenter.default.addObserver(self,
                                                selector: #selector(handleDataUpdate),
                                                name: .quizDataUpdated,
                                                object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
    }

    @objc private func didTapSettings() {
//        let alert = UIAlertController(title: "Settings",
//                                      message: "Settings go here",
//                                      preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
        navigationController?.pushViewController(SettingsViewController(), animated: true)
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
    
    @objc private func handleDataUpdate() {
        topics = QuizDataStore.shared.topics
        tableView.reloadData()
    }

}
