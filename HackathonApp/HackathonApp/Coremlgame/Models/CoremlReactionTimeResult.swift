//
//  CoremlReactionTimeResult.swift
//  Coremlgame
//

import Foundation
import SwiftData

/// Coremlgame reaction time model — renamed to avoid conflict with main app's ReactionTimeResult
@Model
final class CoremlReactionTimeResult {
    var timestamp: Date
    var averageReactionTime: Double
    var reactionTimes: [Double] // Stored as array of doubles
    
    init(timestamp: Date, averageReactionTime: Double, reactionTimes: [Double] = []) {
        self.timestamp = timestamp
        self.averageReactionTime = averageReactionTime
        self.reactionTimes = reactionTimes
    }
}
