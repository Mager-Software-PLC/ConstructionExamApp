import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.145.60.161:5000/api';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Get stored token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'userToken');
  }
  
  // Set token
  Future<void> _setToken(String token) async {
    await _storage.write(key: 'userToken', value: token);
  }
  
  // Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: 'userToken');
  }
  
  // Verify token exists (for debugging)
  Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
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
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      } else {
        print('[API] Error: Token is null or empty for endpoint: $endpoint');
        throw ApiException(
          message: 'Authentication token not provided. Please login again.',
          statusCode: 401,
        );
      }
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
      final token = response['data']['token'] as String?;
      if (token != null) {
        await _setToken(token);
      }
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
      final token = response['data']['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _setToken(token);
        // Verify token was saved
        final savedToken = await _getToken();
        if (savedToken != token) {
          print('[API] Warning: Token save verification failed');
        } else {
          print('[API] Token saved successfully, length: ${token.length}');
        }
      } else {
        print('[API] Error: No token in login response');
      }
    } else {
      print('[API] Error: Login response missing data or failed');
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
    return await _request('GET', '/auth/me');
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
      if (token != null) {
        await _setToken(token);
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
  
  // Question endpoints
  Future<Map<String, dynamic>> getQuestions({
    String? categoryId,
    int page = 1,
    int limit = 10,
    String? difficulty,
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
    int limit = 10,
  }) async {
    return await _request(
      'GET',
      '/questions/category/$categoryId?page=$page&limit=$limit',
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

  // Certificate endpoints
  Future<Map<String, dynamic>> getMyCertificate() async {
    return await _request('GET', '/certificates/my-certificate');
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
    return await _request('GET', '/materials/admin/all');
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

