import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/screenshot_protection_service.dart';
import '../models/api_models.dart';

class AdminQuestionEditScreen extends StatefulWidget {
  final Question? question;

  const AdminQuestionEditScreen({super.key, this.question});

  @override
  State<AdminQuestionEditScreen> createState() => _AdminQuestionEditScreenState();
}

class _AdminQuestionEditScreenState extends State<AdminQuestionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final List<TextEditingController> _choiceControllers = [];
  final ApiService _apiService = ApiService();
  int _correctIndex = 0;
  bool _isSaving = false;

  bool get _isFormValid {
    // Check if question text is filled
    if (_textController.text.trim().isEmpty) return false;
    
    // Check if all choices are filled
    if (_choiceControllers.any((controller) => controller.text.trim().isEmpty)) return false;
    
    // Check if correct index is valid
    if (_correctIndex < 0 || _correctIndex >= _choiceControllers.length) return false;
    
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Enable screenshot protection for admin question edit screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenshotProtectionService().enableProtection();
    });
    
    if (widget.question != null) {
      _textController.text = widget.question!.getQuestionText('en');
      final correctIndex = widget.question!.options.indexWhere((opt) => opt.isCorrect);
      _correctIndex = correctIndex >= 0 ? correctIndex : 0;
      for (var option in widget.question!.options) {
        _choiceControllers.add(TextEditingController(text: option.getText('en')));
      }
    } else {
      // Initialize with 4 empty choices for new question
      for (int i = 0; i < 4; i++) {
        _choiceControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate choices
    final choices = _choiceControllers.map((c) => c.text.trim()).toList();
    if (choices.any((c) => c.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All choices must be filled'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_correctIndex < 0 || _correctIndex >= choices.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a correct answer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Implement question create/update via backend API
      // For now, show a message that this feature needs backend implementation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question management via API not yet implemented. Please use admin web panel.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.question != null
                ? 'Question updated successfully'
                : 'Question added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question != null ? 'Edit Question' : 'Add Question'),
        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'Enter the question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  onChanged: (_) => setState(() {}), // Trigger rebuild to update button state
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter question text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Answer Choices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFFFFE4E9) // Light blush for light mode
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Correct Answer Index: $_correctIndex',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            'Answer Choices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFFFFE4E9) // Light blush for light mode
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Correct Answer Index: $_correctIndex',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                ..._choiceControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  final isSelected = _correctIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outline,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.onPrimary 
                                              : Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Choice ${String.fromCharCode(65 + index)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle, 
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Choice ${String.fromCharCode(65 + index)}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.error,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  suffixIcon: isSelected
                                      ? Icon(
                                          Icons.check_circle, 
                                          color: Theme.of(context).colorScheme.tertiary,
                                        )
                                      : null,
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                onChanged: (_) => setState(() {}), // Trigger rebuild to update button state
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter choice text';
                                  }
                                  return null;
                                },
                              ),
                              if (!isSelected) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _correctIndex = index;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 40),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 18),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Set as Correct',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? const Color(0xFFFFE4E9) // Light blush for light mode
                                        : Theme.of(context).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.tertiary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).colorScheme.tertiary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Correct Answer (Index: $index)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.onPrimary 
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Choice ${String.fromCharCode(65 + index)}',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: isSelected
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter choice text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!isSelected)
                                Container(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _correctIndex = index;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(100, 40),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 18),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Set Correct',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? const Color(0xFFFFE4E9) // Light blush for light mode
                                        : Theme.of(context).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.tertiary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).colorScheme.tertiary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Correct',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSaving || !_isFormValid) ? null : _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFFFFB6C1) // Light blush pink when disabled in light mode
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                      foregroundColor: _isFormValid
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).brightness == Brightness.light
                              ? Colors.white.withOpacity(0.8)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      disabledBackgroundColor: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFFFB6C1)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                      disabledForegroundColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      elevation: _isFormValid ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _isFormValid
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.question != null ? Icons.update : Icons.add_circle_outline,
                                size: 20,
                                color: _isFormValid
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).brightness == Brightness.light
                                        ? Colors.white.withOpacity(0.8)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.question != null ? 'Update Question' : 'Add Question',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isFormValid
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).brightness == Brightness.light
                                          ? Colors.white.withOpacity(0.8)
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (!_isFormValid) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFFFE4E9).withOpacity(0.5) // Light blush background
                          : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Please fill all fields and select a correct answer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24), // Extra padding at bottom to ensure button is visible
              ],
            ),
          ),
        ),
      ),
    );
  }
}

