//
//  ShapeSequenceResult.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Result model for shape sequence memory test
@Model
final class ShapeSequenceResult {
    var timestamp: Date
    var maxSequenceLength: Int // Maximum sequence length achieved
    var totalRounds: Int // Total rounds played
    var correctRounds: Int // Rounds completed correctly
    var averageResponseTime: Double // Average time to complete each round (seconds)
    var individualResponseTimes: [Double] // Response time for each round
    
    init(
        timestamp: Date = Date(),
        maxSequenceLength: Int = 0,
        totalRounds: Int = 0,
        correctRounds: Int = 0,
        averageResponseTime: Double = 0,
        individualResponseTimes: [Double] = []
    ) {
        self.timestamp = timestamp
        self.maxSequenceLength = maxSequenceLength
        self.totalRounds = totalRounds
        self.correctRounds = correctRounds
        self.averageResponseTime = averageResponseTime
        self.individualResponseTimes = individualResponseTimes
    }
    
    /// Calculate cognitive score from this test (0-100)
    var cognitiveScore: Double {
        // Score based on:
        // - Max sequence length (60%) - higher is better
        // - Accuracy (30%) - correct rounds / total rounds
        // - Response time (10%) - faster is better
        
        // Normalize sequence length (0-10+ sequences = 0-100 points)
        let sequenceScore = min(100, Double(maxSequenceLength) * 10)
        
        // Accuracy score
        let accuracy = totalRounds > 0 ? Double(correctRounds) / Double(totalRounds) : 0
        let accuracyScore = accuracy * 100
        
        // Response time score (faster = better, normalize)
        // Good response time: < 3 seconds per sequence = 100 points
        // Poor response time: > 8 seconds per sequence = 0 points
        let responseTimeScore = max(0, min(100, 100 - ((averageResponseTime - 3) * 20)))
        
        // Weighted combination
        let finalScore = (sequenceScore * 0.60) + (accuracyScore * 0.30) + (responseTimeScore * 0.10)
        
        return max(0, min(100, finalScore))
    }
    
    /// Get status based on performance
    var status: String {
        let score = cognitiveScore
        switch score {
        case 0..<40:
            return "at_risk"
        case 40..<70:
            return "monitor"
        default:
            return "stable"
        }
    }
    
    /// Calculate accuracy percentage
    var accuracy: Double {
        guard totalRounds > 0 else { return 0 }
        return Double(correctRounds) / Double(totalRounds) * 100
    }
}
