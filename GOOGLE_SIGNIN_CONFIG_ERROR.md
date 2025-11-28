# Google Sign-In Configuration Error Fix

## Issue
The mobile app is experiencing Google Sign-In configuration errors. This is likely due to:

1. **Client ID Mismatch**: The mobile app uses a different client ID than configured in Google Cloud Console
2. **SHA-1 Not Added**: Android requires SHA-1 fingerprint to be added in Google Cloud Console
3. **iOS URL Scheme**: The reversed client ID in Info.plist must match the client ID being used

## Current Configuration

### Mobile App Client ID
- **Client ID**: `373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com`
- **Reversed Client ID** (for iOS): `com.googleusercontent.apps.373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5`

### Web Client ID
- **Client ID**: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`

## Quick Fix Steps

### Step 1: Verify Client ID in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Check if you have an OAuth 2.0 Client ID with this value:
   - `373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com`
3. If this client ID exists, check:
   - **Android**: Package name = `com.constructionexamapp`, SHA-1 fingerprint added
   - **iOS**: Bundle ID matches your app's bundle ID

### Step 2: Get SHA-1 Fingerprint (Android)

Run this from `mobile/android` directory:
```powershell
.\get-sha1.ps1
```

This will show your SHA-1 fingerprint. Add it to Google Cloud Console:
1. Go to your Android OAuth client ID
2. Click "Edit"
3. Add the SHA-1 fingerprint
4. Save

### Step 3: Update Backend Configuration

Add the mobile client ID to backend `.env`:

```env
# Web Client ID (already configured)
GOOGLE_CLIENT_ID=373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com

# Android Client ID (add this)
GOOGLE_ANDROID_CLIENT_ID=373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com

# iOS Client ID (same as Android if using same client ID)
GOOGLE_IOS_CLIENT_ID=373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com
```

### Step 4: Verify iOS Configuration

The `mobile/ios/Runner/Info.plist` should have:
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5</string>
</array>
```

✅ Already fixed in the codebase!

### Step 5: Rebuild and Test

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

## Alternative: Use Web Client ID for Mobile

If you want to use the same client ID for web and mobile:

1. **Update `mobile/lib/config/app_config.dart`**:
   ```dart
   static const String googleClientId = '373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com';
   ```

2. **Update iOS Info.plist** (already done):
   ```xml
   <string>com.googleusercontent.apps.373625809559-0028ioi1et07vobj231645rd3g7ddeor</string>
   ```

3. **In Google Cloud Console**:
   - Edit the web OAuth client ID
   - Add Android package name: `com.constructionexamapp`
   - Add SHA-1 fingerprint (from `get-sha1.ps1`)
   - Add iOS bundle ID if needed

4. **Rebuild app**:
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

## Common Errors and Solutions

### Error: "10:" or "DEVELOPER_ERROR"
- **Cause**: SHA-1 fingerprint not added to Google Cloud Console
- **Fix**: Run `get-sha1.ps1` and add fingerprint to Android OAuth client

### Error: "Invalid Google ID token" from Backend
- **Cause**: Backend doesn't have mobile client ID configured
- **Fix**: Add `GOOGLE_ANDROID_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` to backend `.env`

### Error: iOS Sign-In Fails Silently
- **Cause**: Reversed client ID in Info.plist doesn't match
- **Fix**: Verify `CFBundleURLSchemes` matches your client ID

### Error: "Sign in with Google temporarily disabled"
- **Cause**: OAuth consent screen not configured
- **Fix**: Go to Google Cloud Console → APIs & Services → OAuth consent screen → Configure

## Testing Checklist

- [ ] SHA-1 fingerprint added to Google Cloud Console
- [ ] Package name matches: `com.constructionexamapp`
- [ ] Client ID in `app_config.dart` matches Google Cloud Console
- [ ] Backend has `GOOGLE_ANDROID_CLIENT_ID` in `.env`
- [ ] iOS Info.plist has correct reversed client ID
- [ ] Backend server restarted after `.env` changes
- [ ] App rebuilt after configuration changes

## Need Help?

1. Check backend logs for Google Sign-In errors
2. Check mobile app logs (look for `[Login]` prefixed messages)
3. Verify all client IDs in Google Cloud Console
4. Test with different Google accounts (some may have restrictions)

