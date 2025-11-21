import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import 'home_screen.dart';
import 'questions_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminService().isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
      _buildScreensAndNavItems();
    });
  }

  void _buildScreensAndNavItems() {
    final l10n = AppLocalizations.of(context)!;
    


    if (_isAdmin) {
      // Admin users only see Admin and Profile tabs
      _screens = [
        const AdminDashboardScreen(),
        const ProfileScreen(),
      ];

      _navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          label: 'Admin', // TODO: Add to localization
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.translate('profile'),
        ),
      ];
    } else {
      // Regular users see all tabs
      _screens = [
        const HomeScreen(),
        const QuestionsScreen(),
        const ProgressScreen(),
        const ProfileScreen(),
      ];

      _navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.translate('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.quiz),
          label: l10n.translate('questions'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics),
          label: l10n.translate('progress'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.translate('profile'),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ensure screens and nav items are built
    if (_screens.isEmpty || _navItems.isEmpty) {
      _buildScreensAndNavItems();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _screens.isNotEmpty && _currentIndex < _screens.length
              ? _screens[_currentIndex]
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex && index < _screens.length) {
              setState(() {
                _currentIndex = index;
              });
              _animationController.reset();
              _animationController.forward();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _navItems,
        ),
      ),
    );
  }
}

