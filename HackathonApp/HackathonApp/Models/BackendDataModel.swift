//
//  Untitled.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 30/01/26.
//

import Foundation

struct BackendMedicalSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [String]
}

struct AISuggestion {
    let questionId: String
    let suggestedAnswer: String
    let confidence: Double
    let sourceText: String
}

