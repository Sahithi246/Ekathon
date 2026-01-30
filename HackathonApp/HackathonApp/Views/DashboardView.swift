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
    @Query(sort: \PhotoRecognitionResult.timestamp, order: .reverse) private var photoRecognitionResults: [PhotoRecognitionResult]
    @Query(sort: \ShapeSequenceResult.timestamp, order: .reverse) private var shapeSequenceResults: [ShapeSequenceResult]
    
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
                                title: "Photo Recognition",
                                status: score.photoRecognitionStatus,
                                score: score.photoRecognitionScore,
                                icon: "photo.on.rectangle.angled"
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            SignalIndicator(
                                title: "Shape Memory",
                                status: score.shapeSequenceStatus,
                                score: score.shapeSequenceScore,
                                icon: "square.stack.3d.up.fill"
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: currentScore != nil)
                    
                    // Historical Data Summary
                    if !allScores.isEmpty {
                        historicalDataSection
                    }
                    
                    // Trend Chart
                    TrendChart(scores: Array(allScores.prefix(7)))
                        .padding(.horizontal)
                    
                    // Recent Test Results
                    if !reactionResults.isEmpty || !photoRecognitionResults.isEmpty || !shapeSequenceResults.isEmpty {
                        recentTestsSection
                    }
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: CognitiveAssessmentFlowView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start Assessment")
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
                            
                            NavigationLink(destination: PhotoSetupView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Setup Photos")
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
            .onChange(of: photoRecognitionResults.count) { _, _ in
                calculateCurrentScore()
            }
            .onChange(of: shapeSequenceResults.count) { _, _ in
                calculateCurrentScore()
            }
        
    }
    
    private func calculateCurrentScore() {
        let latestReaction = reactionResults.first
        let latestSleep = sleepData.first
        let latestPhotoRecognition = photoRecognitionResults.first
        let latestShapeSequence = shapeSequenceResults.first
        
        let newScore = CognitiveScoreService.calculateFromModels(
            reactionTime: latestReaction,
            sleep: latestSleep,
            photoRecognition: latestPhotoRecognition,
            medicalRecords: nil, // Medical records removed from dashboard
            shapeSequence: latestShapeSequence
        )
        
        // Only save if we don't already have a score for today
        let today = Calendar.current.startOfDay(for: Date())
        let existingTodayScore = allScores.first { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        
        if existingTodayScore == nil {
            // Save to database
            modelContext.insert(newScore)
        }
        
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
    
    // MARK: - Historical Data Section
    
    private var historicalDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Historical Data")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("\(allScores.count) assessments")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Show stats
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Tests",
                    value: "\(reactionResults.count + photoRecognitionResults.count + shapeSequenceResults.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Days Tracked",
                    value: "\(uniqueDaysCount)",
                    icon: "calendar",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Score",
                    value: String(format: "%.0f", averageScore),
                    icon: "star.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Recent Tests Section
    
    private var recentTestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("Recent Tests")
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                if let latestReaction = reactionResults.first {
                    RecentTestRow(
                        icon: "timer",
                        title: "Reaction Time",
                        score: String(format: "%.0f ms", latestReaction.averageReactionTime),
                        date: latestReaction.timestamp,
                        color: .blue
                    )
                }
                
                if let latestPhoto = photoRecognitionResults.first {
                    RecentTestRow(
                        icon: "photo.on.rectangle.angled",
                        title: "Photo Recognition",
                        score: "\(latestPhoto.correctAnswers)/\(latestPhoto.totalPhotos)",
                        date: latestPhoto.timestamp,
                        color: .orange
                    )
                }
                
                if let latestShape = shapeSequenceResults.first {
                    RecentTestRow(
                        icon: "square.stack.3d.up.fill",
                        title: "Shape Memory",
                        score: "\(latestShape.maxSequenceLength) sequences",
                        date: latestShape.timestamp,
                        color: .purple
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
    
    private var uniqueDaysCount: Int {
        let allDates = Set(
            reactionResults.map { Calendar.current.startOfDay(for: $0.timestamp) } +
            photoRecognitionResults.map { Calendar.current.startOfDay(for: $0.timestamp) } +
            shapeSequenceResults.map { Calendar.current.startOfDay(for: $0.timestamp) }
        )
        return allDates.count
    }
    
    private var averageScore: Double {
        guard !allScores.isEmpty else { return 0 }
        let sum = allScores.reduce(0.0) { $0 + $1.overallScore }
        return sum / Double(allScores.count)
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

// MARK: - Supporting Views

struct StatCard: View {
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentTestRow: View {
    let icon: String
    let title: String
    let score: String
    let date: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(score)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeAgoString(from: date))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(days) days ago"
        }
    }
}

// MARK: - Recommendation Views (kept for potential future use)

struct CompactRecommendationCard: View {
    let recommendation: GameRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForGame(recommendation.gameType))
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                
                Spacer()
                
                Text("HIGH")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .cornerRadius(4)
            }
            
            Text(titleForGame(recommendation.gameType))
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
            
            Text(recommendation.frequency.displayName)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func iconForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "timer"
        case .shapeSequence:
            return "square.stack.3d.up.fill"
        case .photoRecognition:
            return "photo.on.rectangle.angled"
        }
    }
    
    private func titleForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "Reaction Time"
        case .shapeSequence:
            return "Shape Memory"
        case .photoRecognition:
            return "Photo Recognition"
        }
    }
}

struct CompactRecommendationRow: View {
    let recommendation: GameRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForGame(recommendation.gameType))
                .font(.system(size: 20))
                .foregroundColor(colorForPriority(recommendation.priority))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(titleForGame(recommendation.gameType))
                        .font(.system(size: 15, weight: .semibold))
                    
                    Spacer()
                    
                    Text(recommendation.priority.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForPriority(recommendation.priority))
                        .cornerRadius(6)
                }
                
                Text(recommendation.frequency.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func iconForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "timer"
        case .shapeSequence:
            return "square.stack.3d.up.fill"
        case .photoRecognition:
            return "photo.on.rectangle.angled"
        }
    }
    
    private func titleForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "Reaction Time Test"
        case .shapeSequence:
            return "Shape Memory Test"
        case .photoRecognition:
            return "Photo Recognition Test"
        }
    }
    
    private func colorForPriority(_ priority: RecommendationPriority) -> Color {
        switch priority {
        case .standard:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [CognitiveScore.self, ReactionTimeResult.self, SleepData.self, PhotoRecognitionResult.self], inMemory: true)
}
