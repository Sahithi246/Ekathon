//
//  MedicalRecordsAnalysisService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData

/// Service for analyzing medical records and extracting cognitive risk factors
class MedicalRecordsAnalysisService {
    
    // MARK: - Cognitive Risk Medications
    /// Medications known to affect cognitive function
    private static let cognitiveRiskMedications: [String: Double] = [
        // Anticholinergics (high risk)
        "diphenhydramine": -30,
        "benztropine": -25,
        "scopolamine": -20,
        "oxybutynin": -15,
        
        // Benzodiazepines
        "lorazepam": -20,
        "diazepam": -20,
        "alprazolam": -18,
        "clonazepam": -15,
        
        // Antidepressants (some)
        "amitriptyline": -10,
        "imipramine": -10,
        
        // Antipsychotics
        "haloperidol": -25,
        "chlorpromazine": -20,
        
        // Antiepileptics (some)
        "phenobarbital": -15,
        "topiramate": -10,
        
        // Opioids (chronic use)
        "morphine": -15,
        "oxycodone": -12,
        "fentanyl": -15,
        
        // Corticosteroids (long-term)
        "prednisone": -10,
        "dexamethasone": -10,
    ]
    
    // MARK: - Cognitive Risk Lab Values
    /// Lab values that indicate cognitive risk when abnormal
    private static let cognitiveRiskLabValues: [String: (lowRisk: Double?, highRisk: Double?, impact: Double)] = [
        "vitamin b12": (lowRisk: 200, highRisk: nil, impact: -25),
        "vitamin d": (lowRisk: 20, highRisk: nil, impact: -20),
        "tsh": (lowRisk: nil, highRisk: 5.0, impact: -15),
        "free t4": (lowRisk: 0.8, highRisk: nil, impact: -15),
        "hemoglobin": (lowRisk: 12, highRisk: nil, impact: -20),
        "hba1c": (lowRisk: nil, highRisk: 7.0, impact: -15),
        "glucose": (lowRisk: nil, highRisk: 140, impact: -10),
        "creatinine": (lowRisk: nil, highRisk: 1.5, impact: -15),
    ]
    
    // MARK: - Chronic Conditions Impact
    private static let chronicConditionImpact: [String: Double] = [
        "diabetes": -15,
        "hypertension": -10,
        "chronic kidney disease": -20,
        "heart failure": -15,
        "stroke": -30,
        "depression": -15,
        "anxiety": -10,
        "sleep apnea": -15,
    ]
    
    // MARK: - Main Analysis Function
    
    /// Analyze medical records and calculate cognitive risk score
    /// This would typically fetch records from Eka Care SDK and analyze them
    static func analyzeMedicalRecords(
        abhaID: String,
        modelContext: ModelContext
    ) async throws -> MedicalRecordAnalysis {
        
        // Step 1: Fetch records from Eka Care API
        let records = try await fetchRecordsFromEkaCare(abhaID: abhaID)
        
        // Step 2: Extract cognitive markers from fetched records
        let markers = extractCognitiveMarkers(from: records)
        
        // Step 3: Calculate impacts
        let medicationImpact = calculateMedicationImpact(markers: markers)
        let labValueImpact = calculateLabValueImpact(markers: markers)
        let chronicConditionImpact = calculateChronicConditionImpact(markers: markers)
        
        // Step 4: Calculate overall risk score
        let riskScore = calculateRiskScore(
            medicationImpact: medicationImpact,
            labValueImpact: labValueImpact,
            chronicConditionImpact: chronicConditionImpact
        )
        
        // Step 5: Create analysis result
        let analysis = MedicalRecordAnalysis(
            abhaID: abhaID,
            riskScore: riskScore,
            medicationImpact: medicationImpact,
            labValueImpact: labValueImpact,
            chronicConditionImpact: chronicConditionImpact,
            totalRecordsAnalyzed: records.count,
            lastSyncDate: Date(),
            cognitiveMarkers: markers
        )
        
        // Step 6: Save to database
        modelContext.insert(analysis)
        try? modelContext.save()
        
        return analysis
    }
    
    // MARK: - Eka Care SDK Integration
    
