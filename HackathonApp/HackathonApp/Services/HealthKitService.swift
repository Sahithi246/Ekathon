//
//  HealthKitService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import HealthKit

/// Service for fetching sleep data from Apple HealthKit
class HealthKitService {
    
    private let healthStore = HKHealthStore()
    
    /// Request authorization for sleep data
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: Set([sleepType]))
    }
    
    /// Fetch sleep data for the last N days
    /// - Parameter days: Number of days to fetch (default: 7)
    /// - Returns: Array of SleepData objects
    func fetchSleepData(days: Int = 7) async throws -> [SleepData] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Check authorization
        let status = healthStore.authorizationStatus(for: sleepType)
        guard status == .sharingAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        // Create date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        // Create query
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Group by date and calculate total sleep per day
                let sleepData = self.processSleepSamples(samples, days: days)
                continuation.resume(returning: sleepData)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Process HealthKit sleep samples into daily SleepData objects
    private func processSleepSamples(_ samples: [HKCategorySample], days: Int) -> [SleepData] {
        var dailySleep: [Date: (hours: Double, start: Date?, end: Date?)] = [:]
        
        for sample in samples {
            // Only count actual sleep (not in bed)
            guard sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue else {
                continue
            }
            
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: sample.startDate)
            
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0 // Convert to hours
            
            if let existing = dailySleep[dayStart] {
                dailySleep[dayStart] = (
                    hours: existing.hours + duration,
                    start: min(existing.start ?? sample.startDate, sample.startDate),
                    end: max(existing.end ?? sample.endDate, sample.endDate)
                )
            } else {
                dailySleep[dayStart] = (
                    hours: duration,
                    start: sample.startDate,
                    end: sample.endDate
                )
            }
        }
        
        // Convert to SleepData models
        var sleepDataArray: [SleepData] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                let dayStart = calendar.startOfDay(for: date)
                
                if let sleep = dailySleep[dayStart] {
                    sleepDataArray.append(SleepData(
                        date: dayStart,
                        totalSleepHours: sleep.hours,
                        sleepStart: sleep.start,
                        sleepEnd: sleep.end
                    ))
                } else {
                    // No data for this day
                    sleepDataArray.append(SleepData(
                        date: dayStart,
                        totalSleepHours: 0
                    ))
                }
            }
        }
        
        return sleepDataArray.sorted { $0.date > $1.date }
    }
    
    /// Check if HealthKit is available and authorized
    func isAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let status = healthStore.authorizationStatus(for: sleepType)
        return status == .sharingAuthorized
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization is required"
        }
    }
}
