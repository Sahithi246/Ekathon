//
//  TrendChart.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import Charts

struct TrendChart: View {
    let scores: [CognitiveScore]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("7-Day Trend")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                if !scores.isEmpty {
                    let trend = CognitiveScoreService.getTrend(from: scores)
                    HStack(spacing: 4) {
                        Text(trend.symbol)
                            .font(.system(size: 16, weight: .bold))
                        Text(trend.label)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Chart
            if scores.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No data yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                Chart {
                    ForEach(Array(scores.enumerated()), id: \.element.timestamp) { index, score in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Score", score.overallScore)
                        )
                        .foregroundStyle(Color(red: 0.12, green: 0.23, blue: 0.37)) // #1E3A5F
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Day", index),
                            y: .value("Score", score.overallScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.23, blue: 0.37).opacity(0.3),
                                    Color(red: 0.12, green: 0.23, blue: 0.37).opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Double.self) {
                                Text("\(Int(intValue))")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .frame(height: 150)
                .padding()
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

extension TrendDirection {
    var label: String {
        switch self {
        case .improving:
            return "Improving"
        case .stable:
            return "Stable"
        case .declining:
            return "Declining"
        }
    }
}

