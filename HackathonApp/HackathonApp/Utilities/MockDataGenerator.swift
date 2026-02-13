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
    
    /// Generate 14 days of historical cognitive data with realistic trends and variation
    static func generateDemoData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
            // Generate data for last 14 days with realistic variation
            // Not all days will have all tests - more realistic data collection pattern
            var dayData: [Date: (reaction: ReactionTimeResult?, sleep: SleepData?, photo: PhotoRecognitionResult?, shape: ShapeSequenceResult?)] = [:]
            
            for dayOffset in 0..<14 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let dayStart = calendar.startOfDay(for: date)
                
                // Create slight improving trend with natural variation
                let trendFactor = Double(dayOffset) / 14.0 // 0.0 = today, 1.0 = 14 days ago
                let dayVariation = sin(Double(dayOffset) * 0.5) * 0.3 // Natural fluctuation
                
                var dayReaction: ReactionTimeResult? = nil
                var daySleep: SleepData? = nil
                var dayPhoto: PhotoRecognitionResult? = nil
                var dayShape: ShapeSequenceResult? = nil
                
                // REACTION TIME TEST (not every day - more realistic)
                if dayOffset % 2 == 0 || dayOffset < 3 { // Every other day, or first 3 days
                    let baseReaction = 350.0
                    let improvement = trendFactor * 50.0
                    let variation = Double.random(in: -60...60) + (dayVariation * 40)
                    let avgReactionTime = baseReaction - improvement + variation
                    
                    dayReaction = ReactionTimeResult(
                        timestamp: calendar.date(byAdding: .hour, value: Int.random(in: 9...18), to: dayStart) ?? date,
                        averageReactionTime: max(180, min(480, avgReactionTime)),
                        testDuration: Double.random(in: 50...70),
                        numberOfTrials: Int.random(in: 8...12),
                        individualReactions: (0..<Int.random(in: 8...12)).map { _ in 
                            max(180, min(480, avgReactionTime + Double.random(in: -40...40)))
                        }
                    )
                    modelContext.insert(dayReaction!)
                }
                
                // SLEEP DATA (every day)
                let baseSleep = 6.8
                let sleepImprovement = trendFactor * 1.5
                let sleepVariation = Double.random(in: -1.2...1.2) + (dayVariation * 0.8)
                let sleepHours = baseSleep + sleepImprovement + sleepVariation
                
                let sleepStartHour = Int.random(in: 22...24)
                daySleep = SleepData(
                    date: dayStart,
                    totalSleepHours: max(5.0, min(10.0, sleepHours)),
                    sleepStart: calendar.date(byAdding: .hour, value: sleepStartHour, to: calendar.date(byAdding: .day, value: -1, to: dayStart) ?? date) ?? date,
                    sleepEnd: calendar.date(byAdding: .hour, value: Int(sleepHours) + sleepStartHour - 24, to: dayStart) ?? date
                )
                modelContext.insert(daySleep!)
                
                // PHOTO RECOGNITION TEST (every 2-3 days)
                if dayOffset % 3 == 0 || dayOffset < 4 {
                    let baseAccuracy = 0.55
                    let accuracyImprovement = trendFactor * 0.3
                    let accuracyVariation = Double.random(in: -0.15...0.15) + (dayVariation * 0.1)
                    let accuracy = baseAccuracy + accuracyImprovement + accuracyVariation
                    
                    let totalPhotos = Int.random(in: 4...6)
                    let correctAnswers = Int(round(accuracy * Double(totalPhotos)))
                    
                    let baseResponseTime = 5.2
                    let responseTimeImprovement = trendFactor * 1.2
                    let responseVariation = Double.random(in: -0.8...0.8)
                    let avgResponseTime = baseResponseTime - responseTimeImprovement + responseVariation
                    
                    dayPhoto = PhotoRecognitionResult(
                        timestamp: calendar.date(byAdding: .hour, value: Int.random(in: 10...19), to: dayStart) ?? date,
                        totalPhotos: totalPhotos,
                        correctAnswers: max(0, min(totalPhotos, correctAnswers)),
                        incorrectAnswers: totalPhotos - max(0, min(totalPhotos, correctAnswers)),
                        averageResponseTime: max(2.5, min(7.0, avgResponseTime)),
                        individualResponseTimes: (0..<totalPhotos).map { _ in 
                            max(2.5, min(7.0, avgResponseTime + Double.random(in: -1.0...1.0)))
                        }
                    )
                    modelContext.insert(dayPhoto!)
                }
                
                // SHAPE SEQUENCE TEST (every 2-3 days, different from photo recognition)
                if dayOffset % 3 == 1 || dayOffset < 4 {
                    let baseSequenceLength = 3
                    let sequenceImprovement = Int(trendFactor * 2.5)
                    let sequenceLength = baseSequenceLength + sequenceImprovement + Int.random(in: -1...2)
                    
                    let totalRounds = Int.random(in: 2...4)
                    let correctRounds = Int.random(in: max(1, totalRounds - 2)...totalRounds)
                    
                    let baseResponseTime = 4.8
                    let responseTimeImprovement = trendFactor * 1.0
                    let responseVariation = Double.random(in: -0.9...0.9)
                    let avgResponseTime = baseResponseTime - responseTimeImprovement + responseVariation
                    
                    dayShape = ShapeSequenceResult(
                        timestamp: calendar.date(byAdding: .hour, value: Int.random(in: 11...20), to: dayStart) ?? date,
                        maxSequenceLength: max(2, min(8, sequenceLength)),
                        totalRounds: totalRounds,
                        correctRounds: correctRounds,
                        averageResponseTime: max(2.0, min(6.5, avgResponseTime)),
                        individualResponseTimes: (0..<totalRounds).map { _ in 
                            max(2.0, min(6.5, avgResponseTime + Double.random(in: -1.2...1.2)))
                        }
                    )
                    modelContext.insert(dayShape!)
                }
                
                // Store day data for score calculation
                dayData[dayStart] = (dayReaction, daySleep, dayPhoto, dayShape)
            }
            
            // Calculate cognitive scores for each day
            for (date, data) in dayData {
                let score = CognitiveScoreService.calculateFromModels(
                    reactionTime: data.reaction,
                    sleep: data.sleep,
                    photoRecognition: data.photo,
                    medicalRecords: nil,
                    shapeSequence: data.shape
                )
                score.timestamp = date
                modelContext.insert(score)
            }
        
        // Save context
        do {
            try modelContext.save()
            print("✅ Generated \(dayData.count) days of varied historical data")
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
