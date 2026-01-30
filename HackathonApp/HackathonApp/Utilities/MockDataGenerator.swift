//
//  MockDataGenerator.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Utility for generating mock data for demo purposes
class MockDataGenerator {
    
    /// Generate 7 days of historical cognitive data with realistic trends
    static func generateDemoData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate data for last 7 days with a slight improving trend
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Create improving trend: older days have worse scores
            let trendFactor = Double(dayOffset) / 7.0 // 0.0 = today, 1.0 = 7 days ago
            
            // Generate reaction time (improving over time = lower reaction time)
            let baseReaction = 320.0
            let reactionVariation = 50.0
            let avgReactionTime = baseReaction - (trendFactor * 40) + Double.random(in: -reactionVariation...reactionVariation)
            
            let reactionResult = ReactionTimeResult(
                timestamp: date,
                averageReactionTime: max(200, min(450, avgReactionTime)),
                testDuration: 60.0,
                numberOfTrials: 10,
                individualReactions: (0..<10).map { _ in 
                    max(200, min(450, avgReactionTime + Double.random(in: -30...30)))
                }
            )
            modelContext.insert(reactionResult)
            
            // Generate sleep data (improving sleep over time)
            let baseSleep = 7.0
            let sleepImprovement = 1.2
            let sleepHours = baseSleep + (trendFactor * sleepImprovement) + Double.random(in: -0.5...0.5)
            
            let sleepData = SleepData(
                date: calendar.startOfDay(for: date),
                totalSleepHours: max(5.5, min(9.5, sleepHours)),
                sleepStart: calendar.date(byAdding: .hour, value: -Int(sleepHours), to: date),
                sleepEnd: date
            )
            modelContext.insert(sleepData)
            
            // Generate photo recognition result (improving recognition over time)
            let baseAccuracy = 0.6
            let accuracyImprovement = 0.25
            let accuracy = baseAccuracy + (trendFactor * accuracyImprovement) + Double.random(in: -0.1...0.1)
            let totalPhotos = 5
            let correctAnswers = Int(round(accuracy * Double(totalPhotos)))
            
            let baseResponseTime = 4.5
            let responseTimeImprovement = 1.0
            let avgResponseTime = baseResponseTime - (trendFactor * responseTimeImprovement) + Double.random(in: -0.5...0.5)
            
            let photoRecognition = PhotoRecognitionResult(
                timestamp: date,
                totalPhotos: totalPhotos,
                correctAnswers: max(0, min(totalPhotos, correctAnswers)),
                incorrectAnswers: totalPhotos - max(0, min(totalPhotos, correctAnswers)),
                averageResponseTime: max(2.0, min(6.0, avgResponseTime)),
                individualResponseTimes: (0..<totalPhotos).map { _ in 
                    max(2.0, min(6.0, avgResponseTime + Double.random(in: -0.8...0.8)))
                }
            )
            modelContext.insert(photoRecognition)
            
            // Calculate and save cognitive score
            let score = CognitiveScoreService.calculateFromModels(
                reactionTime: reactionResult,
                sleep: sleepData,
                photoRecognition: photoRecognition
            )
            score.timestamp = date
            modelContext.insert(score)
        }
        
        // Save context
        do {
            try modelContext.save()
            print("✅ Demo data generated successfully")
        } catch {
            print("❌ Error generating mock data: \(error)")
        }
    }
    
    /// Check if demo data should be generated (first launch)
    static func shouldGenerateDemoData() -> Bool {
        // Check UserDefaults to see if we've already generated demo data
        return !UserDefaults.standard.bool(forKey: "hasGeneratedDemoData")
    }
    
    /// Mark demo data as generated
    static func markDemoDataGenerated() {
        UserDefaults.standard.set(true, forKey: "hasGeneratedDemoData")
    }
    
    /// Clear all existing data (for testing)
    static func clearAllData(modelContext: ModelContext) {
        // Note: In production, you'd want more sophisticated deletion
        // This is simplified for demo purposes
    }
}
