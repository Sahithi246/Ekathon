//
//  CognitiveScore.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Unified cognitive risk score model
/// Score range: 0-100 (0 = highest risk, 100 = lowest risk/healthy)
@Model
final class CognitiveScore {
    var timestamp: Date
    var overallScore: Double // 0-100
    var reactionTimeScore: Double // 0-100
    var sleepScore: Double // 0-100
    var voiceScore: Double // 0-100
    
    // Individual signal statuses
    var reactionTimeStatus: String // "stable", "monitor", "at_risk"
    var sleepStatus: String
    var voiceStatus: String
    
    init(
        timestamp: Date = Date(),
        overallScore: Double = 0,
        reactionTimeScore: Double = 0,
        sleepScore: Double = 0,
        voiceScore: Double = 0,
        reactionTimeStatus: String = "stable",
        sleepStatus: String = "stable",
        voiceStatus: String = "stable"
    ) {
        self.timestamp = timestamp
        self.overallScore = overallScore
        self.reactionTimeScore = reactionTimeScore
        self.sleepScore = sleepScore
        self.voiceScore = voiceScore
        self.reactionTimeStatus = reactionTimeStatus
        self.sleepStatus = sleepStatus
        self.voiceStatus = voiceStatus
    }
}

// MARK: - Helper Extensions
extension CognitiveScore {
    /// Get risk level based on overall score
    var riskLevel: RiskLevel {
        switch overallScore {
        case 0..<40:
            return .high
        case 40..<70:
            return .medium
        default:
            return .low
        }
    }
    
    /// Get status emoji for UI
    var statusEmoji: String {
        switch riskLevel {
        case .low:
            return "🟢"
        case .medium:
            return "🟡"
        case .high:
            return "🔴"
        }
    }
}

enum RiskLevel {
    case low    // 70-100: Stable
    case medium // 40-69: Monitor
    case high   // 0-39: At Risk
}
