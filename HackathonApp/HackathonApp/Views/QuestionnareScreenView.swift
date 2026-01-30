//
//  QuestionnareScreenView.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 30/01/26.
//

import SwiftUI

struct QuestionnaireScreen: View {

  let questions: [Question]
  let transcript: String
  let backendSections: [BackendMedicalSection]

  @StateObject private var viewModel: QuestionnaireViewModel
  @State private var isLoadingSuggestions = false

  /// Form filling from backend data (and optional transcript). Suggestions are
  /// generated from this data only (Apple Intelligence or fallback).
  init(
    questions: [Question],
    transcript: String = "",
    backendSections: [BackendMedicalSection] = []
  ) {
    self.questions = questions
    self.transcript = transcript
    self.backendSections = backendSections
    _viewModel = StateObject(wrappedValue: QuestionnaireViewModel(suggestions: []))
  }

  var body: some View {
    ScrollView {
      if isLoadingSuggestions {
        ProgressView("Generating answers from transcript & patient data…")
          .padding()
      }
      ForEach(questions) { question in
        QuestionRow(
          question: question,
          suggestion: viewModel.suggestions[question.id],
          viewModel: viewModel
        )
      }

      Button("Submit") {
        print("Final answers:", viewModel.answers)
      }
      .padding()
    }
    .task(id: "\(transcript.count)-\(backendSections.count)") {
      guard !transcript.isEmpty || !backendSections.isEmpty else { return }
      isLoadingSuggestions = true
      let service = AppleIntelligenceQAService()
      let suggestions = await service.generateSuggestions(
        transcript: transcript,
        backendSections: backendSections,
        questions: questions
      )
      viewModel.setSuggestions(suggestions)
      isLoadingSuggestions = false
    }
  }
}

struct QuestionRow: View {

  let question: Question
  let suggestion: AISuggestion?
  @ObservedObject var viewModel: QuestionnaireViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {

      Text(question.text)
        .font(.headline)

      if let suggestion {
        VStack(alignment: .leading, spacing: 4) {
          Text("AI Suggestion: \(suggestion.suggestedAnswer)")
            .foregroundColor(.blue)

          Text("Based on: \(suggestion.sourceText)")
            .font(.caption)
            .foregroundColor(.gray)

          Button("Insert") {
            viewModel.applySuggestion(for: question)
          }
        }
      }

      inputView
    }
    .padding()
  }

  @ViewBuilder
  private var inputView: some View {
    switch question.answerType {
    case .yesNo:
      Picker("", selection: Binding(
        get: { viewModel.answer(for: question.id) },
        set: { viewModel.updateAnswer($0, for: question.id) }
      )) {
        Text("Select…").tag("")
        Text("Yes").tag("Yes")
        Text("No").tag("No")
      }
      .pickerStyle(.menu)

    case .number:
      TextField("Enter number", text: Binding(
        get: { viewModel.answer(for: question.id) },
        set: { viewModel.updateAnswer(filterNumeric($0), for: question.id) }
      ))
      .textFieldStyle(.roundedBorder)
      .keyboardType(.decimalPad)

    case .text:
      TextField("Your answer", text: Binding(
        get: { viewModel.answer(for: question.id) },
        set: { viewModel.updateAnswer($0, for: question.id) }
      ))
      .textFieldStyle(.roundedBorder)
    }
  }
}

private func filterNumeric(_ string: String) -> String {
  string.filter { $0.isNumber || $0 == "." }
}
