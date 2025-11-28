# iOS Build Optimization Guide

This document outlines the iOS build optimizations that have been configured to reduce app size and improve build performance.

## Build Optimizations Applied

### 1. Release Configuration Optimizations

The following optimizations have been applied to the Release build configuration in `ios/Runner.xcodeproj/project.pbxproj`:

#### Project-Level Release Settings:
- **DEAD_CODE_STRIPPING = YES**: Removes unused code and dead code paths
- **COPY_PHASE_STRIP = YES**: Strips symbols during the copy phase
- **STRIP_INSTALLED_PRODUCT = YES**: Strips symbols from the final product
- **STRIP_STYLE = "non-global"**: Strips non-global symbols (reduces binary size)
- **GCC_OPTIMIZATION_LEVEL = s**: Optimizes for size instead of speed
- **SWIFT_OPTIMIZATION_LEVEL = "-Osize"**: Swift compiler optimization for size
- **SWIFT_COMPILATION_MODE = wholemodule**: Enables whole module optimization for better Swift performance

#### Target-Level Release Settings:
- **DEAD_CODE_STRIPPING = YES**: Removes unused code
- **STRIP_INSTALLED_PRODUCT = YES**: Strips symbols from installed product
- **STRIP_STYLE = "non-global"**: Strips non-global symbols
- **SWIFT_OPTIMIZATION_LEVEL = "-Osize"**: Swift optimization for size
- **SWIFT_COMPILATION_MODE = wholemodule**: Whole module optimization

### 2. Profile Configuration Optimizations

The Profile configuration (used for performance profiling) also includes the same optimizations as Release to ensure consistent build sizes during testing.

## Building the iOS App

### Prerequisites

1. **macOS**: iOS development requires macOS with Xcode installed
2. **Xcode**: Install Xcode from the App Store (latest version recommended)
3. **CocoaPods**: Install CocoaPods if not already installed:
   ```bash
   sudo gem install cocoapods
   ```

### Build Steps

1. **Install Flutter dependencies**:
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Install iOS dependencies** (CocoaPods):
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Clean previous builds**:
   ```bash
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```

4. **Build for Release** (optimized):
   ```bash
   flutter build ios --release
   ```

5. **Build IPA for distribution**:
   ```bash
   flutter build ipa --release
   ```

### Building in Xcode

1. Open the workspace (not the project):
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the **Release** scheme from the scheme selector

3. Select your target device or "Any iOS Device"

4. Go to **Product > Archive** to create an archive

5. After archiving, the Organizer window will open where you can:
   - Validate the app
   - Distribute to App Store
   - Export for Ad Hoc, Enterprise, or Development distribution

## Expected Results

With these optimizations enabled:

- **Reduced binary size**: Dead code stripping and symbol stripping significantly reduce app size
- **Faster runtime**: Whole module optimization improves Swift compilation and runtime performance
- **Smaller downloads**: Optimized for size reduces download times for users
- **Better App Store approval**: Smaller apps are more likely to pass App Store review

## Additional Optimization Tips

### 1. Asset Optimization

- Use Vector Graphics (PDF) where possible for icons and images
- Compress PNG images using tools like `pngcrush` or `ImageOptim`
- Use Asset Catalog for all images and icons
- Consider using WebP format for large images (requires additional setup)

### 2. Code Optimization

- Remove unused dependencies from `pubspec.yaml`
- Use tree shaking to eliminate unused code
- Minimize third-party dependencies
- Use native iOS APIs where possible instead of Flutter plugins

### 3. Build Settings Verification

To verify the optimizations are applied:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** project in the navigator
3. Select the **Runner** target
4. Go to **Build Settings** tab
5. Search for:
   - `DEAD_CODE_STRIPPING` (should be YES for Release)
   - `SWIFT_OPTIMIZATION_LEVEL` (should be `-Osize` for Release)
   - `STRIP_STYLE` (should be `non-global` for Release)

## Troubleshooting

### Build Fails After Optimization Changes

If the build fails after applying optimizations:

1. Clean the build folder: **Product > Clean Build Folder** (Shift + Cmd + K)
2. Delete Derived Data:
   - Xcode > Preferences > Locations
   - Click the arrow next to Derived Data path
   - Delete the folder
3. Reinstall pods:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   ```

### App Size Still Large

If the app size is still larger than expected:

1. Check Flutter build mode:
   ```bash
   flutter build ios --release --split-debug-info=build/debug-info
   ```

2. Analyze the app bundle:
   - Archive the app in Xcode
   - Distribute to App Store
   - Use App Store Connect to see detailed size breakdown

3. Review large assets and dependencies

### Symbol Stripping Issues

If you encounter issues with symbol stripping (e.g., crash reports lack symbols):

1. Keep `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"` (already set)
2. Archive creates a `.dSYM` file for symbolication
3. Upload `.dSYM` files to crash reporting services (e.g., Firebase Crashlytics)

## Notes

- **Bitcode**: Disabled (`ENABLE_BITCODE = NO`) as it's deprecated in Xcode 14+
- **Debug Info**: Kept as `dwarf-with-dsym` for crash symbolication
- **Optimization Level**: Set to size (`-Osize`) to minimize binary size
- **Profile builds**: Use same optimizations as Release for accurate performance testing

## References

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [App Store Submission Guidelines](https://developer.apple.com/app-store/review/guidelines/)

