import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _sessionKey = 'user_session';
  static const String _sessionTimestampKey = 'session_timestamp';
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'user_email';
  static const String _tokenKey = 'user_token';
  static const int _sessionTimeoutHours = 24 * 30; // 30 days for persistent auth
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Save session with email and ID token for persistence
  Future<void> saveSession(String userId, {bool rememberMe = true, String? email, String? idToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, userId);
      await prefs.setInt(_sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_rememberMeKey, rememberMe);
      
      // Verify session was saved
      final savedUserId = prefs.getString(_sessionKey);
      if (savedUserId != userId) {
        throw Exception('Session save verification failed');
      }
      
      // Store email and ID token securely
      if (email != null) {
        try {
          await _secureStorage.write(key: _emailKey, value: email);
        } catch (e) {
          // If secure storage fails, continue without storing email
          // Session will still work with SharedPreferences
        }
      }
      if (idToken != null) {
        try {
          await _secureStorage.write(key: _tokenKey, value: idToken);
        } catch (e) {
          // If secure storage fails, continue without storing token
          // Session will still work with SharedPreferences
        }
      }
    } catch (e) {
      // If session save fails, throw the exact error
      final errorString = e.toString();
      if (errorString.contains(':')) {
        throw errorString.split(':').last.trim();
      }
      throw errorString;
    }
  }

  // Get saved session
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionKey);
    final timestamp = prefs.getInt(_sessionTimestampKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (userId == null || timestamp == null) {
      return null;
    }

    // Check if session is expired
    // If rememberMe is true, session persists indefinitely (until logout)
    // If rememberMe is false, session expires after timeout
    final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(sessionTime);

    // Only check expiration if rememberMe is false
    if (!rememberMe && difference.inHours > _sessionTimeoutHours) {
      await clearSession();
      return null;
    }

    return userId;
  }

  // Check if session exists and is valid
  Future<bool> hasValidSession() async {
    final userId = await getSession();
    if (userId == null) return false;
    
    // Check if we have a valid token
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  // Get stored email
  Future<String?> getStoredEmail() async {
    try {
      return await _secureStorage.read(key: _emailKey);
    } catch (e) {
      // If secure storage read fails, return null
      return null;
    }
  }
  
  // Get stored token
  Future<String?> getStoredToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      // If secure storage read fails, return null
      return null;
    }
  }

  // Clear session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionTimestampKey);
      await prefs.remove(_rememberMeKey);
      
      // Clear secure storage
      try {
        await _secureStorage.delete(key: _emailKey);
      } catch (e) {
        // Ignore secure storage delete errors
      }
      try {
        await _secureStorage.delete(key: _tokenKey);
      } catch (e) {
        // Ignore secure storage delete errors
      }
    } catch (e) {
      // If clear fails, throw the exact error
      final errorString = e.toString();
      if (errorString.contains(':')) {
        throw errorString.split(':').last.trim();
      }
      throw errorString;
    }
  }

  // Update session timestamp (refresh session)
  Future<void> refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_sessionKey)) {
      await prefs.setInt(_sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // Get remember me preference
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Set remember me preference
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  // Get session age
  Future<Duration?> getSessionAge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_sessionTimestampKey);
    if (timestamp == null) return null;

    final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(sessionTime);
  }
}

