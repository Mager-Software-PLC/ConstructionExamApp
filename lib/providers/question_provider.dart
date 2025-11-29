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
    int limit = 10000, // High limit to fetch all questions
    String? difficulty,
    BuildContext? context,
    bool loadAll = true, // By default, load all questions
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
      
      // If loadAll is true, use a high limit to get all questions
      final actualLimit = loadAll ? 10000 : limit;
      
      if (categoryId != null) {
        response = await _apiService.getQuestionsByCategory(
          categoryId,
          page: page,
          limit: actualLimit,
          language: language,
        );
      } else {
        response = await _apiService.getQuestions(
          categoryId: categoryId,
          page: page,
          limit: actualLimit,
          difficulty: difficulty,
          language: language,
        );
      }
      
      // Handle pagination - if there are more pages and loadAll is true, fetch them
      if (loadAll && response['pagination'] != null) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        final totalPages = pagination['totalPages'] as int? ?? 1;
        final currentPage = pagination['currentPage'] as int? ?? 1;
        
        if (totalPages > currentPage) {
          debugPrint('[QuestionProvider] Fetching additional pages: $currentPage of $totalPages');
          
          // Fetch remaining pages
          List<dynamic> allQuestionsList = [];
          if (response['data'] is List) {
            allQuestionsList.addAll(response['data'] as List);
          } else if (response['data'] is Map && response['data']['data'] != null) {
            allQuestionsList.addAll(response['data']['data'] as List);
          }
          
          for (int nextPage = currentPage + 1; nextPage <= totalPages; nextPage++) {
            try {
              Map<String, dynamic> nextResponse;
              if (categoryId != null) {
                nextResponse = await _apiService.getQuestionsByCategory(
                  categoryId,
                  page: nextPage,
                  limit: actualLimit,
                  language: language,
                );
              } else {
                nextResponse = await _apiService.getQuestions(
                  categoryId: categoryId,
                  page: nextPage,
                  limit: actualLimit,
                  difficulty: difficulty,
                  language: language,
                );
              }
              
              if (nextResponse['success'] == true) {
                final nextData = nextResponse['data'];
                if (nextData is List) {
                  allQuestionsList.addAll(nextData);
                } else if (nextData is Map && nextData['data'] != null) {
                  allQuestionsList.addAll(nextData['data'] as List);
                }
              }
            } catch (e) {
              debugPrint('[QuestionProvider] Error fetching page $nextPage: $e');
              // Continue with what we have
            }
          }
          
          // Update response with all questions
          response['data'] = allQuestionsList;
          debugPrint('[QuestionProvider] ✅ Fetched all ${allQuestionsList.length} questions from $totalPages pages');
        }
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
