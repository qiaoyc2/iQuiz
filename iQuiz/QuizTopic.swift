//
//  QuizTopic.swift
//  iQuiz
//
//  Created by Katharina Cheng on 2/26/26.
//

import Foundation

struct QuizQuestion {
    let text: String
    let answers: [String]
    let correctIndex: Int
}

struct QuizTopic {
    let title: String
    let desc: String
    let iconSystemName: String
    let questions: [QuizQuestion]
}

struct QuizTopicDTO: Codable {
    let title: String
    let desc: String
    let questions: [QuizQuestionDTO]
}

struct QuizQuestionDTO: Codable {
    let text: String
    let answer: String      // e.g. "1" (1-based index as string)
    let answers: [String]
}

extension QuizTopicDTO {
    func toModel() -> QuizTopic {
        let icon: String = {
            let t = title.lowercased()
            if t.contains("math") { return "function" }
            if t.contains("marvel") { return "bolt.fill" }
            if t.contains("science") { return "atom" }
            return "questionmark.circle"
        }()

        let qs: [QuizQuestion] = questions.map { q in
            let oneBased = Int(q.answer) ?? 1
            let zeroBased = oneBased - 1
            let safeIndex = max(0, min(q.answers.count - 1, zeroBased))
            return QuizQuestion(text: q.text, answers: q.answers, correctIndex: safeIndex)
        }

        return QuizTopic(title: title, desc: desc, iconSystemName: icon, questions: qs)
    }
}
