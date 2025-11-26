import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'admin_question_edit_screen.dart';
import 'admin_users_screen.dart';
import 'admin_materials_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
      questionProvider.loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: _selectedIndex == 0
            ? _buildQuestionsView()
            : _selectedIndex == 1
                ? const AdminUsersScreen()
                : const AdminMaterialsScreen(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Navigation Items
              _buildDrawerItem(Icons.quiz, 'Questions', 0),
              _buildDrawerItem(Icons.people, 'Users & Results', 1),
              _buildDrawerItem(Icons.description, 'Materials', 2),
              const Spacer(),
              const Divider(),
              // Clear All Answers button
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text(
                  'Clear All Answers',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // Close drawer first
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Answers'),
                      content: const Text(
                        'This will delete ALL answers and reset progress for ALL users. This action cannot be undone. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    try {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // TODO: Implement clear all answers via backend API
                      // await _apiService.clearAllUsersAnswers();
                      throw Exception('Clear all answers not yet implemented in backend API');

                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All answers cleared successfully. All users can now start fresh.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const Divider(),
              // Logout button
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // Close drawer first
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
              ),
              // Close drawer button
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.of(context).pop(); // Close drawer
      },
    );
  }


  Widget _buildQuestionsView() {
    final questionProvider = Provider.of<QuestionProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive header
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminQuestionEditScreen(),
                            ),
                          ).then((_) {
                            questionProvider.loadQuestions();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminQuestionEditScreen(),
                          ),
                        ).then((_) {
                          questionProvider.loadQuestions();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          if (questionProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (questionProvider.questions.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(height: 16),
                  Text(
                    'No questions found',
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: isMobile
                  ? ListView.builder(
                      itemCount: questionProvider.questions.length,
                      itemBuilder: (context, index) {
                        final question = questionProvider.questions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            title: Text(
                              question.getQuestionText('en'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Difficulty: ${question.difficulty}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AdminQuestionEditScreen(
                                          question: question,
                                        ),
                                      ),
                                    ).then((_) {
                                      questionProvider.loadQuestions();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteQuestion(question),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Options:',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: question.options.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final option = entry.value;
                                        final isCorrect = option.isCorrect;
                                        return Chip(
                                          label: Text(
                                            '${String.fromCharCode(65 + idx)}: ${option.getText('en')}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: isCorrect ? Colors.green.shade50 : Colors.grey.shade100,
                                          side: BorderSide(
                                            color: isCorrect ? Colors.green : Colors.grey.shade300,
                                            width: isCorrect ? 2 : 1,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: questionProvider.questions.length,
                      itemBuilder: (context, index) {
                        final question = questionProvider.questions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            title: Text(
                              question.getQuestionText('en'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Difficulty: ${question.difficulty}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: question.options.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final option = entry.value;
                                    final isCorrect = option.isCorrect;
                                    final optionText = option.getText('en');
                                    return Chip(
                                      label: Text(
                                        '${String.fromCharCode(65 + idx)}: ${optionText.length > 20 ? optionText.substring(0, 20) + "..." : optionText}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: isCorrect ? Colors.green.shade50 : Colors.grey.shade100,
                                      side: BorderSide(
                                        color: isCorrect ? Colors.green : Colors.grey.shade300,
                                        width: isCorrect ? 2 : 1,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AdminQuestionEditScreen(
                                          question: question,
                                        ),
                                      ),
                                    ).then((_) {
                                      questionProvider.loadQuestions();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteQuestion(question),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Are you sure you want to delete:\n\n"${question.getQuestionText('en')}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement delete question via backend API
        // await _apiService.deleteQuestion(question.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delete question not yet implemented in backend API'),
              backgroundColor: Colors.orange,
            ),
          );
          // For now, just reload questions
          final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
          questionProvider.loadQuestions();
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
      }
    }
  }
}

