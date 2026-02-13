//
//  ShapeSequenceGameView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct ShapeSequenceGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: ((ShapeSequenceResult) -> Void)?
    var hideNavigationBar = false
    
    @State private var gameState: ShapeSequenceGameState = .ready
    @State private var currentSequence: [ShapeType] = []
    @State private var userSequence: [ShapeType] = []
    @State private var currentRound = 1
    @State private var isShowingSequence = false
    @State private var sequenceIndex = 0
    @State private var correctRounds = 0
    @State private var responseTimes: [Double] = []
    @State private var roundStartTime: Date?
    @State private var highlightedShape: ShapeType?
    @State private var isProcessingTap = false
    
    private let startSequenceLength = 3
    private let sequenceDisplayDuration: TimeInterval = 0.8 // Time each shape is shown
    private let pauseBetweenShapes: TimeInterval = 0.3
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            switch gameState {
            case .ready:
                readyView
            case .showingSequence:
                showingSequenceView
            case .userInput:
                userInputView
            case .completed:
                completedView
            }
        }
        .navigationTitle(hideNavigationBar ? "" : "Shape Memory")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(hideNavigationBar)
        .toolbar {
            if !hideNavigationBar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Ready View
    
    private var readyView: some View {
        VStack(spacing: 30) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Shape Sequence Memory")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 16) {
                Text("Watch the sequence of shapes")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("Then tap them in the same order")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            // Show shape examples
            HStack(spacing: 20) {
                ForEach(ShapeType.allCases, id: \.self) { shape in
                    ShapeView(shape: shape, size: 50, isHighlighted: false)
                }
            }
            .padding(.vertical, 20)
            
            Button(action: startGame) {
                Text("Start Test")
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
    
    // MARK: - Showing Sequence View
    
    private var showingSequenceView: some View {
        VStack(spacing: 30) {
            Text("Round \(currentRound)")
                .font(.system(size: 24, weight: .semibold))
            
            Text("Watch carefully...")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            // Shape grid
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ShapeView(
                        shape: .circle,
                        size: 80,
                        isHighlighted: highlightedShape == .circle
                    )
                    ShapeView(
                        shape: .square,
                        size: 80,
                        isHighlighted: highlightedShape == .square
                    )
                }
                
                HStack(spacing: 20) {
                    ShapeView(
                        shape: .triangle,
                        size: 80,
                        isHighlighted: highlightedShape == .triangle
                    )
                    ShapeView(
                        shape: .star,
                        size: 80,
                        isHighlighted: highlightedShape == .star
                    )
                }
            }
            .padding(.vertical, 40)
            
            // Progress indicator
            Text("\(sequenceIndex + 1) / \(currentSequence.count)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - User Input View
    
    private var userInputView: some View {
        VStack(spacing: 30) {
            Text("Round \(currentRound)")
                .font(.system(size: 24, weight: .semibold))
            
            Text("Tap the shapes in order")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            // Shape grid (tappable)
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ShapeButton(shape: .circle) {
                        handleShapeTap(.circle)
                    }
                    ShapeButton(shape: .square) {
                        handleShapeTap(.square)
                    }
                }
                
                HStack(spacing: 20) {
                    ShapeButton(shape: .triangle) {
                        handleShapeTap(.triangle)
                    }
                    ShapeButton(shape: .star) {
                        handleShapeTap(.star)
                    }
                }
            }
            .padding(.vertical, 40)
            
            // Progress indicator
            Text("\(userSequence.count) / \(currentSequence.count)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Completed View
    
    private var completedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Test Complete!")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 16) {
                ScoreRow(label: "Max Sequence", value: "\(currentSequence.count - 1)", color: .blue)
                ScoreRow(label: "Rounds Correct", value: "\(correctRounds)/\(currentRound - 1)", color: .green)
                ScoreRow(label: "Accuracy", value: String(format: "%.0f%%", accuracy), color: .purple)
            }
            .padding(.horizontal, 40)
            
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
        }
    }
    
    // MARK: - Computed Properties
    
    private var accuracy: Double {
        guard currentRound > 1 else { return 0 }
        return Double(correctRounds) / Double(currentRound - 1) * 100
    }
    
    // MARK: - Game Logic
    
    private func startGame() {
        currentRound = 1
        correctRounds = 0
        responseTimes = []
        isProcessingTap = false
        generateNewSequence()
    }
    
    private func generateNewSequence() {
        // Start with 3 shapes, increase by 1 each round
        let sequenceLength = startSequenceLength + (currentRound - 1)
        currentSequence = (0..<sequenceLength).map { _ in
            ShapeType.allCases.randomElement()!
        }
        userSequence = []
        sequenceIndex = 0
        highlightedShape = nil
        isProcessingTap = false
        
        // Start showing sequence
        gameState = .showingSequence
        showNextShapeInSequence()
    }
    
    private func showNextShapeInSequence() {
        guard sequenceIndex < currentSequence.count else {
            // Sequence shown, now user inputs
            gameState = .userInput
            userSequence = []
            roundStartTime = Date()
            isProcessingTap = false // Reset tap processing flag
            return
        }
        
        // Highlight current shape
        highlightedShape = currentSequence[sequenceIndex]
        
        // Move to next shape after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + sequenceDisplayDuration) {
            highlightedShape = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseBetweenShapes) {
                sequenceIndex += 1
                showNextShapeInSequence()
            }
        }
    }
    
    private func handleShapeTap(_ shape: ShapeType) {
        guard gameState == .userInput, !isProcessingTap else { return }
        
        // Prevent multiple rapid taps
        isProcessingTap = true
        
        // Check if this tap is correct BEFORE appending
        let expectedShape = currentSequence[userSequence.count]
        
        // If wrong shape tapped, end game immediately
        if shape != expectedShape {
            print("❌ Wrong shape tapped! Expected: \(expectedShape), Got: \(shape)")
            handleWrongInput()
            return
        }
        
        // Correct shape - add to sequence
        print("✅ Correct shape tapped: \(shape) (\(userSequence.count + 1)/\(currentSequence.count))")
        userSequence.append(shape)
        
        // Check if sequence is complete
        if userSequence.count == currentSequence.count {
            checkSequence()
        }
        
        // Allow next tap after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isProcessingTap = false
        }
    }
    
    private func checkSequence() {
        guard let startTime = roundStartTime else { return }
        
        let responseTime = Date().timeIntervalSince(startTime)
        responseTimes.append(responseTime)
        
        let isCorrect = userSequence == currentSequence
        
        if isCorrect {
            print("✅ Round \(currentRound) completed correctly!")
            correctRounds += 1
            // Continue to next round
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentRound += 1
                generateNewSequence()
            }
        } else {
            // Wrong sequence - end game
            print("❌ Round \(currentRound) failed! Expected: \(currentSequence), Got: \(userSequence)")
            handleWrongInput()
        }
    }
    
    private func handleWrongInput() {
        // End game
        gameState = .completed
    }
    
    private func saveAndDismiss() {
        let maxSequenceLength = currentSequence.count - 1
        let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        let result = ShapeSequenceResult(
            timestamp: Date(),
            maxSequenceLength: maxSequenceLength,
            totalRounds: currentRound - 1,
            correctRounds: correctRounds,
            averageResponseTime: averageResponseTime,
            individualResponseTimes: responseTimes
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
                print("Error saving result: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

enum ShapeSequenceGameState {
    case ready
    case showingSequence
    case userInput
    case completed
}

enum ShapeType: String, CaseIterable {
    case circle
    case square
    case triangle
    case star
    
    var systemImage: String {
        switch self {
        case .circle:
            return "circle.fill"
        case .square:
            return "square.fill"
        case .triangle:
            return "triangle.fill"
        case .star:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .circle:
            return .blue
        case .square:
            return .green
        case .triangle:
            return .orange
        case .star:
            return .purple
        }
    }
}

// MARK: - Shape Views

struct ShapeView: View {
    let shape: ShapeType
    let size: CGFloat
    let isHighlighted: Bool
    
    var body: some View {
        Image(systemName: shape.systemImage)
            .font(.system(size: size))
            .foregroundColor(isHighlighted ? .yellow : shape.color)
            .scaleEffect(isHighlighted ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

struct ShapeButton: View {
    let shape: ShapeType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: shape.systemImage)
                .font(.system(size: 80))
                .foregroundColor(shape.color)
                .frame(width: 100, height: 100)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

