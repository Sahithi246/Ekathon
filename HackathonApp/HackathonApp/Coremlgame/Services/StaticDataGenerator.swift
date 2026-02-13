//
//  StaticDataGenerator.swift
//  Coremlgame
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Service to generate static sample data for testing
class StaticDataGenerator {
    
    static func generateSampleData(modelContext: ModelContext) {
        // Clear existing data
        let descriptor = FetchDescriptor<CoremlCognitiveScore>()
        if let existing = try? modelContext.fetch(descriptor) {
            for item in existing {
                modelContext.delete(item)
            }
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate Cognitive Scores (last 30 days)
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let score = Double.random(in: 60...90)
            let riskLevel: CoremlRiskLevel = score < 70 ? .medium : .low
            let cognitiveScore = CoremlCognitiveScore(
                timestamp: date,
                overallScore: score,
                riskLevel: riskLevel
            )
            modelContext.insert(cognitiveScore)
        }
        
        // Generate Reaction Time Results (last 30 days, every 2-3 days)
        for i in stride(from: 0, to: 30, by: 2) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let avgReactionTime = Double.random(in: 250...450)
            let reactionResult = CoremlReactionTimeResult(
                timestamp: date,
                averageReactionTime: avgReactionTime,
                reactionTimes: [avgReactionTime - 20, avgReactionTime, avgReactionTime + 20]
            )
            modelContext.insert(reactionResult)
        }
        
        // Generate Sleep Data (last 30 days, daily)
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let sleepHours = Double.random(in: 5.5...9.5)
            let sleepQuality = Double.random(in: 60...90)
            let sleepData = CoremlSleepData(
                date: date,
                totalSleepHours: sleepHours,
                sleepQuality: sleepQuality
            )
            modelContext.insert(sleepData)
        }
        
        // Generate Photo Recognition Results (last 30 days, every 3-4 days)
        for i in stride(from: 0, to: 30, by: 3) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let totalQuestions = Int.random(in: 10...20)
            let correctAnswers = Int.random(in: Int(Double(totalQuestions) * 0.6)...totalQuestions)
            let accuracy = (Double(correctAnswers) / Double(totalQuestions)) * 100.0
            let avgResponseTime = Double.random(in: 2.0...5.0)
            let photoResult = CoremlPhotoRecognitionResult(
                timestamp: date,
                accuracy: accuracy,
                averageResponseTime: avgResponseTime,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers
            )
            modelContext.insert(photoResult)
        }
        
        // Save context
        try? modelContext.save()
    }
}
