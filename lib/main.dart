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
import 'services/socket_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service (local notifications only)
  await NotificationService().initialize();
  
  // Initialize sound service
  await SoundService().initialize();
  
  // Small delay to ensure Flutter Secure Storage is ready
  await Future.delayed(const Duration(milliseconds: 100));
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Import socket service
    final socketService = SocketService();
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - reconnect socket if needed
      debugPrint('📱 App resumed - checking socket connection...');
      if (!socketService.isConnected && !socketService.isConnecting) {
        debugPrint('🔄 Reconnecting socket after app resume...');
        socketService.enableReconnection();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background - socket will auto-reconnect when needed
      debugPrint('📱 App paused');
    }
  }

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
    // Longer delay to ensure Flutter Secure Storage is fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionService = SessionService();
    final backendAuthService = BackendAuthService();
    
    // Check if token exists in persistent storage (most reliable check)
    // Try multiple times with longer delays to ensure we get the correct result
    bool hasToken = false;
    String? actualToken;
    
    for (int i = 0; i < 5; i++) {
      hasToken = await backendAuthService.isLoggedIn();
      if (hasToken) {
        // Also verify we can actually get the token value
        actualToken = await backendAuthService.getToken();
        if (actualToken != null && actualToken.isNotEmpty) {
          debugPrint('[Splash] ✅ Token verified: exists and retrievable, length: ${actualToken.length}');
          break;
        } else {
          debugPrint('[Splash] ⚠️ isLoggedIn returned true but token is null/empty, retrying...');
          hasToken = false;
        }
      }
      
      if (i < 4) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    debugPrint('[Splash] Token check result: $hasToken (token length: ${actualToken?.length ?? 0})');
    
    // Wait for AuthProvider to initialize (with reasonable timeout)
    try {
      await authProvider.waitForInitialization().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[Splash] AuthProvider initialization timeout - continuing with token check');
        },
      );
    } catch (e) {
      debugPrint('[Splash] Error waiting for initialization: $e');
    }
    
    // If token exists, try to load user first before navigating
    if (hasToken) {
      debugPrint('[Splash] ✅ Token found - loading user...');
      
      // Try to load user if not already loaded
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        debugPrint('[Splash] User not loaded yet, attempting to load...');
        try {
          // Try to load user with timeout
          await authProvider.loadUserFromToken().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('[Splash] User loading timeout - checking if token is still valid');
              // Don't navigate if user loading times out - might be network issue
              // But also don't block forever - let MainNavigation handle it
            },
          );
          
          // Check if user was loaded successfully
          if (!authProvider.isAuthenticated || authProvider.user == null) {
            debugPrint('[Splash] User not loaded after attempt - but token exists, allowing navigation');
            // Token exists but user not loaded - might be network issue
            // Navigate anyway - MainNavigation will allow access if token exists
          } else {
            debugPrint('[Splash] ✅ User loaded successfully: ${authProvider.user!.id}');
          }
        } catch (e) {
          debugPrint('[Splash] Error loading user: $e');
          // Check if it's an auth error (401) - clear token and go to login
          if (e.toString().contains('401') || 
              e.toString().contains('Unauthorized') ||
              e.toString().contains('Invalid token')) {
            debugPrint('[Splash] Token is invalid (401), clearing and going to login');
            await backendAuthService.logout();
            await authProvider.logout();
            if (mounted) {
              await AppInitializer.setLanguageSelected();
              Navigator.of(context).pushReplacementNamed('/auth');
            }
            return;
          }
          // For other errors (network, etc.), still navigate - MainNavigation will handle
        }
      } else {
        debugPrint('[Splash] ✅ User already loaded: ${authProvider.user!.id}');
      }
      
      // Navigate to home - MainNavigation will ensure user is authenticated
      await AppInitializer.setLanguageSelected();
      if (mounted) {
        debugPrint('[Splash] ✅ Navigating to home screen (token exists: $hasToken, token length: ${actualToken?.length ?? 0})');
        // Ensure navigation happens
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
      return;
    }
    
    // No token found - check if user is authenticated (shouldn't happen, but check anyway)
    if (authProvider.isAuthenticated && authProvider.user != null) {
      debugPrint('[Splash] ✅ User authenticated but no token - checking token again...');
      // Double-check token one more time
      final finalTokenCheck = await backendAuthService.isLoggedIn();
      if (finalTokenCheck) {
        debugPrint('[Splash] ✅ Token found on final check, navigating to home');
        if (mounted) {
          await AppInitializer.setLanguageSelected();
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }
      debugPrint('[Splash] ⚠️ User authenticated but no token found, will show login');
    }
    
    // Check saved session as last resort (only if no token)
    if (!hasToken) {
      final savedSessionId = await sessionService.getSession();
      if (savedSessionId != null) {
        debugPrint('[Splash] Found saved session: $savedSessionId, attempting to load user...');
        try {
          await authProvider.loadUserFromSession(savedSessionId);
          if (authProvider.isAuthenticated && authProvider.user != null && mounted) {
            debugPrint('[Splash] ✅ User authenticated from session: ${authProvider.user!.id}');
            // Verify token was created/restored
            final tokenAfterSession = await backendAuthService.isLoggedIn();
            if (tokenAfterSession) {
              await AppInitializer.setLanguageSelected();
              Navigator.of(context).pushReplacementNamed('/home');
              return;
            } else {
              debugPrint('[Splash] ⚠️ User loaded from session but no token, will show login');
            }
          }
        } catch (e) {
          debugPrint('[Splash] Failed to load user from saved session: $e');
        }
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
        debugPrint('[Splash] No valid authentication, showing login screen');
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
