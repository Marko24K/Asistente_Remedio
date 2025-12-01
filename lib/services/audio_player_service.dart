import 'package:flutter/services.dart';

class AudioPlayerService {
  static const platform = MethodChannel('com.example.asistente_remedio/audio');

  /// Reproducir un sonido desde assets/sounds/
  static Future<void> playSound(String soundName) async {
    try {
      print('🔊 Reproduciendo sonido: $soundName');
      await platform.invokeMethod('playSound', {'soundName': soundName});
      print('✅ Sonido reproducido: $soundName');
    } catch (e) {
      print('❌ Error reproduciendo sonido: $e');
    }
  }
}
