/// Application configuration
/// Centralized configuration for API endpoints and URLs
class AppConfig {
  // Backend API base URL
  static const String backendBaseUrl = 'http://10.145.60.161:5000';
  static const String apiBaseUrl = '$backendBaseUrl/api';
  
  // Socket.IO server URL (same as backend base URL)
  static const String socketUrl = backendBaseUrl;
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
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

