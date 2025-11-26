import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/auth_provider.dart';
import '../models/api_models.dart' show Question;
import '../l10n/app_localizations.dart';

class QuestionsScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  
  const QuestionsScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isSubmitting = false;

  Future<void> _loadProgress() async {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    await progressProvider.getProgressStats();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load questions
      final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
      // Always reload questions if categoryId is provided or if questions are empty
      if (widget.categoryId != null || questionProvider.questions.isEmpty) {
        await questionProvider.loadQuestions(categoryId: widget.categoryId);
      }
    });
  }

  Future<void> _handleAnswerSelection(
    Question question,
    int selectedIndex,
  ) async {
    if (_showFeedback || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    setState(() {
      _selectedAnswerIndex = selectedIndex;
      final correctOptionIndex = question.options.indexWhere((opt) => opt.isCorrect);
      _isCorrect = selectedIndex == correctOptionIndex;
      _showFeedback = true;
      _isSubmitting = false;
    });

    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    await progressProvider.submitAnswer(
      questionId: question.id,
      selectedOption: String.fromCharCode(65 + selectedIndex),
      categoryId: question.categoryId,
    );

    // Reload progress
    await _loadProgress();
  }

  Future<void> _nextQuestion() async {
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
      await _loadProgress();
      
      // Navigate to home screen instead of just popping
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.translate('well_done')),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to home screen
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final questionProvider = Provider.of<QuestionProvider>(context);
    final questions = questionProvider.questions;

    if (questionProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translate('questions'))),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
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
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.translate('no_questions_available'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
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
            Text(widget.categoryName ?? l10n.translate('questions')),
            Text(
              '${l10n.translate('question')} ${_currentQuestionIndex + 1} ${l10n.translate('of')} ${questions.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // Progress bar
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
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
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Q',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question.getQuestionText('en'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Answer choices
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrectAnswer = option.isCorrect;

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
                      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
                      textColor = Theme.of(context).colorScheme.onSurface;
                      borderColor = Theme.of(context).colorScheme.outline;
                      }
                    } else if (isSelected) {
                      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
                      textColor = Theme.of(context).colorScheme.primary;
                      borderColor = Theme.of(context).colorScheme.primary;
                    } else {
                      backgroundColor = Theme.of(context).colorScheme.surface;
                      textColor = Theme.of(context).colorScheme.onSurface;
                      borderColor = Theme.of(context).colorScheme.outline;
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
                                        color: borderColor,
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
                                      ? Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 20)
                                      : isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            )
                                          : Center(
                                              child: Text(
                                                String.fromCharCode(65 + index), // A, B, C, D
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? Theme.of(context).colorScheme.onPrimary
                                                      : borderColor,
                                                ),
                                              ),
                                            ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.getText('en'),
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
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
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
                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF1E3A8A).withOpacity(0.5),
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
