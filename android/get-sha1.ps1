# PowerShell script to get SHA-1 fingerprint for Android Google Sign-In
# This script helps you get the SHA-1 fingerprint needed for Google Cloud Console configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Android SHA-1 Fingerprint Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Java keytool is available
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "Java found: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Java is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Java JDK and add it to your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Getting SHA-1 fingerprint for DEBUG keystore..." -ForegroundColor Yellow
Write-Host ""

# Default debug keystore location on Windows
$debugKeystorePath = "$env:USERPROFILE\.android\debug.keystore"
$androidDir = "$env:USERPROFILE\.android"

# Create .android directory if it doesn't exist
if (-not (Test-Path $androidDir)) {
    New-Item -ItemType Directory -Path $androidDir -Force | Out-Null
    Write-Host "Created .android directory at: $androidDir" -ForegroundColor Yellow
}

if (Test-Path $debugKeystorePath) {
    Write-Host "Debug keystore found at: $debugKeystorePath" -ForegroundColor Green
    Write-Host ""
    
    # Get SHA-1 fingerprint
    $sha1Output = keytool -list -v -keystore $debugKeystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SHA-1 Fingerprint:" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan
        
        # Extract SHA-1 from output
        $sha1Line = $sha1Output | Select-String "SHA1:" | Select-Object -First 1
        if ($sha1Line) {
            $sha1 = ($sha1Line.ToString() -replace ".*SHA1: ", "").Trim()
            Write-Host ""
            Write-Host $sha1 -ForegroundColor Green -BackgroundColor Black
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Next Steps:" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "1. Copy the SHA-1 fingerprint above" -ForegroundColor White
            Write-Host "2. Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor White
            Write-Host "3. Create or edit your Android OAuth 2.0 Client ID" -ForegroundColor White
            Write-Host "4. Add this SHA-1 to the 'SHA-1 certificate fingerprint' field" -ForegroundColor White
            Write-Host "5. Package name must be: com.constructionexamapp" -ForegroundColor White
        } else {
            Write-Host "Could not parse SHA-1 from keytool output" -ForegroundColor Red
            Write-Host "Full output:" -ForegroundColor Yellow
            Write-Host $sha1Output
        }
    } else {
        Write-Host "Error running keytool command" -ForegroundColor Red
        Write-Host "Output: $sha1Output" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Debug keystore not found at: $debugKeystorePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is normal for a new project. The keystore will be created automatically." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Option 1: Create it now (Recommended)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run this command to create the debug keystore:" -ForegroundColor White
    Write-Host ""
    Write-Host "keytool -genkey -v -keystore `"$debugKeystorePath`" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname `"CN=Android Debug,O=Android,C=US`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then run this script again to get the SHA-1." -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Option 2: Let Flutter create it automatically" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The debug keystore will be created when you:" -ForegroundColor White
    Write-Host "1. Build and run your Flutter app: flutter run" -ForegroundColor White
    Write-Host "2. Then come back and run this script again" -ForegroundColor White
    Write-Host ""
    
    # Offer to create it now
    $createNow = Read-Host "Would you like to create the keystore now? (Y/N)"
    if ($createNow -eq "Y" -or $createNow -eq "y") {
        Write-Host ""
        Write-Host "Creating debug keystore..." -ForegroundColor Yellow
        $createCmd = "keytool -genkey -v -keystore `"$debugKeystorePath`" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname `"CN=Android Debug,O=Android,C=US`""
        
        Invoke-Expression $createCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Debug keystore created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Now getting SHA-1 fingerprint..." -ForegroundColor Yellow
            Write-Host ""
            
            # Get SHA-1 after creation
            $sha1Output = keytool -list -v -keystore $debugKeystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $sha1Line = $sha1Output | Select-String "SHA1:" | Select-Object -First 1
                if ($sha1Line) {
                    $sha1 = ($sha1Line.ToString() -replace ".*SHA1: ", "").Trim()
                    Write-Host "SHA-1 Fingerprint:" -ForegroundColor Cyan
                    Write-Host "==================" -ForegroundColor Cyan
                    Write-Host ""
                    Write-Host $sha1 -ForegroundColor Green -BackgroundColor Black
                    Write-Host ""
                    Write-Host "Copy this SHA-1 and add it to Google Cloud Console!" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "❌ Failed to create keystore. Please try manually." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "For Release Build:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "If you have a release keystore, run:" -ForegroundColor Yellow
Write-Host "keytool -list -v -keystore <path-to-your-release-key.keystore> -alias <your-key-alias>" -ForegroundColor Cyan
Write-Host ""

