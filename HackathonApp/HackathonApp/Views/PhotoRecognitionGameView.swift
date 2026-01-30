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
    
    var onComplete: ((PhotoRecognitionResult) -> Void)?
    var hideNavigationBar = false
    
    @State private var currentPhotoIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var responseTimes: [Double] = []
    @State private var currentPhotoStartTime: Date?
    @State private var gameState: PhotoRecognitionGameState = .ready
    @State private var showingPhotoSetup = false
    
    @Query(filter: #Predicate<UserPhoto> { $0.isActive == true }, sort: \UserPhoto.timestamp) private var userPhotos: [UserPhoto]
    
    /// Get photos that have actual image data (not blank)
    private var gamePhotos: [UserPhoto] {
        // Only use photos that have actual image data
        let photosWithImages = userPhotos.filter { $0.imageData != nil && !$0.imageData!.isEmpty }
        return Array(photosWithImages.prefix(5)) // Use up to 5 photos
    }
    
    /// Check if user has any photos with images
    private var hasPhotosWithImages: Bool {
        return !gamePhotos.isEmpty
    }
    
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
        .navigationTitle(hideNavigationBar ? "" : "Photo Recognition")
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
        .sheet(isPresented: $showingPhotoSetup) {
            PhotoSetupView()
                .onDisappear {
                    // When photo setup closes, check if photos were added
                    // SwiftData @Query will automatically update, so we can check after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if hasPhotosWithImages && hideNavigationBar {
                            // Auto-start game if photos are now available in flow mode
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                startGame()
                            }
                        }
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
            
            if hasPhotosWithImages {
                VStack(spacing: 8) {
                    Text("\(gamePhotos.count) photo\(gamePhotos.count == 1 ? "" : "s") ready")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    if userPhotos.count > gamePhotos.count {
                        Text("\(userPhotos.count - gamePhotos.count) photo\(userPhotos.count - gamePhotos.count == 1 ? "" : "s") without images")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("No photos available")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Add photos of people you know to start the recognition test")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Show start button or add photos button
            if hasPhotosWithImages {
                if hideNavigationBar {
                    // Auto-start in flow mode if photos are available
                    Text("Starting test...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .onAppear {
                            // Auto-start after a brief delay in flow mode
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                startGame()
                            }
                        }
                } else {
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
            } else {
                // Show add photos button
                if hideNavigationBar {
                    // In flow mode, use sheet instead of NavigationLink
                    Button(action: {
                        // Show photo setup in a sheet
                        showingPhotoSetup = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photos")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                } else {
                    NavigationLink(destination: PhotoSetupView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photos")
                        }
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
        }
    }
    
    // MARK: - Playing View
    private var playingView: some View {
        VStack(spacing: 24) {
            // Progress
            VStack(spacing: 8) {
                Text("Photo \(currentPhotoIndex + 1) of \(gamePhotos.count)")
                    .font(.system(size: 16, weight: .medium))
                
                ProgressView(value: Double(currentPhotoIndex), total: Double(gamePhotos.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 200)
            }
            .padding(.top)
            
            // Photo
            if currentPhotoIndex < gamePhotos.count {
                let photo = gamePhotos[currentPhotoIndex]
                
                VStack(spacing: 20) {
                    // Photo display - should always have image data at this point
                    if let uiImage = photo.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    } else {
                        // Fallback: This shouldn't happen if gamePhotos is filtered correctly
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Photo not available")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 300)
                    }
                    
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
                ScoreRow(label: "Correct", value: "\(correctCount)/\(gamePhotos.count)", color: .green)
                ScoreRow(label: "Incorrect", value: "\(incorrectCount)", color: .red)
                ScoreRow(label: "Accuracy", value: String(format: "%.0f%%", gamePhotos.isEmpty ? 0 : (Double(correctCount) / Double(gamePhotos.count)) * 100), color: .blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal, 40)
            
            if hideNavigationBar {
                // In flow mode, auto-save after brief delay
                Text("Saving results...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            saveAndDismiss()
                        }
                    }
            } else {
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
    }
    
    // MARK: - Game Logic
    private func startGame() {
        guard hasPhotosWithImages else {
            print("⚠️ Cannot start game: No photos with images available")
            return
        }
        gameState = .playing
        currentPhotoIndex = 0
        correctCount = 0
        incorrectCount = 0
        responseTimes = []
        loadNextPhoto()
    }
    
    private func loadNextPhoto() {
        guard currentPhotoIndex < gamePhotos.count else {
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
        
        let photo = gamePhotos[currentPhotoIndex]
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
            if currentPhotoIndex < gamePhotos.count {
                loadNextPhoto()
            } else {
                gameState = .completed
            }
        }
    }
    
    
    private func saveAndDismiss() {
        // Ensure we have at least some response times (use 0 if empty for demo photos)
        let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        // Ensure we have valid game photos count
        let photosCount = max(1, gamePhotos.count)
        
        let result = PhotoRecognitionResult(
            timestamp: Date(),
            totalPhotos: photosCount,
            correctAnswers: correctCount,
            incorrectAnswers: max(0, photosCount - correctCount),
            averageResponseTime: averageResponseTime,
            individualResponseTimes: responseTimes.isEmpty ? [0.0] : responseTimes
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
                print("Error saving photo recognition result: \(error)")
            }
        }
    }
}

enum PhotoRecognitionGameState {
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
