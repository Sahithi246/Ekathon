# Eka Care SDK Setup Instructions

## 📦 Step 1: Add Swift Package

1. Open your Xcode project
2. Go to **File → Add Package Dependencies...**
3. Enter the package URL:
   ```
   https://github.com/eka-care/EkaMedicalRecordsCore.git
   ```
4. Select **"Up to Next Major Version"** or **"Branch: main"**
5. Click **Add Package**
6. Select the **EkaMedicalRecordsCore** product and click **Add Package**

## 🔑 Step 2: Get Eka Care Credentials

1. Sign up at [developer.eka.care](https://developer.eka.care)
2. Create a new application
3. Get your **Client ID** and **Client Secret**
4. Store these securely (use environment variables or secure storage)

## 🔐 Step 3: Implement Authentication

You need to authenticate with Eka Care to get tokens:

```swift
// Example authentication flow (implement based on Eka Care Auth SDK)
func authenticateWithEkaCare() async throws -> (authToken: String, refreshToken: String) {
    // Use your Client ID and Secret to get tokens
    // This typically involves OAuth flow or API key authentication
    // Refer to Eka Care documentation for exact implementation
}
```

## 🚀 Step 4: Initialize SDK

Once you have tokens, initialize the SDK in `HackathonAppApp.swift`:

```swift
import EkaMedicalRecordsCore

init() {
    // Get tokens from your auth service
    let (authToken, refreshToken) = try await authenticateWithEkaCare()
    let abhaID = UserDefaults.standard.string(forKey: "abhaID") ?? ""
    
    // Initialize SDK
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.ownerID = abhaID
}
```

## 📝 Step 5: Update MedicalRecordsAnalysisService

Uncomment the SDK integration code in `MedicalRecordsAnalysisService.swift`:

1. Remove the placeholder `EkaRecord` struct
2. Import `EkaMedicalRecordsCore`
3. Uncomment the `fetchRecordsFromEkaCare` function
4. Update `extractCognitiveMarkers` to use real `Record` objects

## ✅ Step 6: Test Integration

1. Enter an ABHA ID in the app
2. Tap "Sync Medical Records"
3. Verify records are fetched and analyzed
4. Check that cognitive markers are extracted correctly

## 🐛 Troubleshooting

### Package Not Found
- Ensure you're using the correct GitHub URL
- Check your internet connection
- Try cleaning build folder (Cmd+Shift+K)

### Authentication Errors
- Verify your Client ID and Secret are correct
- Check token expiration
- Ensure ABHA ID is valid

### No Records Found
- Verify ABHA ID is linked to Eka Care account
- Check if patient has medical records in the system
- Ensure proper permissions/consent

## 📚 Additional Resources

- [Eka Care Developer Documentation](https://developer.eka.care)
- [EkaMedicalRecordsCore GitHub](https://github.com/eka-care/EkaMedicalRecordsCore)
- [ABHA Integration Guide](https://developer.eka.care/abdm-connect)
