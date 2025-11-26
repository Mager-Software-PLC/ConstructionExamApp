import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

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
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _selectedCategoryId = categoryId;
      notifyListeners();

      Map<String, dynamic> response;
      
      if (categoryId != null) {
        response = await _apiService.getQuestionsByCategory(
          categoryId,
          page: page,
          limit: limit,
        );
      } else {
        response = await _apiService.getQuestions(
          categoryId: categoryId,
          page: page,
          limit: limit,
          difficulty: difficulty,
        );
      }

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['data'] != null) {
          _questions = (data['data'] as List)
              .map((json) => Question.fromJson(json))
              .toList();
          _pagination = data['pagination'] as Map<String, dynamic>?;
        } else if (data is List) {
          _questions = data
              .map((json) => Question.fromJson(json))
              .toList();
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load questions';
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
