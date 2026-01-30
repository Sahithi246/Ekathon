//
//  GameRecommendationService.swift
//  HackathonApp
//
//  Created on 30/01/26.
//

import Foundation
import SwiftData

/// Service that analyzes medical records and recommends suitable cognitive games/tests
class GameRecommendationService {
    
    /// Analyze medical records and recommend which games are most suitable
    /// - Parameter analysis: The medical record analysis to base recommendations on
    /// - Returns: Array of recommended games with priority and reasoning
    static func recommendGames(basedOn analysis: MedicalRecordAnalysis?) -> [GameRecommendation] {
        guard let analysis = analysis else {
            // No medical records - recommend all games as standard assessment
            return defaultRecommendations()
        }
        
        var recommendations: [GameRecommendation] = []
        let markers = analysis.cognitiveMarkers
        let riskFactors = MedicalRecordsAnalysisService.detectPatterns(analysis: analysis)
        
        // Analyze based on detected risk factors and markers
        
        // 1. REACTION TIME TEST
        // Recommended for: Attention issues, medication side effects, sleep disorders
        let reactionTimePriority = calculateReactionTimePriority(
            markers: markers,
            riskFactors: riskFactors,
            medicationImpact: analysis.medicationImpact
        )
        recommendations.append(GameRecommendation(
            gameType: .reactionTime,
            priority: reactionTimePriority.priority,
            reasoning: reactionTimePriority.reasoning,
            frequency: reactionTimePriority.frequency
        ))
        
        // 2. SHAPE SEQUENCE MEMORY TEST
        // Recommended for: Memory issues, cognitive medications, vitamin deficiencies
        let shapeSequencePriority = calculateShapeSequencePriority(
            markers: markers,
            riskFactors: riskFactors,
            labValueImpact: analysis.labValueImpact
        )
        recommendations.append(GameRecommendation(
            gameType: .shapeSequence,
            priority: shapeSequencePriority.priority,
            reasoning: shapeSequencePriority.reasoning,
            frequency: shapeSequencePriority.frequency
        ))
        
        // 3. PHOTO RECOGNITION TEST
        // Recommended for: Memory issues, face recognition problems, cognitive decline
        let photoRecognitionPriority = calculatePhotoRecognitionPriority(
            markers: markers,
            riskFactors: riskFactors,
            chronicConditionImpact: analysis.chronicConditionImpact
        )
        recommendations.append(GameRecommendation(
            gameType: .photoRecognition,
            priority: photoRecognitionPriority.priority,
            reasoning: photoRecognitionPriority.reasoning,
            frequency: photoRecognitionPriority.frequency
        ))
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Priority Calculations
    
    private static func calculateReactionTimePriority(
        markers: [CognitiveMarker],
        riskFactors: [RiskFactor],
        medicationImpact: Double
    ) -> (priority: RecommendationPriority, reasoning: String, frequency: AssessmentFrequency) {
        var reasons: [String] = []
        var priorityScore = 0
        
        // Check for attention-affecting medications
        let attentionMedications = markers.filter {
            $0.type == .medication &&
            ($0.name.lowercased().contains("benzodiazepine") ||
             $0.name.lowercased().contains("antihistamine") ||
             $0.name.lowercased().contains("anticholinergic"))
        }
        
        if !attentionMedications.isEmpty {
            priorityScore += 3
            reasons.append("Taking medications that may affect attention and reaction time")
        }
        
        // Check for sleep-related issues
        let sleepIssues = riskFactors.filter {
            $0.name.lowercased().contains("sleep") ||
            $0.description.lowercased().contains("sleep")
        }
        
        if !sleepIssues.isEmpty {
            priorityScore += 2
            reasons.append("Sleep-related conditions detected")
        }
        
        // High medication impact
        if medicationImpact < -20 {
            priorityScore += 2
            reasons.append("Multiple medications with cognitive side effects")
        }
        
        // Determine priority and frequency
        let priority: RecommendationPriority
        let frequency: AssessmentFrequency
        
        if priorityScore >= 5 {
            priority = .high
            frequency = .frequent // Weekly
            reasons.insert("High priority: Important for monitoring attention and reaction time", at: 0)
        } else if priorityScore >= 2 {
            priority = .medium
            frequency = .regular // Bi-weekly
            reasons.insert("Moderate priority: Useful for tracking attention changes", at: 0)
        } else {
            priority = .standard
            frequency = .standard // Monthly
            reasons.insert("Standard assessment: Baseline reaction time monitoring", at: 0)
        }
        
        let reasoning = reasons.joined(separator: ". ")
        return (priority, reasoning, frequency)
    }
    
    private static func calculateShapeSequencePriority(
        markers: [CognitiveMarker],
        riskFactors: [RiskFactor],
        labValueImpact: Double
    ) -> (priority: RecommendationPriority, reasoning: String, frequency: AssessmentFrequency) {
        var reasons: [String] = []
        var priorityScore = 0
        
        // Check for memory-affecting medications
        let memoryMedications = markers.filter {
            $0.type == .medication &&
            ($0.name.lowercased().contains("anticholinergic") ||
             $0.name.lowercased().contains("benzodiazepine") ||
             $0.impact < -15)
        }
        
        if !memoryMedications.isEmpty {
            priorityScore += 3
            reasons.append("Taking medications that may affect memory")
        }
        
        // Check for vitamin deficiencies
        let vitaminDeficiencies = markers.filter {
            $0.type == .labValue &&
            ($0.name.lowercased().contains("vitamin b12") ||
             $0.name.lowercased().contains("vitamin d")) &&
            $0.impact < 0
        }
        
        if !vitaminDeficiencies.isEmpty {
            priorityScore += 3
            reasons.append("Vitamin deficiencies detected (B12 or D)")
        }
        
        // High lab value impact
        if labValueImpact < -20 {
            priorityScore += 2
            reasons.append("Abnormal lab values affecting cognitive function")
        }
        
        // Check for chronic conditions affecting memory
        let memoryConditions = riskFactors.filter {
            $0.name.lowercased().contains("chronic") ||
            $0.description.lowercased().contains("memory")
        }
        
        if !memoryConditions.isEmpty {
            priorityScore += 1
            reasons.append("Chronic conditions that may impact memory")
        }
        
        // Determine priority and frequency
        let priority: RecommendationPriority
        let frequency: AssessmentFrequency
        
        if priorityScore >= 5 {
            priority = .high
            frequency = .frequent // Weekly
            reasons.insert("High priority: Critical for monitoring memory function", at: 0)
        } else if priorityScore >= 2 {
            priority = .medium
            frequency = .regular // Bi-weekly
            reasons.insert("Moderate priority: Important for tracking memory changes", at: 0)
        } else {
            priority = .standard
            frequency = .standard // Monthly
            reasons.insert("Standard assessment: Baseline memory monitoring", at: 0)
        }
        
        let reasoning = reasons.joined(separator: ". ")
        return (priority, reasoning, frequency)
    }
    
    private static func calculatePhotoRecognitionPriority(
        markers: [CognitiveMarker],
        riskFactors: [RiskFactor],
        chronicConditionImpact: Double
    ) -> (priority: RecommendationPriority, reasoning: String, frequency: AssessmentFrequency) {
        var reasons: [String] = []
        var priorityScore = 0
        
        // Check for conditions affecting recognition
        let recognitionConditions = markers.filter {
            $0.type == .chronicCondition &&
            ($0.name.lowercased().contains("stroke") ||
             $0.name.lowercased().contains("dementia") ||
             $0.name.lowercased().contains("alzheimer"))
        }
        
        if !recognitionConditions.isEmpty {
            priorityScore += 4
            reasons.append("Conditions affecting face recognition detected")
        }
        
        // High chronic condition impact
        if chronicConditionImpact < -20 {
            priorityScore += 2
            reasons.append("Multiple chronic conditions affecting cognitive health")
        }
        
        // Check for memory-related risk factors
        let memoryFactors = riskFactors.filter {
            $0.description.lowercased().contains("memory") ||
            $0.description.lowercased().contains("cognitive")
        }
        
        if !memoryFactors.isEmpty {
            priorityScore += 2
            reasons.append("Memory-related risk factors identified")
        }
        
        // Age-related considerations (would need age from records)
        // For now, high chronic condition impact suggests age-related concerns
        
        // Determine priority and frequency
        let priority: RecommendationPriority
        let frequency: AssessmentFrequency
        
        if priorityScore >= 4 {
            priority = .high
            frequency = .frequent // Weekly
            reasons.insert("High priority: Essential for monitoring recognition and memory", at: 0)
        } else if priorityScore >= 2 {
            priority = .medium
            frequency = .regular // Bi-weekly
            reasons.insert("Moderate priority: Useful for tracking recognition abilities", at: 0)
        } else {
            priority = .standard
            frequency = .standard // Monthly
            reasons.insert("Standard assessment: Baseline recognition monitoring", at: 0)
        }
        
        let reasoning = reasons.joined(separator: ". ")
        return (priority, reasoning, frequency)
    }
    
    // MARK: - Default Recommendations
    
    /// Default recommendations when no medical records are available
    private static func defaultRecommendations() -> [GameRecommendation] {
        return [
            GameRecommendation(
                gameType: .reactionTime,
                priority: .standard,
                reasoning: "Standard cognitive assessment: Baseline reaction time test",
                frequency: .standard
            ),
            GameRecommendation(
                gameType: .shapeSequence,
                priority: .standard,
                reasoning: "Standard cognitive assessment: Baseline memory sequence test",
                frequency: .standard
            ),
            GameRecommendation(
                gameType: .photoRecognition,
                priority: .standard,
                reasoning: "Standard cognitive assessment: Baseline recognition test",
                frequency: .standard
            )
        ]
    }
    
    /// Get recommended games for assessment flow
    /// Filters to only include games that should be included in the assessment
    static func getRecommendedGamesForAssessment(basedOn analysis: MedicalRecordAnalysis?) -> [GameType] {
        let recommendations = recommendGames(basedOn: analysis)
        
        // For assessment flow, include all games but prioritize based on recommendations
        // Games with high/medium priority should be shown first
        return recommendations.map { $0.gameType }
    }
    
    /// Get summary of recommendations
    static func getRecommendationSummary(basedOn analysis: MedicalRecordAnalysis?) -> String {
        let recommendations = recommendGames(basedOn: analysis)
        
        let highPriority = recommendations.filter { $0.priority == .high }
        let mediumPriority = recommendations.filter { $0.priority == .medium }
        
        if !highPriority.isEmpty {
            return "Based on your medical records, \(highPriority.count) test(s) are highly recommended for regular monitoring."
        } else if !mediumPriority.isEmpty {
            return "Based on your medical records, \(mediumPriority.count) test(s) are moderately recommended."
        } else {
            return "Standard cognitive assessment recommended for baseline monitoring."
        }
    }
}

// MARK: - Supporting Types

/// Game recommendation based on medical record analysis
struct GameRecommendation: Identifiable {
    let id = UUID()
    let gameType: GameType
    let priority: RecommendationPriority
    let reasoning: String
    let frequency: AssessmentFrequency
}

enum RecommendationPriority: Int, Comparable {
    case standard = 1
    case medium = 2
    case high = 3
    
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .medium:
            return "Moderate"
        case .high:
            return "High"
        }
    }
    
    var color: String {
        switch self {
        case .standard:
            return "blue"
        case .medium:
            return "orange"
        case .high:
            return "red"
        }
    }
    
    static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum AssessmentFrequency: String {
    case standard = "Monthly"
    case regular = "Bi-weekly"
    case frequent = "Weekly"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .standard:
            return "Recommended monthly"
        case .regular:
            return "Recommended every 2 weeks"
        case .frequent:
            return "Recommended weekly"
        }
    }
}
