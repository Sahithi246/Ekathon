//
//  CoremlPhotoRecognitionResult.swift
//  Coremlgame
//

import Foundation
import SwiftData

/// Coremlgame photo recognition model — renamed to avoid conflict with main app's PhotoRecognitionResult
@Model
final class CoremlPhotoRecognitionResult {
    var timestamp: Date
    var accuracy: Double // Percentage
    var averageResponseTime: Double // In seconds
    var totalQuestions: Int
    var correctAnswers: Int
    
    init(timestamp: Date, accuracy: Double, averageResponseTime: Double, totalQuestions: Int, correctAnswers: Int) {
        self.timestamp = timestamp
        self.accuracy = accuracy
        self.averageResponseTime = averageResponseTime
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
    }
}
