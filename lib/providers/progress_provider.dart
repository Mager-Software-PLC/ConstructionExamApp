import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class ProgressProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> submitAnswer({
    required String questionId,
    required int selectedIndex,
    required int correctIndex,
    required int totalQuestions,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      bool isCorrect = selectedIndex == correctIndex;

      // Check if this is the first correct answer for this question
      final existingAnswer =
          await _firestoreService.getUserAnswer(user.uid, questionId);
      
      // It's the first correct answer if:
      // 1. Current answer is correct AND
      // 2. (No existing answer OR existing answer was NOT correct)
      bool isFirstCorrect = false;
      if (isCorrect) {
        if (existingAnswer == null) {
          // No previous answer - this is definitely the first correct
          isFirstCorrect = true;
        } else {
          // Check if previous answer was correct
          final wasPreviousCorrect = existingAnswer['isCorrect'] == true;
          // It's first correct only if previous answer was NOT correct
          isFirstCorrect = !wasPreviousCorrect;
        }
      }

      // Save answer first
      await _firestoreService.saveUserAnswer(
        userId: user.uid,
        questionId: questionId,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
        isFirstCorrect: isFirstCorrect,
      );

      // Wait a bit to ensure Firestore has written the data
      await Future.delayed(const Duration(milliseconds: 100));

      // Calculate and update progress
      final progress = await _firestoreService.calculateProgress(
        user.uid,
        totalQuestions,
      );
      await _firestoreService.updateUserProgress(user.uid, progress);

      // Send notification for milestones
      _checkAndNotifyMilestones(progress, totalQuestions);

      notifyListeners();
    } catch (e) {
      // Log error for debugging
      debugPrint('Error submitting answer: $e');
    }
  }

  void _checkAndNotifyMilestones(Map<String, dynamic> progress, int totalQuestions) {
    final completionPercentage = progress['completionPercentage'] as double;

    // Notify at 25%, 50%, 70% (pass), and 100%
    if (completionPercentage >= 25.0 && completionPercentage < 30.0) {
      NotificationService().showLocalNotification(
        title: 'Great Progress! 🎉',
        body: 'You\'ve completed 25% of the exam. Keep going!',
      );
    } else if (completionPercentage >= 50.0 && completionPercentage < 55.0) {
      NotificationService().showLocalNotification(
        title: 'Halfway There! 🚀',
        body: 'You\'ve completed 50% of the exam. Excellent work!',
      );
    } else if (completionPercentage >= 70.0 && completionPercentage < 75.0) {
      NotificationService().showLocalNotification(
        title: 'Congratulations! 🏆',
        body: 'You\'ve passed the exam! Certificate is ready.',
      );
    } else if (completionPercentage >= 100.0) {
      NotificationService().showLocalNotification(
        title: 'Perfect Score! 🌟',
        body: 'You\'ve completed all questions. Outstanding achievement!',
      );
    }
  }

  Future<Map<String, dynamic>?> getUserAnswer(String questionId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      return await _firestoreService.getUserAnswer(user.uid, questionId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshProgress(int totalQuestions) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final progress = await _firestoreService.calculateProgress(
        user.uid,
        totalQuestions,
      );
      await _firestoreService.updateUserProgress(user.uid, progress);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}

