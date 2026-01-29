//
//  SignalIndicator.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI

struct SignalIndicator: View {
    let title: String
    let status: String
    let score: Double
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(statusColor)
                .frame(width: 40, height: 40)
                .background(statusColor.opacity(0.1))
                .clipShape(Circle())
            
            // Title and Status
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(statusEmoji)
                        .font(.system(size: 14))
                    Text(statusLabel)
                        .font(.system(size: 14))
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(score))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(statusColor)
                Text("points")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var statusEmoji: String {
        switch status {
        case "stable":
            return "🟢"
        case "monitor":
            return "🟡"
        case "at_risk":
            return "🔴"
        default:
            return "⚪"
        }
    }
    
    private var statusLabel: String {
        switch status {
        case "stable":
            return "Stable"
        case "monitor":
            return "Monitor"
        case "at_risk":
            return "At Risk"
        default:
            return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "stable":
            return Color(red: 0.3, green: 0.69, blue: 0.31) // Green
        case "monitor":
            return Color(red: 1.0, green: 0.6, blue: 0.0) // Amber
        case "at_risk":
            return Color(red: 0.96, green: 0.26, blue: 0.21) // Red
        default:
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SignalIndicator(
            title: "Reaction Time",
            status: "stable",
            score: 85,
            icon: "timer"
        )
        SignalIndicator(
            title: "Sleep",
            status: "monitor",
            score: 60,
            icon: "bed.double.fill"
        )
        SignalIndicator(
            title: "Speech Variability",
            status: "at_risk",
            score: 35,
            icon: "waveform"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
