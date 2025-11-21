# Notifications Setup Guide

This app now includes Firebase Cloud Messaging (FCM) for push notifications and local notifications.

## Features

✅ **Push Notifications**: Receive notifications from Firebase Cloud Messaging
✅ **Local Notifications**: Show notifications when app is in foreground
✅ **Milestone Notifications**: Automatic notifications at 25%, 50%, 70% (pass), and 100% completion
✅ **Topic Subscriptions**: Subscribe to topics for targeted notifications
✅ **Background Handling**: Notifications work even when app is closed

## Setup Instructions

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **Cloud Messaging**
4. Enable **Cloud Messaging API (Legacy)** if not already enabled
5. Copy the **Server Key** (you'll need this to send notifications from backend)

### 2. Android Configuration

The Android configuration is already set up:
- ✅ Permissions added to `AndroidManifest.xml`
- ✅ Notification channel configured
- ✅ Firebase Messaging service registered

### 3. Testing Notifications

#### Test from Firebase Console:
1. Go to Firebase Console > **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification title and text
4. Click **Send test message**
5. Enter the FCM token (check app logs for `FCM Token:`)

#### Test Local Notification:
The app automatically shows notifications when users reach milestones:
- 25% completion
- 50% completion  
- 70% completion (Pass)
- 100% completion

### 4. Get FCM Token

The FCM token is automatically logged when the app starts. Check your debug console for:
```
FCM Token: [your-token-here]
```

You can also access it programmatically:
```dart
final token = NotificationService().fcmToken;
```

### 5. Send Notifications from Backend

Use the FCM Server Key to send notifications. Example using curl:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Exam Reminder",
      "body": "Don't forget to practice today!"
    },
    "data": {
      "screen": "home"
    }
  }'
```

### 6. Topic Subscriptions

Subscribe users to topics for broadcast notifications:

```dart
// Subscribe to exam updates
await NotificationService().subscribeToTopic('exam_updates');

// Unsubscribe
await NotificationService().unsubscribeFromTopic('exam_updates');
```

### 7. Custom Notification Handling

The notification service handles:
- **Foreground messages**: Shows local notification when app is open
- **Background messages**: Handles when app is in background
- **Terminated app**: Handles when app is closed
- **Notification taps**: Navigates to appropriate screen

## Notification Types

### 1. Progress Milestones
Automatically triggered when users reach:
- 25% completion
- 50% completion
- 70% completion (Pass status)
- 100% completion

### 2. Push Notifications
Sent from Firebase Console or backend server

### 3. Local Notifications
Programmatically triggered notifications

## Troubleshooting

### Notifications not working?
1. Check if permissions are granted (Android 13+)
2. Verify Firebase configuration is correct
3. Check FCM token is generated (check logs)
4. Ensure Cloud Messaging API is enabled in Firebase Console

### Background notifications not showing?
- Make sure the app has notification permissions
- Check that the notification channel is created
- Verify Firebase Messaging service is registered in AndroidManifest.xml

### Token not generated?
- Check Firebase initialization is complete
- Verify internet connection
- Check Firebase project configuration

## Code Examples

### Show Custom Notification
```dart
await NotificationService().showLocalNotification(
  title: 'Custom Title',
  body: 'Custom message body',
  payload: 'custom_data',
);
```

### Subscribe to Topic
```dart
await NotificationService().subscribeToTopic('construction_updates');
```

### Handle Notification Tap
The notification service automatically handles taps. You can customize navigation in `_onNotificationTapped` method in `notification_service.dart`.

## Next Steps

1. Set up Firebase Cloud Messaging in Firebase Console
2. Test notifications using Firebase Console
3. Integrate with your backend to send targeted notifications
4. Customize notification handling based on your needs

