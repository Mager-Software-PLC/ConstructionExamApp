import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/question_provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart' show Category;
import 'questions_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  Map<String, Map<String, dynamic>> _categoryProgress = {}; // categoryId -> progress data
  bool _isLoadingProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryProgress();
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (categoryProvider.categories.isEmpty) {
        categoryProvider.loadCategories();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload progress when returning to screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryProgress();
    });
  }

  Future<void> _loadCategoryProgress() async {
    if (_isLoadingProgress) return;
    
    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getUserProgress();
      
      if (mounted && response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final progressByCategory = data['progressByCategory'] as List<dynamic>?;
        
        if (progressByCategory != null) {
          final progressMap = <String, Map<String, dynamic>>{};
          
          for (var item in progressByCategory) {
            final categoryData = item as Map<String, dynamic>;
            final category = categoryData['category'] as Map<String, dynamic>?;
            if (category != null) {
              final categoryId = category['id']?.toString() ?? '';
              if (categoryId.isNotEmpty) {
                final answeredQuestions = categoryData['answeredQuestions'] as int?;
                final correctAnswers = categoryData['correctAnswers'] as int? ?? 0;
                final totalQuestions = categoryData['totalQuestions'] as int? ?? 0;
                
                debugPrint('[Categories] Category $categoryId: answeredQuestions=$answeredQuestions, correctAnswers=$correctAnswers, totalQuestions=$totalQuestions');
                
                progressMap[categoryId] = {
                  'progress': categoryData['progress'] ?? 0,
                  'correctAnswers': correctAnswers,
                  'answeredQuestions': answeredQuestions ?? correctAnswers ?? 0,
                  'totalQuestions': totalQuestions,
                  'attemptCount': categoryData['attemptCount'] ?? 0,
                };
              }
            }
          }
          
          setState(() {
            _categoryProgress = progressMap;
            _isLoadingProgress = false;
          });
          
          debugPrint('[Categories] Progress loaded for ${progressMap.length} categories');
          // Debug: Print progress for each category
          progressMap.forEach((catId, data) {
            debugPrint('[Categories] Category $catId: answered=${data['answeredQuestions']}, total=${data['totalQuestions']}, progress=${data['progress']}%');
          });
        } else {
          setState(() {
            _isLoadingProgress = false;
          });
        }
      } else {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading category progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  bool _hasCategoryStarted(String categoryId) {
    final progress = _categoryProgress[categoryId];
    if (progress == null) return false;
    final answeredQuestions = progress['answeredQuestions'] as int? ?? progress['correctAnswers'] as int? ?? 0;
    final progressPercent = progress['progress'] as int? ?? 0;
    final attemptCount = progress['attemptCount'] as int? ?? 0;
    return answeredQuestions > 0 || progressPercent > 0 || attemptCount > 0;
  }

  int _getCategoryProgress(String categoryId) {
    final progress = _categoryProgress[categoryId];
    return progress?['progress'] as int? ?? 0;
  }

  int _getAttemptCount(String categoryId) {
    final progress = _categoryProgress[categoryId];
    return progress?['attemptCount'] as int? ?? 0;
  }
  

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.withOpacity(0.7);
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.trending_down;
      case 'medium':
        return Icons.trending_flat;
      case 'hard':
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
  }

  String _getDifficultyText(String difficulty, AppLocalizations l10n) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return l10n.translate('easy') ?? 'Easy';
      case 'medium':
        return l10n.translate('medium') ?? 'Medium';
      case 'hard':
        return l10n.translate('hard') ?? 'Hard';
      default:
        return difficulty;
    }
  }

  Future<void> _startPractice(Category category) async {
    // Check if category has reached max attempts (5)
    final progress = _categoryProgress[category.id];
    final attemptCount = progress?['attemptCount'] as int? ?? 0;
    if (attemptCount >= 5) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('max_attempts_reached') ?? 'You have reached the maximum number of attempts (5) for this category'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('loading_questions') ?? 'Loading questions...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await questionProvider.loadQuestions(
        categoryId: category.id,
        context: context,
      );

      if (mounted) {
        Navigator.of(context).pop();

        if (questionProvider.questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('no_questions_available') ?? 'No questions available in this category'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuestionsScreen(
                categoryId: category.id,
                categoryName: category.name,
              ),
            ),
          ).then((_) async {
            // Reload progress when returning from questions screen
            await _loadCategoryProgress();
            // Force a rebuild to show updated progress
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('error_loading_questions') ?? 'Error loading questions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.translate('categories') ?? 'Categories',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => categoryProvider.loadCategories(refresh: true),
                tooltip: l10n.translate('refresh') ?? 'Refresh',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: categoryProvider.isLoading && categoryProvider.categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : categoryProvider.errorMessage != null
                    ? _buildErrorState(context, categoryProvider, l10n)
                    : categoryProvider.categories.isEmpty
                        ? _buildEmptyState(context, categoryProvider, l10n)
                        : RefreshIndicator(
                            onRefresh: () => categoryProvider.loadCategories(refresh: true),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Show all categories (no restriction)
                                  ...categoryProvider.categories.map((category) {
                                    // Filter out taxi driver category
                                    final name = category.name.toLowerCase();
                                    if (name.contains('taxi') || name.contains('driver')) {
                                      return const SizedBox.shrink();
                                    }
                                    
                                    return _buildCategoryCard(
                                      context, 
                                      category, 
                                      l10n,
                                      hasStarted: _hasCategoryStarted(category.id),
                                      progress: _getCategoryProgress(category.id),
                                      attemptCount: _getAttemptCount(category.id),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CategoryProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('error_loading_categories') ?? 'Error loading categories',
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadCategories(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('retry') ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoryProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_categories_available') ?? 'No categories available',
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadCategories(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('refresh') ?? 'Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, 
    Category category, 
    AppLocalizations l10n, {
    bool hasStarted = false,
    int progress = 0,
    int attemptCount = 0,
  }) {
    final isCompleted = progress >= 100;
    final canRetake = isCompleted && attemptCount < 5;
    final isMaxAttempts = attemptCount >= 5;
    final categoryColor = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    final difficultyColor = _getDifficultyColor(category.difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.1),
            categoryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMaxAttempts ? null : () => _startPractice(category),
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isMaxAttempts ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isMaxAttempts ? Icons.lock : Icons.category,
                        color: categoryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (category.description != null && category.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category.description!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: difficultyColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getDifficultyIcon(category.difficulty),
                            size: 18,
                            color: difficultyColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getDifficultyText(category.difficulty, l10n),
                            style: AppTypography.labelMedium.copyWith(
                              color: difficultyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${category.questionCount}',
                            style: AppTypography.labelMedium.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Attempt count badge
                if (attemptCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.translate('attempt') ?? 'Attempt'} $attemptCount${attemptCount >= 5 ? ' (Max)' : ' / 5'}',
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Progress bar if category has been started
                if (hasStarted && !isMaxAttempts) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.translate('progress') ?? 'Progress',
                            style: AppTypography.labelMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: AppTypography.labelMedium.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_categoryProgress[category.id]?['answeredQuestions'] ?? _categoryProgress[category.id]?['correctAnswers'] ?? 0} / ${_categoryProgress[category.id]?['totalQuestions'] ?? category.questionCount ?? 0} ${l10n.translate('answered') ?? 'answered'}',
                            style: AppTypography.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isMaxAttempts ? null : () => _startPractice(category),
                    icon: Icon(
                      isMaxAttempts 
                        ? Icons.lock 
                        : canRetake
                          ? Icons.refresh
                          : hasStarted 
                            ? Icons.play_circle_outline 
                            : Icons.play_arrow, 
                      size: 20,
                    ),
                    label: Text(
                      isMaxAttempts 
                        ? (l10n.translate('max_attempts_reached') ?? 'Max Attempts Reached')
                        : canRetake
                          ? (l10n.translate('retake') ?? 'Retake')
                          : hasStarted
                            ? (l10n.translate('continue') ?? 'Continue')
                            : (l10n.translate('practice') ?? 'Practice'),
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
