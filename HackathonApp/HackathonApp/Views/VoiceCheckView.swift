//
//  VoiceCheckView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData
import AVFoundation

struct VoiceCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var recorder = VoiceRecorder()
    @State private var showResults = false
    @State private var voiceMetrics: VoiceMetrics?
    
    private let prompt = "Describe your day yesterday."
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if showResults, let metrics = voiceMetrics {
                    // Results View
                    ScrollView {
                        VStack(spacing: 24) {
                            // Success indicator
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("Analysis Complete")
                                    .font(.system(size: 24, weight: .bold))
                            }
                            .padding(.top, 40)
                            
                            // Metrics Cards
                            VStack(spacing: 16) {
                                MetricCard(
                                    title: "Words Per Minute",
                                    value: "\(Int(metrics.wordsPerMinute))",
                                    icon: "textformat.123",
                                    color: .blue
                                )
                                
                                MetricCard(
                                    title: "Average Pause",
                                    value: String(format: "%.2f s", metrics.averagePauseDuration),
                                    icon: "pause.circle",
                                    color: .orange
                                )
                                
                                MetricCard(
                                    title: "Speech Variability",
                                    value: String(format: "%.2f", metrics.speechVariability),
                                    icon: "waveform",
                                    color: .purple
                                )
                                
                                // Cognitive Score
                                VStack(spacing: 12) {
                                    Text("Voice Cognitive Score")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(Int(metrics.cognitiveScore))")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(metrics.riskLevel.color)
                                    
                                    Text(metrics.riskLevel.label)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(metrics.riskLevel.color)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                            
                            // Transcription preview
                            if let transcription = metrics.transcription, !transcription.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Transcription")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text(transcription)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
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
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                } else {
                    // Recording View
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // Prompt
                        VStack(spacing: 16) {
                            Text("1-Minute Voice Check")
                                .font(.system(size: 28, weight: .bold))
                            
                            Text(prompt)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Waveform visualization
                        if recorder.isRecording {
                            WaveformView(amplitude: recorder.currentAmplitude)
                                .frame(height: 100)
                                .padding(.horizontal, 40)
                        } else {
                            Image(systemName: "waveform")
                                .font(.system(size: 80))
                                .foregroundColor(.blue.opacity(0.3))
                                .frame(height: 100)
                        }
                        
                        // Timer
                        Text(formatTime(recorder.elapsedTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(recorder.isRecording ? .red : .secondary)
                        
                        // Recording button
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(recorder.isRecording ? Color.red : Color.blue)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .disabled(recorder.isProcessing)
                        
                        if recorder.isProcessing {
                            ProgressView()
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Voice Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        recorder.stop()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stop { result in
                analyzeRecording(result: result)
            }
        } else {
            recorder.start()
        }
    }
    
    private func analyzeRecording(result: VoiceRecorder.RecordingResult) {
        let analysisService = VoiceAnalysisService()
        
        // For now, use mock transcription if no real transcription available
        let transcription = result.transcription ?? generateMockTranscription(duration: result.duration)
        
        let metrics = analysisService.analyzeTranscription(
            transcription: transcription,
            audioDuration: result.duration,
            wordTimings: nil
        )
        
        voiceMetrics = metrics
        showResults = true
    }
    
    private func generateMockTranscription(duration: Double) -> String {
        // Generate realistic mock transcription based on duration
        let estimatedWords = Int((140.0 * duration) / 60.0) // ~140 WPM average
        let words = [
            "I", "woke", "up", "yesterday", "morning", "feeling", "pretty", "good",
            "had", "breakfast", "around", "eight", "then", "went", "to", "work",
            "the", "meeting", "was", "productive", "had", "lunch", "with", "colleagues",
            "in", "the", "afternoon", "I", "focused", "on", "my", "project",
            "evening", "I", "relaxed", "at", "home", "watched", "a", "show",
            "read", "a", "book", "and", "went", "to", "bed", "early"
        ]
        
        var transcription = ""
        for i in 0..<min(estimatedWords, 100) {
            if i > 0 {
                transcription += " "
            }
            transcription += words[i % words.count]
        }
        
        return transcription
    }
    
    private func saveAndDismiss() {
        guard let metrics = voiceMetrics else {
            dismiss()
            return
        }
        
        modelContext.insert(metrics)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving voice metrics: \(error)")
        }
        
        dismiss()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct WaveformView: View {
    let amplitude: Double
    
    var body: some View {
        GeometryReader { geometry in
            let barCount = 20
            let barWidth = geometry.size.width / CGFloat(barCount)
            
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: barWidth - 2)
                        .frame(height: geometry.size.height * (0.3 + amplitude * 0.7))
                }
            }
        }
    }
}

extension VoiceMetrics {
    var riskLevel: (label: String, color: Color) {
        let score = cognitiveScore
        if score >= 70 {
            return ("Stable", Color(red: 0.3, green: 0.69, blue: 0.31))
        } else if score >= 40 {
            return ("Monitor", Color(red: 1.0, green: 0.6, blue: 0.0))
        } else {
            return ("At Risk", Color(red: 0.96, green: 0.26, blue: 0.21))
        }
    }
}

#Preview {
    VoiceCheckView()
        .modelContainer(for: VoiceMetrics.self, inMemory: true)
}
