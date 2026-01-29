//
//  VoiceMetrics.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Voice-based cognitive metrics model
@Model
final class VoiceMetrics {
    var timestamp: Date
    var wordsPerMinute: Double
    var averagePauseDuration: Double // seconds
    var speechVariability: Double // coefficient of variation
    var totalWords: Int
    var recordingDuration: Double // seconds
    var transcription: String?
    
    init(
        timestamp: Date = Date(),
        wordsPerMinute: Double = 0,
        averagePauseDuration: Double = 0,
        speechVariability: Double = 0,
        totalWords: Int = 0,
        recordingDuration: Double = 0,
        transcription: String? = nil
    ) {
        self.timestamp = timestamp
        self.wordsPerMinute = wordsPerMinute
        self.averagePauseDuration = averagePauseDuration
        self.speechVariability = speechVariability
        self.totalWords = totalWords
        self.recordingDuration = recordingDuration
        self.transcription = transcription
    }
}

// MARK: - Helper Extensions
extension VoiceMetrics {
    /// Calculate cognitive score from voice metrics
    /// Combines: WPM, pause consistency, speech variability
    var cognitiveScore: Double {
        // Normal WPM range: 120-160 words per minute
        let optimalWPM = 140.0
        let wpmScore = calculateWPMScore()
        
        // Optimal pause duration: 0.3-0.8 seconds
        let pauseScore = calculatePauseScore()
        
        // Lower variability = better (more consistent speech)
        let variabilityScore = calculateVariabilityScore()
        
        // Weighted average: WPM (40%), Pauses (30%), Variability (30%)
        let combinedScore = (wpmScore * 0.4) + (pauseScore * 0.3) + (variabilityScore * 0.3)
        return max(0, min(100, combinedScore))
    }
    
    private func calculateWPMScore() -> Double {
        let optimalMin = 120.0
        let optimalMax = 160.0
        let minAcceptable = 80.0
        let maxAcceptable = 200.0
        
        if wordsPerMinute >= optimalMin && wordsPerMinute <= optimalMax {
            return 100.0
        } else if wordsPerMinute < optimalMin {
            // Too slow: 0-100 points
            return max(0, 100.0 * (wordsPerMinute - minAcceptable) / (optimalMin - minAcceptable))
        } else {
            // Too fast: 0-100 points
            return max(0, 100.0 * (1.0 - (wordsPerMinute - optimalMax) / (maxAcceptable - optimalMax)))
        }
    }
    
    private func calculatePauseScore() -> Double {
        let optimalMin = 0.3
        let optimalMax = 0.8
        let minAcceptable = 0.1
        let maxAcceptable = 2.0
        
        if averagePauseDuration >= optimalMin && averagePauseDuration <= optimalMax {
            return 100.0
        } else if averagePauseDuration < optimalMin {
            // Too few pauses: 50-100 points
            return 50.0 + (50.0 * (averagePauseDuration / optimalMin))
        } else {
            // Too many/long pauses: 0-100 points
            if averagePauseDuration >= maxAcceptable {
                return 0.0
            }
            return 100.0 * (1.0 - (averagePauseDuration - optimalMax) / (maxAcceptable - optimalMax))
        }
    }
    
    private func calculateVariabilityScore() -> Double {
        // Lower variability is better
        // Optimal: 0.1-0.3, concerning: >0.5
        let optimalMax = 0.3
        let concerning = 0.5
        
        if speechVariability <= optimalMax {
            return 100.0
        } else if speechVariability >= concerning {
            return 0.0
        } else {
            // Linear interpolation
            return 100.0 * (1.0 - (speechVariability - optimalMax) / (concerning - optimalMax))
        }
    }
    
    /// Get status based on voice metrics
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
