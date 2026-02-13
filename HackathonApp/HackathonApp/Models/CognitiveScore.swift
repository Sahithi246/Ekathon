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
    var photoRecognitionScore: Double // 0-100
    var medicalRecordsScore: Double // 0-100
    var shapeSequenceScore: Double // 0-100
    
    // Individual signal statuses
    var reactionTimeStatus: String // "stable", "monitor", "at_risk"
    var sleepStatus: String
    var photoRecognitionStatus: String
    var medicalRecordsStatus: String
    var shapeSequenceStatus: String
    
    init(
        timestamp: Date = Date(),
        overallScore: Double = 0,
        reactionTimeScore: Double = 0,
        sleepScore: Double = 0,
        photoRecognitionScore: Double = 0,
        medicalRecordsScore: Double = 0,
        shapeSequenceScore: Double = 0,
        reactionTimeStatus: String = "stable",
        sleepStatus: String = "stable",
        photoRecognitionStatus: String = "stable",
        medicalRecordsStatus: String = "stable",
        shapeSequenceStatus: String = "stable"
    ) {
        self.timestamp = timestamp
        self.overallScore = overallScore
        self.reactionTimeScore = reactionTimeScore
        self.sleepScore = sleepScore
        self.photoRecognitionScore = photoRecognitionScore
        self.medicalRecordsScore = medicalRecordsScore
        self.shapeSequenceScore = shapeSequenceScore
        self.reactionTimeStatus = reactionTimeStatus
        self.sleepStatus = sleepStatus
        self.photoRecognitionStatus = photoRecognitionStatus
        self.medicalRecordsStatus = medicalRecordsStatus
        self.shapeSequenceStatus = shapeSequenceStatus
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
