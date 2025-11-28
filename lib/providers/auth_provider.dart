import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('[Auth] Initializing AuthProvider...');
      
      // Check if user is logged in by verifying token exists
      final isLoggedIn = await _authService.isLoggedIn();
      debugPrint('[Auth] Token exists: $isLoggedIn');
      
      if (isLoggedIn) {
        try {
          // Get token to verify it's valid
          final token = await _authService.getToken();
          if (token == null || token.isEmpty) {
            debugPrint('[Auth] ⚠️ Token is null or empty');
            _isSessionValid = false;
            _isInitialized = true;
            if (!_initCompleter.isCompleted) {
              _initCompleter.complete();
            }
            notifyListeners();
            return;
          }
          
          debugPrint('[Auth] Token found, length: ${token.length}');
          
          // Try to load user data from API to verify token is still valid
          // Use timeout to prevent hanging on network issues
          debugPrint('[Auth] Loading user from API...');
          final result = await _authService.getCurrentUser().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[Auth] ⚠️ Timeout loading user - network issue, but token exists');
              return {'success': false, 'message': 'Network timeout'};
            },
          );
          
          if (result['success'] == true && result['user'] != null) {
            _user = User.fromJson(result['user']);
            debugPrint('[Auth] ✅ User loaded successfully: ${_user!.id}');
            
            // Save session for persistence
            await _sessionService.saveSession(
              _user!.id,
              rememberMe: true,
              email: _user!.email,
            );
            await _sessionService.refreshSession();
            _isSessionValid = true;
            debugPrint('[Auth] ✅ Session saved and validated - login will persist');
          } else {
            debugPrint('[Auth] ⚠️ Failed to load user: ${result['message']}');
            // Check if it's a 401 (unauthorized) - only then is token invalid
            final errorMessage = result['message']?.toString() ?? '';
            if (errorMessage.contains('401') || errorMessage.contains('Unauthorized') || errorMessage.contains('Invalid token')) {
              debugPrint('[Auth] ❌ Token is invalid (401), will be cleared');
              _isSessionValid = false;
              // Don't clear token here - let splash screen handle it after confirmation
            } else {
              // Network error or other issue - token might still be valid
              // Set session as potentially valid (will be verified later)
              debugPrint('[Auth] ⚠️ Network/API error, but token exists - assuming valid for now');
              _isSessionValid = true; // Assume valid until proven otherwise
            }
          }
        } catch (e) {
          debugPrint('[Auth] ⚠️ Error loading user: $e');
          final errorStr = e.toString();
          // Only mark as invalid if it's clearly an auth error
          if (errorStr.contains('401') || errorStr.contains('Unauthorized') || errorStr.contains('Invalid token')) {
            debugPrint('[Auth] ❌ Token is invalid based on error');
            _isSessionValid = false;
          } else {
            // Network or other error - assume token is still valid
            debugPrint('[Auth] ⚠️ Network/other error, but token exists - assuming valid');
            _isSessionValid = true; // Assume valid until proven otherwise
          }
        }
      } else {
        debugPrint('[Auth] No token found');
        _isSessionValid = false;
      }
      
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] Initialization error: $e');
      _errorMessage = e.toString();
      _isSessionValid = false;
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
    // Legacy registration - redirects to phone verification flow
    _errorMessage = 'Please use the phone verification flow';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Send registration OTP
  Future<bool> sendRegistrationOTP({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? preferredLanguage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendRegistrationOTP(
        name: name,
        email: email,
        password: password,
        phone: phone,
        preferredLanguage: preferredLanguage,
      );

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
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

  // Verify registration OTP
  Future<bool> verifyRegistrationOTP({
    required String phone,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyRegistrationOTP(
        phone: phone,
        code: code,
      );

      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        debugPrint('[Auth] Registration OTP verified. User parsed: ${_user!.id}, email: ${_user!.email}');

        await Future.delayed(const Duration(milliseconds: 500)); // Give time for token to save

        final hasToken = await _authService.isLoggedIn();
        if (!hasToken) {
          debugPrint('[Auth] ❌ Error: Token not found after registration OTP verification.');
          _errorMessage = 'Failed to save authentication token. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _sessionService.saveSession(
          _user!.id,
          rememberMe: true,
          email: _user!.email,
        );
        await _sessionService.refreshSession();
        _isSessionValid = true;
        _isLoading = false;
        notifyListeners();
        debugPrint('[Auth] ✅ Registration OTP verification complete. User will remain logged in.');
        return true;
      } else {
        _errorMessage = result['message'] ?? 'OTP verification failed';
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

  Future<bool> googleSignIn(String idToken) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.googleSignIn(idToken);

      if (result['success'] == true && result['user'] != null) {
        // Parse user data
        _user = User.fromJson(result['user']);
        debugPrint('[Auth] Google sign-in successful. User parsed: ${_user!.id}, email: ${_user!.email}');
        
        // Wait a bit to ensure token is saved by API service
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify token was saved
        final hasToken = await _authService.isLoggedIn();
        debugPrint('[Auth] Token check after Google sign-in: $hasToken');
        
        if (!hasToken) {
          debugPrint('[Auth] ❌ Error: Token not found after Google sign-in');
          _errorMessage = 'Failed to save authentication token. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Double-check token is actually stored
        final token = await _authService.getToken();
        if (token == null || token.isEmpty) {
          debugPrint('[Auth] ❌ Error: Token verification failed after Google sign-in');
          _errorMessage = 'Failed to save authentication token. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        debugPrint('[Auth] ✅ Google sign-in successful, token verified. User ID: ${_user!.id}, Token length: ${token.length}');
        
        // Save session for persistence
        try {
          await _sessionService.saveSession(
            _user!.id,
            rememberMe: true,
            email: _user!.email,
          );
          await _sessionService.refreshSession();
          debugPrint('[Auth] ✅ Session saved successfully after Google sign-in');
        } catch (e) {
          debugPrint('[Auth] ⚠️ Error saving session after Google sign-in: $e');
        }
        
        _isSessionValid = true;
        _isLoading = false;
        notifyListeners();
        
        debugPrint('[Auth] ✅ Google sign-in complete. User will remain logged in after app restart.');
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Google sign-in failed';
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

      if (result['success'] == true && result['user'] != null) {
        // Parse user data
        _user = User.fromJson(result['user']);
        debugPrint('[Auth] User parsed: ${_user!.id}, email: ${_user!.email}');
        
        // Wait a bit longer to ensure token is saved by API service
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify token was saved (it should be saved in api_service.login)
        final hasToken = await _authService.isLoggedIn();
        debugPrint('[Auth] Token check after login: $hasToken');
        
        if (!hasToken) {
          debugPrint('[Auth] ❌ Error: Token not found after login. Token should have been saved in api_service.login');
          _errorMessage = 'Failed to save authentication token. Please try logging in again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Double-check token is actually stored
        final token = await _authService.getToken();
        if (token == null || token.isEmpty) {
          debugPrint('[Auth] ❌ Error: Token verification failed - token is null or empty');
          _errorMessage = 'Failed to save authentication token. Please try logging in again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        debugPrint('[Auth] ✅ Login successful, token verified. User ID: ${_user!.id}, Token length: ${token.length}');
        
        // Save session for persistence with user data
        try {
          await _sessionService.saveSession(
            _user!.id,
            rememberMe: true,
            email: _user!.email,
          );
          await _sessionService.refreshSession();
          debugPrint('[Auth] ✅ Session saved successfully');
        } catch (e) {
          debugPrint('[Auth] ⚠️ Error saving session: $e');
          // Continue anyway - token is saved which is more important
        }
        
        _isSessionValid = true;
        _isLoading = false;
        notifyListeners();
        
        debugPrint('[Auth] ✅ Login complete. User will remain logged in after app restart.');
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
      debugPrint('[Auth] loadUserFromToken called');
      _isLoading = true;
      notifyListeners();

      // First verify token exists - try multiple times
      bool hasToken = false;
      for (int i = 0; i < 3; i++) {
        hasToken = await _authService.isLoggedIn();
        if (hasToken) {
          debugPrint('[Auth] ✅ Token found on attempt ${i + 1}');
          break;
        }
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      if (!hasToken) {
        debugPrint('[Auth] ❌ No token found for auto-login after retries');
        _user = null;
        _isSessionValid = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get the actual token to verify it's valid
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Auth] Token is null or empty');
        _user = null;
        _isSessionValid = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('[Auth] Token found, length: ${token.length}, attempting to load user...');
      
      // Use timeout to prevent hanging
      final result = await _authService.getCurrentUser().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Auth] Timeout loading user from token');
          return {'success': false, 'message': 'Network timeout'};
        },
      );
      
      if (result['success'] == true && result['user'] != null) {
        _user = User.fromJson(result['user']);
        await _sessionService.saveSession(
          _user!.id,
          rememberMe: true,
          email: _user!.email,
        );
        await _sessionService.refreshSession();
        _isSessionValid = true;
        debugPrint('[Auth] ✅ Auto-login successful for user: ${_user!.id}');
      } else {
        final errorMessage = result['message']?.toString() ?? '';
        debugPrint('[Auth] Auto-login failed: $errorMessage');
        
        // Check if it's an authentication error (401) - token is invalid
        if (errorMessage.contains('401') || 
            errorMessage.contains('Unauthorized') || 
            errorMessage.contains('Invalid token') ||
            errorMessage.contains('Token expired')) {
          debugPrint('[Auth] ❌ Token is invalid - will be cleared');
          _user = null;
          _isSessionValid = false;
          // Clear token - it's invalid
          await _authService.logout();
        } else {
          // Network or other error - don't clear token, might be temporary
          debugPrint('[Auth] ⚠️ Network/API error - token might still be valid');
          // Keep user as null but don't mark session as invalid yet
          _isSessionValid = false;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] Auto-login error: $e');
      final errorStr = e.toString();
      
      // Check if it's an authentication error
      if (errorStr.contains('401') || 
          errorStr.contains('Unauthorized') || 
          errorStr.contains('Invalid token') ||
          errorStr.contains('Token expired')) {
        debugPrint('[Auth] ❌ Token is invalid based on exception');
        _user = null;
        _isSessionValid = false;
        // Clear invalid token
        await _authService.logout();
      } else {
        // Network or other error - don't clear token
        debugPrint('[Auth] ⚠️ Network/other error - token might still be valid');
        _isSessionValid = false;
      }
      
      _errorMessage = errorStr;
      _isLoading = false;
      notifyListeners();
    }
  }
}
