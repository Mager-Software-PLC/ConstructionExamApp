import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for offline support
  List<QuestionModel>? _cachedQuestions;

  Future<List<QuestionModel>> getQuestions() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('questions').get();

      List<QuestionModel> questions = snapshot.docs.map((doc) {
        return QuestionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Cache questions for offline use
      _cachedQuestions = questions;
      return questions;
    } catch (e) {
      // Return cached questions if available
      if (_cachedQuestions != null) {
        return _cachedQuestions!;
      }
      throw Exception('Failed to fetch questions: $e');
    }
  }

  Future<void> saveUserAnswer({
    required String userId,
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
    required bool isFirstCorrect,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('answers')
          .doc(questionId)
          .set({
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'isCorrect': isCorrect,
        'isFirstCorrect': isFirstCorrect,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save answer: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserAnswer(
      String userId, String questionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('answers')
          .doc(questionId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<Map<String, dynamic>> calculateProgress(
      String userId, int totalQuestions) async {
    try {
      QuerySnapshot answersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('answers')
          .get();

      int attempted = 0;
      int correct = 0;
      int wrong = 0;
      Set<String> uniqueQuestions = {};

      for (var doc in answersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['questionId'] == null) continue;
        
        final questionId = data['questionId'] as String;
        uniqueQuestions.add(questionId);
        
        // Count correct answers (only first correct counts)
        if (data['isCorrect'] == true && data['isFirstCorrect'] == true) {
          correct++;
        }
        // Count wrong answers (only if answer is wrong and not first correct)
        else if (data['isCorrect'] == false) {
          wrong++;
        }
      }

      attempted = uniqueQuestions.length;
      double completionPercentage = totalQuestions > 0
          ? (correct / totalQuestions * 100)
          : 0.0;

      return {
        'attempted': attempted,
        'correct': correct,
        'wrong': wrong,
        'completionPercentage': completionPercentage,
      };
    } catch (e) {
      return {
        'attempted': 0,
        'correct': 0,
        'wrong': 0,
        'completionPercentage': 0.0,
      };
    }
  }

  Future<void> updateUserProgress(String userId, Map<String, dynamic> progress) async {
    try {
      // Allow certificate generation regardless of completion percentage
      // Certificate is available once user has attempted at least one question
      final hasAttempted = (progress['attempted'] ?? 0) > 0;
      await _firestore.collection('users').doc(userId).update({
        'progress': progress,
        'certificateIssued': hasAttempted, // Certificate available if user has attempted questions
      });
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Admin: Add question
  Future<String> addQuestion({
    required String text,
    required List<String> choices,
    required int correctIndex,
  }) async {
    try {
      final docRef = await _firestore.collection('questions').add({
        'text': text,
        'choices': choices,
        'correctIndex': correctIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add question: $e');
    }
  }

  // Admin: Update question
  Future<void> updateQuestion({
    required String questionId,
    required String text,
    required List<String> choices,
    required int correctIndex,
  }) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'text': text,
        'choices': choices,
        'correctIndex': correctIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  // Admin: Delete question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // Admin: Get all users with their progress
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }
}

