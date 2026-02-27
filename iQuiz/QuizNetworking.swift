//
//  QuizNetworking.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import Foundation
import Network

// MARK: - Notification for list refresh

extension Notification.Name {
    static let quizDataUpdated = Notification.Name("quizDataUpdated")
}

// MARK: - Settings persistence (URL field)

enum SettingsStore {
    private static let urlKey = "quizSourceURL"
    static let defaultURL = "http://tednewardsandbox.site44.com/questions.json"

    static var quizURL: String {
        get { UserDefaults.standard.string(forKey: urlKey) ?? defaultURL }
        set { UserDefaults.standard.set(newValue, forKey: urlKey) }
    }
}

// MARK: - Network availability monitor

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Service (download + decode)

enum QuizServiceError: Error {
    case badURL
    case noData
}

final class QuizService {
    func fetchTopics(from urlString: String, completion: @escaping (Result<[QuizTopic], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(QuizServiceError.badURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(QuizServiceError.noData)) }
                return
            }

            do {
                // JSON format: [ { "title":..., "desc":..., "questions":[...] }, ... ]
                let dtos = try JSONDecoder().decode([QuizTopicDTO].self, from: data)
                let models = dtos.map { $0.toModel() }
                DispatchQueue.main.async { completion(.success(models)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}

// MARK: - Data store (holds latest topics + notifies list)

final class QuizDataStore {
    static let shared = QuizDataStore()

    private(set) var topics: [QuizTopic] = []
    private let service = QuizService()

    private init() {}

    /// Downloads from SettingsStore.quizURL and updates `topics`.
    /// Posts Notification.Name.quizDataUpdated on success.
    func refresh(completion: @escaping (Result<[QuizTopic], Error>) -> Void) {
        service.fetchTopics(from: SettingsStore.quizURL) { [weak self] result in
            switch result {
            case .success(let topics):
                self?.topics = topics
                NotificationCenter.default.post(name: .quizDataUpdated, object: nil)
                completion(.success(topics))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}
