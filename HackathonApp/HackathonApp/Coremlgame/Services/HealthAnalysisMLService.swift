//
//  HealthAnalysisMLService.swift
//  Coremlgame
//
//  Created on 29/01/26.
//

import Foundation
import CoreML
import SwiftData

/// Service for analyzing health data using Core ML
class HealthAnalysisMLService {
    
    // MARK: - Data Structure for ML Input
    struct HealthFeatures {
        // Reaction Time Features
        let avgReactionTime: Double
        let reactionTimeVariance: Double
        let reactionTimeTrend: Double // Positive = improving, Negative = declining
        
        // Sleep Features
        let avgSleepHours: Double
        let sleepConsistency: Double // Standard deviation (lower = more consistent)
        let sleepTrend: Double
        
        // Photo Recognition Features
        let avgAccuracy: Double
        let avgResponseTime: Double
        let recognitionTrend: Double
        
        // Temporal Features
        let daysSinceFirstData: Double
        let dataPointCount: Double
        
        // Convert to MLMultiArray for Core ML
        func toMLMultiArray() throws -> MLMultiArray {
            let array = try MLMultiArray(shape: [10], dataType: .double)
            array[0] = NSNumber(value: avgReactionTime)
            array[1] = NSNumber(value: reactionTimeVariance)
            array[2] = NSNumber(value: reactionTimeTrend)
            array[3] = NSNumber(value: avgSleepHours)
            array[4] = NSNumber(value: sleepConsistency)
            array[5] = NSNumber(value: sleepTrend)
            array[6] = NSNumber(value: avgAccuracy)
            array[7] = NSNumber(value: avgResponseTime)
            array[8] = NSNumber(value: recognitionTrend)
            array[9] = NSNumber(value: daysSinceFirstData)
            return array
        }
    }
    
    // MARK: - Health Insights
    struct HealthInsight {
        let riskLevel: CoremlRiskLevel
        let overallScore: Double
        let keyFindings: [String]
        let recommendations: [String]
        let predictedTrend: String
        let confidence: Double
    }
    
    // MARK: - Analyze Historical Data
    static func analyzeHistoricalData(
        reactionTimes: [CoremlReactionTimeResult],
        sleepData: [CoremlSleepData],
        photoRecognition: [CoremlPhotoRecognitionResult],
        cognitiveScores: [CoremlCognitiveScore]
    ) -> HealthInsight {
        
        // Extract features from historical data
        let features = extractFeatures(
            reactionTimes: reactionTimes,
            sleepData: sleepData,
            photoRecognition: photoRecognition,
            cognitiveScores: cognitiveScores
        )
        
        // For now, use rule-based analysis
        // TODO: Replace with actual Core ML model prediction
        let insight = generateInsights(from: features, cognitiveScores: cognitiveScores)
        
        return insight
    }
    
    // MARK: - Feature Extraction
    private static func extractFeatures(
        reactionTimes: [CoremlReactionTimeResult],
        sleepData: [CoremlSleepData],
        photoRecognition: [CoremlPhotoRecognitionResult],
        cognitiveScores: [CoremlCognitiveScore]
    ) -> HealthFeatures {
        
        // Reaction Time Features
        let reactionTimeValues = reactionTimes.map { $0.averageReactionTime }
        let avgReactionTime = reactionTimeValues.isEmpty ? 300.0 : reactionTimeValues.reduce(0, +) / Double(reactionTimeValues.count)
        let reactionTimeVariance = calculateVariance(reactionTimeValues)
        let reactionTimeTrend = calculateTrend(reactionTimeValues)
        
        // Sleep Features
        let sleepHours = sleepData.map { $0.totalSleepHours }
        let avgSleepHours = sleepHours.isEmpty ? 7.0 : sleepHours.reduce(0, +) / Double(sleepHours.count)
        let sleepConsistency = calculateStandardDeviation(sleepHours)
        let sleepTrend = calculateTrend(sleepHours)
        
        // Photo Recognition Features
        let accuracies = photoRecognition.map { $0.accuracy }
        let avgAccuracy = accuracies.isEmpty ? 70.0 : accuracies.reduce(0, +) / Double(accuracies.count)
        let responseTimes = photoRecognition.map { $0.averageResponseTime }
        let avgResponseTime = responseTimes.isEmpty ? 3.0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        let recognitionTrend = calculateTrend(accuracies)
        
        // Temporal Features
        let allTimestamps = (reactionTimes.map { $0.timestamp } +
                            sleepData.map { $0.date } +
                            photoRecognition.map { $0.timestamp })
        let firstDate = allTimestamps.min() ?? Date()
        let daysSinceFirstData = Date().timeIntervalSince(firstDate) / 86400.0
        let dataPointCount = Double(reactionTimes.count + sleepData.count + photoRecognition.count)
        
        return HealthFeatures(
            avgReactionTime: avgReactionTime,
            reactionTimeVariance: reactionTimeVariance,
            reactionTimeTrend: reactionTimeTrend,
            avgSleepHours: avgSleepHours,
            sleepConsistency: sleepConsistency,
            sleepTrend: sleepTrend,
            avgAccuracy: avgAccuracy,
            avgResponseTime: avgResponseTime,
            recognitionTrend: recognitionTrend,
            daysSinceFirstData: daysSinceFirstData,
            dataPointCount: dataPointCount
        )
    }
    
