import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSessionValid = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isSessionValid => _isSessionValid;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to auth state changes FIRST (Firebase Auth persists automatically)
    // This stream will emit the current user if Firebase Auth has restored the session
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData(firebaseUser.uid);
        // Save session with rememberMe = true for persistent auth
        await _sessionService.saveSession(firebaseUser.uid, rememberMe: true);
        _isSessionValid = true;
        notifyListeners();
      } else {
        _user = null;
        _isSessionValid = false;
        await _sessionService.clearSession();
        notifyListeners();
      }
    });
    
    // Wait for Firebase Auth to restore session from local storage
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Check for existing session after Firebase Auth has had time to restore
    await _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // First check if Firebase Auth has restored the user (most reliable)
      final user = _authService.currentUser;
      if (user != null) {
        await loadUserData(user.uid);
        await _sessionService.saveSession(user.uid, rememberMe: true);
        await _sessionService.refreshSession();
        _isSessionValid = true;
        notifyListeners();
        return;
      }
      
      // If Firebase Auth hasn't restored, check SharedPreferences
      final hasSession = await _sessionService.hasValidSession();
      if (hasSession) {
        final savedUserId = await _sessionService.getSession();
        if (savedUserId != null) {
          // Wait a bit more for Firebase Auth to restore
          await Future.delayed(const Duration(milliseconds: 500));
          final userRetry = _authService.currentUser;
          if (userRetry != null && userRetry.uid == savedUserId) {
            await loadUserData(userRetry.uid);
            await _sessionService.refreshSession();
            _isSessionValid = true;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Session check failed, user needs to login
      _isSessionValid = false;
    }
  }

  Future<void> loadUserData(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.getUserData(uid);
      if (_user != null) {
        // Ensure session is saved whenever we load user data
        await _sessionService.saveSession(uid, rememberMe: true);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    bool rememberMe = true, // Default to true for persistent auth
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      if (_user != null) {
        // Save session after registration
        await _sessionService.saveSession(_user!.uid, rememberMe: rememberMe);
        _isSessionValid = true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isSessionValid = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true, // Default to true for persistent auth
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.login(
        email: email,
        password: password,
      );

      if (_user != null) {
        // Save session
        await _sessionService.saveSession(_user!.uid, rememberMe: rememberMe);
        _isSessionValid = true;
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isSessionValid = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _sessionService.clearSession();
    _user = null;
    _isSessionValid = false;
    notifyListeners();
  }

  // Refresh session (call periodically to keep session alive)
  Future<void> refreshSession() async {
    if (_user != null) {
      await _sessionService.refreshSession();
    }
  }

  // Check and restore session on app start
  Future<bool> restoreSession() async {
    try {
      // First check if we have a saved session
      final userId = await _sessionService.getSession();
      if (userId == null) {
        return false;
      }

      // Wait a bit for Firebase Auth to restore session
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check if Firebase Auth has restored the user
      final user = _authService.currentUser;
      if (user != null && user.uid == userId) {
        // User is authenticated in Firebase - load their data
        await loadUserData(user.uid);
        await _sessionService.refreshSession();
        _isSessionValid = true;
        notifyListeners();
        return true;
      } else {
        // Session exists but Firebase user is null - might need to wait more
        // Try one more time after a longer delay
        await Future.delayed(const Duration(milliseconds: 500));
        final userRetry = _authService.currentUser;
        if (userRetry != null && userRetry.uid == userId) {
          await loadUserData(userRetry.uid);
          await _sessionService.refreshSession();
          _isSessionValid = true;
          notifyListeners();
          return true;
        }
        // Session exists but Firebase user is null - clear invalid session
        await _sessionService.clearSession();
        _isSessionValid = false;
        return false;
      }
    } catch (e) {
      // Error restoring session - clear it
      await _sessionService.clearSession();
      _isSessionValid = false;
      return false;
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.updateUserData(updatedUser);
      _user = updatedUser;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

