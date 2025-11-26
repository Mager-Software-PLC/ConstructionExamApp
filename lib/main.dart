import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/question_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/message_provider.dart';
import 'providers/category_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/app_initializer.dart';
import 'widgets/session_manager.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/session_service.dart';
import 'services/backend_auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service (local notifications only)
  await NotificationService().initialize();
  
  // Initialize sound service
  await SoundService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, _) {
          return MaterialApp(
            themeMode: themeProvider.themeMode,
            title: 'Construction Exam App',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('am', ''),
              Locale('om', ''),
              Locale('ti', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
            onGenerateRoute: (RouteSettings settings) {
              WidgetBuilder? builder;
              switch (settings.name) {
                case '/language':
                  builder = (context) => const LanguageSelectionScreen();
                  break;
                case '/auth':
                  builder = (context) => const LoginScreen();
                  break;
                case '/home':
                  builder = (context) => const SessionManager(
                        child: MainNavigation(),
                      );
                  break;
                default:
                  return null;
              }

              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) => builder!(context),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 0.1);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 250),
              );
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Minimal delay for UI smoothness
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionService = SessionService();
    final backendAuthService = BackendAuthService();
    
    // Check if token exists in persistent storage
    final hasToken = await backendAuthService.isLoggedIn();
    
    if (hasToken) {
      debugPrint('Token found in storage, attempting auto-login...');
      try {
        // Wait for AuthProvider to initialize
        await authProvider.waitForInitialization().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('AuthProvider initialization timeout - continuing');
          },
        );
        
        // Try to load user from token
        await authProvider.loadUserFromToken();
        if (authProvider.isAuthenticated && authProvider.user != null && mounted) {
          debugPrint('Auto-login successful: ${authProvider.user!.id}');
          await AppInitializer.setLanguageSelected();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
          return;
        } else {
          // Token is invalid, clear it
          debugPrint('Token invalid, clearing storage');
          await backendAuthService.logout();
        }
      } catch (e) {
        debugPrint('Auto-login failed: $e');
        // Clear invalid token
        await backendAuthService.logout();
      }
    }
    
    // Wait for AuthProvider to initialize
    try {
      await authProvider.waitForInitialization().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('AuthProvider initialization timeout - continuing');
        },
      );
    } catch (e) {
      debugPrint('Error waiting for initialization: $e');
    }
    
    // Check if user is authenticated after initialization
    if (authProvider.isAuthenticated && authProvider.user != null) {
      debugPrint('User authenticated: ${authProvider.user!.id}');
      if (mounted) {
        await authProvider.refreshSession();
        await AppInitializer.setLanguageSelected();
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }
    
    // Check saved session
    final savedSessionId = await sessionService.getSession();
    if (savedSessionId != null) {
      debugPrint('Found saved session: $savedSessionId');
      try {
        await authProvider.loadUserFromSession(savedSessionId);
        if (authProvider.isAuthenticated && authProvider.user != null && mounted) {
          await authProvider.refreshSession();
          await AppInitializer.setLanguageSelected();
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        }
      } catch (e) {
        debugPrint('Failed to load user from saved session: $e');
      }
    }
    
    // User is not authenticated - check if language selection is needed
    if (!mounted) return;
    
    final isFirstLaunch = await AppInitializer.isFirstLaunch();
    final isLanguageSelected = await AppInitializer.isLanguageSelected();
    
    if (isFirstLaunch || !isLanguageSelected) {
      // First launch - show language selection
      await AppInitializer.setFirstLaunchComplete();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/language');
      }
    } else {
      // Language already selected, show login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.construction,
                  size: 80,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Construction Exam',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
