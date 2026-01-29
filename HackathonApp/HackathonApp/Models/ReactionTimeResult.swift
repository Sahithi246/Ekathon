//
//  ReactionTimeResult.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Reaction time test result model
@Model
final class ReactionTimeResult {
    var timestamp: Date
    var averageReactionTime: Double // milliseconds
    var testDuration: Double // seconds
    var numberOfTrials: Int
    var individualReactions: [Double] // Array of reaction times in ms
    
    init(
        timestamp: Date = Date(),
        averageReactionTime: Double = 0,
        testDuration: Double = 0,
        numberOfTrials: Int = 0,
        individualReactions: [Double] = []
    ) {
        self.timestamp = timestamp
        self.averageReactionTime = averageReactionTime
        self.testDuration = testDuration
        self.numberOfTrials = numberOfTrials
        self.individualReactions = individualReactions
    }
}

// MARK: - Helper Extensions
extension ReactionTimeResult {
    /// Calculate cognitive score from reaction time
    /// Lower reaction time = better score
    /// Typical range: 200-300ms is good, >400ms is concerning
    var cognitiveScore: Double {
        let baseline = 250.0 // milliseconds (good baseline)
        let maxReaction = 600.0 // milliseconds (worst case)
        
        // Normalize: 250ms = 100 points, 600ms = 0 points
        if averageReactionTime <= baseline {
            return 100.0
        } else if averageReactionTime >= maxReaction {
            return 0.0
        } else {
            // Linear interpolation
            let normalized = 100.0 * (1.0 - (averageReactionTime - baseline) / (maxReaction - baseline))
            return max(0, min(100, normalized))
        }
    }
    
    /// Get status based on reaction time
    var status: String {
        switch averageReactionTime {
        case 0..<300:
            return "stable"
        case 300..<450:
            return "monitor"
        default:
            return "at_risk"
        }
    }
}
