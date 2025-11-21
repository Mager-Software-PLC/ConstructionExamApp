# Build Size Optimization Guide

This document explains the optimizations applied to reduce the APK size.

## Optimizations Applied

### 1. Code Shrinking (R8/ProGuard)
- **Enabled**: `isMinifyEnabled = true` in release builds
- **Resource Shrinking**: `isShrinkResources = true`
- **ProGuard Rules**: Custom rules in `proguard-rules.pro` to keep necessary classes

### 2. APK Splitting by ABI
- **Enabled**: Split APKs by architecture (armeabi-v7a, arm64-v8a, x86_64)
- **Benefit**: Users only download the APK for their device architecture
- **Size Reduction**: ~30-40% smaller per APK

### 3. Resource Optimization
- **Excludes**: Removed unnecessary META-INF files
- **Packaging**: Optimized resource packaging

### 4. Build Commands

#### Build optimized release APK (single architecture):
```bash
flutter build apk --release --target-platform android-arm64
```

#### Build split APKs (all architectures):
```bash
flutter build apk --release --split-per-abi
```

#### Build App Bundle (recommended for Play Store):
```bash
flutter build appbundle --release
```

### 5. Expected Size Reduction

- **Before optimization**: ~50-60 MB
- **After optimization**: ~20-30 MB per architecture
- **With App Bundle**: ~15-20 MB download size (Play Store handles splitting)

### 6. Additional Tips

1. **Remove unused assets**: Review `pubspec.yaml` and remove unused images/fonts
2. **Use vector graphics**: Prefer SVG/vector assets over raster images
3. **Optimize images**: Compress images before adding to assets
4. **Review dependencies**: Remove unused packages

### 7. Verify Build Size

After building, check the APK size:
```bash
# For split APKs
ls -lh build/app/outputs/flutter-apk/app-*-release.apk

# For App Bundle
ls -lh build/app/outputs/bundle/release/app-release.aab
```

## Notification Setup

### Firebase Cloud Messaging (FCM)

1. **Enable FCM in Firebase Console**:
   - Go to Firebase Console > Project Settings > Cloud Messaging
   - Enable Cloud Messaging API

2. **Get Server Key**:
   - Copy the Server Key from Firebase Console
   - Use it to send notifications from your backend

3. **Test Notifications**:
   - Use Firebase Console > Cloud Messaging > Send test message
   - Or use the FCM token from the app logs

### Notification Features

- ✅ Push notifications (foreground & background)
- ✅ Local notifications
- ✅ Topic subscriptions
- ✅ Notification tap handling
- ✅ Custom notification channels

### Usage Example

```dart
// Show local notification
await NotificationService().showLocalNotification(
  title: 'Exam Reminder',
  body: 'Don\'t forget to practice today!',
);

// Subscribe to topic
await NotificationService().subscribeToTopic('exam_updates');
```

