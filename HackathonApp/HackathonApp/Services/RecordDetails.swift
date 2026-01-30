//
//  RecordDetails.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation

/// Detailed record data including SmartReport information
struct RecordDetails {
    let documentID: String?
    let documentDate: Date?
    let documentType: Int?
    let smartReport: SmartReportData?
    let patientName: String?
    let description: String?
}

/// SmartReport data extracted from medical records
struct SmartReportData {
    let verified: [VerifiedData]?
    let unverified: [VerifiedData]?
}

/// Verified data from SmartReport (medications, lab values, etc.)
struct VerifiedData {
    let name: String
    let value: String?
    let unit: String?
    let vitalID: String?
    let ekaID: String?
    let range: String?
    let result: String?
    let displayResult: String?
    let date: Date?
    let type: DataType
    
    enum DataType {
        case medication
        case labValue
        case vitalSign
        case diagnosis
        case unknown
    }
}
