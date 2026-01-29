//
//  DashboardView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CognitiveScore.timestamp, order: .reverse) private var allScores: [CognitiveScore]
    @Query(sort: \ReactionTimeResult.timestamp, order: .reverse) private var reactionResults: [ReactionTimeResult]
    @Query(sort: \SleepData.date, order: .reverse) private var sleepData: [SleepData]
    @Query(sort: \VoiceMetrics.timestamp, order: .reverse) private var voiceMetrics: [VoiceMetrics]
    
    @State private var currentScore: CognitiveScore?
    @State private var isLoading = false
    @State private var healthKitService = HealthKitService()
    @State private var isFetchingHealthData = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Risk Score Card
                    if let score = currentScore {
                        RiskScoreCard(
                            score: score.overallScore,
                            riskLevel: score.riskLevel
                        )
                        .padding(.horizontal)
                        .padding(.top)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // Loading or empty state
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Calculating cognitive score...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // Signal Indicators
                    VStack(spacing: 12) {
                        if let score = currentScore {
                            SignalIndicator(
                                title: "Reaction Time",
                                status: score.reactionTimeStatus,
                                score: score.reactionTimeScore,
                                icon: "timer"
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            SignalIndicator(
                                title: "Sleep",
                                status: score.sleepStatus,
                                score: score.sleepScore,
                                icon: "bed.double.fill"
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            SignalIndicator(
                                title: "Speech Variability",
                                status: score.voiceStatus,
                                score: score.voiceScore,
                                icon: "waveform"
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: currentScore != nil)
                    
                    // Trend Chart
                    TrendChart(scores: Array(allScores.prefix(7)))
                        .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            NavigationLink(destination: ReactionTimeTestView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Take Test")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.12, green: 0.23, blue: 0.37))
                                )
                            }
                            
                            NavigationLink(destination: VoiceCheckView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Voice Check")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.12, green: 0.23, blue: 0.37))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    // Disclaimer
                    VStack(spacing: 8) {
                        Text("⚠️ Medical Disclaimer")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("This is not diagnostic — it's a screening and monitoring tool.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cognitive Track")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Generate demo data on first launch
                if MockDataGenerator.shouldGenerateDemoData() {
                    MockDataGenerator.generateDemoData(modelContext: modelContext)
                    MockDataGenerator.markDemoDataGenerated()
                }
                
                calculateCurrentScore()
                fetchHealthKitData()
            }
            .refreshable {
                await refreshData()
            }
            .onChange(of: reactionResults.count) { _, _ in
                calculateCurrentScore()
            }
            .onChange(of: voiceMetrics.count) { _, _ in
                calculateCurrentScore()
            }
        }
    }
    
    private func calculateCurrentScore() {
        let latestReaction = reactionResults.first
        let latestSleep = sleepData.first
        let latestVoice = voiceMetrics.first
        
        let newScore = CognitiveScoreService.calculateFromModels(
            reactionTime: latestReaction,
            sleep: latestSleep,
            voice: latestVoice
        )
        
        // Save to database
        modelContext.insert(newScore)
        
        // Update current score
        currentScore = newScore
        
        // Try to save context
        do {
            try modelContext.save()
        } catch {
            print("Error saving score: \(error)")
        }
    }
    
    private func refreshData() async {
        isLoading = true
        await fetchHealthKitData()
        calculateCurrentScore()
        isLoading = false
    }
    
    private func fetchHealthKitData() {
        guard !isFetchingHealthData else { return }
        
        Task {
            isFetchingHealthData = true
            
            // Request authorization if needed
            if !healthKitService.isAuthorized() {
                do {
                    try await healthKitService.requestAuthorization()
                } catch {
                    print("HealthKit authorization error: \(error)")
                    isFetchingHealthData = false
                    return
                }
            }
            
            // Fetch sleep data
            do {
                let healthSleepData = try await healthKitService.fetchSleepData(days: 7)
                
                // Save to SwiftData if we got real data
                if !healthSleepData.isEmpty {
                    await MainActor.run {
                        for sleep in healthSleepData {
                            // Only insert if we don't already have data for this date
                            let existing = sleepData.first { Calendar.current.isDate($0.date, inSameDayAs: sleep.date) }
                            if existing == nil && sleep.totalSleepHours > 0 {
                                modelContext.insert(sleep)
                            }
                        }
                        
                        do {
                            try modelContext.save()
                            calculateCurrentScore()
                        } catch {
                            print("Error saving HealthKit data: \(error)")
                        }
                    }
                }
            } catch {
                print("Error fetching HealthKit data: \(error)")
                // Silently fail - demo data will be used instead
            }
            
            isFetchingHealthData = false
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [CognitiveScore.self, ReactionTimeResult.self, SleepData.self, VoiceMetrics.self], inMemory: true)
}
