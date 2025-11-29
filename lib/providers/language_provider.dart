import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  List<Language> _availableLanguages = [];
  bool _isLoadingLanguages = false;
  String? _languagesError;

  Locale get locale => _locale;
  List<Language> get availableLanguages => _availableLanguages;
  bool get isLoadingLanguages => _isLoadingLanguages;
  String? get languagesError => _languagesError;

  final ApiService _apiService = ApiService();

  LanguageProvider() {
    _loadLanguage();
    _loadLanguages();
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> _loadLanguages() async {
    try {
      _isLoadingLanguages = true;
      _languagesError = null;
      notifyListeners();

      final response = await _apiService.getLanguages();
      
      if (response['success'] == true && response['data'] != null) {
        final languagesData = response['data'] as List<dynamic>;
        _availableLanguages = languagesData
            .where((lang) => lang is Map<String, dynamic>)
            .map((lang) => Language.fromJson(lang as Map<String, dynamic>))
            .where((lang) => lang.isActive) // Only include active languages
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)); // Sort by order

        // If current language is not in available languages, reset to first available or English
        if (_availableLanguages.isNotEmpty) {
          final currentLangCode = _locale.languageCode;
          final isCurrentLangAvailable = _availableLanguages
              .any((lang) => lang.code.toLowerCase() == currentLangCode.toLowerCase());
          
          if (!isCurrentLangAvailable) {
            // Try to find English first, otherwise use first available
            final englishLang = _availableLanguages
                .firstWhere((lang) => lang.code.toLowerCase() == 'en', orElse: () => _availableLanguages.first);
            await setLanguage(Locale(englishLang.code.toLowerCase()));
          }
        }
      } else {
        _languagesError = response['message'] ?? 'Failed to load languages';
        // Fallback to default languages if API fails
        _loadDefaultLanguages();
      }
    } catch (e) {
      _languagesError = e.toString();
      debugPrint('[LanguageProvider] Error loading languages: $e');
      // Fallback to default languages on error
      _loadDefaultLanguages();
    } finally {
      _isLoadingLanguages = false;
      notifyListeners();
    }
  }

  void _loadDefaultLanguages() {
    // Fallback default languages if API fails
    _availableLanguages = [
      Language(
        id: 'en',
        code: 'en',
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
        isActive: true,
        order: 0,
      ),
      Language(
        id: 'am',
        code: 'am',
        name: 'Amharic',
        nativeName: 'አማርኛ',
        flag: '🇪🇹',
        isActive: true,
        order: 1,
      ),
      Language(
        id: 'om',
        code: 'om',
        name: 'Afan Oromo',
        nativeName: 'Afaan Oromoo',
        flag: '🇪🇹',
        isActive: true,
        order: 2,
      ),
      Language(
        id: 'ti',
        code: 'ti',
        name: 'Tigrinya',
        nativeName: 'ትግርኛ',
        flag: '🇪🇷',
        isActive: true,
        order: 3,
      ),
      Language(
        id: 'ar',
        code: 'ar',
        name: 'Arabic',
        nativeName: 'العربية',
        flag: '🇸🇦',
        isActive: true,
        order: 4,
      ),
    ];
  }

  Future<void> refreshLanguages() async {
    await _loadLanguages();
  }

  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  Future<bool> isLanguageSelected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('language_code');
  }

  Language? getLanguageByCode(String code) {
    try {
      return _availableLanguages.firstWhere(
        (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

