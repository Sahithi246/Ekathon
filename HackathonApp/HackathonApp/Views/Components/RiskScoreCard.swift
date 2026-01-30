//
//  RiskScoreCard.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI

struct RiskScoreCard: View {
    let score: Double
    let riskLevel: RiskLevel
    let title: String?
    let subtitle: String?
    
    init(score: Double, riskLevel: RiskLevel, title: String? = nil, subtitle: String? = nil) {
        self.score = score
        self.riskLevel = riskLevel
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Custom Title (if provided)
            if let title = title {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Status Emoji
            Text(riskLevel.emoji)
                .font(.system(size: 48))
            
            // Score Display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(score))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(riskLevel.color)
                
                Text("/ 100")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Risk Level Label
            Text(riskLevel.label)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(riskLevel.color)
            
            // Custom Subtitle (if provided) or default description
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                // Description
                Text(riskLevel.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

extension RiskLevel {
    var emoji: String {
        switch self {
        case .low:
            return "🟢"
        case .medium:
            return "🟡"
        case .high:
            return "🔴"
        }
    }
    
    var label: String {
        switch self {
        case .low:
            return "Stable"
        case .medium:
            return "Monitor"
        case .high:
            return "At Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return Color(red: 0.3, green: 0.69, blue: 0.31) // #4CAF50
        case .medium:
            return Color(red: 1.0, green: 0.6, blue: 0.0) // #FF9800
        case .high:
            return Color(red: 0.96, green: 0.26, blue: 0.21) // #F44336
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Your cognitive signals are within normal range"
        case .medium:
            return "Some signals need attention. Continue monitoring."
        case .high:
            return "Multiple signals indicate concern. Consider consultation."
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RiskScoreCard(score: 85, riskLevel: .low)
        RiskScoreCard(score: 55, riskLevel: .medium)
        RiskScoreCard(score: 30, riskLevel: .high)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
