//
//  EkaCareAuthService.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation

/// Service for authenticating with Eka Care API
class EkaCareAuthService {
    
    static let shared = EkaCareAuthService()
    
    // MARK: - API Configuration
    private let baseURL = "https://api.eka.care"
    private let clientID: String
    private let clientSecret: String?
    
    // MARK: - Token Storage
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    
    private init() {
        // The API key provided might be client_id
        // If you have a separate client_secret, add it here
        self.clientID = "eka_2d23a059161b4b6391677ed5"
        self.clientSecret = nil // Add your client_secret here if you have one
    }
    
    /// Authenticate with Eka Care API
    /// This exchanges the API key for access and refresh tokens
    func authenticate() async throws -> (accessToken: String, refreshToken: String) {
        // Check if we have valid cached tokens
        if let token = accessToken,
           let expiry = tokenExpiryDate,
           expiry > Date() {
            return (token, refreshToken ?? "")
        }
        
        // Try to refresh token if we have one
        if let refresh = refreshToken {
            do {
                let tokens = try await refreshAccessToken(refreshToken: refresh)
                return tokens
            } catch {
                // Refresh failed, need to re-authenticate
                print("⚠️ Token refresh failed, re-authenticating...")
            }
        }
        
        // Authenticate using client_id and client_secret
        // Based on Eka Care API documentation: https://developer.eka.care/api-reference/authorization/client-login
        guard let url = URL(string: "\(baseURL)/connect-auth/v1/account/login") else {
            throw EkaCareAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request body - Eka Care requires ConnectId and ConnectSecret
        var body: [String: Any] = [
            "ConnectId": clientID
        ]
        
        // Add ConnectSecret if available
        if let secret = clientSecret {
            body["ConnectSecret"] = secret
        } else {
            // If no ConnectSecret, try using the API key as both
            // Some APIs use the same value for both
            body["ConnectSecret"] = clientID
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Log request for debugging
        print("🔐 Authenticating with Eka Care API...")
        print("📤 Request URL: \(url)")
        print("📤 Client ID: \(clientID)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EkaCareAuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Authentication failed with status \(httpResponse.statusCode)")
            print("❌ Error response: \(errorMessage)")
            
            // Try to parse error details
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("❌ Error details: \(errorJSON)")
            }
            
            throw EkaCareAuthError.authenticationFailed(message: "Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            print("❌ Invalid JSON response: \(responseString)")
            throw EkaCareAuthError.invalidResponse
        }
        
        print("✅ Authentication successful!")
        print("📥 Response: \(json)")
        
        guard let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            print("❌ Missing access_token or refresh_token in response")
            print("📥 Available keys: \(json.keys.joined(separator: ", "))")
            throw EkaCareAuthError.invalidResponse
        }
        
        // Cache tokens
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        // Set expiry (default to 1 hour if not provided)
        if let expiresIn = json["expires_in"] as? Int {
            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            print("⏰ Token expires in \(expiresIn) seconds")
        } else {
            self.tokenExpiryDate = Date().addingTimeInterval(3600) // 1 hour default
            print("⏰ Token expiry not provided, defaulting to 1 hour")
        }
        
        return (accessToken, refreshToken)
    }
    
    /// Refresh access token using refresh token
    private func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/connect-auth/v1/account/refresh") else {
            throw EkaCareAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "refresh_token": refreshToken
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EkaCareAuthError.tokenRefreshFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw EkaCareAuthError.invalidResponse
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        if let expiresIn = json["expires_in"] as? Int {
            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        }
        
        return (accessToken, refreshToken)
    }
    
    /// Get current access token (refreshes if needed)
    func getAccessToken() async throws -> String {
        let tokens = try await authenticate()
        return tokens.accessToken
    }
    
    /// Check if authenticated
    var isAuthenticated: Bool {
        return accessToken != nil && tokenExpiryDate != nil && tokenExpiryDate! > Date()
    }
}

// MARK: - Error Types

enum EkaCareAuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationFailed(message: String)
    case tokenRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid authentication URL"
        case .invalidResponse:
            return "Invalid response from authentication server"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        }
    }
}
