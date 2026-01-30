//
//  CoremlgameDashboardView.swift
//  Coremlgame
//
//  Renamed file and view to avoid conflict with main app's DashboardView.
//

import SwiftUI
import SwiftData

/// Coremlgame dashboard — renamed to avoid conflict with main app's DashboardView
struct CoremlgameDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CoremlCognitiveScore.timestamp, order: .reverse) private var allScores: [CoremlCognitiveScore]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Dashboard")
                            .font(.system(size: 32, weight: .bold))
                        Text("Track your cognitive health")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Quick Stats
                    if let latestScore = allScores.first {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Latest Score")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text("\(Int(latestScore.overallScore))")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(colorForRiskLevel(latestScore.riskLevelEnum))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Risk Level")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text(latestScore.riskLevelEnum.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(colorForRiskLevel(latestScore.riskLevelEnum))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Action Cards
                    VStack(spacing: 16) {
                        NavigationLink(destination: AnalysisView()) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                    .frame(width: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Analysis")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("See detailed health insights")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AnalysisView()) {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
            }
        }
    }
    
    private func colorForRiskLevel(_ level: CoremlRiskLevel) -> Color {
        switch level {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

struct CoremlStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    CoremlgameDashboardView()
        .modelContainer(for: [CoremlCognitiveScore.self, CoremlReactionTimeResult.self, CoremlSleepData.self, CoremlPhotoRecognitionResult.self], inMemory: true)
}
