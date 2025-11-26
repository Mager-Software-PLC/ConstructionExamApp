import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ProgressProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> submitAnswer({
    required String questionId,
    required String selectedOption,
    required String categoryId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.submitAnswer(
        questionId: questionId,
        selectedAnswer: selectedOption,
        categoryId: categoryId,
      );

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        // Show notification for correct answer
        final isCorrect = response['data']?['isCorrect'] ?? false;
        if (isCorrect) {
          await NotificationService().showLocalNotification(
            title: 'Correct!',
            body: 'Well done!',
          );
        }
        return isCorrect;
      } else {
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProgress() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getUserProgress();

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProgressByCategory(String categoryId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getProgressByCategory(categoryId);

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProgressStats() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getProgressStats();

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
