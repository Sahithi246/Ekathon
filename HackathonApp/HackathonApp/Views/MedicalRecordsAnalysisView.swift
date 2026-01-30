//
//  MedicalRecordsAnalysisView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import SwiftData

struct MedicalRecordsAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MedicalRecordAnalysis.timestamp, order: .reverse) private var analyses: [MedicalRecordAnalysis]
    
    @State private var isFetching = false
    @State private var errorMessage: String?
    @State private var showingABHASetup = false
    @State private var abhaID: String = ""
    
    var latestAnalysis: MedicalRecordAnalysis? {
        analyses.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Medical Records Analysis")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Analyze your medical records for cognitive risk factors")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // ABHA Setup (if not configured)
                if abhaID.isEmpty {
                    abhaSetupSection
                } else {
                    // Fetch Records Button
                    Button(action: fetchMedicalRecords) {
                        HStack {
                            if isFetching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isFetching ? "Fetching Records..." : "Fetch from ABHA")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(isFetching)
                    
                    // Analysis Results
                    if let analysis = latestAnalysis {
                        analysisResultsSection(analysis: analysis)
                    } else {
                        emptyStateView
                    }
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Medical Records")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingABHASetup) {
            ABHASetupSheet(abhaID: $abhaID)
        }
        .onAppear {
            loadABHAID()
        }
    }
    
    // MARK: - ABHA Setup Section
    
    private var abhaSetupSection: some View {
        VStack(spacing: 16) {
            Text("Connect Your ABHA Account")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Link your Ayushman Bharat Health Account to fetch and analyze your medical records.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingABHASetup = true
            }) {
                Text("Enter ABHA ID")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Analysis Results Section
    
    private func analysisResultsSection(analysis: MedicalRecordAnalysis) -> some View {
        VStack(spacing: 20) {
            // Risk Score Card
            RiskScoreCard(
                score: analysis.riskScore,
                riskLevel: analysis.riskLevel,
                title: "Medical Records Risk Score",
                subtitle: "Based on \(analysis.totalRecordsAnalyzed) records analyzed"
            )
            
            // Cognitive Markers
            if !analysis.cognitiveMarkers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cognitive Markers")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal)
                    
                    ForEach(analysis.cognitiveMarkers.prefix(5)) { marker in
                        MarkerRow(marker: marker)
                    }
                    
                    if analysis.cognitiveMarkers.count > 5 {
                        Text("+ \(analysis.cognitiveMarkers.count - 5) more markers")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Impact Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Impact Breakdown")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal)
                
                ImpactRow(
                    label: "Medications",
                    impact: analysis.medicationImpact,
                    color: .orange
                )
                
                ImpactRow(
                    label: "Lab Values",
                    impact: analysis.labValueImpact,
                    color: .blue
                )
                
                ImpactRow(
                    label: "Chronic Conditions",
                    impact: analysis.chronicConditionImpact,
                    color: .purple
                )
            }
            
            // Risk Factors
            let riskFactors = MedicalRecordsAnalysisService.detectPatterns(analysis: analysis)
            if !riskFactors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Risk Factors Detected")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal)
                    
                    ForEach(riskFactors) { factor in
                        RiskFactorCard(factor: factor)
                    }
                }
            }
            
            // Last Sync Info
            if let lastSync = analysis.lastSyncDate {
                Text("Last synced: \(lastSync, style: .relative)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Medical Records Analyzed")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Tap 'Sync Medical Records' to fetch and analyze your records from ABHA.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func fetchMedicalRecords() {
        guard !abhaID.isEmpty else {
            errorMessage = "Please enter your ABHA ID first"
            return
        }
        
        isFetching = true
        errorMessage = nil
        
        Task {
            do {
                // Initialize SDK if needed
                if !EkaCareSDKService.shared.isInitialized {
                    try await EkaCareSDKService.shared.initialize(ownerID: abhaID)
                }
                
                // Analyze medical records
                let analysis = try await MedicalRecordsAnalysisService.analyzeMedicalRecords(
                    abhaID: abhaID,
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    isFetching = false
                    // Analysis is automatically saved by the service
                    print("✅ Medical records analysis completed successfully")
                }
            } catch {
                await MainActor.run {
                    isFetching = false
                    let errorDesc = error.localizedDescription
                    errorMessage = "Failed to fetch records: \(errorDesc)"
                    print("❌ Error fetching medical records: \(errorDesc)")
                }
            }
        }
    }
    
    private func loadABHAID() {
        // TODO: Load from UserDefaults or secure storage
        // For now, using placeholder
        abhaID = UserDefaults.standard.string(forKey: "abhaID") ?? ""
    }
}

// MARK: - Supporting Views

struct MarkerRow: View {
    let marker: CognitiveMarker
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType(marker.type))
                .foregroundColor(colorForType(marker.type))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(marker.name)
                    .font(.system(size: 15, weight: .medium))
                
                if let value = marker.value {
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 13))
                        if let unit = marker.unit {
                            Text(unit)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if marker.impact < 0 {
                Text("⚠️")
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
        .padding(.horizontal)
    }
    
    private func iconForType(_ type: MarkerType) -> String {
        switch type {
        case .medication:
            return "pills"
        case .labValue:
            return "testtube.2"
        case .chronicCondition:
            return "heart.text.square"
        case .medicalEvent:
            return "calendar.badge.exclamationmark"
        case .vitalSign:
            return "waveform.path.ecg"
        }
    }
    
    private func colorForType(_ type: MarkerType) -> Color {
        switch type {
        case .medication:
            return .orange
        case .labValue:
            return .blue
        case .chronicCondition:
            return .purple
        case .medicalEvent:
            return .red
        case .vitalSign:
            return .green
        }
    }
}

struct ImpactRow: View {
    let label: String
    let impact: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(String(format: "%.1f", impact))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(impact < 0 ? .red : .green)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct RiskFactorCard: View {
    let factor: RiskFactor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(factor.name)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text(severityEmoji(factor.severity))
                    .font(.system(size: 20))
            }
            
            Text(factor.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            if let recommendation = factor.recommendation {
                Text("💡 \(recommendation)")
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor(factor.severity), lineWidth: 2)
        )
        .padding(.horizontal)
    }
    
    private func severityEmoji(_ severity: RiskSeverity) -> String {
        switch severity {
        case .low:
            return "🟢"
        case .medium:
            return "🟡"
        case .high:
            return "🟠"
        case .critical:
            return "🔴"
        }
    }
    
    private func severityColor(_ severity: RiskSeverity) -> Color {
        switch severity {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct ABHASetupSheet: View {
    @Binding var abhaID: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Enter Your ABHA ID")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Your Ayushman Bharat Health Account ID allows us to securely fetch your medical records.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("ABHA ID", text: $abhaID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)
                
                Button(action: {
                    UserDefaults.standard.set(abhaID, forKey: "abhaID")
                    dismiss()
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(abhaID.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(abhaID.isEmpty)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("ABHA Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        MedicalRecordsAnalysisView()
            .modelContainer(for: MedicalRecordAnalysis.self, inMemory: true)
    }
}
