# Google Sign-In Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "10:" or "DEVELOPER_ERROR" on Android

**Symptoms**: Google Sign-In fails immediately with error code 10 or DEVELOPER_ERROR

**Causes**:
- SHA-1 fingerprint not configured in Google Cloud Console
- Package name mismatch
- Wrong OAuth client ID (using web client ID instead of Android client ID)

**Solutions**:

1. **Get your SHA-1 fingerprint**:
   ```powershell
   # Windows PowerShell (run from mobile/android directory)
   .\get-sha1.ps1
   
   # Or manually:
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add SHA-1 to Google Cloud Console**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Find your Android OAuth 2.0 Client ID
   - Add the SHA-1 fingerprint (without colons or with colons, both work)
   - Save changes

3. **Verify package name**:
   - Your package name: `com.constructionexamapp`
   - Must match exactly in Google Cloud Console OAuth client

4. **Use Android OAuth Client ID**:
   - Create a separate Android OAuth client ID in Google Cloud Console
   - Use that client ID in your app (not the web client ID)
   - Or configure your web client ID to support Android by adding SHA-1

### Issue 2: Google Sign-In Works on Web but Not Mobile

**Symptoms**: Sign-in works in web browser but fails in mobile app

**Causes**:
- Different OAuth client IDs needed for web vs mobile
- SHA-1 fingerprint not configured for mobile
- Client ID is web-only configuration

**Solutions**:

1. **Create separate OAuth clients**:
   - Web client ID for web application
   - Android client ID for Android app
   - iOS client ID for iOS app

2. **Or use same client ID** (simpler):
   - Configure the web client ID to support Android/iOS
   - Add Android package name and SHA-1
   - Add iOS bundle ID

3. **Backend verification**:
   - Ensure `GOOGLE_CLIENT_ID` in backend matches the client ID being used
   - The backend verifies tokens, so it needs to accept tokens from all client IDs you're using

### Issue 3: "Invalid Google ID token" from Backend

**Symptoms**: Google Sign-In succeeds in app but backend rejects the token

**Causes**:
- Backend `GOOGLE_CLIENT_ID` doesn't match mobile client ID
- Token audience mismatch
- Token verification failure

**Solutions**:

1. **Check backend environment variable**:
   ```bash
   # In backend, check .env file
   GOOGLE_CLIENT_ID=373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com
   ```

2. **Use same client ID**:
   - Mobile app and backend should use the same Google Client ID
   - Or ensure backend accepts tokens from multiple client IDs (requires code changes)

3. **Verify token audience**:
   - The idToken from mobile must have the correct audience
   - Check backend logs for specific error messages

### Issue 4: "Network Error" or Connection Issues

**Symptoms**: App can't connect to Google Sign-In services

**Causes**:
- No internet connection
- Firewall blocking Google services
- DNS issues

**Solutions**:
1. Check internet connection
2. Try on different network (mobile data vs WiFi)
3. Check if Google services are accessible from your region
4. Verify app has internet permission (AndroidManifest.xml)

### Issue 5: iOS - "The operation couldn't be completed"

**Symptoms**: iOS Google Sign-In fails silently

**Causes**:
- Reversed client ID incorrect in Info.plist
- Bundle ID mismatch
- URL scheme not configured

**Solutions**:

1. **Check Info.plist**:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
           </array>
       </dict>
   </array>
   ```
   - Replace `YOUR-CLIENT-ID` with your actual client ID
   - Format: `com.googleusercontent.apps.373625809559-0028ioi1et07vobj231645rd3g7ddeor`

2. **Verify bundle ID**:
   - Info.plist: `com.example.constructionExamApp`
   - Must match Google Cloud Console iOS client configuration

3. **Rebuild app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Quick Checklist

Before testing Google Sign-In, verify:

- [ ] SHA-1 fingerprint is added to Google Cloud Console (Android)
- [ ] Package name matches: `com.constructionexamapp`
- [ ] OAuth client ID is created for Android/iOS
- [ ] Client ID in `app_config.dart` matches Google Cloud Console
- [ ] Backend `GOOGLE_CLIENT_ID` matches mobile client ID
- [ ] Info.plist has correct reversed client ID (iOS)
- [ ] Bundle ID matches in Info.plist and Google Cloud Console (iOS)
- [ ] App has internet permission (Android)
- [ ] Test with debug keystore first, then release keystore

## Testing Steps

1. **Get SHA-1 fingerprint**:
   ```powershell
   cd mobile/android
   .\get-sha1.ps1
   ```

2. **Configure Google Cloud Console**:
   - Add SHA-1 to Android OAuth client
   - Verify package name

3. **Update app config** (if needed):
   - Verify `mobile/lib/config/app_config.dart` has correct client ID

4. **Test**:
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check logs**:
   - Look for `[Login]` debug messages in console
   - Check for specific error codes or messages

## Still Having Issues?

1. **Check app logs**: Look for `[Login]` prefixed messages
2. **Check backend logs**: Look for Google token verification errors
3. **Verify in Google Cloud Console**: Ensure all configurations are correct
4. **Test with different Google account**: Some accounts may have restrictions
5. **Check OAuth consent screen**: Ensure it's in Testing or Published mode

## Debug Mode

The app now includes detailed debug logging. Look for:
- `[Login] Attempting Google sign-in...`
- `[Login] Google sign-in successful...`
- `[Login] ❌` for errors

Enable verbose logging in your IDE to see all debug messages.

