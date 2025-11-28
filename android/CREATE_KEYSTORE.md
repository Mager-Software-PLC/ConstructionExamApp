# Create Debug Keystore for SHA-1 Fingerprint

The debug keystore doesn't exist yet. This is normal for a new project. Here's how to create it:

## Quick Solution

Run this PowerShell command to create the debug keystore:

```powershell
cd mobile\android
keytool -genkey -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

**Note**: Use `$env:USERPROFILE` in PowerShell, not `%USERPROFILE%` (that's CMD syntax).

## After Creating the Keystore

1. Run the SHA-1 script again:
   ```powershell
   .\get-sha1.ps1
   ```

2. It will now show your SHA-1 fingerprint

## Alternative: Let Flutter Create It Automatically

The debug keystore will also be created automatically when you:
1. Build and run your Flutter app: `flutter run`
2. Then come back and run `.\get-sha1.ps1`

## What is the Debug Keystore?

- Used for signing debug builds of your Android app
- Created automatically on first build
- Located at: `C:\Users\YourUsername\.android\debug.keystore`
- Password is always: `android`
- Alias is always: `androiddebugkey`

## Using the Updated Script

The `get-sha1.ps1` script has been updated to:
- Automatically detect if the keystore doesn't exist
- Offer to create it for you
- Handle the creation process automatically

Just run:
```powershell
cd mobile\android
.\get-sha1.ps1
```

It will guide you through creating the keystore if needed.

