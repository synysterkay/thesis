import 'package:flutter/services.dart';

class PlatformLanguageService {
  static const platform = MethodChannel('language_channel');

  static Future<void> setLanguage(String languageCode) async {
    try {
      await platform.invokeMethod('setLanguage', languageCode);
    } catch (e) {
      print('Failed to set platform language: $e');
    }
  }
}
