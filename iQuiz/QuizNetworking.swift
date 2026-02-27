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
    static let settingsChanged = Notification.Name("settingsChanged")
}

// MARK: - Settings persistence (URL field)

enum SettingsStore {
    private static let urlKey = "quizSourceURL"
    static let defaultURL = "http://tednewardsandbox.site44.com/questions.json"
    private static let refreshKey = "refreshIntervalSeconds"

    static var quizURL: String {
        get { UserDefaults.standard.string(forKey: urlKey) ?? defaultURL }
        set { UserDefaults.standard.set(newValue, forKey: urlKey) }
    }
    
    static var refreshIntervalSeconds: Int {
        get { UserDefaults.standard.integer(forKey: refreshKey) } // 0 if not set
        set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
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
    func fetchRawJSON(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
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
            DispatchQueue.main.async { completion(.success(data)) }
        }.resume()
    }

    func decodeTopics(from data: Data) throws -> [QuizTopic] {
        let dtos = try JSONDecoder().decode([QuizTopicDTO].self, from: data)
        return dtos.map { $0.toModel() }
    }
}


// MARK: - Data store (holds latest topics + notifies list)

enum QuizCache {
    private static let fileName = "cached_questions.json"

    private static var fileURL: URL {
        let fm = FileManager.default
        let dir = try! fm.url(for: .applicationSupportDirectory,
                              in: .userDomainMask,
                              appropriateFor: nil,
                              create: true)
        return dir.appendingPathComponent(fileName)
    }

    static func save(_ data: Data) throws {
        try data.write(to: fileURL, options: [.atomic])
    }

    static func load() throws -> Data {
        try Data(contentsOf: fileURL)
    }

    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
}

final class QuizDataStore {
    static let shared = QuizDataStore()

    private(set) var topics: [QuizTopic] = []
    private let service = QuizService()

    private init() {}

    func loadFromDiskIfAvailable() {
        guard QuizCache.exists() else { return }
        do {
            let data = try QuizCache.load()
            let models = try service.decodeTopics(from: data)
            topics = models
            NotificationCenter.default.post(name: .quizDataUpdated, object: nil)
        } catch {
            // ignore; cache may be corrupted
        }
    }

    func refresh(completion: @escaping (Result<[QuizTopic], Error>) -> Void) {
        service.fetchRawJSON(from: SettingsStore.quizURL) { [weak self] result in
            switch result {
            case .success(let data):
                do {
                    let models = try self?.service.decodeTopics(from: data) ?? []
                    // Save to disk for offline use
                    try QuizCache.save(data)

                    self?.topics = models
                    NotificationCenter.default.post(name: .quizDataUpdated, object: nil)
                    completion(.success(models))
                } catch {
                    completion(.failure(error))
                }

            case .failure(let err):
                // OFFLINE FALLBACK: load cached file
                if QuizCache.exists() {
                    do {
                        let data = try QuizCache.load()
                        let models = try self?.service.decodeTopics(from: data) ?? []
                        self?.topics = models
                        NotificationCenter.default.post(name: .quizDataUpdated, object: nil)
                        completion(.success(models))
                    } catch {
                        completion(.failure(err)) // fallback failed too
                    }
                } else {
                    completion(.failure(err))
                }
            }
        }
    }
}
