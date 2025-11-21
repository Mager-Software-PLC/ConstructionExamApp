import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importQuestions() async {
    try {
      // Load questions from JSON file
      final String jsonString = await rootBundle.loadString('lib/data/construction_questions.json');
      final List<dynamic> questionsJson = json.decode(jsonString);

      // Get existing questions count
      final existingQuestions = await _firestore.collection('questions').get();
      final existingCount = existingQuestions.docs.length;

      if (existingCount > 0) {
        print('⚠️  Warning: $existingCount questions already exist in Firestore.');
        print('   This will add new questions. Duplicates may be created.');
      }

      print('📝 Starting import of ${questionsJson.length} questions...');

      // Import questions in batches
      int imported = 0;
      int batchSize = 10;
      
      for (int i = 0; i < questionsJson.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < questionsJson.length) ? i + batchSize : questionsJson.length;

        for (int j = i; j < end; j++) {
          final question = questionsJson[j];
          final docRef = _firestore.collection('questions').doc();
          
          batch.set(docRef, {
            'text': question['text'],
            'choices': question['choices'],
            'correctIndex': question['correctIndex'],
            'createdAt': FieldValue.serverTimestamp(),
            'order': j + 1,
          });
        }

        await batch.commit();
        imported += (end - i);
        print('✅ Imported $imported/${questionsJson.length} questions...');
      }

      print('🎉 Successfully imported all ${questionsJson.length} questions!');
    } catch (e) {
      print('❌ Error importing questions: $e');
      rethrow;
    }
  }

  Future<void> clearAllQuestions() async {
    try {
      print('🗑️  Clearing all questions from Firestore...');
      final questions = await _firestore.collection('questions').get();
      
      final batch = _firestore.batch();
      for (var doc in questions.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Cleared ${questions.docs.length} questions.');
    } catch (e) {
      print('❌ Error clearing questions: $e');
      rethrow;
    }
  }

  Future<int> getQuestionCount() async {
    try {
      final questions = await _firestore.collection('questions').get();
      return questions.docs.length;
    } catch (e) {
      print('❌ Error getting question count: $e');
      return 0;
    }
  }
}

