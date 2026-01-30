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
    /// Formula: Reaction Time (30%) + Sleep (20%) + Photo Recognition (15%) + Medical Records (20%) + Shape Sequence (15%)
    /// 
    /// - Parameters:
    ///   - reactionTimeScore: Score from reaction time test (0-100)
    ///   - sleepScore: Score from sleep data (0-100)
    ///   - photoRecognitionScore: Score from photo recognition game (0-100)
    ///   - medicalRecordsScore: Score from medical records analysis (0-100)
    ///   - shapeSequenceScore: Score from shape sequence memory game (0-100)
    /// - Returns: Unified cognitive risk score (0-100, where 0 = highest risk)
    static func calculateUnifiedScore(
        reactionTimeScore: Double,
        sleepScore: Double,
        photoRecognitionScore: Double,
        medicalRecordsScore: Double,
        shapeSequenceScore: Double
    ) -> Double {
        // Weighted formula: Reaction Time (30%), Sleep (20%), Photo Recognition (15%), Medical Records (20%), Shape Sequence (15%)
        let weightedScore = (reactionTimeScore * 0.30) + 
                           (sleepScore * 0.20) + 
                           (photoRecognitionScore * 0.15) +
                           (medicalRecordsScore * 0.20) +
                           (shapeSequenceScore * 0.15)
        
        // Ensure score is within bounds
        return max(0, min(100, weightedScore))
    }
    
    /// Calculate unified score from model objects
    static func calculateFromModels(
        reactionTime: ReactionTimeResult?,
        sleep: SleepData?,
        photoRecognition: PhotoRecognitionResult?,
        medicalRecords: MedicalRecordAnalysis?,
        shapeSequence: ShapeSequenceResult?
    ) -> CognitiveScore {
        let reactionScore = reactionTime?.cognitiveScore ?? 50.0 // Default if missing
        let sleepScoreValue = sleep?.cognitiveScore ?? 50.0
        let photoRecognitionScoreValue = photoRecognition?.cognitiveScore ?? 50.0
        let medicalRecordsScoreValue = medicalRecords?.cognitiveScore ?? 50.0
        let shapeSequenceScoreValue = shapeSequence?.cognitiveScore ?? 50.0
        
        let overallScore = calculateUnifiedScore(
            reactionTimeScore: reactionScore,
            sleepScore: sleepScoreValue,
            photoRecognitionScore: photoRecognitionScoreValue,
            medicalRecordsScore: medicalRecordsScoreValue,
            shapeSequenceScore: shapeSequenceScoreValue
        )
        
        return CognitiveScore(
            timestamp: Date(),
            overallScore: overallScore,
            reactionTimeScore: reactionScore,
            sleepScore: sleepScoreValue,
            photoRecognitionScore: photoRecognitionScoreValue,
            medicalRecordsScore: medicalRecordsScoreValue,
            shapeSequenceScore: shapeSequenceScoreValue,
            reactionTimeStatus: reactionTime?.status ?? "stable",
            sleepStatus: sleep?.status ?? "stable",
            photoRecognitionStatus: photoRecognition?.status ?? "stable",
            medicalRecordsStatus: medicalRecords?.status ?? "stable",
            shapeSequenceStatus: shapeSequence?.status ?? "stable"
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
