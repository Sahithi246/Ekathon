//
//  MedicalRecordAnalysis.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Medical record analysis model for cognitive risk assessment
@Model
final class MedicalRecordAnalysis {
    var timestamp: Date
    var abhaID: String
    var riskScore: Double // 0-100 (0 = highest risk, 100 = lowest risk)
    var medicationImpact: Double // -100 to +100
    var labValueImpact: Double // -100 to +100
    var chronicConditionImpact: Double // -100 to +100
    var totalRecordsAnalyzed: Int
    var lastSyncDate: Date?
    
    // Store cognitive markers as JSON data (SwiftData doesn't support arrays of structs well)
    var cognitiveMarkersJSON: Data?
    
    init(
        timestamp: Date = Date(),
        abhaID: String = "",
        riskScore: Double = 50.0,
        medicationImpact: Double = 0,
        labValueImpact: Double = 0,
        chronicConditionImpact: Double = 0,
        totalRecordsAnalyzed: Int = 0,
        lastSyncDate: Date? = nil,
        cognitiveMarkers: [CognitiveMarker] = []
    ) {
        self.timestamp = timestamp
        self.abhaID = abhaID
        self.riskScore = riskScore
        self.medicationImpact = medicationImpact
        self.labValueImpact = labValueImpact
        self.chronicConditionImpact = chronicConditionImpact
        self.totalRecordsAnalyzed = totalRecordsAnalyzed
        self.lastSyncDate = lastSyncDate
        self.cognitiveMarkersJSON = try? JSONEncoder().encode(cognitiveMarkers)
    }
    
    /// Get cognitive markers from JSON data
    var cognitiveMarkers: [CognitiveMarker] {
        guard let data = cognitiveMarkersJSON,
              let markers = try? JSONDecoder().decode([CognitiveMarker].self, from: data) else {
            return []
        }
        return markers
    }
    
    /// Set cognitive markers (stores as JSON)
    func setCognitiveMarkers(_ markers: [CognitiveMarker]) {
        cognitiveMarkersJSON = try? JSONEncoder().encode(markers)
    }
    
    /// Calculate overall cognitive score from medical records (0-100)
    var cognitiveScore: Double {
        // Normalize to 0-100 scale
        // Higher risk factors = lower score
        let baseScore = 50.0 // Neutral starting point
        
        // Adjust based on impacts (negative impacts reduce score)
        let adjustedScore = baseScore + 
            (medicationImpact * 0.3) + 
            (labValueImpact * 0.4) + 
            (chronicConditionImpact * 0.3)
        
        return max(0, min(100, adjustedScore))
    }
    
    /// Get status based on risk score
    var status: String {
        switch riskScore {
        case 0..<40:
            return "at_risk"
        case 40..<70:
            return "monitor"
        default:
            return "stable"
        }
    }
    
    /// Get RiskLevel enum from risk score
    var riskLevel: RiskLevel {
        switch riskScore {
        case 0..<40:
            return .high
        case 40..<70:
            return .medium
        default:
            return .low
        }
    }
}

/// Cognitive marker extracted from medical records
struct CognitiveMarker: Codable, Identifiable, Hashable {
    let id: String
    let type: MarkerType
    let name: String
    let value: String?
    let impact: Double // -100 to +100 (negative = risk, positive = protective)
    let date: Date
    let unit: String?
    let referenceRange: String?
    
    init(
        id: String = UUID().uuidString,
        type: MarkerType,
        name: String,
        value: String? = nil,
        impact: Double = 0,
        date: Date = Date(),
        unit: String? = nil,
        referenceRange: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.value = value
        self.impact = impact
        self.date = date
        self.unit = unit
        self.referenceRange = referenceRange
    }
}

enum MarkerType: String, Codable {
    case medication
    case labValue
    case chronicCondition
    case medicalEvent
    case vitalSign
    
    var displayName: String {
        switch self {
        case .medication:
            return "Medication"
        case .labValue:
            return "Lab Value"
        case .chronicCondition:
            return "Chronic Condition"
        case .medicalEvent:
            return "Medical Event"
        case .vitalSign:
            return "Vital Sign"
        }
    }
}

/// Risk factor identified from medical records
struct RiskFactor: Identifiable, Hashable {
    let id: String
    let name: String
    let severity: RiskSeverity
    let description: String
    let recommendation: String?
    let detectedDate: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        severity: RiskSeverity,
        description: String,
        recommendation: String? = nil,
        detectedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
        self.detectedDate = detectedDate
    }
}

enum RiskSeverity: String {
    case low
    case medium
    case high
    case critical
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
}
