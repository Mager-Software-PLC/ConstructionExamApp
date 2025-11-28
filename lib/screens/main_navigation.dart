import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../services/backend_auth_service.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasToken = false;

  // Screens are created once and preserved for fast navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      const ProgressScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    _ensureUserLoaded();
  }

  Future<void> _ensureUserLoaded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final backendAuthService = BackendAuthService();
    
    // Small delay to ensure storage is ready
    await Future.delayed(const Duration(milliseconds: 200));
    
    // If user is already authenticated and loaded, skip check
    if (authProvider.isAuthenticated && authProvider.user != null) {
      debugPrint('[MainNavigation] ✅ User already authenticated, skipping check');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasToken = true;
        });
      }
      return;
    }
    
    // Check if token exists with retry
    bool hasToken = false;
    String? actualToken;
    
    for (int i = 0; i < 3; i++) {
      hasToken = await backendAuthService.isLoggedIn();
      if (hasToken) {
        actualToken = await backendAuthService.getToken();
        if (actualToken != null && actualToken.isNotEmpty) {
          debugPrint('[MainNavigation] ✅ Token verified: exists and retrievable, length: ${actualToken.length}');
          break;
        } else {
          debugPrint('[MainNavigation] ⚠️ isLoggedIn returned true but token is null, retrying...');
          hasToken = false;
        }
      }
      
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    if (mounted) {
      setState(() {
        _hasToken = hasToken;
      });
    }
    
    if (hasToken) {
      debugPrint('[MainNavigation] ✅ Token exists, allowing access');
      
      // Token exists - allow user to stay even if loading fails temporarily
      // Only redirect if we get a clear 401/Unauthorized error
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        debugPrint('[MainNavigation] Token exists but user not loaded, attempting to load user...');
        try {
          // Use timeout to prevent hanging
          await authProvider.loadUserFromToken().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[MainNavigation] ⚠️ User loading timeout - allowing user to stay (token exists)');
              // Don't throw - allow user to stay if token exists
            },
          );
          
          // Only redirect if we get a clear authentication error (401)
          if (!authProvider.isAuthenticated || authProvider.user == null) {
            debugPrint('[MainNavigation] User still not loaded after attempt, but token exists - allowing access');
            // Don't redirect immediately - allow user to stay if token exists
            // The app will work in offline mode or retry later
          } else {
            debugPrint('[MainNavigation] ✅ User loaded successfully: ${authProvider.user!.id}');
          }
        } catch (e) {
          debugPrint('[MainNavigation] Error loading user: $e');
          // Only redirect on clear auth errors (401), not on network errors
          if (e.toString().contains('401') || 
              e.toString().contains('Unauthorized') ||
              e.toString().contains('Invalid token')) {
            // Clear auth error - token is invalid
            debugPrint('[MainNavigation] ❌ Token is invalid (401), redirecting to login');
            if (mounted) {
              await authProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/auth',
                (route) => false,
              );
              return;
            }
          } else {
            // Network or other error - allow user to stay if token exists
            debugPrint('[MainNavigation] ⚠️ Network error but token exists - allowing user to stay');
          }
        }
      } else {
        debugPrint('[MainNavigation] ✅ User already authenticated: ${authProvider.user!.id}');
      }
      
      // Set user ID in MessageProvider for notification logic
      if (authProvider.user != null) {
        final messageProvider = Provider.of<MessageProvider>(context, listen: false);
        messageProvider.setCurrentUserId(authProvider.user!.id);
        debugPrint('[MainNavigation] ✅ User ID set in MessageProvider: ${authProvider.user!.id}');
        
        // Initialize notification provider
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.initialize();
        debugPrint('[MainNavigation] ✅ Notification provider initialized');
      }
    } else {
      // No token, redirect to login
      debugPrint('[MainNavigation] ❌ No token found after retries, redirecting to login');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    // Show loading while ensuring user is authenticated
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // If user is not authenticated after loading, check if token exists
    // If token exists, allow user to stay (might be network issue)
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      if (!_hasToken) {
        // No token - show loading (will redirect in _ensureUserLoaded)
        debugPrint('[MainNavigation] No token found in state - showing loading');
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      } else {
        // Token exists but user not loaded - might be network issue
        // Allow user to stay and try to use the app
        debugPrint('[MainNavigation] Token exists (state: $_hasToken) but user not loaded - allowing access');
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != _currentIndex && index < _screens.length) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTypography.labelSmall,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                    size: 24,
                  ),
                ),
                label: l10n.translate('home'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 1
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 1 ? Icons.category : Icons.category_outlined,
                    size: 24,
                  ),
                ),
                label: l10n.translate('categories'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 2
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 2 ? Icons.analytics : Icons.analytics_outlined,
                    size: 24,
                  ),
                ),
                label: l10n.translate('progress'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 3
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        _currentIndex == 3 ? Icons.chat : Icons.chat_bubble_outline,
                        size: 24,
                      ),
                      // Badge for unread messages can be added here
                    ],
                  ),
                ),
                label: l10n.translate('messages'),
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 4
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _currentIndex == 4 ? Icons.person : Icons.person_outline,
                    size: 24,
                  ),
                ),
                label: l10n.translate('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
