import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  static const String _sessionKey = 'user_session';
  static const String _sessionTimestampKey = 'session_timestamp';
  static const String _rememberMeKey = 'remember_me';
  static const int _sessionTimeoutHours = 24 * 30; // 30 days for persistent auth

  // Save session
  Future<void> saveSession(String userId, {bool rememberMe = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
    await prefs.setInt(_sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_rememberMeKey, rememberMe);
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

    // Verify user still exists in Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null && user.uid == userId;
    } catch (e) {
      return false;
    }
  }

  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionTimestampKey);
    await prefs.remove(_rememberMeKey);
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

