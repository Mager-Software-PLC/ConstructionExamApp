import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/session_service.dart';

class SessionManager extends StatefulWidget {
  final Widget child;

  const SessionManager({super.key, required this.child});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _checkSessionPeriodically();
  }

  void _checkSessionPeriodically() {
    // Check session every 10 minutes
    Future.delayed(const Duration(minutes: 10), () {
      if (mounted) {
        _verifySession();
        _checkSessionPeriodically();
      }
    });
  }

  Future<void> _verifySession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated OR if token exists (user might be loading)
    final isAuthenticated = authProvider.isAuthenticated;
    
    if (isAuthenticated) {
      final hasValidSession = await _sessionService.hasValidSession();
      
      // Only logout if session is invalid AND user is null (not just loading)
      if (!hasValidSession && authProvider.user == null) {
        // Try to load user one more time before logging out
        try {
          await authProvider.loadUserFromToken();
          // If still no user after loading, then logout
          if (authProvider.user == null && mounted) {
            await authProvider.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/auth',
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your session has expired. Please login again.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            // User loaded successfully, refresh session
            await _sessionService.refreshSession();
          }
        } catch (e) {
          // Error loading user - might be network issue, don't logout yet
          debugPrint('[SessionManager] Error loading user: $e');
          // Only logout if it's clearly an auth error
          if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
            if (mounted) {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth',
                  (route) => false,
                );
              }
            }
          }
        }
      } else {
        // Refresh session timestamp
        await _sessionService.refreshSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

