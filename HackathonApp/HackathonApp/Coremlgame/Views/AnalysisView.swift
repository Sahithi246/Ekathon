//
//  AnalysisView.swift
//  Coremlgame
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CoremlCognitiveScore.timestamp, order: .reverse) private var allScores: [CoremlCognitiveScore]
    @Query(sort: \CoremlReactionTimeResult.timestamp, order: .reverse) private var reactionResults: [CoremlReactionTimeResult]
    @Query(sort: \CoremlSleepData.date, order: .reverse) private var sleepData: [CoremlSleepData]
    @Query(sort: \CoremlPhotoRecognitionResult.timestamp, order: .reverse) private var photoRecognitionResults: [CoremlPhotoRecognitionResult]
    
    @State private var insight: HealthAnalysisMLService.HealthInsight?
    @State private var isLoading = false
    @State private var selectedTimeRange: TimeRange = .last30Days
    
    enum TimeRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case allTime = "All Time"
        
        var days: Int? {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .allTime: return nil
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _ in
                        analyzeData()
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else if let insight = insight {
                        
                        // Key Findings
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("Key Findings")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            
                            ForEach(insight.keyFindings, id: \.self) { finding in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    Text(finding)
                                        .font(.system(size: 15))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
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
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.orange)
                                Text("Recommendations")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            
                            ForEach(Array(insight.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    Text(recommendation)
                                        .font(.system(size: 15))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
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
                        
                        // Data Summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data Summary")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            HStack(spacing: 16) {
                                DataSummaryCard(
                                    title: "Reaction Tests",
                                    count: filteredReactionResults.count,
                                    icon: "timer"
                                )
                                DataSummaryCard(
                                    title: "Sleep Records",
                                    count: filteredSleepData.count,
                                    icon: "bed.double.fill"
                                )
                                DataSummaryCard(
                                    title: "Photo Games",
                                    count: filteredPhotoRecognition.count,
                                    icon: "photo.on.rectangle.angled"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No data available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Complete some tests to see insights")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                analyzeData()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredReactionResults: [CoremlReactionTimeResult] {
        filterByTimeRange(reactionResults, timestampKeyPath: \.timestamp)
    }
    
    private var filteredSleepData: [CoremlSleepData] {
        filterByTimeRange(sleepData, timestampKeyPath: \.date)
    }
    
    private var filteredPhotoRecognition: [CoremlPhotoRecognitionResult] {
        filterByTimeRange(photoRecognitionResults, timestampKeyPath: \.timestamp)
    }
    
    private func filterByTimeRange<T>(_ items: [T], timestampKeyPath: KeyPath<T, Date>) -> [T] {
        guard let days = selectedTimeRange.days else { return items }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return items.filter { $0[keyPath: timestampKeyPath] >= cutoffDate }
    }
    
    // MARK: - Functions
    private func analyzeData() {
        isLoading = true
        
        // Get filtered data on main thread (since @Query properties must be accessed on main thread)
        let reactionTimes = filteredReactionResults
        let sleepData = filteredSleepData
        let photoRecognition = filteredPhotoRecognition
        let cognitiveScores = allScores
        
        DispatchQueue.global(qos: .userInitiated).async {
            let insight = HealthAnalysisMLService.analyzeHistoricalData(
                reactionTimes: reactionTimes,
                sleepData: sleepData,
                photoRecognition: photoRecognition,
                cognitiveScores: cognitiveScores
            )
            
            DispatchQueue.main.async {
                self.insight = insight
                self.isLoading = false
            }
        }
    }
    
    private func trendIcon(_ trend: String) -> String {
        switch trend {
        case "improving":
            return "↑"
        case "declining":
            return "↓"
        default:
            return "→"
        }
    }
    
    private func trendText(_ trend: String) -> String {
        switch trend {
        case "improving":
            return "Improving"
        case "declining":
            return "Declining"
        default:
            return "Stable"
        }
    }
    
    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "improving":
            return .green
        case "declining":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Data Summary Card
struct DataSummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            Text("\(count)")
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
    AnalysisView()
        .modelContainer(for: [CoremlCognitiveScore.self, CoremlReactionTimeResult.self, CoremlSleepData.self, CoremlPhotoRecognitionResult.self], inMemory: true)
}