    /// Fetch medical records from Eka Care API
    static func fetchRecordsFromEkaCare(abhaID: String) async throws -> [EkaRecord] {
        // Initialize SDK if needed
        if !EkaCareSDKService.shared.isInitialized {
            try await EkaCareSDKService.shared.initialize(ownerID: abhaID)
        }
        
        // Get access token
        let accessToken = try await EkaCareSDKService.shared.ensureAuthenticated()
        
        // Fetch records from Eka Care API
        // Note: This is a direct API call. Once SDK package is added, use SDK methods instead
        let baseURL = "https://api.eka.care"
        guard let url = URL(string: "\(baseURL)/medical-records/v1/records") else {
            throw NSError(domain: "EkaCare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add query parameters for filtering by ABHA ID
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "owner_id", value: abhaID),
            URLQueryItem(name: "limit", value: "100")
        ]
        
        if let finalURL = components?.url {
            request.url = finalURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "EkaCare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "EkaCare", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMessage)"])
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "EkaCare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        // Extract records from response
        // Adjust based on actual API response structure
        var records: [EkaRecord] = []
        
        if let recordsArray = json["records"] as? [[String: Any]] {
            for recordDict in recordsArray {
                let documentID = recordDict["document_id"] as? String
                let documentDateString = recordDict["document_date"] as? String
                let documentType = recordDict["document_type"] as? Int
                let oid = recordDict["oid"] as? String ?? abhaID
                
                // Parse date
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let documentDate = documentDateString.flatMap { dateFormatter.date(from: $0) }
                
                records.append(EkaRecord(
                    documentID: documentID,
                    documentDate: documentDate,
                    documentType: documentType,
                    oid: oid
                ))
            }
        } else if let recordsArray = json["data"] as? [[String: Any]] {
            // Alternative response structure
            for recordDict in recordsArray {
                let documentID = recordDict["document_id"] as? String
                let documentDateString = recordDict["document_date"] as? String
                let documentType = recordDict["document_type"] as? Int
                let oid = recordDict["oid"] as? String ?? abhaID
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let documentDate = documentDateString.flatMap { dateFormatter.date(from: $0) }
                
                records.append(EkaRecord(
                    documentID: documentID,
                    documentDate: documentDate,
                    documentType: documentType,
                    oid: oid
                ))
            }
        }
        
