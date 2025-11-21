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
    // Check for existing session
    await _checkSession();

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData(firebaseUser.uid);
        // Save session
        await _sessionService.saveSession(firebaseUser.uid);
        _isSessionValid = true;
      } else {
        _user = null;
        _isSessionValid = false;
        await _sessionService.clearSession();
        notifyListeners();
      }
    });
  }

  Future<void> _checkSession() async {
    try {
      final hasSession = await _sessionService.hasValidSession();
      if (hasSession) {
        final user = _authService.currentUser;
        if (user != null) {
          await loadUserData(user.uid);
          await _sessionService.refreshSession();
          _isSessionValid = true;
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
    bool rememberMe = true,
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
    bool rememberMe = true,
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
      final hasSession = await _sessionService.hasValidSession();
      if (hasSession) {
        final user = _authService.currentUser;
        if (user != null) {
          await loadUserData(user.uid);
          await _sessionService.refreshSession();
          _isSessionValid = true;
          return true;
        }
      }
      return false;
    } catch (e) {
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

