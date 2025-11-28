import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart' show ApiService, ApiException;

class BackendAuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Check if user is logged in with retry logic
  Future<bool> isLoggedIn() async {
    try {
      // Try multiple times to handle potential race conditions
      for (int i = 0; i < 3; i++) {
        final token = await _storage.read(key: 'userToken');
        if (token != null && token.isNotEmpty) {
          debugPrint('[BackendAuth] ✅ isLoggedIn: Token found, length: ${token.length}');
          return true;
        }
        
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
      
      debugPrint('[BackendAuth] ❌ isLoggedIn: No token found after retries');
      return false;
    } catch (e) {
      debugPrint('[BackendAuth] ❌ Error checking token: $e');
      return false;
    }
  }
  
  // Register new user (legacy - kept for backward compatibility)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      
      if (response['success'] == true) {
        // Registration might not include token if email verification is required
        return {
          'success': true,
          'user': response['user'] ?? response['data']?['user'],
          'token': response['token'] ?? response['data']?['token'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Send registration OTP
  Future<Map<String, dynamic>> sendRegistrationOTP({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? preferredLanguage,
  }) async {
    try {
      final response = await _apiService.sendRegistrationOTP(
        name: name,
        email: email,
        password: password,
        phone: phone,
        preferredLanguage: preferredLanguage,
      );
      
      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      String errorMessage = 'Failed to send OTP. Please try again.';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Verify registration OTP
  Future<Map<String, dynamic>> verifyRegistrationOTP({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _apiService.verifyRegistrationOTP(
        phone: phone,
        code: code,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'user': response['data']['user'],
          'token': response['data']['token'],
          'refreshToken': response['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      String errorMessage = 'OTP verification failed. Please try again.';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'user': response['data']['user'],
          'token': response['data']['token'],
          'refreshToken': response['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      // Extract error message from ApiException if available
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
        // Clean up common error messages
        if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
          errorMessage = 'Unable to connect to server. Please check your internet connection.';
        } else if (errorMessage.contains('TimeoutException')) {
          errorMessage = 'Connection timeout. Please try again.';
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
  
  // Send OTP
  Future<Map<String, dynamic>> sendOTP(String emailOrPhone) async {
    try {
      final response = await _apiService.sendOTP(emailOrPhone);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String emailOrPhone,
    required String otp,
  }) async {
    try {
      final response = await _apiService.verifyOTP(
        emailOrPhone: emailOrPhone,
        otp: otp,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response['success'] == true) {
        return {
          'success': true,
          'user': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to get user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
  }
  
  // Get stored token with retry logic
  Future<String?> getToken() async {
    try {
      // Try multiple times to handle potential race conditions
      for (int i = 0; i < 3; i++) {
        final token = await _storage.read(key: 'userToken');
        if (token != null && token.isNotEmpty) {
          debugPrint('[BackendAuth] ✅ getToken: Token retrieved, length: ${token.length}');
          return token;
        }
        
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
      
      debugPrint('[BackendAuth] ❌ getToken: No token found after retries');
      return null;
    } catch (e) {
      debugPrint('[BackendAuth] ❌ Error getting token: $e');
      return null;
    }
  }
  
  // Google Sign-In
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    try {
      final response = await _apiService.googleSignIn(idToken: idToken);
      
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'user': response['data']['user'],
          'token': response['data']['token'],
          'refreshToken': response['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Google sign-in failed',
        };
      }
    } catch (e) {
      String errorMessage = 'Google sign-in failed. Please try again.';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
        if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
          errorMessage = 'Unable to connect to server. Please check your internet connection.';
        } else if (errorMessage.contains('TimeoutException')) {
          errorMessage = 'Connection timeout. Please try again.';
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
}

