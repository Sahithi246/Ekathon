//
//  FoundationModelsQARunner.swift
//  HackathonApp
//
//  Uses Apple Intelligence (Foundation Models) to answer questionnaire
//  questions from context. Requires iOS 26+ and Foundation Models capability.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Runs Q&A using Foundation Models when available (iOS 26+, Apple Intelligence).
/// Use only from AppleIntelligenceQAService so fallback is applied on older OS.
enum FoundationModelsQARunner {

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    static func generateSuggestions(context: String, questions: [Question]) async -> [AISuggestion] {
        var suggestions: [AISuggestion] = []
        let session = LanguageModelSession(
            instructions: """
            You are a medical assistant. Answer questions using ONLY the provided patient information and transcript. \
            Reply with the answer first, then on a new line write SOURCE: and the exact sentence you used. \
            For yes/no questions answer only Yes or No. For numbers answer only the number. Keep answers short.
            """
        )

        do {
            try await session.prewarm()
        } catch {
            return []
        }

        for question in questions {
            let format: String
            switch question.answerType {
            case .yesNo:
                format = "Answer with only Yes or No."
            case .number:
                format = "Answer with only a number."
            case .text:
                format = "Answer in one short sentence."
            }

            let prompt = """
            PATIENT INFORMATION AND TRANSCRIPT:
            \(context)

            QUESTION: \(question.text)
            \(format) Then on a new line: SOURCE: <exact sentence from the text above>.

            ANSWER:
            """

            do {
                let response = try await session.respond(to: prompt)
                let content = response.content
                if let suggestion = parseResponse(content, questionId: question.id) {
                    suggestions.append(suggestion)
                }
            } catch {
                continue
            }
        }

        return suggestions
    }

    private static func parseResponse(_ response: String, questionId: String) -> AISuggestion? {
        let lines = response.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        guard let first = lines.first, !first.isEmpty else { return nil }
        let answer = first
            .replacingOccurrences(of: "SOURCE:", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        let sourceLine = lines.first { $0.uppercased().hasPrefix("SOURCE:") }
        let sourceText = sourceLine?
            .replacingOccurrences(of: "SOURCE:", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces) ?? answer
        return AISuggestion(
            questionId: questionId,
            suggestedAnswer: answer,
            confidence: 0.92,
            sourceText: sourceText
        )
    }
    #endif
}
