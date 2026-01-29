//
//  SleepData.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Sleep data model from HealthKit
@Model
final class SleepData {
    var date: Date
    var totalSleepHours: Double
    var sleepStart: Date?
    var sleepEnd: Date?
    var sleepQuality: String? // "good", "fair", "poor"
    
    init(
        date: Date = Date(),
        totalSleepHours: Double = 0,
        sleepStart: Date? = nil,
        sleepEnd: Date? = nil,
        sleepQuality: String? = nil
    ) {
        self.date = date
        self.totalSleepHours = totalSleepHours
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.sleepQuality = sleepQuality
    }
}

// MARK: - Helper Extensions
extension SleepData {
    /// Calculate cognitive score from sleep hours
    /// Optimal: 7-9 hours = 100 points
    /// Too little or too much = lower score
    var cognitiveScore: Double {
        let optimalMin = 7.0
        let optimalMax = 9.0
        let minAcceptable = 6.0
        let maxAcceptable = 10.0
        
        if totalSleepHours >= optimalMin && totalSleepHours <= optimalMax {
            return 100.0
        } else if totalSleepHours >= minAcceptable && totalSleepHours <= maxAcceptable {
            // Partial score for acceptable range
            if totalSleepHours < optimalMin {
                // 6-7 hours: 70-100 points
                return 70.0 + (30.0 * (totalSleepHours - minAcceptable) / (optimalMin - minAcceptable))
            } else {
                // 9-10 hours: 70-100 points
                return 100.0 - (30.0 * (totalSleepHours - optimalMax) / (maxAcceptable - optimalMax))
            }
        } else if totalSleepHours < minAcceptable {
            // < 6 hours: 0-70 points
            return max(0, 70.0 * (totalSleepHours / minAcceptable))
        } else {
            // > 10 hours: 0-70 points
            let excess = totalSleepHours - maxAcceptable
            return max(0, 70.0 - (excess * 10.0))
        }
    }
    
    /// Get status based on sleep hours
    var status: String {
        switch totalSleepHours {
        case 7..<9:
            return "stable"
        case 6..<7, 9..<10:
            return "monitor"
        default:
            return "at_risk"
        }
    }
    
    /// Calculate sleep deficit (hours below optimal)
    var sleepDeficit: Double {
        let optimal = 8.0
        return max(0, optimal - totalSleepHours)
    }
}