    // MARK: - Generate Insights (Rule-based for now)
    private static func generateInsights(
        from features: HealthFeatures,
        cognitiveScores: [CoremlCognitiveScore]
    ) -> HealthInsight {
        
        var findings: [String] = []
        var recommendations: [String] = []
        var riskLevel: CoremlRiskLevel = .low
        var overallScore = 70.0
        var predictedTrend = "stable"
        
        // Analyze reaction time
        if features.avgReactionTime > 400 {
            findings.append("Reaction time is slower than optimal (avg: \(Int(features.avgReactionTime))ms)")
            recommendations.append("Consider regular reaction time exercises")
            riskLevel = .medium
        } else if features.avgReactionTime < 300 {
            findings.append("Reaction time is within healthy range")
        }
        
        if features.reactionTimeTrend < -0.1 {
            findings.append("Reaction time is declining over time")
            recommendations.append("Monitor reaction time closely and consult healthcare provider if trend continues")
            riskLevel = riskLevel == .low ? .medium : .high
        }
        
        // Analyze sleep
        if features.avgSleepHours < 6 {
            findings.append("Average sleep duration is below recommended (avg: \(String(format: "%.1f", features.avgSleepHours)) hours)")
            recommendations.append("Aim for 7-9 hours of sleep per night")
            riskLevel = riskLevel == .low ? .medium : .high
        } else if features.avgSleepHours > 9 {
            findings.append("Sleep duration is above optimal range")
            recommendations.append("Consider discussing excessive sleep with healthcare provider")
        } else {
            findings.append("Sleep duration is within healthy range")
        }
        
        if features.sleepConsistency > 2.0 {
            findings.append("Sleep schedule is inconsistent")
            recommendations.append("Try to maintain a consistent sleep schedule")
        }
        
        // Analyze photo recognition
        if features.avgAccuracy < 60 {
            findings.append("Photo recognition accuracy is below average (\(Int(features.avgAccuracy))%)")
            recommendations.append("Practice memory exercises regularly")
            riskLevel = riskLevel == .low ? .medium : .high
        }
        
        // Calculate overall score from recent cognitive scores
        if let latestScore = cognitiveScores.first {
            overallScore = latestScore.overallScore
            riskLevel = latestScore.riskLevelEnum
        }
        
        // Predict trend
        if cognitiveScores.count >= 3 {
            let recent = Array(cognitiveScores.prefix(3))
            let older = Array(cognitiveScores.suffix(min(3, cognitiveScores.count - 3)))
            
            let recentAvg = recent.map { $0.overallScore }.reduce(0, +) / Double(recent.count)
            let olderAvg = older.map { $0.overallScore }.reduce(0, +) / Double(older.count)
            
            if recentAvg > olderAvg + 5 {
                predictedTrend = "improving"
            } else if recentAvg < olderAvg - 5 {
                predictedTrend = "declining"
            }
        }
        
        // Add general recommendations based on risk level
        switch riskLevel {
        case .high:
            recommendations.append("Consider consulting with a healthcare provider for comprehensive cognitive assessment")
        case .medium:
            recommendations.append("Continue monitoring and maintain healthy lifestyle habits")
        case .low:
            recommendations.append("Keep up the good work! Maintain current healthy habits")
        }
        
        return HealthInsight(
            riskLevel: riskLevel,
            overallScore: overallScore,
            keyFindings: findings.isEmpty ? ["Insufficient data for analysis"] : findings,
            recommendations: recommendations.isEmpty ? ["Continue collecting data for better insights"] : recommendations,
            predictedTrend: predictedTrend,
            confidence: min(1.0, features.dataPointCount / 30.0) // Confidence based on data points
        )
    }
    
    // MARK: - Helper Functions
    private static func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private static func calculateStandardDeviation(_ values: [Double]) -> Double {
        return sqrt(calculateVariance(values))
    }
    
    private static func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let recent = Array(values.prefix(values.count / 2))
        let older = Array(values.suffix(values.count - recent.count))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        return recentAvg - olderAvg
    }
    
    // MARK: - Core ML Model Prediction (Placeholder)
    /// This method will use an actual Core ML model once created
    static func predictWithMLModel(features: HealthFeatures) throws -> HealthInsight? {
        // TODO: Load and use Core ML model
        // Example:
        // let model = try HealthAnalysisModel(configuration: MLModelConfiguration())
        // let input = HealthAnalysisModelInput(features: try features.toMLMultiArray())
        // let prediction = try model.prediction(from: input)
        // return convertPredictionToInsight(prediction)
        return nil
    }
}
