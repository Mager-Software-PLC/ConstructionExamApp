import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isInitialized = false;
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;
  
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
    }
  }

  Future<void> playMessageSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Play a pleasant two-tone notification sound
      // First tone
      await SystemSound.play(SystemSoundType.alert);
      // Small delay
      await Future.delayed(const Duration(milliseconds: 100));
      // Second tone (using click for variation)
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Error playing message sound: $e');
    }
  }

  Future<void> playSendSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Use a lighter system sound for send confirmation
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Error playing send sound: $e');
    }
  }

  void dispose() {
    // No cleanup needed for SystemSound
  }
}

