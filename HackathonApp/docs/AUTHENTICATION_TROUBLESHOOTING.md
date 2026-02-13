# Authentication Troubleshooting Guide

## Current Configuration

- **Client ID**: `eka_2d23a059161b4b6391677ed5`
- **Client Secret**: Not set (using Client ID as fallback)

## Common Issues

### Issue: "connectloginrequest connectid" Error

This error indicates that the API is expecting `client_id` in the request body, which we've now implemented.

### If Authentication Still Fails

#### Option 1: You Need a Separate Client Secret

If Eka Care requires both `client_id` and `client_secret`:

1. Get your `client_secret` from:
   - Eka Care Console: https://console.eka.care
   - Or request from your healthcare provider workspace

2. Update `EkaCareAuthService.swift`:
   ```swift
   private init() {
       self.clientID = "eka_2d23a059161b4b6391677ed5"
       self.clientSecret = "your_client_secret_here" // Add your secret
   }
   ```

#### Option 2: API Key Format

The API key might need to be used differently:

1. **As Authorization Header:**
   ```swift
   request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
   ```

2. **As X-API-Key Header:**
   ```swift
   request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
   ```

3. **In Query Parameters:**
   ```swift
   components?.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
   ```

#### Option 3: Different Endpoint

The authentication endpoint might be different:
- `/api/v1/auth/login`
- `/auth/login`
- `/connect/login`

Check Eka Care documentation for the exact endpoint.

## Debug Steps

1. **Check Console Logs:**
   - Look for "🔐 Authenticating with Eka Care API..."
   - Check the error response details
   - Verify the request URL and body

2. **Test with cURL:**
   ```bash
   curl -X POST https://api.eka.care/connect-auth/v1/account/login \
     -H "Content-Type: application/json" \
     -d '{"client_id": "eka_2d23a059161b4b6391677ed5", "client_secret": "your_secret"}'
   ```

3. **Verify API Key:**
   - Confirm the API key is active
   - Check if it has the right permissions
   - Verify it's not expired

## Next Steps

1. Check the console logs when authentication fails
2. Share the exact error message and response
3. Verify if you need a separate `client_secret`
4. Check Eka Care documentation for your specific API key type
