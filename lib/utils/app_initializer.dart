import 'package:shared_preferences/shared_preferences.dart';

class AppInitializer {
  static const String _firstLaunchKey = 'first_launch';
  static const String _languageSelectedKey = 'language_selected';

  static Future<bool> isFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) != false;
  }

  static Future<void> setFirstLaunchComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  static Future<bool> isLanguageSelected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  static Future<void> setLanguageSelected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageSelectedKey, true);
  }
}

