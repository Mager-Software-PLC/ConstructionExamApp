import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCategories => _categories.length;

  Future<void> loadCategories({bool refresh = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.getCategories();

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _categories = data
              .map((json) => Category.fromJson(json))
              .where((category) {
                // Only show active categories and exclude taxi driver category
                if (!category.isActive) return false;
                final name = category.name.toLowerCase();
                return !name.contains('taxi') && !name.contains('driver');
              })
              .toList();
          // Sort by order, then by name
          _categories.sort((a, b) {
            if (a.order != b.order) {
              return a.order.compareTo(b.order);
            }
            return a.name.compareTo(b.name);
          });
        } else {
          _errorMessage = 'Invalid response format';
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load categories';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearCategories() {
    _categories = [];
    _errorMessage = null;
    notifyListeners();
  }
}

