//
//  PhotoRecognitionResult.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Photo recognition game result model
/// Tests memory and facial recognition - cognitive markers
@Model
final class PhotoRecognitionResult {
    var timestamp: Date
    var totalPhotos: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    var averageResponseTime: Double // seconds
    var individualResponseTimes: [Double] // Array of response times
    
    init(
        timestamp: Date = Date(),
        totalPhotos: Int = 0,
        correctAnswers: Int = 0,
        incorrectAnswers: Int = 0,
        averageResponseTime: Double = 0,
        individualResponseTimes: [Double] = []
    ) {
        self.timestamp = timestamp
        self.totalPhotos = totalPhotos
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.averageResponseTime = averageResponseTime
        self.individualResponseTimes = individualResponseTimes
    }
}

// MARK: - Helper Extensions
extension PhotoRecognitionResult {
    /// Calculate accuracy percentage
    var accuracy: Double {
        guard totalPhotos > 0 else { return 0 }
        return (Double(correctAnswers) / Double(totalPhotos)) * 100.0
    }
    
    /// Calculate cognitive score from photo recognition results
    /// Combines: Accuracy (70%) + Response Time (30%)
    var cognitiveScore: Double {
        let accuracyScore = accuracy // 0-100
        
        // Response time score: faster is better, but not too fast (guessing)
        // Optimal: 2-5 seconds per photo
        let responseTimeScore = calculateResponseTimeScore()
        
        // Weighted: Accuracy (70%), Response Time (30%)
        let combinedScore = (accuracyScore * 0.7) + (responseTimeScore * 0.3)
        return max(0, min(100, combinedScore))
    }
    
    private func calculateResponseTimeScore() -> Double {
        let optimalMin = 2.0 // seconds
        let optimalMax = 5.0 // seconds
        let tooFast = 1.0 // seconds (likely guessing)
        let tooSlow = 10.0 // seconds
        
        if averageResponseTime >= optimalMin && averageResponseTime <= optimalMax {
            return 100.0
        } else if averageResponseTime < tooFast {
            // Too fast = guessing, penalize
            return 50.0 * (averageResponseTime / tooFast)
        } else if averageResponseTime > tooSlow {
            return 0.0
        } else if averageResponseTime < optimalMin {
            // Between tooFast and optimalMin
            return 50.0 + (50.0 * (averageResponseTime - tooFast) / (optimalMin - tooFast))
        } else {
            // Between optimalMax and tooSlow
            return 100.0 * (1.0 - (averageResponseTime - optimalMax) / (tooSlow - optimalMax))
        }
    }
    
    /// Get status based on photo recognition results
    var status: String {
        let score = cognitiveScore
        switch score {
        case 70...100:
            return "stable"
        case 40..<70:
            return "monitor"
        default:
            return "at_risk"
        }
    }
}
