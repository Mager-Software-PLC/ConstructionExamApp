/// Application configuration
/// Centralized configuration for API endpoints and URLs
class AppConfig {
  // Backend API base URL
  static const String backendBaseUrl = 'http://192.168.100.254:5000';
  static const String apiBaseUrl = '$backendBaseUrl/api';
  
  // Socket.IO server URL (same as backend base URL)
  static const String socketUrl = backendBaseUrl;
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Google OAuth Client ID
  // Using web client ID for consistency with backend
  static const String googleClientId = '373625809559-0028ioi1et07vobj231645rd3g7ddeor.apps.googleusercontent.com';
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String categoriesEndpoint = '/categories';
  static const String questionsEndpoint = '/questions';
  static const String progressEndpoint = '/progress';
  static const String messagesEndpoint = '/messages';
  static const String materialsEndpoint = '/materials';
  static const String certificatesEndpoint = '/certificates';
}

