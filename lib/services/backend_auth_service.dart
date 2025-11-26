import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart' show ApiService, ApiException;

class BackendAuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'userToken');
    return token != null && token.isNotEmpty;
  }
  
  // Register new user
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
        return {
          'success': true,
          'user': response['data']['user'],
          'token': response['data']['token'],
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
  
  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'userToken');
  }
}

