//
//  ViewController.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import UIKit

final class ViewController: UITableViewController {


    private var topics: [QuizTopic] = []
    private var refreshTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QuizDataStore.shared.loadFromDiskIfAvailable()
        topics = QuizDataStore.shared.topics
        
        title = "iQuiz"
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(handleDataUpdate),
                                                name: .quizDataUpdated,
                                                object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(settingsDidChange),
                                               name: .settingsChanged,
                                               object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        
        
    }

    @objc private func didTapSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc private func pullToRefresh() {
        // Optional: if no network, just stop spinner + alert
        guard NetworkMonitor.shared.isConnected else {
            refreshControl?.endRefreshing()
            let a = UIAlertController(title: "Network Error", message: "Network is not available.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        QuizDataStore.shared.refresh { [weak self] _ in
            self?.refreshControl?.endRefreshing()
            // topics + table reload will happen via Notification .quizDataUpdated
        }
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureRefreshTimer()
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        refreshTimer?.invalidate()
//        refreshTimer = nil
//    }
    
    @objc private func handleDataUpdate() {
        topics = QuizDataStore.shared.topics
        tableView.reloadData()
    }
    
    @objc private func settingsDidChange() {
        configureRefreshTimer()
    }

    private func configureRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil

        let interval = SettingsStore.refreshIntervalSeconds
        guard interval > 0 else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            guard let self else { return }
            guard NetworkMonitor.shared.isConnected else { return } // silently skip if offline

            QuizDataStore.shared.refresh { _ in
                // list reload happens via .quizDataUpdated
            }
        }
    }

    
}
