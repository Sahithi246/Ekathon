//
//  Untitled.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 30/01/26.
//

import Foundation
import Combine

final class QuestionnaireViewModel: ObservableObject {
  
  @Published var answers: [String: String] = [:]
  @Published var suggestions: [String: AISuggestion] = [:]
  
  init(suggestions: [AISuggestion]) {
    self.suggestions = Dictionary(
      uniqueKeysWithValues: suggestions.map { ($0.questionId, $0) }
    )
  }

  /// Update suggestions (e.g. after Apple Intelligence returns answers).
  func setSuggestions(_ newSuggestions: [AISuggestion]) {
    suggestions = Dictionary(
      uniqueKeysWithValues: newSuggestions.map { ($0.questionId, $0) }
    )
  }

  func applySuggestion(for question: Question) {
    guard let suggestion = suggestions[question.id] else { return }
    answers[question.id] = suggestion.suggestedAnswer
  }
  
  func updateAnswer(_ value: String, for questionId: String) {
    answers[questionId] = value
  }
  
  func answer(for questionId: String) -> String {
    answers[questionId] ?? ""
  }
}

