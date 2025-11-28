# Google Sign-In Quick Fix Guide

## Problem
Your mobile app is using a **different Google Client ID** than your web app, causing configuration errors.

## Current Configuration

### Mobile App
- **Client ID**: `373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com`
- **iOS Reversed Client ID**: `com.googleusercontent.apps.373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5` ✅ (Fixed)

### Web App / Backend
- **Client ID**: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`

## Solution Options

### Option 1: Use Same Client ID (Recommended - Simplest)

**Make mobile app use the web client ID:**

1. **Update `mobile/lib/config/app_config.dart`**:
   ```dart
   static const String googleClientId = '373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com';
   ```

2. **Update iOS Info.plist** - The reversed client ID:
   ```xml
   <string>com.googleusercontent.apps.373625809559-0028ioi1et07vobj231645rd3g7ddeor</string>
   ```

3. **In Google Cloud Console**:
   - Go to: https://console.cloud.google.com/apis/credentials
   - Find the OAuth client ID: `373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com`
   - Click "Edit"
   - **For Android**:
     - Application type: Keep as "Web application"
     - Add to "Authorized redirect URIs" (optional, not required for mobile)
   - **Create a NEW Android OAuth client** OR edit existing one:
     - Package name: `com.constructionexamapp`
     - SHA-1 fingerprint: (Run `mobile/android/get-sha1.ps1` to get this)
     - Or add package name + SHA-1 to the existing web client

4. **Rebuild app**:
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

### Option 2: Keep Different Client IDs (More Complex)

**Configure backend to accept both client IDs:**

1. **Add to backend `.env` file**:
   ```env
   # Web Client ID (already configured)
   GOOGLE_CLIENT_ID=373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com

   # Mobile Client ID
   GOOGLE_ANDROID_CLIENT_ID=373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com
   GOOGLE_IOS_CLIENT_ID=373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5.apps.googleusercontent.com
   ```

2. **Restart backend server**

3. **In Google Cloud Console**:
   - Verify the mobile client ID `373625809559-b45eg9dc10dh2d3r0t3godjd01llcue5` exists
   - For Android: Package name = `com.constructionexamapp`, SHA-1 fingerprint added
   - For iOS: Bundle ID matches your app

4. **iOS Info.plist is already correct** (uses mobile client ID)

## Quick Check List

Before testing, verify:

- [ ] Client ID in `mobile/lib/config/app_config.dart` matches your choice
- [ ] iOS `Info.plist` has correct reversed client ID
- [ ] Backend `.env` has the client ID(s) configured
- [ ] Google Cloud Console has the client ID configured
- [ ] **Android**: SHA-1 fingerprint added (run `get-sha1.ps1`)
- [ ] **Android**: Package name matches: `com.constructionexamapp`
- [ ] Backend server restarted after `.env` changes
- [ ] App rebuilt (`flutter clean && flutter pub get && flutter run`)

## Get SHA-1 Fingerprint (Android)

```powershell
cd mobile/android
.\get-sha1.ps1
```

Copy the SHA-1 and add it to Google Cloud Console → Your Android OAuth Client ID

## Most Common Error: "10:" or "DEVELOPER_ERROR"

**This means SHA-1 fingerprint is missing!**

1. Run `get-sha1.ps1`
2. Copy the SHA-1 fingerprint
3. Go to Google Cloud Console
4. Edit your Android OAuth Client ID
5. Add the SHA-1 fingerprint
6. Save
7. Wait 5-10 minutes for changes to propagate
8. Try again

## Need Help?

Check the logs:
- **Mobile**: Look for `[Login]` messages in console
- **Backend**: Look for `[Google Sign-In]` messages in server logs

The backend will log which client ID it used to verify the token.

