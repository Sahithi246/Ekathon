//
//  ReactionTimeTestView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct ReactionTimeTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: ((ReactionTimeResult) -> Void)?
    var hideNavigationBar = false
    
    @State private var testState: TestState = .ready
    @State private var reactionTimes: [Double] = []
    @State private var currentTrial = 0
    @State private var startTime: Date?
    @State private var showColor = false
    @State private var colorTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var countdown = 3
    @State private var testStartTime: Date?
    
    private let numberOfTrials = 3
    private let minWaitTime: TimeInterval = 1.0
    private let maxWaitTime: TimeInterval = 4.0
    
    var body: some View {
        ZStack {
            // Background color changes based on state
            Color(testState.backgroundColor)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: testState)
            
            VStack(spacing: 30) {
                // Header
                if testState == .ready || testState == .countdown {
                    VStack(spacing: 12) {
                        Text("Reaction Time Test")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Tap when the screen turns green")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Countdown
                if testState == .countdown {
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Test instructions
                if testState == .ready {
                    VStack(spacing: 20) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Get ready!")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Button(action: startTest) {
                            Text("Start Test")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                // Waiting for tap
                if testState == .waiting {
                    VStack(spacing: 20) {
                        Text("Wait for green...")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 100, height: 100)
                    }
                }
                
                // Tap now!
                if testState == .tapNow {
                    VStack(spacing: 20) {
                        Text("TAP NOW!")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.3), radius: 20)
                    }
                    .onTapGesture {
                        recordReaction()
                    }
                }
                
                // Trial progress
                if testState == .waiting || testState == .tapNow {
                    VStack(spacing: 8) {
                        Text("Trial \(currentTrial + 1) of \(numberOfTrials)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        ProgressView(value: Double(currentTrial), total: Double(numberOfTrials))
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                    }
                }
                
                // Results
                if testState == .completed {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Test Complete!")
                            .font(.system(size: 28, weight: .bold))
                        
                        if let averageTime = calculateAverage() {
                            VStack(spacing: 12) {
                                Text("Average Reaction Time")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(averageTime)) ms")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        Button(action: saveAndDismiss) {
                            Text("Done")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            cleanupTimers()
        }
    }
    
    private func startTest() {
        testState = .countdown
        countdown = 3
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                startFirstTrial()
            }
        }
    }
    
    private func startFirstTrial() {
        testStartTime = Date()
        currentTrial = 0
        reactionTimes = []
        startNextTrial()
    }
    
    private func startNextTrial() {
        testState = .waiting
        showColor = false
        
        // Random wait time before showing color
        let waitTime = Double.random(in: minWaitTime...maxWaitTime)
        
        colorTimer = Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { _ in
            showColor = true
            testState = .tapNow
            startTime = Date()
        }
    }
    
    private func recordReaction() {
        guard let startTime = startTime else { return }
        
        let reactionTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        reactionTimes.append(reactionTime)
        
        cleanupTimers()
        
        currentTrial += 1
        
        if currentTrial >= numberOfTrials {
            testState = .completed
        } else {
            // Brief pause before next trial
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startNextTrial()
            }
        }
    }
    
    private func calculateAverage() -> Double? {
        guard !reactionTimes.isEmpty else { return nil }
        return reactionTimes.reduce(0, +) / Double(reactionTimes.count)
    }
    
    private func saveAndDismiss() {
        guard let averageTime = calculateAverage(),
              let testStartTime = testStartTime else {
            dismiss()
            return
        }
        
        let testDuration = Date().timeIntervalSince(testStartTime)
        
        let result = ReactionTimeResult(
            timestamp: Date(),
            averageReactionTime: averageTime,
            testDuration: testDuration,
            numberOfTrials: numberOfTrials,
            individualReactions: reactionTimes
        )
        
        // Call completion handler if provided (for flow view)
        if let onComplete = onComplete {
            onComplete(result)
        } else {
            // Save and dismiss normally
            modelContext.insert(result)
            
            do {
                try modelContext.save()
                dismiss()
            } catch {
                print("Error saving reaction time result: \(error)")
            }
        }
    }
    
    private func cleanupTimers() {
        colorTimer?.invalidate()
        colorTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

enum TestState {
    case ready
    case countdown
    case waiting
    case tapNow
    case completed
    
    var backgroundColor: Color {
        switch self {
        case .ready:
            return Color(red: 0.12, green: 0.23, blue: 0.37) // Deep blue
        case .countdown:
            return Color(red: 0.12, green: 0.23, blue: 0.37)
        case .waiting:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray
        case .tapNow:
            return Color(red: 0.3, green: 0.69, blue: 0.31) // Green
        case .completed:
            return Color(.systemBackground)
        }
    }
}

#Preview {
    NavigationView {
        ReactionTimeTestView()
    }
    .modelContainer(for: ReactionTimeResult.self, inMemory: true)
}
