//
//  AppleIntelligenceQAService.swift
//  HackathonApp
//
//  Uses Apple Intelligence (Foundation Models) to answer questionnaire
//  questions from transcript + backend patient data — no manual answering.
//

import Foundation

/// Generates AI suggestions for questionnaire questions using:
/// 1. Consultation transcript (e.g. from EkaScribe / voice)
/// 2. Backend patient data (e.g. Patient Medical History, Other medical notes)
///
/// When Apple Intelligence is available (iOS 18+ with Foundation Models),
/// uses the on-device model. Otherwise falls back to rule-based extraction.
final class AppleIntelligenceQAService {

    /// Generate suggestions for all questions using transcript + backend data.
    /// Call this after you have transcript and backend sections; pass the result
    /// into `QuestionnaireViewModel(suggestions:)`.
    func generateSuggestions(
        transcript: String,
        backendSections: [BackendMedicalSection],
        questions: [Question]
    ) async -> [AISuggestion] {
        let context = buildContext(transcript: transcript, backendSections: backendSections)

        if #available(iOS 26.0, *) {
            return await generateWithFoundationModels(context: context, questions: questions)
        } else {
            return generateWithFallback(context: context, questions: questions)
        }
    }

    // MARK: - Context

    private func buildContext(transcript: String, backendSections: [BackendMedicalSection]) -> String {
        var parts: [String] = []

        if !transcript.isEmpty {
            parts.append("## Consultation transcript\n\(transcript)")
        }

        for section in backendSections {
            parts.append("## \(section.title)\n\(section.items.map { "• \($0)" }.joined(separator: "\n"))")
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Apple Intelligence (Foundation Models)

    @available(iOS 18.0, *)
    private func generateWithFoundationModels(context: String, questions: [Question]) async -> [AISuggestion] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let suggestions = await FoundationModelsQARunner.generateSuggestions(context: context, questions: questions)
            if !suggestions.isEmpty {
                return suggestions
            }
        }
        #endif
        return generateWithFallback(context: context, questions: questions)
    }

    /// Prompt template for one question. Use this with Foundation Models when integrated.
    private func buildPrompt(context: String, question: Question) -> String {
        let format: String
        switch question.answerType {
        case .yesNo:
            format = "Answer with only Yes or No."
        case .number:
            format = "Answer with only a number."
        case .text:
            format = "Answer in one short sentence."
        }

        return """
        You are a medical assistant. Using ONLY the following patient information and consultation transcript, answer the question. \(format) Then on a new line write: SOURCE: <the exact sentence you used>.

        PATIENT INFORMATION AND TRANSCRIPT:
        \(context)

        QUESTION: \(question.text)

        ANSWER:
        """
    }

    /// Parse model output into AISuggestion (e.g. "Yes\nSOURCE: Patient is currently pregnant").
    private func parseResponse(_ response: String, questionId: String) -> AISuggestion? {
        let lines = response.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        guard let first = lines.first, !first.isEmpty else { return nil }
        let answer = first.replacingOccurrences(of: "SOURCE:", with: "").trimmingCharacters(in: .whitespaces)
        let sourceLine = lines.first { $0.uppercased().hasPrefix("SOURCE:") }
        let sourceText = sourceLine?
            .replacingOccurrences(of: "SOURCE:", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces) ?? answer
        return AISuggestion(
            questionId: questionId,
            suggestedAnswer: answer,
            confidence: 0.9,
            sourceText: sourceText
        )
    }

    // MARK: - Fallback (no Apple Intelligence)

    /// Fallback: derive answers from context using simple matching.
    /// Keeps the app working on devices without Apple Intelligence.
    private func generateWithFallback(context: String, questions: [Question]) -> [AISuggestion] {
        let contextLower = context.lowercased()
        let sentences = context
            .components(separatedBy: .newlines)
            .flatMap { $0.split(separator: ".").map { String($0).trimmingCharacters(in: .whitespaces) } }
            .filter { !$0.isEmpty && $0 != "•" }

        return questions.compactMap { question in
            answerOneQuestion(question, contextLower: contextLower, sentences: sentences)
        }
    }

    private func answerOneQuestion(
        _ question: Question,
        contextLower: String,
        sentences: [String]
    ) -> AISuggestion? {
        let qLower = question.text.lowercased()
        let qWords = Set(qLower.split(separator: " ").map(String.init).filter { $0.count > 2 })

        // Find best matching sentence
        var best: (sentence: String, score: Int)? = nil
        for sentence in sentences {
            let sLower = sentence.lowercased()
            let score = qWords.filter { sLower.contains($0) }.count
            if score > 0, best == nil || score > best!.score {
                best = (sentence, score)
            }
        }

        guard let (sentence, _) = best else { return nil }

        let answer: String
        switch question.answerType {
        case .yesNo:
            if sentence.lowercased().contains("not ") || sentence.lowercased().contains("no ") || sentence.lowercased().contains("never ") {
                answer = "No"
            } else if sentence.lowercased().contains("yes ") || sentence.lowercased().contains("is ") || sentence.lowercased().contains("has ") || sentence.lowercased().contains("have ") {
                answer = "Yes"
            } else {
                answer = sentence
            }
        case .number:
            let numbers = sentence.components(separatedBy: .decimalDigits.inverted).joined()
            answer = numbers.isEmpty ? sentence : numbers
        case .text:
            answer = sentence
        }

        return AISuggestion(
            questionId: question.id,
            suggestedAnswer: answer,
            confidence: 0.85,
            sourceText: sentence
        )
    }
}
