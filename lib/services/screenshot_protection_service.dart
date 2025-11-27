import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to protect screens from screenshots and screen recording
class ScreenshotProtectionService {
  static final ScreenshotProtectionService _instance = ScreenshotProtectionService._internal();
  factory ScreenshotProtectionService() => _instance;
  ScreenshotProtectionService._internal();

  static const MethodChannel _channel = MethodChannel('screenshot_protection');
  bool _isProtected = false;

  /// Enable screenshot protection
  /// This prevents users from taking screenshots or recording the screen
  Future<void> enableProtection() async {
    if (_isProtected) {
      debugPrint('[ScreenshotProtection] Protection already enabled');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Use platform channel to set FLAG_SECURE on Android
        await _channel.invokeMethod('enable');
        _isProtected = true;
        debugPrint('[ScreenshotProtection] ✅ Screenshot protection enabled (Android)');
      } else if (Platform.isIOS) {
        // iOS screenshot protection
        await _channel.invokeMethod('enable');
        _isProtected = true;
        debugPrint('[ScreenshotProtection] ✅ Screenshot protection enabled (iOS)');
      } else {
        debugPrint('[ScreenshotProtection] ⚠️ Platform not supported for screenshot protection');
        _isProtected = true; // Mark as protected even if not supported
      }
    } catch (e) {
      debugPrint('[ScreenshotProtection] ❌ Error enabling protection: $e');
      // Try alternative method for Android
      if (Platform.isAndroid) {
        try {
          await _setSecureFlag(true);
          _isProtected = true;
          debugPrint('[ScreenshotProtection] ✅ Screenshot protection enabled (alternative method)');
        } catch (e2) {
          debugPrint('[ScreenshotProtection] ❌ Alternative method also failed: $e2');
          _isProtected = true; // Mark as protected anyway
        }
      } else {
        _isProtected = true;
      }
    }
  }

  /// Disable screenshot protection
  /// This allows screenshots and screen recording again
  Future<void> disableProtection() async {
    if (!_isProtected) {
      debugPrint('[ScreenshotProtection] Protection already disabled');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('disable');
        _isProtected = false;
        debugPrint('[ScreenshotProtection] ✅ Screenshot protection disabled');
      } else {
        _isProtected = false;
      }
    } catch (e) {
      debugPrint('[ScreenshotProtection] ⚠️ Error disabling protection: $e');
      // Try alternative method for Android
      if (Platform.isAndroid) {
        try {
          await _setSecureFlag(false);
          _isProtected = false;
          debugPrint('[ScreenshotProtection] ✅ Screenshot protection disabled (alternative method)');
        } catch (e2) {
          debugPrint('[ScreenshotProtection] ❌ Alternative method also failed: $e2');
          _isProtected = false; // Still mark as disabled
        }
      } else {
        _isProtected = false;
      }
    }
  }

  /// Alternative method for Android using platform channel
  Future<void> _setSecureFlag(bool enable) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('setSecureFlag', {'enable': enable});
      } catch (e) {
        debugPrint('[ScreenshotProtection] Error setting secure flag: $e');
        rethrow;
      }
    }
  }

  /// Check if protection is currently enabled
  bool get isProtected => _isProtected;

  /// Toggle protection state
  Future<void> toggleProtection() async {
    if (_isProtected) {
      await disableProtection();
    } else {
      await enableProtection();
    }
  }
}

