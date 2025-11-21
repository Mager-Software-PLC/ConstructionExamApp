import 'package:flutter/material.dart';
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
    
    if (authProvider.isAuthenticated) {
      final hasValidSession = await _sessionService.hasValidSession();
      
      if (!hasValidSession && authProvider.currentUser == null) {
        // Session expired, logout user
        if (mounted) {
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

