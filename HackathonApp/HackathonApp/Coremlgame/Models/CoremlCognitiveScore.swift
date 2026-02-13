//
//  CoremlCognitiveScore.swift
//  Coremlgame
//
//  Renamed file and type to avoid conflict with main app's CognitiveScore.
//

import Foundation
import SwiftData

@Model
final class CoremlCognitiveScore {
    var timestamp: Date
    var overallScore: Double
    var riskLevel: String // Stored as String for SwiftData compatibility
    
    init(timestamp: Date, overallScore: Double, riskLevel: CoremlRiskLevel) {
        self.timestamp = timestamp
        self.overallScore = overallScore
        self.riskLevel = riskLevel.rawValue
    }
    
    var riskLevelEnum: CoremlRiskLevel {
        get { CoremlRiskLevel(rawValue: riskLevel) ?? .low }
        set { riskLevel = newValue.rawValue }
    }
}
