# Google Sign-In Setup Guide for Mobile App

This guide will help you configure Google Sign-In for both Android and iOS platforms.

## Prerequisites

1. A Google Cloud Platform project with the OAuth consent screen configured
2. OAuth 2.0 credentials created for your app
3. Package name: `com.constructionexamapp`

## Step 1: Get Your SHA-1 Certificate Fingerprint (Android)

The SHA-1 fingerprint is required for Android Google Sign-In. You need to get the SHA-1 from your debug and release keystores.

### Get Debug SHA-1 Fingerprint

On **Windows**:
```powershell
cd android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

On **macOS/Linux**:
```bash
cd android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Get Release SHA-1 Fingerprint

If you have a release keystore:
```bash
keytool -list -v -keystore android/app/your-release-key.keystore -alias your-key-alias
```

**Important**: Copy the SHA-1 fingerprint (it looks like: `AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12`)

## Step 2: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**

### For Android:
1. Application type: **Android**
2. Name: `Construction Exam App - Android`
3. Package name: `com.constructionexamapp`
4. SHA-1 certificate fingerprint: Paste your SHA-1 (from Step 1)
5. Click **Create**

### For iOS:
1. Application type: **iOS**
2. Name: `Construction Exam App - iOS`
3. Bundle ID: `com.example.constructionExamApp` (check your iOS Info.plist)
4. Click **Create**

### For Web (if not already created):
1. Application type: **Web application**
2. Name: `Construction Exam App - Web`
3. Authorized JavaScript origins: Add your backend URL (e.g., `http://10.145.60.161:5000`)
4. Authorized redirect URIs: Add your backend callback URL
5. Click **Create**

**Note**: You can use the same Web client ID for mobile if it's configured properly, but separate Android/iOS client IDs are recommended for better security.

## Step 3: Update Your App Configuration

### Android

1. Copy the **Client ID** (not the Client Secret) from your Android OAuth credential
2. Update `mobile/lib/config/app_config.dart`:
   ```dart
   static const String googleClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
   ```

### iOS

1. Copy the **Client ID** from your iOS OAuth credential
2. The iOS configuration is already set in `Info.plist` with the reversed client ID
3. If you're using a different client ID, update `mobile/lib/config/app_config.dart` and `mobile/ios/Runner/Info.plist`

## Step 4: Verify Configuration

### Android Manifest
- ✅ Package name matches: `com.constructionexamapp`
- ✅ Internet permission is set

### iOS Info.plist
- ✅ Bundle identifier: `com.example.constructionExamApp`
- ✅ URL scheme is configured with reversed client ID

## Step 5: Testing

1. **Clean and rebuild**:
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Google Sign-In**:
   - Tap "Continue with Google" button
   - Sign in with a Google account
   - Verify authentication works

## Troubleshooting

### Error: "10:" or "DEVELOPER_ERROR"

This usually means:
- SHA-1 fingerprint is not configured in Google Cloud Console
- Package name mismatch
- Client ID is incorrect

**Solution**:
1. Double-check your SHA-1 fingerprint in Google Cloud Console
2. Verify package name matches exactly: `com.constructionexamapp`
3. Ensure you're using the Android client ID, not the web client ID

### Error: "Sign in with Google temporarily disabled"

This means the OAuth consent screen needs approval or there's a configuration issue.

**Solution**:
1. Check OAuth consent screen status in Google Cloud Console
2. Ensure all required scopes are configured
3. Verify the app is in "Testing" mode or "Published" mode

### iOS: "The operation couldn't be completed"

**Solution**:
1. Verify the reversed client ID in `Info.plist` matches your iOS client ID
2. Ensure the bundle ID matches exactly
3. Check that the URL scheme is properly formatted

### Token Verification Fails

If the backend fails to verify the token:
- Ensure `GOOGLE_CLIENT_ID` environment variable in backend matches the client ID used in mobile
- For Android, you might need to use the Web client ID in the backend for token verification
- Check backend logs for specific error messages

## Quick Reference

- **Package Name (Android)**: `com.constructionexamapp`
- **Bundle ID (iOS)**: `com.example.constructionExamApp`
- **Current Client ID**: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`
- **Backend URL**: `http://10.145.60.161:5000`

## Additional Notes

1. **For Production**: Create a release keystore and add its SHA-1 to Google Cloud Console
2. **Multiple Environments**: You may want separate client IDs for development, staging, and production
3. **Firebase**: If using Firebase Authentication, configure it separately
4. **Testing**: Use test accounts during development to avoid quota limits

## Support

If you continue to have issues:
1. Check the console logs in your development environment
2. Review Google Cloud Console for any error messages
3. Verify all client IDs are correctly configured
4. Ensure network connectivity to Google's servers

