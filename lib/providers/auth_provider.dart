import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_auth_service.dart';
import '../services/session_service.dart';
import '../models/api_models.dart';

class AuthProvider with ChangeNotifier {
  final BackendAuthService _authService = BackendAuthService();
  final SessionService _sessionService = SessionService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSessionValid = false;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isSessionValid => _isSessionValid;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  // Wait for initialization to complete
  Future<void> waitForInitialization() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
  }

  Future<void> _init() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Load user data from API
        final result = await _authService.getCurrentUser();
        if (result['success'] == true && result['user'] != null) {
          _user = User.fromJson(result['user']);
          await _sessionService.saveSession(
            _user!.id,
            rememberMe: true,
            email: _user!.email,
          );
          await _sessionService.refreshSession();
          _isSessionValid = true;
        }
      }
      
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<void> loadUserFromSession(String sessionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.getCurrentUser();
      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        _isSessionValid = true;
      } else {
        _user = null;
        _isSessionValid = false;
        await _sessionService.clearSession();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _user = null;
      _isSessionValid = false;
      await _sessionService.clearSession();
      notifyListeners();
    }
  }

  Future<void> loadUserData(String userId) async {
    // Load user data from API using current user endpoint
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.getCurrentUser();
      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        _isSessionValid = true;
      } else {
        _user = null;
        _isSessionValid = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _user = null;
      _isSessionValid = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        await _sessionService.saveSession(
          _user!.id,
          rememberMe: true,
          email: _user!.email,
        );
        _isSessionValid = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        
        // Small delay to ensure token is saved
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify token was saved (it should be saved in api_service.login)
        final hasToken = await _authService.isLoggedIn();
        if (!hasToken) {
          print('[Auth] Error: Token not found after login. Token should have been saved in api_service.login');
          _errorMessage = 'Failed to save authentication token. Please try logging in again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        print('[Auth] Login successful, token verified. User ID: ${_user!.id}');
        
        await _sessionService.saveSession(
          _user!.id,
          rememberMe: true,
          email: _user!.email,
        );
        await _sessionService.refreshSession();
        _isSessionValid = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.logout();
      await _sessionService.clearSession();
      
      _user = null;
      _isSessionValid = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final result = await _authService.getCurrentUser();
        if (result['success'] == true && result['user'] != null) {
          _user = User.fromJson(result['user']);
          _isSessionValid = true;
        } else {
          _isSessionValid = false;
        }
      } else {
        _isSessionValid = false;
      }
      notifyListeners();
    } catch (e) {
      _isSessionValid = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to set user from token (for auto-login)
  Future<void> loadUserFromToken() async {
    try {
      _isLoading = true;
      notifyListeners();

      // First verify token exists
      final hasToken = await _authService.isLoggedIn();
      if (!hasToken) {
        print('[Auth] No token found for auto-login');
        _user = null;
        _isSessionValid = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _authService.getCurrentUser();
      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        await _sessionService.saveSession(
          _user!.id,
          rememberMe: true,
          email: _user!.email,
        );
        _isSessionValid = true;
        print('[Auth] Auto-login successful for user: ${_user!.id}');
      } else {
        print('[Auth] Auto-login failed: ${result['message']}');
        _user = null;
        _isSessionValid = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[Auth] Auto-login error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      _user = null;
      _isSessionValid = false;
      notifyListeners();
    }
  }
}
