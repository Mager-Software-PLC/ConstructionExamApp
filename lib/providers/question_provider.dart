import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'language_provider.dart';

class QuestionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Question> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategoryId;
  Map<String, dynamic>? _pagination;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalQuestions => _questions.length;
  String? get selectedCategoryId => _selectedCategoryId;
  Map<String, dynamic>? get pagination => _pagination;

  Future<void> loadQuestions({
    String? categoryId,
    int page = 1,
    int limit = 50,
    String? difficulty,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _selectedCategoryId = categoryId;
      notifyListeners();

      // Get current language from LanguageProvider if context is provided
      String? language;
      if (context != null) {
        try {
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          language = languageProvider.locale.languageCode;
        } catch (e) {
          // If LanguageProvider is not available, default to 'en'
          language = 'en';
        }
      } else {
        language = 'en'; // Default to English
      }

      Map<String, dynamic> response;
      
      if (categoryId != null) {
        response = await _apiService.getQuestionsByCategory(
          categoryId,
          page: page,
          limit: limit,
          language: language,
        );
      } else {
        response = await _apiService.getQuestions(
          categoryId: categoryId,
          page: page,
          limit: limit,
          difficulty: difficulty,
          language: language,
        );
      }

      if (response['success'] == true) {
        final data = response['data'];
        
        // Handle different response structures
        List<dynamic> questionsList = [];
        
        if (data is List) {
          // Direct array response (e.g., from getQuestionsByCategory)
          questionsList = data;
          // Check if pagination exists at root level
          if (response['pagination'] != null) {
            _pagination = response['pagination'] as Map<String, dynamic>;
          }
        } else if (data is Map && data['data'] != null) {
          // Nested structure (e.g., paginated response)
          questionsList = data['data'] as List;
          _pagination = data['pagination'] as Map<String, dynamic>?;
        } else if (response['pagination'] != null) {
          // Pagination at root level, data might be in response['data'] as list
          if (data is List) {
            questionsList = data;
          }
          _pagination = response['pagination'] as Map<String, dynamic>;
        } else {
          debugPrint('[QuestionProvider] ⚠️ Unexpected response format: ${response.keys}');
          _errorMessage = 'Invalid response format';
        }
        
        // Parse questions
        _questions = questionsList
            .map((json) {
              try {
                if (json is! Map<String, dynamic>) {
                  debugPrint('[QuestionProvider] ⚠️ Question is not a map: ${json.runtimeType}');
                  return null;
                }
                final question = Question.fromJson(json);
                // Validate question has required fields
                if (question.id.isEmpty || question.options.isEmpty) {
                  debugPrint('[QuestionProvider] ⚠️ Invalid question structure: id=${question.id}, options=${question.options.length}');
                  return null;
                }
                return question;
              } catch (e, stackTrace) {
                debugPrint('[QuestionProvider] ❌ Error parsing question: $e');
                debugPrint('[QuestionProvider] Stack trace: $stackTrace');
                debugPrint('[QuestionProvider] Question data: ${json.toString().substring(0, 200)}...');
                return null;
              }
            })
            .whereType<Question>()
            .toList();
        
        debugPrint('[QuestionProvider] ✅ Loaded ${_questions.length} questions (from ${questionsList.length} raw items)');
        
        if (_questions.isEmpty && questionsList.isNotEmpty) {
          debugPrint('[QuestionProvider] ⚠️ No valid questions parsed from ${questionsList.length} items');
          _errorMessage = 'No valid questions found in response';
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load questions';
        debugPrint('[QuestionProvider] ❌ API error: $_errorMessage');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Question?> getQuestionById(String id) async {
    try {
      // First check cached questions
      final cached = _questions.where((q) => q.id == id).firstOrNull;
      if (cached != null) return cached;

      // If not found, fetch from API
      final response = await _apiService.getQuestionById(id);
      if (response['success'] == true && response['data'] != null) {
        return Question.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void clearQuestions() {
    _questions = [];
    _pagination = null;
    _selectedCategoryId = null;
    notifyListeners();
  }
}
