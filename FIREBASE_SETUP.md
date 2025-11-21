# Firebase Setup Guide for Construction Exam App

## Prerequisites
- A Firebase account (create one at https://firebase.google.com)
- Flutter SDK installed
- Android Studio / Xcode (for platform-specific setup)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: `Construction Exam App`
4. Follow the setup wizard (disable Google Analytics if not needed)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon (or "Add app")
2. Register your Android app:
   - **Package name**: `com.example.construction_exam_app` (check `android/app/build.gradle.kts` for actual package name)
   - **App nickname**: Construction Exam App (Android)
   - **Debug signing certificate**: Leave blank for now
3. Click "Register app"
4. Download `
`
5. Place it in `android/app/` directory

## Step 3: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (or "Add app")
2. Register your iOS app:
   - **Bundle ID**: `com.example.constructionExamApp` (check `ios/Runner.xcodeproj` for actual bundle ID)
   - **App nickname**: Construction Exam App (iOS)
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/` directory
6. Open `ios/Runner.xcworkspace` in Xcode
7. Right-click `Runner` folder → Add Files to Runner → Select `GoogleService-Info.plist`
8. Make sure "Copy items if needed" is checked

## Step 4: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Step 5: Configure Firebase for Flutter

Run the following command in your project root:

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Let you select the project
- Automatically configure both Android and iOS
- Create `lib/firebase_options.dart`

## Step 6: Update main.dart

The app already has Firebase initialization code, but you need to import the options:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## Step 7: Enable Firebase Services

### Enable Authentication
1. Go to Firebase Console → Authentication
2. Click "Get started"
3. Enable "Email/Password" provider
4. Click "Save"

### Enable Firestore Database
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Enable"

### Enable Storage
1. Go to Firebase Console → Storage
2. Click "Get started"
3. Start in test mode
4. Choose a location
5. Click "Done"

## Step 8: Set Up Firestore Security Rules

Go to Firestore Database → Rules and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User answers subcollection
      match /answers/{answerId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Questions are readable by authenticated users
    match /questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write (set up admin rules separately)
    }
  }
}
```

## Step 9: Set Up Storage Security Rules

Go to Storage → Rules and update:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 10: Add Sample Questions to Firestore

1. Go to Firestore Database → Data
2. Click "Start collection"
3. Collection ID: `questions`
4. Add documents with the following structure:

```json
{
  "text": "What is the minimum required concrete strength for most construction projects?",
  "choices": [
    "15 MPa",
    "20 MPa",
    "25 MPa",
    "30 MPa"
  ],
  "correctIndex": 2
}
```

Add more questions as needed.

## Step 11: Update Android Configuration

### Update `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### Update `android/app/build.gradle.kts`:
Add at the bottom:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

## Step 12: Update iOS Configuration

### Update `ios/Podfile`:
Make sure you have:
```ruby
platform :ios, '12.0'
```

Then run:
```bash
cd ios
pod install
cd ..
```

## Step 13: Test the Connection

Run the app:
```bash
flutter run
```

The app should:
1. Show language selection on first launch
2. Allow user registration/login
3. Connect to Firebase successfully

## Troubleshooting

### Android Issues:
- Make sure `google-services.json` is in `android/app/`
- Check that `minSdkVersion` is at least 21 in `android/app/build.gradle.kts`
- Run `flutter clean` and `flutter pub get`

### iOS Issues:
- Make sure `GoogleService-Info.plist` is added to Xcode project
- Run `pod install` in `ios/` directory
- Check that iOS deployment target is 12.0 or higher

### Firebase Connection Issues:
- Verify Firebase project is active
- Check that all services are enabled
- Ensure internet connection is available
- Check Firebase console for any error messages

## Next Steps

After Firebase is connected:
1. Test user registration
2. Add sample questions to Firestore
3. Test question answering functionality
4. Verify progress tracking works
5. Test certificate generation

