import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Get stored token with retry logic
  Future<String?> _getToken() async {
    try {
      String? token = await _storage.read(key: 'userToken');
      
      // If token is null, try again with a small delay (handles race conditions)
      if (token == null || token.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        token = await _storage.read(key: 'userToken');
      }
      
      if (token != null && token.isNotEmpty) {
        debugPrint('[API] _getToken: Token retrieved successfully, length: ${token.length}');
      } else {
        debugPrint('[API] _getToken: ⚠️ No token found in storage');
      }
      
      return token;
    } catch (e) {
      debugPrint('[API] _getToken: ❌ Error reading token: $e');
      return null;
    }
  }
  
  // Get stored refresh token
  Future<String?> _getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }
  
  // Set token
  Future<void> _setToken(String token) async {
    try {
      // Clean token before saving
      final cleanToken = token.trim();
      if (cleanToken.isEmpty) {
        throw Exception('Cannot save empty token');
      }
      
      debugPrint('[API] Saving token to Flutter Secure Storage, length: ${cleanToken.length}');
      await _storage.write(key: 'userToken', value: cleanToken);
      
      // Verify it was saved immediately
      final saved = await _storage.read(key: 'userToken');
      if (saved == null || saved.isEmpty) {
        debugPrint('[API] ❌ Token save verification failed - token is null or empty after save!');
        throw Exception('Token was not saved to secure storage');
      }
      
      if (saved != cleanToken) {
        debugPrint('[API] ⚠️ Token save verification failed - token mismatch!');
        debugPrint('[API] Expected: ${cleanToken.substring(0, 20)}..., Got: ${saved.substring(0, 20)}...');
        throw Exception('Token verification failed - saved token does not match');
      }
      
      debugPrint('[API] ✅ Token saved and verified successfully in Flutter Secure Storage');
    } catch (e) {
      debugPrint('[API] ❌ Error saving token to Flutter Secure Storage: $e');
      rethrow;
    }
  }
  
  // Set refresh token
  Future<void> _setRefreshToken(String refreshToken) async {
    try {
      final cleanToken = refreshToken.trim();
      await _storage.write(key: 'refreshToken', value: cleanToken);
      debugPrint('[API] Refresh token saved to secure storage, length: ${cleanToken.length}');
    } catch (e) {
      debugPrint('[API] ❌ Error saving refresh token: $e');
      rethrow;
    }
  }
  
  // Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: 'userToken');
    await _storage.delete(key: 'refreshToken');
  }
  
  // Verify token exists (for debugging)
  Future<bool> hasToken() async {
    try {
      final token = await _getToken();
      final hasToken = token != null && token.isNotEmpty;
      debugPrint('[API] hasToken check: $hasToken, token length: ${token?.length ?? 0}');
      return hasToken;
    } catch (e) {
      debugPrint('[API] Error checking token: $e');
      return false;
    }
  }
  
  // Get token (public method for providers)
  Future<String?> getToken() async {
    try {
      final token = await _getToken();
      debugPrint('[API] getToken called, token length: ${token?.length ?? 0}');
      return token;
    } catch (e) {
      debugPrint('[API] Error getting token: $e');
      return null;
    }
  }
  
  // Make authenticated request
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    // Check if this is a public route (auth routes that don't need token)
    final isPublicAuthRoute = endpoint == '/auth/login' ||
                              endpoint == '/auth/register' ||
                              endpoint.startsWith('/auth/send-otp') ||
                              endpoint.startsWith('/auth/verify-otp') ||
                              endpoint.startsWith('/auth/send-registration-otp') ||
                              endpoint.startsWith('/auth/verify-registration-otp') ||
                              endpoint.startsWith('/auth/forgot-password') ||
                              endpoint.startsWith('/auth/reset-password') ||
                              endpoint.startsWith('/auth/google') ||
                              endpoint.startsWith('/auth/verify-email') ||
                              endpoint.startsWith('/auth/test-credentials');
    
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    // Send Bearer token globally if:
    // 1. Auth is required (requiresAuth = true)
    // 2. It's NOT a public auth route
    // 3. Token is available
    if (requiresAuth && !isPublicAuthRoute) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
        debugPrint('[API] ✅ Bearer token added globally for endpoint: $endpoint (length: ${token.length})');
      } else {
        // Try to get token one more time with a small delay (in case of race condition)
        await Future.delayed(const Duration(milliseconds: 100));
        final retryToken = await _getToken();
        if (retryToken != null && retryToken.isNotEmpty) {
          requestHeaders['Authorization'] = 'Bearer $retryToken';
          debugPrint('[API] ✅ Bearer token added on retry for endpoint: $endpoint');
        } else {
          // Token required but not found
          debugPrint('[API] ❌ Error: Token is null or empty for endpoint: $endpoint');
          throw ApiException(
            message: 'Authentication token not provided. Please login again.',
            statusCode: 401,
          );
        }
      }
    } else {
      // Don't send token for public auth routes or when explicitly not required
      debugPrint('[API] ⏭️ Skipping Bearer token for endpoint: $endpoint (requiresAuth: $requiresAuth, isPublicAuthRoute: $isPublicAuthRoute)');
    }
    
    http.Response response;
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      // Handle empty response body
      Map<String, dynamic> responseData;
      if (response.body.isEmpty) {
        responseData = {'success': false, 'message': 'Empty response from server'};
      } else {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw ApiException(
            message: 'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }
  
  // Authentication endpoints
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await _request(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      },
      requiresAuth: false,
    );
    
    if (response['success'] == true && response['data'] != null) {
      // Registration might return token or just user data (if email verification required)
      final token = response['data']['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _setToken(token);
      }
      // Return user data in the expected format
      if (response['data']['user'] != null) {
        return {
          ...response,
          'user': response['data']['user'],
          'token': token,
        };
      }
    }
    
    return response;
  }

  // Send registration OTP
  Future<Map<String, dynamic>> sendRegistrationOTP({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? preferredLanguage,
  }) async {
    final response = await _request(
      'POST',
      '/auth/send-registration-otp',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      },
      requiresAuth: false,
    );
    
    return response;
  }

  // Verify registration OTP
  Future<Map<String, dynamic>> verifyRegistrationOTP({
    required String phone,
    required String code,
  }) async {
    final response = await _request(
      'POST',
      '/auth/verify-registration-otp',
      body: {
        'phone': phone,
        'code': code,
      },
      requiresAuth: false,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (token != null && token.isNotEmpty) {
        await _setToken(token);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _setRefreshToken(refreshToken);
      }
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
  }) async {
    final response = await _request(
      'POST',
      '/auth/google',
      body: {
        'idToken': idToken,
      },
      requiresAuth: false,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      
      debugPrint('[API] Google sign-in response received. Token present: ${token != null}, RefreshToken present: ${refreshToken != null}');
      
      // Store access token
      if (token != null && token.isNotEmpty) {
        try {
          await _setToken(token);
          debugPrint('[API] ✅ Google sign-in token saved successfully to Flutter Secure Storage, length: ${token.trim().length}');
        } catch (e) {
          debugPrint('[API] ❌ Error saving Google sign-in token: $e');
          throw Exception('Failed to save authentication token: $e');
        }
      } else {
        debugPrint('[API] ❌ Error: No token in Google sign-in response data');
        throw Exception('No token received in Google sign-in response');
      }
      
      // Store refresh token if provided
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _setRefreshToken(refreshToken);
      }
      
      return response;
    }
    
    return response;
  }

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {
        'emailOrPhone': emailOrPhone,
        'password': password,
      },
      requiresAuth: false,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      
      debugPrint('[API] Login response received. Token present: ${token != null}, RefreshToken present: ${refreshToken != null}');
      
      // Store access token
      if (token != null && token.isNotEmpty) {
        try {
          await _setToken(token);
          // Verify token was saved
          final savedToken = await _getToken();
          if (savedToken != token.trim()) {
            debugPrint('[API] ⚠️ Warning: Token save verification failed');
            debugPrint('[API] Expected length: ${token.trim().length}, Saved length: ${savedToken?.length ?? 0}');
          } else {
            debugPrint('[API] ✅ Token saved successfully to Flutter Secure Storage, length: ${token.trim().length}');
          }
        } catch (e) {
          debugPrint('[API] ❌ Error saving token: $e');
          throw Exception('Failed to save authentication token: $e');
        }
      } else {
        debugPrint('[API] ❌ Error: No token in login response data');
        throw Exception('No token received in login response');
      }
      
      // Store refresh token if provided
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await _setRefreshToken(refreshToken);
          debugPrint('[API] ✅ Refresh token saved successfully to Flutter Secure Storage, length: ${refreshToken.trim().length}');
        } catch (e) {
          debugPrint('[API] ⚠️ Error saving refresh token: $e');
          // Don't throw - refresh token is optional
        }
      } else {
        debugPrint('[API] ⚠️ No refresh token in login response');
      }
      
      // Final verification - ensure token is accessible
      // Add delay and retry to ensure storage write is complete
      bool tokenVerified = false;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        final verifyToken = await _getToken();
        if (verifyToken != null && verifyToken.isNotEmpty && verifyToken == token.trim()) {
          debugPrint('[API] ✅ Final token verification passed on attempt ${i + 1}, token length: ${verifyToken.length}');
          tokenVerified = true;
          break;
        }
        debugPrint('[API] ⚠️ Token verification attempt ${i + 1} failed, retrying...');
      }
      
      if (!tokenVerified) {
        debugPrint('[API] ❌ Critical: Token not accessible after save!');
        throw Exception('Token was not properly saved to secure storage');
      }
      // Token verification completed in loop above
    } else {
      debugPrint('[API] ❌ Error: Login response missing data or failed');
      debugPrint('[API] Response: $response');
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> sendOTP(String emailOrPhone) async {
    return await _request(
      'POST',
      '/auth/send-otp',
      body: {'emailOrPhone': emailOrPhone},
      requiresAuth: false,
    );
  }
  
  Future<Map<String, dynamic>> verifyOTP({
    required String emailOrPhone,
    required String otp,
  }) async {
    return await _request(
      'POST',
      '/auth/verify-otp',
      body: {
        'emailOrPhone': emailOrPhone,
        'otp': otp,
      },
      requiresAuth: false,
    );
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      return await _request('GET', '/auth/me');
    } catch (e) {
      // If token is invalid, try to refresh it
      final storedRefreshToken = await _getRefreshToken();
      if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
        try {
          final refreshResponse = await refreshToken(storedRefreshToken);
          if (refreshResponse['success'] == true) {
            // Retry the request with new token
            return await _request('GET', '/auth/me');
          }
        } catch (refreshError) {
          debugPrint('[API] Token refresh failed: $refreshError');
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _request(
      'POST',
      '/auth/refresh-token',
      body: {'refreshToken': refreshToken},
      requiresAuth: false,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['token'] as String?;
      final newRefreshToken = response['data']['refreshToken'] as String?;
      
      if (token != null && token.isNotEmpty) {
        await _setToken(token);
        debugPrint('[API] Token refreshed successfully');
      }
      
      // Update refresh token if provided
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _setRefreshToken(newRefreshToken);
        debugPrint('[API] Refresh token updated');
      }
    }
    
    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _request(
      'POST',
      '/auth/forgot-password',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> resetPassword(String token, String password) async {
    return await _request(
      'POST',
      '/auth/reset-password/$token',
      body: {'password': password},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    return await _request(
      'GET',
      '/auth/verify-email/$token',
      requiresAuth: false,
    );
  }
  
  // Category endpoints
  Future<Map<String, dynamic>> getCategories() async {
    return await _request('GET', '/categories', requiresAuth: false);
  }
  
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    return await _request('GET', '/categories/$id', requiresAuth: false);
  }
  
  Future<Map<String, dynamic>> getFirstCategoryAndStatus() async {
    return await _request('GET', '/categories/first/status', requiresAuth: true);
  }
  
  // Question endpoints
  Future<Map<String, dynamic>> getQuestions({
    String? categoryId,
    int page = 1,
    int limit = 50,
    String? difficulty,
    String? language,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }
    if (difficulty != null) {
      queryParams['difficulty'] = difficulty;
    }
    if (language != null) {
      queryParams['language'] = language;
    }
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return await _request(
      'GET',
      '/questions?$queryString',
      requiresAuth: false,
    );
  }
  
  Future<Map<String, dynamic>> getQuestionsByCategory(String categoryId, {
    int page = 1,
    int limit = 50,
    String? language,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (language != null) {
      queryParams['language'] = language;
    }
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return await _request(
      'GET',
      '/questions/category/$categoryId?$queryString',
      requiresAuth: false,
    );
  }
  
  Future<Map<String, dynamic>> getQuestionById(String id) async {
    return await _request('GET', '/questions/$id', requiresAuth: false);
  }
  
  // Progress endpoints
  Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required String selectedAnswer,
    String? categoryId,
    int? timeSpent,
    String? language,
  }) async {
    return await _request(
      'POST',
      '/progress/submit',
      body: {
        'questionId': questionId,
        'selectedAnswer': selectedAnswer,
        if (categoryId != null) 'categoryId': categoryId,
        if (timeSpent != null) 'timeSpent': timeSpent,
        if (language != null) 'language': language,
      },
    );
  }

  Future<Map<String, dynamic>> getUserProgress() async {
    return await _request('GET', '/progress/my-progress');
  }
  
  Future<Map<String, dynamic>> getProgressByCategory(String categoryId) async {
    return await _request('GET', '/progress/category/$categoryId');
  }
  
  Future<Map<String, dynamic>> getProgressStats() async {
    return await _request('GET', '/progress/stats');
  }
  
  // Message endpoints
  Future<Map<String, dynamic>> getConversations() async {
    return await _request('GET', '/messages/conversations');
  }
  
  Future<Map<String, dynamic>> getConversationById(String id) async {
    return await _request('GET', '/messages/conversations/$id');
  }
  
  Future<Map<String, dynamic>> createConversation() async {
    return await _request('POST', '/messages/conversations');
  }
  
  Future<Map<String, dynamic>> getMessages(String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    return await _request(
      'GET',
      '/messages/conversations/$conversationId/messages?page=$page&limit=$limit',
    );
  }
  
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    List<String>? attachments,
  }) async {
    return await _request(
      'POST',
      '/messages/conversations/$conversationId/messages',
      body: {
        'content': content,
        if (attachments != null) 'attachments': attachments,
      },
    );
  }
  
  Future<Map<String, dynamic>> markConversationAsRead(String conversationId) async {
    return await _request(
      'PATCH',
      '/messages/conversations/$conversationId/read',
    );
  }
  
  // User management endpoints
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    return await _request(
      'PUT',
      '/users/$userId',
      body: data,
    );
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/users/profile/upload-image');
      final token = await _getToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to upload profile image');
      }
    } catch (e) {
      debugPrint('[API] Error uploading profile image: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await _request('PUT', '/users/profile', body: data);
  }

  // Certificate endpoints
  Future<Map<String, dynamic>> getMyCertificate() async {
    return await _request('GET', '/certificates/my-certificate');
  }
  
  Future<Map<String, dynamic>> getMyCertificateStatus() async {
    return await _request('GET', '/certificates/my-certificate/status');
  }
  
  Future<Map<String, dynamic>> generateMyCertificate({String? language}) async {
    return await _request(
      'POST',
      '/certificates/generate',
      body: language != null ? {'language': language} : {},
    );
  }
  
  Future<Map<String, dynamic>> verifyCertificate(String certificateId) async {
    return await _request(
      'GET',
      '/certificates/verify/$certificateId',
      requiresAuth: false,
    );
  }
  
  // User endpoints
  Future<Map<String, dynamic>> getUserById(String id) async {
    return await _request('GET', '/users/$id');
  }
  
  Future<Map<String, dynamic>> updateUserProgress(String id, Map<String, dynamic> data) async {
    return await _request('PATCH', '/users/$id/progress', body: data);
  }

  // Material endpoints
  Future<Map<String, dynamic>> getMaterials() async {
    return await _request('GET', '/materials', requiresAuth: false);
  }

  Future<Map<String, dynamic>> getMaterialById(String id) async {
    return await _request('GET', '/materials/$id', requiresAuth: false);
  }

  Future<Map<String, dynamic>> getAllMaterials() async {
    return await _request('GET', '/materials/admin/all', requiresAuth: true);
  }

  Future<Map<String, dynamic>> createMaterial({
    required String title,
    required String description,
    required String filePath,
  }) async {
    // For file upload, we'll need to use multipart/form-data
    // This is a simplified version - in production, use http.MultipartRequest
    final url = Uri.parse('$baseUrl/materials');
    final token = await _getToken();
    
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(
        message: responseData['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> updateMaterial({
    required String id,
    String? title,
    String? description,
    bool? isActive,
    String? filePath,
  }) async {
    final url = Uri.parse('$baseUrl/materials/$id');
    final token = await _getToken();
    
    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';
    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (isActive != null) request.fields['isActive'] = isActive.toString();
    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(
        message: responseData['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> deleteMaterial(String id) async {
    return await _request('DELETE', '/materials/$id');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException({required this.message, required this.statusCode});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

