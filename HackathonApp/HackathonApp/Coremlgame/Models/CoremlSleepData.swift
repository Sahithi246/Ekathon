//
//  CoremlSleepData.swift
//  Coremlgame
//

import Foundation
import SwiftData

/// Coremlgame sleep model — renamed to avoid conflict with main app's SleepData
@Model
final class CoremlSleepData {
    var date: Date
    var totalSleepHours: Double
    var sleepQuality: Double // 0-100 scale
    
    init(date: Date, totalSleepHours: Double, sleepQuality: Double = 70.0) {
        self.date = date
        self.totalSleepHours = totalSleepHours
        self.sleepQuality = sleepQuality
    }
}
