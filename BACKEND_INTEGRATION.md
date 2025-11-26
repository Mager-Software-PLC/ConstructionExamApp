# Backend API Integration Guide

This document explains how the mobile app integrates with the backend API.

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure API URL:**
   - Edit `lib/services/api_service.dart`
   - Update `baseUrl` constant:
     ```dart
     static const String baseUrl = 'http://YOUR_IP:5000/api';
     // For Android emulator, use: http://10.0.2.2:5000/api
     // For iOS simulator, use: http://localhost:5000/api
     // For physical device, use your computer's IP: http://192.168.1.X:5000/api
     ```

## Architecture

### Services

- **`api_service.dart`**: Core API service with HTTP client and authentication
- **`backend_auth_service.dart`**: Authentication service using backend API

### Models

- **`api_models.dart`**: Data models matching backend API responses

## Key Features

### Authentication

```dart
final authService = BackendAuthService();

// Register
final result = await authService.register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
  phone: '+1234567890',
);

// Login
final result = await authService.login(
  emailOrPhone: 'john@example.com',
  password: 'password123',
);

// Check if logged in
final isLoggedIn = await authService.isLoggedIn();

// Logout
await authService.logout();
```

### Categories

```dart
final apiService = ApiService();

// Get all categories
final response = await apiService.getCategories();
final categories = (response['data'] as List)
    .map((json) => Category.fromJson(json))
    .toList();
```

### Questions

```dart
// Get questions by category
final response = await apiService.getQuestionsByCategory(
  categoryId,
  page: 1,
  limit: 10,
);
final questions = (response['data']['data'] as List)
    .map((json) => Question.fromJson(json))
    .toList();
```

### Progress

```dart
// Submit answer
await apiService.submitAnswer(
  questionId: questionId,
  selectedOption: selectedOption,
  categoryId: categoryId,
);

// Get user progress
final response = await apiService.getUserProgress();
```

### Messages

```dart
// Get conversations
final response = await apiService.getConversations();

// Send message
await apiService.sendMessage(
  conversationId: conversationId,
  content: 'Hello!',
);
```

## Migration from Firebase

To migrate from Firebase to backend API:

1. Replace `AuthService` with `BackendAuthService`
2. Replace Firestore calls with `ApiService` methods
3. Update models to use `api_models.dart`
4. Update providers to use API services

## Testing

1. Start the backend server:
   ```bash
   cd backend
   npm run dev
   ```

2. Run the mobile app:
   ```bash
   flutter run
   ```

3. Test authentication and API calls

## Error Handling

All API calls return a consistent format:
```dart
{
  'success': true/false,
  'message': 'Error or success message',
  'data': {...}
}
```

Handle errors:
```dart
try {
  final response = await apiService.getCategories();
  if (response['success'] == true) {
    // Handle success
  } else {
    // Handle error
    print(response['message']);
  }
} catch (e) {
  // Handle exception
  print('Error: $e');
}
```

## Next Steps

1. Update existing screens to use `BackendAuthService` and `ApiService`
2. Replace Firebase providers with API-based providers
3. Implement real-time messaging with Socket.IO (if needed)
4. Add offline support with local caching

