//
//  CognitiveAssessmentFlowView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

/// Unified cognitive assessment flow that runs all games in sequence
struct CognitiveAssessmentFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \MedicalRecordAnalysis.timestamp, order: .reverse) private var medicalAnalyses: [MedicalRecordAnalysis]
    
    @State private var currentGameIndex = 0
    @State private var assessmentState: AssessmentState = .ready
    @State private var results: AssessmentResults = AssessmentResults()
    @State private var showResults = false
    
    // Game states
    @State private var reactionTimeCompleted = false
    @State private var shapeSequenceCompleted = false
    @State private var photoRecognitionCompleted = false
    
    private let games: [GameType] = [.reactionTime, .shapeSequence, .photoRecognition]
    
    /// Latest medical record analysis
    private var latestMedicalAnalysis: MedicalRecordAnalysis? {
        medicalAnalyses.first
    }
    
    /// Game recommendations based on medical records
    private var gameRecommendations: [GameRecommendation] {
        GameRecommendationService.recommendGames(basedOn: latestMedicalAnalysis)
    }
    
    /// Recommendation summary
    private var recommendationSummary: String {
        GameRecommendationService.getRecommendationSummary(basedOn: latestMedicalAnalysis)
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            switch assessmentState {
            case .ready:
                readyView
            case .inProgress:
                inProgressView
            case .completed:
                completedView
            }
        }
        .navigationTitle("Cognitive Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(assessmentState == .inProgress)
    }
    
    // MARK: - Ready View
    
    private var readyView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Cognitive Assessment")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 16) {
                    Text("Complete all tests to get your cognitive health score")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Show personalized recommendations if medical records are available
                    if let analysis = latestMedicalAnalysis {
                        personalizedRecommendationsSection(analysis: analysis)
                    }
                    
                    // Show games that will be tested
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tests Included")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 40)
                        
                        ForEach(games, id: \.self) { game in
                            if let recommendation = gameRecommendations.first(where: { $0.gameType == game }) {
                                RecommendedGameRow(
                                    game: game,
                                    recommendation: recommendation
                                )
                            } else {
                                GamePreviewRow(
                                    icon: iconForGame(game),
                                    title: gameTitle(for: game),
                                    description: descriptionForGame(game)
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                Button(action: startAssessment) {
                    Text("Start Assessment")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Personalized Recommendations Section
    
    private func personalizedRecommendationsSection(analysis: MedicalRecordAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue)
                Text("Personalized Recommendations")
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.horizontal, 40)
            
            Text(recommendationSummary)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            // Show high priority recommendations
            let highPriority = gameRecommendations.filter { $0.priority == .high }
            if !highPriority.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("High Priority Tests")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                    
                    ForEach(highPriority) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal, 40)
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
    
    private func descriptionForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "Tap when screen turns green"
        case .shapeSequence:
            return "Remember and repeat sequences"
        case .photoRecognition:
            return "Identify people in photos"
        }
    }
    
    // MARK: - In Progress View
    
    private var inProgressView: some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(spacing: 12) {
                Text("Test \(currentGameIndex + 1) of \(games.count)")
                    .font(.system(size: 18, weight: .semibold))
                
                ProgressView(value: Double(currentGameIndex), total: Double(games.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 200)
                
                Text(gameTitle(for: games[currentGameIndex]))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Show current game
            Group {
                switch games[currentGameIndex] {
                case .reactionTime:
                    ReactionTimeTestView(
                        onComplete: { result in
                            results.reactionTimeResult = result
                            moveToNextGame()
                        },
                        hideNavigationBar: true
                    )
                case .shapeSequence:
                    ShapeSequenceGameView(
                        onComplete: { result in
                            results.shapeSequenceResult = result
                            moveToNextGame()
                        },
                        hideNavigationBar: true
                    )
                case .photoRecognition:
                    PhotoRecognitionGameView(
                        onComplete: { result in
                            results.photoRecognitionResult = result
                            completeAssessment()
                        },
                        hideNavigationBar: true
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
    }
    
    // MARK: - Completed View
    
    private var completedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Assessment Complete!")
                .font(.system(size: 28, weight: .bold))
            
            // Calculate overall score
            let overallScore = calculateOverallScore()
            
            VStack(spacing: 16) {
                ScoreRow(label: "Overall Score", value: "\(Int(overallScore))", color: scoreColor(overallScore))
                
                if let rt = results.reactionTimeResult {
                    ScoreRow(label: "Reaction Time", value: String(format: "%.0f", rt.cognitiveScore), color: .blue)
                }
                
                if let ss = results.shapeSequenceResult {
                    ScoreRow(label: "Shape Memory", value: String(format: "%.0f", ss.cognitiveScore), color: .purple)
                }
                
                if let pr = results.photoRecognitionResult {
                    ScoreRow(label: "Photo Recognition", value: String(format: "%.0f", pr.cognitiveScore), color: .orange)
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: saveAndDismiss) {
                Text("View Dashboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Functions
    
    private func startAssessment() {
        assessmentState = .inProgress
        currentGameIndex = 0
        results = AssessmentResults()
    }
    
    private func moveToNextGame() {
        if currentGameIndex < games.count - 1 {
            withAnimation {
                currentGameIndex += 1
            }
        } else {
            completeAssessment()
        }
    }
    
    private func completeAssessment() {
        assessmentState = .completed
    }
    
    private func gameTitle(for game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "Reaction Time Test"
        case .shapeSequence:
            return "Shape Memory"
        case .photoRecognition:
            return "Photo Recognition"
        }
    }
    
    private func calculateOverallScore() -> Double {
        // Use CognitiveScoreService to calculate unified score
        // Include medical records score if available
        let medicalRecordsScore = latestMedicalAnalysis?.cognitiveScore ?? 50
        
        return CognitiveScoreService.calculateUnifiedScore(
            reactionTimeScore: results.reactionTimeResult?.cognitiveScore ?? 50,
            sleepScore: 50, // No sleep data in assessment
            photoRecognitionScore: results.photoRecognitionResult?.cognitiveScore ?? 50,
            medicalRecordsScore: medicalRecordsScore,
            shapeSequenceScore: results.shapeSequenceResult?.cognitiveScore ?? 50
        )
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<70:
            return .orange
        default:
            return .green
        }
    }
    
    private func saveAndDismiss() {
        // Save all results
        if let rt = results.reactionTimeResult {
            modelContext.insert(rt)
        }
        if let ss = results.shapeSequenceResult {
            modelContext.insert(ss)
        }
        if let pr = results.photoRecognitionResult {
            modelContext.insert(pr)
        }
        
        // Calculate and save cognitive score
        let sleepData: SleepData? = nil // Will be fetched from HealthKit
        let medicalRecords: MedicalRecordAnalysis? = latestMedicalAnalysis // Use latest analysis if available
        
        let cognitiveScore = CognitiveScoreService.calculateFromModels(
            reactionTime: results.reactionTimeResult,
            sleep: sleepData,
            photoRecognition: results.photoRecognitionResult,
            medicalRecords: medicalRecords,
            shapeSequence: results.shapeSequenceResult
        )
        
        modelContext.insert(cognitiveScore)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving assessment results: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum AssessmentState {
    case ready
    case inProgress
    case completed
}

enum GameType {
    case reactionTime
    case shapeSequence
    case photoRecognition
}

struct AssessmentResults {
    var reactionTimeResult: ReactionTimeResult?
    var shapeSequenceResult: ShapeSequenceResult?
    var photoRecognitionResult: PhotoRecognitionResult?
}


struct GamePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }
}

struct RecommendedGameRow: View {
    let game: GameType
    let recommendation: GameRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForGame(game))
                .font(.system(size: 24))
                .foregroundColor(colorForPriority(recommendation.priority))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(titleForGame(game))
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    // Priority badge
                    Text(recommendation.priority.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForPriority(recommendation.priority))
                        .cornerRadius(8)
                }
                
                Text(descriptionForGame(game))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // Show reasoning if available
                if !recommendation.reasoning.isEmpty {
                    Text(recommendation.reasoning)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                
                // Frequency recommendation
                Text("📅 \(recommendation.frequency.description)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForPriority(recommendation.priority).opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 40)
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
            return "Shape Memory"
        case .photoRecognition:
            return "Photo Recognition"
        }
    }
    
    private func descriptionForGame(_ game: GameType) -> String {
        switch game {
        case .reactionTime:
            return "Tap when screen turns green"
        case .shapeSequence:
            return "Remember and repeat sequences"
        case .photoRecognition:
            return "Identify people in photos"
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

struct RecommendationCard: View {
    let recommendation: GameRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForGame(recommendation.gameType))
                    .foregroundColor(.red)
                
                Text(titleForGame(recommendation.gameType))
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("HIGH PRIORITY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(6)
            }
            
            Text(recommendation.reasoning)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("📅 Recommended: \(recommendation.frequency.displayName)")
                .font(.system(size: 12))
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 40)
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
            return "Shape Memory"
        case .photoRecognition:
            return "Photo Recognition"
        }
    }
}


#Preview {
    NavigationView {
        CognitiveAssessmentFlowView()
            .modelContainer(for: [ReactionTimeResult.self, ShapeSequenceResult.self, PhotoRecognitionResult.self], inMemory: true)
    }
}