        print("✅ Fetched \(records.count) medical records from Eka Care")
        return records
    }
    
    // MARK: - Cognitive Marker Extraction
    
    /// Extract cognitive-relevant markers from medical records
    private static func extractCognitiveMarkers(from records: [EkaRecord]) -> [CognitiveMarker] {
        var markers: [CognitiveMarker] = []
        
        // Process each record to extract cognitive markers
        for record in records {
            // Fetch detailed record data including smart report
            // Note: This would typically use Eka Care SDK's getFileDetails method
            // For now, we'll extract what we can from the record metadata
            
            // Extract based on document type
            if let documentType = record.documentType {
                // Document types: 1=Lab Report, 2=Prescription, 3=Discharge Summary, etc.
                switch documentType {
                case 1: // Lab Report
                    // Extract lab values from smart report if available
                    // This would require fetching the full record details
                    break
                case 2: // Prescription
                    // Extract medications - would need to parse prescription text or smart report
                    break
                case 3: // Discharge Summary
                    // Extract diagnoses and conditions
                    break
                default:
                    break
                }
            }
            
            // TODO: Once SDK is integrated, fetch full record details including SmartReport
            // For now, we'll create placeholder markers based on record metadata
            // In production, you'd fetch the full record with:
            // recordsRepo.getFileDetails(record: record) { response in
            //     // Parse SmartReport data
            //     // Extract medications, lab values, conditions
            // }
        }
        
        // For demo purposes, if we have records but no markers extracted,
        // create a sample marker to show the system is working
        if !records.isEmpty && markers.isEmpty {
            // This indicates records were fetched but need SmartReport parsing
            // In production, this would be handled by fetching full record details
            print("ℹ️ \(records.count) records fetched. SmartReport parsing needed for detailed markers.")
        }
        
        return markers
    }
    
    /// Fetch detailed record data including SmartReport
    /// This would be called for each record to get full analysis data
    private static func fetchRecordDetails(record: EkaRecord) async throws -> RecordDetails? {
        // This would use Eka Care SDK's getFileDetails method
        // For now, return nil - will be implemented with SDK
        return nil
    }
    
    // MARK: - Impact Calculations
    
    private static func calculateMedicationImpact(markers: [CognitiveMarker]) -> Double {
        let medicationMarkers = markers.filter { $0.type == .medication }
        let totalImpact = medicationMarkers.reduce(0.0) { $0 + $1.impact }
        
        // Normalize: average impact, capped at -50
        return max(-50, min(0, totalImpact / max(1, Double(medicationMarkers.count))))
    }
    
    private static func calculateLabValueImpact(markers: [CognitiveMarker]) -> Double {
        let labMarkers = markers.filter { $0.type == .labValue }
        let totalImpact = labMarkers.reduce(0.0) { $0 + $1.impact }
        
        // Normalize: average impact, capped at -50
        return max(-50, min(0, totalImpact / max(1, Double(labMarkers.count))))
    }
    
    private static func calculateChronicConditionImpact(markers: [CognitiveMarker]) -> Double {
        let conditionMarkers = markers.filter { $0.type == .chronicCondition }
        let totalImpact = conditionMarkers.reduce(0.0) { $0 + $1.impact }
        
        // Normalize: average impact, capped at -50
        return max(-50, min(0, totalImpact / max(1, Double(conditionMarkers.count))))
    }
    
    private static func calculateRiskScore(
        medicationImpact: Double,
        labValueImpact: Double,
        chronicConditionImpact: Double
    ) -> Double {
        // Convert impacts to risk score (0-100)
        // Negative impacts reduce score
        let baseScore = 50.0
        let adjustedScore = baseScore + 
            (medicationImpact * 0.3) +
            (labValueImpact * 0.4) +
            (chronicConditionImpact * 0.3)
        
        return max(0, min(100, adjustedScore))
    }
    
    // MARK: - Lab Value Analysis
    
    private static func analyzeLabValue(_ labValue: LabValueData) -> Double {
        guard let labName = cognitiveRiskLabValues[labValue.name.lowercased()] else {
            return 0
        }
        
        guard let value = Double(labValue.value ?? "") else {
            return 0
        }
        
        let (lowRisk, highRisk, impact) = labName
        
        // Check if value is outside normal range
        if let low = lowRisk, value < low {
            return impact // Low value = risk
        }
        if let high = highRisk, value > high {
            return impact // High value = risk
        }
        
        return 0 // Normal range
    }
    
    // MARK: - Pattern Detection
    
    /// Detect patterns in medical records that correlate with cognitive decline
    static func detectPatterns(analysis: MedicalRecordAnalysis) -> [RiskFactor] {
        var riskFactors: [RiskFactor] = []
        let markers = analysis.cognitiveMarkers
        
        // Check for medication risks
        let highRiskMedications = markers.filter { 
            $0.type == .medication && $0.impact < -15 
        }
        
        if !highRiskMedications.isEmpty {
            riskFactors.append(RiskFactor(
                name: "Cognitive-Affecting Medications",
                severity: highRiskMedications.count > 2 ? .high : .medium,
                description: "You are taking \(highRiskMedications.count) medication(s) that may affect cognitive function.",
                recommendation: "Discuss with your doctor about potential alternatives or dosage adjustments."
            ))
        }
        
        // Check for vitamin deficiencies
        let lowVitamins = markers.filter {
            $0.type == .labValue && 
            ($0.name.lowercased().contains("vitamin b12") || 
             $0.name.lowercased().contains("vitamin d")) &&
            $0.impact < 0
        }
        
        if !lowVitamins.isEmpty {
            riskFactors.append(RiskFactor(
                name: "Vitamin Deficiency",
                severity: .medium,
                description: "Low vitamin levels detected, which can affect cognitive function.",
                recommendation: "Consider vitamin supplements and discuss with your doctor."
            ))
        }
        
        // Check for chronic conditions
        let chronicConditions = markers.filter { $0.type == .chronicCondition }
        if !chronicConditions.isEmpty {
            riskFactors.append(RiskFactor(
                name: "Chronic Conditions",
                severity: .medium,
                description: "Chronic conditions may impact cognitive health over time.",
                recommendation: "Regular monitoring and management of chronic conditions is important."
            ))
        }
        
        return riskFactors
    }
}

// MARK: - Placeholder Types (Replace with Eka Care SDK types)

/// Placeholder for Eka Care Record type
/// Replace with actual EkaMedicalRecordsCore.Record once SDK is added
struct EkaRecord {
    let documentID: String?
    let documentDate: Date?
    let documentType: Int?
    let oid: String?
}

struct LabValueData {
    let name: String
    let value: String?
    let unit: String?
    let range: String?
}
