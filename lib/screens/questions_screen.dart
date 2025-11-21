import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/auth_provider.dart';
import '../models/question_model.dart';
import '../l10n/app_localizations.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questionProvider =
          Provider.of<QuestionProvider>(context, listen: false);
      if (questionProvider.questions.isEmpty) {
        questionProvider.loadQuestions();
      }
    });
  }

  Future<void> _handleAnswerSelection(
    QuestionModel question,
    int selectedIndex,
  ) async {
    if (_showFeedback || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    final questions = questionProvider.questions;

    setState(() {
      _selectedAnswerIndex = selectedIndex;
      _isCorrect = selectedIndex == question.correctIndex;
      _showFeedback = true;
      _isSubmitting = false;
    });

    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    await progressProvider.submitAnswer(
      questionId: question.id,
      selectedIndex: selectedIndex,
      correctIndex: question.correctIndex,
      totalQuestions: questions.length,
    );

    // Update user progress
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      await authProvider.loadUserData(authProvider.user!.uid);
    }
  }

  void _nextQuestion() {
    if (!_showFeedback) return; // Don't allow next if no answer selected
    
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    if (_currentQuestionIndex < questionProvider.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showFeedback = false;
        _isCorrect = false;
      });
    } else {
      // All questions completed
        Navigator.of(context).pop();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(l10n.translate('well_done')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questionProvider = Provider.of<QuestionProvider>(context);
    final questions = questionProvider.questions;

    if (questionProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translate('questions'))),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translate('questions'))),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.translate('no_questions_available'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    questionProvider.loadQuestions();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.translate('load_questions')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('app_name')),
            Text(
              '${l10n.translate('question')} ${_currentQuestionIndex + 1} ${l10n.translate('of')} ${questions.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.03),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_currentQuestionIndex + 1)} / ${questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A).withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Q',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Answer choices
                  ...question.choices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final choice = entry.value;
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrectAnswer = index == question.correctIndex;

                    Color backgroundColor;
                    Color textColor;
                    Color borderColor;
                    IconData? icon;

                    if (_showFeedback) {
                      if (isCorrectAnswer) {
                        backgroundColor = Colors.green.shade50;
                        textColor = Colors.green.shade900;
                        borderColor = Colors.green;
                        icon = Icons.check_circle;
                      } else if (isSelected && !isCorrectAnswer) {
                        backgroundColor = Colors.red.shade50;
                        textColor = Colors.red.shade900;
                        borderColor = Colors.red;
                        icon = Icons.cancel;
                      } else {
                        backgroundColor = Colors.grey.shade50;
                        textColor = Colors.grey.shade700;
                                    borderColor = Colors.grey.shade300;
                      }
                    } else if (isSelected) {
                      backgroundColor = const Color(0xFF1E3A8A).withOpacity(0.1);
                      textColor = const Color(0xFF1E3A8A);
                      borderColor = const Color(0xFF1E3A8A);
                    } else {
                      backgroundColor = Colors.white;
                      textColor = Colors.black87;
                      borderColor = Colors.grey.shade300;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showFeedback ? null : () => _handleAnswerSelection(question, index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || (isCorrectAnswer && _showFeedback) ? 2.5 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected || (isCorrectAnswer && _showFeedback)
                                  ? [
                                      BoxShadow(
                                        color: borderColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected || (isCorrectAnswer && _showFeedback)
                                        ? borderColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: icon != null
                                      ? Icon(icon, color: Colors.white, size: 20)
                                      : isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : Center(
                                              child: Text(
                                                String.fromCharCode(65 + index), // A, B, C, D
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : borderColor,
                                                ),
                                              ),
                                            ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    choice,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: isSelected || (isCorrectAnswer && _showFeedback)
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  // Feedback and Next button
                  if (_showFeedback) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isCorrect ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isCorrect ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCorrect ? l10n.translate('correct_answer') : l10n.translate('incorrect'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isCorrect
                                      ? l10n.translate('well_done')
                                      : l10n.translate('try_again_message'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Fixed Next Button at bottom
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: Icon(
                      _currentQuestionIndex < questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check_circle,
                    ),
                    label: Text(
                      _currentQuestionIndex < questions.length - 1
                          ? l10n.translate('next_question')
                          : l10n.translate('finish_exam'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
