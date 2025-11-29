import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ProgressProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _currentProgress; // Store current progress stats

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentProgress => _currentProgress;

  Future<String?> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('language_code') ?? 'en';
    } catch (e) {
      return 'en';
    }
  }

  Future<bool> submitAnswer({
    required String questionId,
    required int selectedAnswer, // Changed to int (order/index) to match web
    required String categoryId,
    int? timeSpent,
    String? language,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current language if not provided
      final currentLanguage = language ?? await _getCurrentLanguage();

      final response = await _apiService.submitAnswer(
        questionId: questionId,
        selectedAnswer: selectedAnswer, // Send as number (order/index)
        categoryId: categoryId,
        timeSpent: timeSpent,
        language: currentLanguage,
      );

      _isLoading = false;

      if (response['success'] == true) {
        // Show notification for correct answer
        final isCorrect = response['data']?['isCorrect'] ?? false;
        if (isCorrect) {
          await NotificationService().showLocalNotification(
            title: 'Correct!',
            body: 'Well done!',
          );
        }
        
        // Update current progress with the updated stats from response
        if (response['data']?['userStats'] != null) {
          _currentProgress = response['data']?['userStats'] as Map<String, dynamic>;
          debugPrint('[ProgressProvider] Updated progress: accuracy=${_currentProgress?['accuracy']}, progress=${_currentProgress?['progress']}');
        }
        
        // Reload full progress to ensure it's up to date
        await getUserProgress();
        
        notifyListeners();
        return isCorrect;
      } else {
        notifyListeners();
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

      if (response['success'] == true) {
        final progressData = response['data'] as Map<String, dynamic>?;
        // Update current progress
        if (progressData != null) {
          _currentProgress = {
            'progress': progressData['overallProgress'] ?? 0,
            'accuracy': progressData['accuracy'] ?? progressData['overallAccuracy'] ?? 0,
            'totalQuestionsAnswered': progressData['totalQuestionsAnswered'] ?? 0,
            'totalCorrectAnswers': progressData['totalCorrectAnswers'] ?? 0,
          };
        }
        notifyListeners();
        return progressData;
      }
      notifyListeners();
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
