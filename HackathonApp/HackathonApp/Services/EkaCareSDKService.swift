//
//  EkaCareSDKService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation

/// Service for initializing and managing Eka Care SDK
class EkaCareSDKService {
    
    static let shared = EkaCareSDKService()
    
    private let authService = EkaCareAuthService.shared
    private var ownerID: String?
    private var isSDKInitialized = false
    
    private init() {}
    
    /// Initialize Eka Care SDK with ABHA ID
    /// This will authenticate and set up the SDK
    /// 
    /// - Parameters:
    ///   - ownerID: ABHA ID of the patient
    ///   - filterID: Optional filter ID for filtering records
    func initialize(ownerID: String, filterID: String? = nil) async throws {
        // Step 1: Authenticate to get tokens
        let tokens = try await authService.authenticate()
        
        // Step 2: Initialize SDK (once package is added, uncomment this)
        /*
        #if canImport(EkaMedicalRecordsCore)
        import EkaMedicalRecordsCore
        
        CoreInitConfigurations.shared.authToken = tokens.accessToken
        CoreInitConfigurations.shared.refreshToken = tokens.refreshToken
        CoreInitConfigurations.shared.ownerID = ownerID
        
        if let filterID = filterID {
            CoreInitConfigurations.shared.filterID = filterID
        }
        
        isSDKInitialized = true
        print("✅ Eka Care SDK initialized successfully for ABHA: \(ownerID)")
        #else
        print("⚠️ EkaMedicalRecordsCore package not found. Add it via Swift Package Manager.")
        #endif
        */
        
        // For now, store ownerID for API calls
        self.ownerID = ownerID
        isSDKInitialized = true
        
        print("✅ Eka Care service initialized successfully for ABHA: \(ownerID)")
        print("⚠️ Note: Add EkaMedicalRecordsCore package for full SDK functionality")
    }
    
    /// Check if SDK is initialized
    var isInitialized: Bool {
        return isSDKInitialized && ownerID != nil
    }
    
    /// Get current owner ID
    var currentOwnerID: String? {
        return ownerID
    }
    
    /// Ensure authenticated and return access token
    func ensureAuthenticated() async throws -> String {
        return try await authService.getAccessToken()
    }
}
