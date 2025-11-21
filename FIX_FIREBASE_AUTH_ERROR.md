# Fix Firebase Authentication Error

## Error: `CONFIGURATION_NOT_FOUND`

This error occurs when Firebase Authentication is not properly enabled in your Firebase Console.

## Quick Fix Steps

### Step 1: Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **photo-share-3e273**
3. In the left sidebar, click on **Authentication**
4. If you see "Get started", click it
5. Click on the **Sign-in method** tab

### Step 2: Enable Email/Password Authentication

1. In the Sign-in providers list, find **Email/Password**
2. Click on **Email/Password**
3. **Enable** the first toggle (Email/Password)
4. Optionally enable "Email link (passwordless sign-in)" if needed
5. Click **Save**

### Step 3: Verify Configuration

After enabling Email/Password authentication, your Firebase Console should show:
- ✅ Email/Password: Enabled

### Step 4: Test the App

1. Rebuild and run your app:
   ```bash
   flutter run
   ```
2. Try registering a new user again
3. The error should be resolved

## Additional Setup (If Not Done)

### Enable Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click **Create database**
3. Choose **Start in test mode**
4. Select a location (closest to your users)
5. Click **Enable**

### Enable Storage

1. Go to **Storage** in Firebase Console
2. Click **Get started**
3. Start in **test mode**
4. Choose a location
5. Click **Done**

## Security Rules Setup

### Firestore Rules

Go to **Firestore Database** → **Rules** and paste:

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
      allow write: if false; // Only admins can write
    }
  }
}
```

Click **Publish**.

### Storage Rules

Go to **Storage** → **Rules** and paste:

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

Click **Publish**.

## Still Having Issues?

1. **Check Firebase Project**: Make sure you're using the correct Firebase project
2. **Verify google-services.json**: Ensure the package name matches (`com.constructionexamapp`)
3. **Check Internet Connection**: Firebase requires internet connectivity
4. **Rebuild App**: After making changes, rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Expected Behavior After Fix

Once Email/Password authentication is enabled:
- ✅ User registration should work
- ✅ User login should work
- ✅ No more `CONFIGURATION_NOT_FOUND` errors
- ✅ Users can be created in Firebase Authentication console

