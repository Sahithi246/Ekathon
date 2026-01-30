//
//  Untitled.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 30/01/26.
//

enum AnswerType {
    case yesNo
    case text
    case number
}

struct Question: Identifiable {
    let id: String
    let text: String
    let answerType: AnswerType
    let required: Bool
}
