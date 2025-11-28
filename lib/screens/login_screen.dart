import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_initializer.dart';
import '../theme/app_theme.dart';
import '../services/screenshot_protection_service.dart';
import '../config/app_config.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Enable screenshot protection for login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenshotProtectionService().enableProtection();
    });
  }

  @override
  void dispose() {
    // Disable screenshot protection when leaving login screen
    ScreenshotProtectionService().disableProtection();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Initialize Google Sign-In
      // Note: On Android, you can use clientId OR rely on google-services.json
      // Using clientId explicitly gives more control
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: AppConfig.googleClientId,
        // On Android, serverClientId is also used for getting idToken
        serverClientId: AppConfig.googleClientId,
      );

      debugPrint('[Login] Attempting Google sign-in...');
      
      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint('[Login] User cancelled Google sign-in');
        return;
      }

      debugPrint('[Login] Google sign-in successful, getting authentication token...');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('[Login] ❌ Failed to get Google ID token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get Google authentication token. Please check your Google Sign-In configuration.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      debugPrint('[Login] ✅ Google ID token obtained, length: ${googleAuth.idToken!.length}');

      // Sign in with Google via backend
      final success = await authProvider.googleSignIn(googleAuth.idToken!);

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (authProvider.isAuthenticated && authProvider.user != null) {
          await AppInitializer.setLanguageSelected();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          debugPrint('[Login] User not loaded after Google sign-in, attempting to load...');
          try {
            await authProvider.loadUserFromToken();
            if (authProvider.isAuthenticated && authProvider.user != null && mounted) {
              await AppInitializer.setLanguageSelected();
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google sign-in successful but failed to load user data. Please try again.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            debugPrint('[Login] Error loading user after Google sign-in: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Google sign-in successful but failed to load user data: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else if (mounted) {
        final errorMsg = authProvider.errorMessage ?? 'Google sign-in failed';
        debugPrint('[Login] ❌ Google sign-in failed: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Login] ❌ Google sign-in exception: $e');
      debugPrint('[Login] Exception type: ${e.runtimeType}');
      if (mounted) {
        String errorMessage = 'Google sign-in failed';
        
        // Provide more helpful error messages
        if (e.toString().contains('10:') || e.toString().contains('DEVELOPER_ERROR')) {
          errorMessage = 'Google Sign-In configuration error. Please check:\n'
              '1. SHA-1 fingerprint is configured in Google Cloud Console\n'
              '2. Package name matches: com.constructionexamapp\n'
              '3. OAuth client ID is correct';
        } else if (e.toString().contains('network') || e.toString().contains('Internet')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Google sign-in failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        emailOrPhone: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (authProvider.isAuthenticated && authProvider.user != null) {
          await AppInitializer.setLanguageSelected();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          debugPrint('[Login] User not loaded after login, attempting to load...');
          try {
            await authProvider.loadUserFromToken();
            if (authProvider.isAuthenticated && authProvider.user != null && mounted) {
              await AppInitializer.setLanguageSelected();
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login successful but failed to load user data. Please try again.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            debugPrint('[Login] Error loading user after login: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login successful but failed to load user data: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo/Icon Section
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              colorBlendMode: BlendMode.dstOver,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.construction_rounded,
                                  size: 64,
                                  color: theme.colorScheme.primary,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            l10n.translate('app_name'),
                            style: AppTypography.displaySmall.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.translate('sign_in_to_continue'),
                            style: AppTypography.bodyLarge.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.bodyLarge,
                        decoration: InputDecoration(
                          labelText: l10n.translate('email_address'),
                          hintText: l10n.translate('email_address'),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.translate('email');
                          }
                          if (!value.contains('@')) {
                            return l10n.translate('email');
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.bodyLarge,
                        decoration: InputDecoration(
                          labelText: l10n.translate('password'),
                          hintText: l10n.translate('password'),
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.translate('password');
                          }
                          if (value.length < 6) {
                            return l10n.translate('password');
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Remember Me & Forgot Password
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _rememberMe
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _rememberMe
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.translate('remember_me'),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            l10n.translate('forgot_password'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Google Sign-In Button
                 
                    const SizedBox(height: 24),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: AppTypography.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n.translate('sign_in'),
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.translate('dont_have_account'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            l10n.translate('sign_up'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                       Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.g_mobiledata,
                                        size: 24,
                                        color: theme.colorScheme.primary,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
