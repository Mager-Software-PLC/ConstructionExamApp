# Using Web OAuth Client ID for Android - Setup Guide

Since you're using a **Web Application** OAuth client ID in Google Cloud Console, here's how to make it work for Android.

## Option 1: Add Android Configuration to Existing Web Client (Recommended)

You can add Android configuration to your existing web client ID so it works for both web and Android.

### Step 1: Get Your SHA-1 Fingerprint

Run this PowerShell command from `mobile/android` directory:

```powershell
cd mobile\android
.\get-sha1.ps1
```

Or manually:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** fingerprint (looks like: `AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12`)

### Step 2: Create Android OAuth Client ID

Even though you have a web client, you need to create a **separate Android OAuth client ID** that uses the same project:

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project
3. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
4. Choose **Application type**: **Android**
5. Fill in:
   - **Name**: `Construction Exam App - Android`
   - **Package name**: `com.constructionexamapp` (must match exactly)
   - **SHA-1 certificate fingerprint**: Paste the SHA-1 from Step 1
6. Click **CREATE**

### Step 3: Update Your App Configuration

You have two choices:

#### Choice A: Use the Android Client ID (Recommended)

This is the proper way - each platform has its own client ID:

1. Copy the **Android Client ID** (not the web one)
2. Update `mobile/lib/config/app_config.dart`:
   ```dart
   static const String googleClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
   ```

#### Choice B: Use the Web Client ID (Alternative)

If you want to use the same web client ID, you need to configure it differently. However, **this is not recommended** as Google recommends separate client IDs for each platform.

## Option 2: Use Same Client ID for Web and Android (Not Recommended)

If you absolutely want to use the same web client ID for Android:

### Limitations:
- You still need to create an Android OAuth client ID
- The web client ID won't automatically work for Android
- Google requires platform-specific client IDs for mobile apps

### Why This Doesn't Work Simply:
- Android apps need the SHA-1 fingerprint and package name configured
- Web clients don't have these fields
- Google Sign-In SDK expects Android-specific configuration

## Recommended Solution: Use Separate Client IDs

Create separate OAuth client IDs for each platform:

1. **Web Client ID**: Keep for your web application
2. **Android Client ID**: Create new one with SHA-1 fingerprint
3. **iOS Client ID**: Create new one with bundle ID (if needed)

Then:
- Use Android Client ID in mobile app
- Use Web Client ID in web app
- Backend can accept tokens from both (if configured correctly)

## Step-by-Step: Creating Android Client ID

1. **Get SHA-1**:
   ```powershell
   cd mobile\android
   .\get-sha1.ps1
   ```

2. **Create Android OAuth Client**:
   - Google Cloud Console > APIs & Services > Credentials
   - Create OAuth client ID > Android
   - Package: `com.constructionexamapp`
   - SHA-1: (from step 1)

3. **Update App Config**:
   - Copy the new Android Client ID
   - Update `mobile/lib/config/app_config.dart`

4. **Backend Configuration**:
   - Your backend `GOOGLE_CLIENT_ID` should accept tokens from the Android client
   - If backend uses the web client ID, you may need to update it to accept Android tokens too
   - Or configure backend to accept multiple client IDs

## Backend Configuration

Your backend currently uses:
```typescript
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
```

To accept tokens from both web and Android clients, you have options:

### Option A: Use Android Client ID in Backend (Simplest)

Update backend `.env`:
```env
GOOGLE_CLIENT_ID=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com
```

Then both mobile and web should use the same Android client ID.

### Option B: Accept Multiple Client IDs (Advanced)

Modify backend to accept tokens from multiple client IDs:

```typescript
// In authController.ts
const WEB_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const ANDROID_CLIENT_ID = process.env.GOOGLE_ANDROID_CLIENT_ID || WEB_CLIENT_ID;

// Try verifying with Android client first, then web client
let ticket;
try {
  ticket = await googleClient.verifyIdToken({
    idToken,
    audience: ANDROID_CLIENT_ID,
  });
} catch (error) {
  // Fallback to web client
  ticket = await googleClient.verifyIdToken({
    idToken,
    audience: WEB_CLIENT_ID,
  });
}
```

## Quick Setup Summary

1. ✅ Create Android OAuth Client ID in Google Cloud Console
2. ✅ Add SHA-1 fingerprint and package name
3. ✅ Copy Android Client ID
4. ✅ Update `mobile/lib/config/app_config.dart` with Android Client ID
5. ✅ Update backend `.env` to use Android Client ID (or configure to accept both)
6. ✅ Test Google Sign-In in mobile app

## Current Configuration

- **Package Name**: `com.constructionexamapp`
- **Web Client ID**: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`
- **Android Client ID**: (Create new one with SHA-1)

## Testing

After setup:
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

Look for debug messages:
- `[Login] Attempting Google sign-in...`
- `[Login] ✅ Google ID token obtained...`

## Important Notes

1. **You cannot directly use a web client ID for Android** - Google requires separate Android client IDs with SHA-1 fingerprints
2. **SHA-1 is required** - Without it, you'll get "10:" or "DEVELOPER_ERROR"
3. **Package name must match exactly** - Case-sensitive: `com.constructionexamapp`
4. **Release builds need separate SHA-1** - Get SHA-1 from your release keystore for production

## Next Steps

1. Run the SHA-1 script: `mobile\android\get-sha1.ps1`
2. Create Android OAuth Client ID in Google Cloud Console
3. Update `app_config.dart` with the new Android Client ID
4. Test!

