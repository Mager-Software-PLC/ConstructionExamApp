import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/question_model.dart';

class QuestionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<QuestionModel> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalQuestions => _questions.length;

  Future<void> loadQuestions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _questions = await _firestoreService.getQuestions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  QuestionModel? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }
}

