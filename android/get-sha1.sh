#!/bin/bash

# Shell script to get SHA-1 fingerprint for Android Google Sign-In
# This script helps you get the SHA-1 fingerprint needed for Google Cloud Console configuration

echo "========================================"
echo "Android SHA-1 Fingerprint Generator"
echo "========================================"
echo ""

# Check if Java keytool is available
if ! command -v keytool &> /dev/null; then
    echo "ERROR: Java keytool is not installed or not in PATH"
    echo "Please install Java JDK and add it to your PATH"
    exit 1
fi

echo "Java keytool found"
echo ""

# Default debug keystore location
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

echo "Getting SHA-1 fingerprint for DEBUG keystore..."
echo ""

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "Debug keystore found at: $DEBUG_KEYSTORE"
    echo ""
    
    # Get SHA-1 fingerprint
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>&1 | grep -A 1 "SHA1:" | head -n 1
    
    echo ""
    echo "Copy the SHA-1 fingerprint above and add it to Google Cloud Console:"
    echo "1. Go to: https://console.cloud.google.com/apis/credentials"
    echo "2. Select your OAuth 2.0 Client ID (Android)"
    echo "3. Add this SHA-1 to the 'SHA-1 certificate fingerprint' field"
else
    echo "ERROR: Debug keystore not found at: $DEBUG_KEYSTORE"
    echo ""
    echo "The debug keystore will be created automatically when you:"
    echo "1. Build and run your Flutter app in debug mode"
    echo "2. Or create it manually using:"
    echo "   keytool -genkey -v -keystore $DEBUG_KEYSTORE -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000"
fi

echo ""
echo "========================================"
echo "For Release Build:"
echo "========================================"
echo "If you have a release keystore, run:"
echo "keytool -list -v -keystore <path-to-your-release-key.keystore> -alias <your-key-alias>"
echo ""

