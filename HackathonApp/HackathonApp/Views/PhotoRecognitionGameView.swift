//
//  PhotoRecognitionGameView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct PhotoRecognitionGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPhotoIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var responseTimes: [Double] = []
    @State private var currentPhotoStartTime: Date?
    @State private var gameState: GameState = .ready
    
    private let photos: [PhotoQuestion] = PhotoRecognitionGameData.photos
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            switch gameState {
            case .ready:
                readyView
            case .playing:
                playingView
            case .completed:
                completedView
            }
        }
        .navigationTitle("Photo Recognition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Ready View
    private var readyView: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Photo Recognition Test")
                .font(.system(size: 28, weight: .bold))
            
            Text("You'll see photos of people. Enter the name of each person you recognize.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("\(photos.count) photos")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
            
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
    
    // MARK: - Playing View
    private var playingView: some View {
        VStack(spacing: 24) {
            // Progress
            VStack(spacing: 8) {
                Text("Photo \(currentPhotoIndex + 1) of \(photos.count)")
                    .font(.system(size: 16, weight: .medium))
                
                ProgressView(value: Double(currentPhotoIndex), total: Double(photos.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 200)
            }
            .padding(.top)
            
            // Photo
            if currentPhotoIndex < photos.count {
                let photo = photos[currentPhotoIndex]
                
                VStack(spacing: 20) {
                    // Photo display
                    // Try to load from assets, fallback to placeholder
                    Group {
                        if let imageURL = photo.imageURL {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                photoPlaceholder(photo: photo)
                            }
                        } else {
                            // Try local asset first, then placeholder
                            if UIImage(named: photo.imageName) != nil {
                                Image(photo.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                photoPlaceholder(photo: photo)
                            }
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    
                    // Answer input
                    VStack(spacing: 12) {
                        Text("Who is this person?")
                            .font(.system(size: 18, weight: .semibold))
                        
                        TextField("Enter name", text: $userAnswer)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 18))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .onSubmit {
                                checkAnswer()
                            }
                        
                        Button(action: checkAnswer) {
                            Text("Submit")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Test Complete!")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 16) {
                ScoreRow(label: "Correct", value: "\(correctCount)/\(photos.count)", color: .green)
                ScoreRow(label: "Incorrect", value: "\(incorrectCount)", color: .red)
                ScoreRow(label: "Accuracy", value: String(format: "%.0f%%", (Double(correctCount) / Double(photos.count)) * 100), color: .blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
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
    
    // MARK: - Game Logic
    private func startGame() {
        gameState = .playing
        currentPhotoIndex = 0
        correctCount = 0
        incorrectCount = 0
        responseTimes = []
        loadNextPhoto()
    }
    
    private func loadNextPhoto() {
        guard currentPhotoIndex < photos.count else {
            gameState = .completed
            return
        }
        userAnswer = ""
        currentPhotoStartTime = Date()
    }
    
    private func checkAnswer() {
        guard let startTime = currentPhotoStartTime else { return }
        
        let responseTime = Date().timeIntervalSince(startTime)
        responseTimes.append(responseTime)
        
        let photo = photos[currentPhotoIndex]
        let userAnswerLower = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let correctAnswerLower = photo.correctName.lowercased()
        
        // Check if answer matches (allowing for minor variations)
        let isCorrectAnswer = userAnswerLower == correctAnswerLower ||
                             userAnswerLower.contains(correctAnswerLower) ||
                             correctAnswerLower.contains(userAnswerLower)
        
        if isCorrectAnswer {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        
        // Show brief feedback
        withAnimation {
            showResult = true
            isCorrect = isCorrectAnswer
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showResult = false
            }
            currentPhotoIndex += 1
            if currentPhotoIndex < photos.count {
                loadNextPhoto()
            } else {
                gameState = .completed
            }
        }
    }
    
    @ViewBuilder
    private func photoPlaceholder(photo: PhotoQuestion) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Photo \(currentPhotoIndex + 1)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            )
    }
    
    private func saveAndDismiss() {
        guard !responseTimes.isEmpty else {
            dismiss()
            return
        }
        
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        let result = PhotoRecognitionResult(
            timestamp: Date(),
            totalPhotos: photos.count,
            correctAnswers: correctCount,
            incorrectAnswers: incorrectCount,
            averageResponseTime: averageResponseTime,
            individualResponseTimes: responseTimes
        )
        
        modelContext.insert(result)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving photo recognition result: \(error)")
        }
        
        dismiss()
    }
}

enum GameState {
    case ready
    case playing
    case completed
}

struct ScoreRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationView {
        PhotoRecognitionGameView()
    }
    .modelContainer(for: PhotoRecognitionResult.self, inMemory: true)
}
