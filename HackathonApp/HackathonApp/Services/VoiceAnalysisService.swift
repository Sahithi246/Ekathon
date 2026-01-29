//
//  VoiceAnalysisService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import AVFoundation

/// Service for analyzing voice recordings and extracting cognitive metrics
class VoiceAnalysisService {
    
    /// Analyze audio file and extract speech metrics
    /// - Parameter audioURL: URL to the recorded audio file
    /// - Returns: VoiceMetrics object with extracted metrics
    func analyzeAudio(audioURL: URL) async throws -> VoiceMetrics {
        // For Phase 1, this is a placeholder
        // In Phase 2, this will:
        // 1. Transcribe audio (using Speech framework or mock)
        // 2. Extract timing data
        // 3. Calculate WPM, pauses, variability
        
        // Mock implementation for now
        return generateMockMetrics()
    }
    
    /// Analyze transcription text and audio timing
    /// - Parameters:
    ///   - transcription: Transcribed text
    ///   - audioDuration: Duration of audio in seconds
    ///   - wordTimings: Optional array of word timestamps
    /// - Returns: VoiceMetrics object
    func analyzeTranscription(
        transcription: String,
        audioDuration: Double,
        wordTimings: [Double]? = nil
    ) -> VoiceMetrics {
        let words = transcription.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let totalWords = words.count
        let wordsPerMinute = (Double(totalWords) / audioDuration) * 60.0
        
        // Calculate pause metrics
        let (averagePause, variability) = calculatePauseMetrics(
            wordTimings: wordTimings,
            audioDuration: audioDuration,
            wordCount: totalWords
        )
        
        return VoiceMetrics(
            timestamp: Date(),
            wordsPerMinute: wordsPerMinute,
            averagePauseDuration: averagePause,
            speechVariability: variability,
            totalWords: totalWords,
            recordingDuration: audioDuration,
            transcription: transcription
        )
    }
    
    /// Calculate pause metrics from word timings
    private func calculatePauseMetrics(
        wordTimings: [Double]?,
        audioDuration: Double,
        wordCount: Int
    ) -> (averagePause: Double, variability: Double) {
        guard let timings = wordTimings, timings.count > 1 else {
            // Estimate if no timings available
            let estimatedPause = audioDuration / Double(wordCount)
            return (estimatedPause, 0.2) // Default variability
        }
        
        // Calculate pauses between words
        var pauses: [Double] = []
        for i in 1..<timings.count {
            let pause = timings[i] - timings[i-1]
            pauses.append(pause)
        }
        
        let averagePause = pauses.reduce(0, +) / Double(pauses.count)
        
        // Calculate variability (coefficient of variation)
        let variance = pauses.map { pow($0 - averagePause, 2) }.reduce(0, +) / Double(pauses.count)
        let stdDev = sqrt(variance)
        let variability = averagePause > 0 ? stdDev / averagePause : 0.0
        
        return (averagePause, variability)
    }
    
    /// Generate mock metrics for demo/testing
    func generateMockMetrics() -> VoiceMetrics {
        // Generate realistic mock data
        let wpm = Double.random(in: 100...180)
        let pauseDuration = Double.random(in: 0.2...1.0)
        let variability = Double.random(in: 0.1...0.4)
        let duration = Double.random(in: 45...75) // 45-75 seconds
        let wordCount = Int((wpm * duration) / 60.0)
        
        return VoiceMetrics(
            timestamp: Date(),
            wordsPerMinute: wpm,
            averagePauseDuration: pauseDuration,
            speechVariability: variability,
            totalWords: wordCount,
            recordingDuration: duration,
            transcription: generateMockTranscription(wordCount: wordCount)
        )
    }
    
    /// Generate mock transcription text
    private func generateMockTranscription(wordCount: Int) -> String {
        let words = [
            "I", "woke", "up", "yesterday", "morning", "feeling", "pretty", "good",
            "had", "breakfast", "around", "eight", "then", "went", "work",
            "meeting", "was", "productive", "lunch", "with", "colleagues",
            "afternoon", "focused", "project", "evening", "relaxed", "home",
            "watched", "show", "read", "book", "went", "bed", "early"
        ]
        
        var transcription = ""
        for i in 0..<wordCount {
            if i > 0 {
                transcription += " "
            }
            transcription += words[i % words.count]
        }
        
        return transcription
    }
}
