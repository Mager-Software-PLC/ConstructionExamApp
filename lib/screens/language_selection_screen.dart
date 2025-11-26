import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_initializer.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
      {'code': 'am', 'name': 'Amharic', 'flag': '🇪🇹', 'native': 'አማርኛ'},
      {'code': 'om', 'name': 'Afan Oromo', 'flag': '🇪🇹', 'native': 'Afaan Oromoo'},
      {'code': 'ti', 'name': 'Tigrinya', 'flag': '🇪🇷', 'native': 'ትግርኛ'},
      {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.language,
                  size: 80,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.translate('select_language'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'اختر اللغة | ቋንቋ ይምረጡ | Afaan Filadhu | ቋንቋ ምረጽ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),
                ...languages.map((lang) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 8,
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await languageProvider.setLanguage(Locale(lang['code']!));
                        // Mark language as selected
                        await AppInitializer.setLanguageSelected();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang['name']!,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang['native']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

