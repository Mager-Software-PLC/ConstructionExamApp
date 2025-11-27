import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/progress_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/screenshot_protection_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'certificate_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storageService = StorageService();
  bool _isEditing = false;
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Enable screenshot protection for profile screen (contains personal info)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenshotProtectionService().enableProtection();
    });
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _fullNameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    // Disable screenshot protection when leaving profile screen
    ScreenshotProtectionService().disableProtection();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _storageService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      final apiService = ApiService();
      
      // Upload profile image first if selected
      if (_selectedImage != null) {
        try {
          debugPrint('[Profile] Uploading profile image...');
          final uploadResult = await apiService.uploadProfileImage(_selectedImage!);
          if (uploadResult['success'] == true) {
            debugPrint('[Profile] ✅ Profile image uploaded successfully');
          } else {
            throw Exception(uploadResult['message'] ?? 'Failed to upload profile image');
          }
        } catch (e) {
          debugPrint('[Profile] ❌ Error uploading profile image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue with profile update even if image upload fails
        }
      }

      // Update profile information
      final result = await apiService.updateProfile({
        'name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (result['success'] == true && result['data'] != null) {
        // Refresh user data to get updated avatar
        await authProvider.refreshSession();
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('profile_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      debugPrint('[Profile] ❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.translate('profile'),
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: l10n.translate('edit'),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                IconButton(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  tooltip: l10n.translate('save'),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(context, user),
                    const SizedBox(height: 32),
                    _buildProfileForm(context, user, l10n),
                    const SizedBox(height: 24),
                    _buildCertificateSection(context, user, l10n),
                    const SizedBox(height: 24),
                    _buildSettingsSection(context, l10n),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, l10n),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (user.avatar != null && user.avatar!.isNotEmpty
                        ? Image.network(
                            user.avatar!.startsWith('http') 
                                ? user.avatar! 
                                : '${ApiService.baseUrl}${user.avatar!}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(context),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : _buildDefaultAvatar(context)),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20),
                    color: Colors.white,
                    onPressed: _pickImage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, user, AppLocalizations l10n) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    labelText: l10n.translate('full_name'),
                    prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: !_isEditing,
                    fillColor: _isEditing ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  style: AppTypography.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.translate('phone'),
                    prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: !_isEditing,
                    fillColor: _isEditing ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  style: AppTypography.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.translate('email'),
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateSection(BuildContext context, user, AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<ProgressProvider>(context, listen: false).getProgressStats(),
      builder: (context, snapshot) {
        final progressData = snapshot.data;
        final overallProgress = progressData?['overallProgress'] ?? {};
        final attempted = overallProgress['totalAttempted'] ?? 0;
        final progressPercentage = (overallProgress['percentage'] ?? user.progress).toDouble();
        
        if (attempted > 0) {
          final canViewCertificate = progressPercentage >= 50.0;
          
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: canViewCertificate ? Colors.green.withOpacity(0.15) : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: canViewCertificate ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CertificateScreen(
                        user: user,
                        progressPercentage: progressPercentage,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: canViewCertificate 
                              ? Colors.green.withOpacity(0.05)
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.verified,
                          color: canViewCertificate ? Colors.green.withOpacity(0.7) : Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canViewCertificate 
                                  ? l10n.translate('certificate_ready')
                                  : l10n.translate('view_certificate'),
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: canViewCertificate ? Colors.green.withOpacity(0.7) : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.translate('tap_to_view_download'),
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: canViewCertificate ? Colors.green : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildLanguageCard(context, l10n),
        const SizedBox(height: 16),
        _buildThemeCard(context),
      ],
    );
  }

  Widget _buildLanguageCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          final currentLocale = languageProvider.locale;
          final languages = [
            {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
            {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'native': 'አማርኛ'},
            {'code': 'om', 'name': 'Afan Oromo', 'flag': '🇪🇹', 'native': 'Afaan Oromoo'},
            {'code': 'ti', 'name': 'Tigrinya', 'flag': '🇪🇷', 'native': 'ትግርኛ'},
            {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
          ];
          
          final currentLang = languages.firstWhere(
            (lang) => lang['code'] == currentLocale.languageCode,
            orElse: () => languages[0],
          );

          return ExpansionTile(
            leading: Text(currentLang['flag']!, style: const TextStyle(fontSize: 28)),
            title: Text(l10n.translate('language'), style: AppTypography.titleMedium),
            subtitle: Text(currentLang['name']!, style: AppTypography.bodySmall),
            children: languages.map((lang) {
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang['name']!, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(lang['native']!, style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
                value: lang['code']!,
                groupValue: currentLocale.languageCode,
                onChanged: (value) async {
                  if (value != null) {
                    await languageProvider.setLanguage(Locale(value));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.translate('language')} changed to ${lang['name']}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ExpansionTile(
            leading: Icon(
              themeProvider.themeMode == ThemeMode.system
                  ? Icons.brightness_auto
                  : themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Theme', style: AppTypography.titleMedium),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.system
                  ? 'Adaptive (System)'
                  : themeProvider.themeMode == ThemeMode.dark
                      ? 'Dark Mode'
                      : 'Light Mode',
              style: AppTypography.bodySmall,
            ),
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Adaptive (System)'),
                subtitle: const Text('Follows device theme'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        },
        icon: const Icon(Icons.logout),
        label: Text(l10n.translate('logout')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
