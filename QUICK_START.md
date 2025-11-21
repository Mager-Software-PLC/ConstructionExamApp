# Quick Start Guide - Firebase Setup

## Fastest Way to Connect Firebase

### Option 1: Using FlutterFire CLI (Recommended)

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Run FlutterFire Configure:**
   ```bash
   flutterfire configure
   ```
   
   This command will:
   - Detect your Firebase projects
   - Let you select/create a project
   - Automatically configure Android and iOS
   - Generate `lib/firebase_options.dart`
   - Add necessary configuration files

4. **That's it!** The app is now configured. Run:
   ```bash
   flutter run
   ```

### Option 2: Manual Setup

If you prefer manual setup, follow the detailed instructions in `FIREBASE_SETUP.md`.

## After Firebase is Connected

### 1. Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/) and enable:

- **Authentication** → Enable Email/Password
- **Firestore Database** → Create database (test mode)
- **Storage** → Get started (test mode)

### 2. Add Sample Questions

In Firestore Console, create a collection named `questions` with documents like:

```json
{
  "text": "What is the standard concrete strength for most construction?",
  "choices": ["15 MPa", "20 MPa", "25 MPa", "30 MPa"],
  "correctIndex": 2
}
```

### 3. Set Security Rules

See `FIREBASE_SETUP.md` for Firestore and Storage security rules.

## Testing

1. Run the app: `flutter run`
2. Select a language on first launch
3. Register a new user
4. Start answering questions
5. Check progress and certificate

## Troubleshooting

- **"FirebaseOptions not found"**: Run `flutterfire configure`
- **"google-services.json not found"**: Download from Firebase Console and place in `android/app/`
- **"GoogleService-Info.plist not found"**: Download from Firebase Console and add to Xcode project
- **Build errors**: Run `flutter clean` then `flutter pub get`

