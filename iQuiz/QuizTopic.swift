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
