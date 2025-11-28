# Using Web Client ID for Android - Complete Guide

Since you're using a **Web Application** OAuth client ID, here's exactly what you need to do to make Google Sign-In work on Android.

## Important: You Still Need an Android Client ID

**You cannot directly use a web client ID for Android.** Google requires separate platform-specific OAuth client IDs. However, you can:

1. ✅ Create an **Android OAuth client ID** in the same Google Cloud project
2. ✅ Use it in your mobile app
3. ✅ Configure your backend to accept tokens from both web and Android clients

## Solution: Create Android Client ID

Even though you have a web client, you **must** create a separate Android client ID for your mobile app. Here's how:

### Step 1: Get Your SHA-1 Fingerprint

This is **REQUIRED** for Android Google Sign-In.

**On Windows (PowerShell)**:
```powershell
cd mobile\android
.\get-sha1.ps1
```

**Or manually**:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** line (looks like: `AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12`)

### Step 2: Create Android OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your **same project** (the one with your web client)
3. Go to **APIs & Services** > **Credentials**
4. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
5. If prompted, configure OAuth consent screen (should already be done)
6. Choose **Application type**: **Android**
7. Fill in:
   - **Name**: `Construction Exam App - Android`
   - **Package name**: `com.constructionexamapp` ⚠️ **Must match exactly!**
   - **SHA-1 certificate fingerprint**: Paste the SHA-1 from Step 1
8. Click **CREATE**

### Step 3: Copy the Android Client ID

After creating, you'll see a dialog with:
- **Client ID**: `xxxxx-xxxxx.apps.googleusercontent.com` ← Copy this!
- **Client Secret**: (not needed for mobile)

### Step 4: Update Mobile App Configuration

Update `mobile/lib/config/app_config.dart`:

```dart
// Replace the web client ID with the Android client ID
static const String googleClientId = 'YOUR_NEW_ANDROID_CLIENT_ID.apps.googleusercontent.com';
```

**Important**: Use the Android client ID, not the web one!

### Step 5: Backend Configuration

Your backend needs to accept tokens from the Android client ID. You have two options:

#### Option A: Use Android Client ID in Backend (Simplest)

Update your backend `.env` file:
```env
GOOGLE_CLIENT_ID=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com
```

This way, both web and mobile use the same Android client ID.

#### Option B: Accept Multiple Client IDs (Advanced)

Keep using web client ID for web, Android client ID for mobile. Update backend to accept both:

```typescript
// In backend/controllers/authController.ts
import { OAuth2Client } from "google-auth-library";

const WEB_CLIENT_ID = process.env.GOOGLE_CLIENT_ID; // Web client ID
const ANDROID_CLIENT_ID = process.env.GOOGLE_ANDROID_CLIENT_ID || WEB_CLIENT_ID;

export const googleSignIn = async (req: Request, res: Response) => {
  try {
    const { idToken } = req.body;
    
    // Try verifying with Android client first, then web client
    let ticket;
    let payload;
    
    // Try Android client ID
    try {
      const androidClient = new OAuth2Client(ANDROID_CLIENT_ID);
      ticket = await androidClient.verifyIdToken({
        idToken,
        audience: ANDROID_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (androidError) {
      // Fallback to web client ID
      const webClient = new OAuth2Client(WEB_CLIENT_ID);
      ticket = await webClient.verifyIdToken({
        idToken,
        audience: WEB_CLIENT_ID,
      });
      payload = ticket.getPayload();
    }
    
    // Rest of your code...
  }
};
```

Add to backend `.env`:
```env
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your-android-client-id.apps.googleusercontent.com
```

## Quick Summary

1. ✅ You **must create** an Android OAuth client ID (can't use web directly)
2. ✅ Get SHA-1 fingerprint from debug keystore
3. ✅ Create Android client ID with package name and SHA-1
4. ✅ Update `app_config.dart` with Android client ID
5. ✅ Update backend to accept Android client ID tokens

## Why This is Necessary

- **Web client IDs** are for web applications (JavaScript origins, redirect URIs)
- **Android client IDs** are for Android apps (package name, SHA-1 fingerprints)
- Google requires platform-specific client IDs for security and proper verification

## Current Configuration

- **Package Name**: `com.constructionexamapp`
- **Web Client ID**: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`
- **Android Client ID**: (Create new one - will be different)

## After Setup

1. Clean and rebuild:
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test Google Sign-In - it should work now!

## Troubleshooting

If you still get "10:" or "DEVELOPER_ERROR":
- ✅ Double-check SHA-1 fingerprint matches exactly
- ✅ Verify package name: `com.constructionexamapp` (case-sensitive)
- ✅ Ensure you're using the Android client ID (not web)
- ✅ Wait a few minutes after adding SHA-1 (Google needs time to propagate)

## Next Steps

1. Run: `mobile\android\get-sha1.ps1` to get your SHA-1
2. Create Android OAuth client ID in Google Cloud Console
3. Update `app_config.dart` with the new Android Client ID
4. Test!

---

**TL;DR**: Create an Android client ID in the same Google Cloud project, add SHA-1 fingerprint, and use that Android client ID in your mobile app. The backend can accept both web and Android tokens.

