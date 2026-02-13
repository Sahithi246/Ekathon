//
//  RiskLevel.swift
//  Coremlgame
//
//  Created on 29/01/26.
//

import Foundation

/// Coremlgame risk level — renamed to avoid conflict with main app's RiskLevel
enum CoremlRiskLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}
