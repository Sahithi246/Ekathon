//
//  CognitiveScoreService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Service for calculating unified cognitive risk scores
class CognitiveScoreService {
    
    /// Calculate unified cognitive risk score
    /// Formula: Reaction Time (45%) + Sleep (25%) + Voice (30%)
    /// 
    /// - Parameters:
    ///   - reactionTimeScore: Score from reaction time test (0-100)
    ///   - sleepScore: Score from sleep data (0-100)
    ///   - voiceScore: Score from voice metrics (0-100)
    /// - Returns: Unified cognitive risk score (0-100, where 0 = highest risk)
    static func calculateUnifiedScore(
        reactionTimeScore: Double,
        sleepScore: Double,
        voiceScore: Double
    ) -> Double {
        // Weighted formula as specified
        let weightedScore = (reactionTimeScore * 0.45) + 
                           (sleepScore * 0.25) + 
                           (voiceScore * 0.30)
        
        // Ensure score is within bounds
        return max(0, min(100, weightedScore))
    }
    
    /// Calculate unified score from model objects
    static func calculateFromModels(
        reactionTime: ReactionTimeResult?,
        sleep: SleepData?,
        voice: VoiceMetrics?
    ) -> CognitiveScore {
        let reactionScore = reactionTime?.cognitiveScore ?? 50.0 // Default if missing
        let sleepScoreValue = sleep?.cognitiveScore ?? 50.0
        let voiceScoreValue = voice?.cognitiveScore ?? 50.0
        
        let overallScore = calculateUnifiedScore(
            reactionTimeScore: reactionScore,
            sleepScore: sleepScoreValue,
            voiceScore: voiceScoreValue
        )
        
        return CognitiveScore(
            timestamp: Date(),
            overallScore: overallScore,
            reactionTimeScore: reactionScore,
            sleepScore: sleepScoreValue,
            voiceScore: voiceScoreValue,
            reactionTimeStatus: reactionTime?.status ?? "stable",
            sleepStatus: sleep?.status ?? "stable",
            voiceStatus: voice?.status ?? "stable"
        )
    }
    
    /// Get trend direction from historical scores
    static func getTrend(from scores: [CognitiveScore]) -> TrendDirection {
        guard scores.count >= 2 else { return .stable }
        
        let recent = Array(scores.suffix(3))
        let older = Array(scores.prefix(max(1, scores.count - 3)))
        
        let recentAvg = recent.map { $0.overallScore }.reduce(0, +) / Double(recent.count)
        let olderAvg = older.map { $0.overallScore }.reduce(0, +) / Double(older.count)
        
        let difference = recentAvg - olderAvg
        
        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .stable
        }
    }
}

enum TrendDirection {
    case improving
    case stable
    case declining
    
    var symbol: String {
        switch self {
        case .improving:
            return "↑"
        case .stable:
            return "→"
        case .declining:
            return "↓"
        }
    }
}
