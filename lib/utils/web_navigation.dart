// web_navigation.dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Use universal_html which works on all platforms
import 'package:universal_html/html.dart' as html;

class WebNavigation {
  static void redirectToHome() {
    if (kIsWeb) {
      try {
        // This will only work on web platform
        html.window.location.href = '/';
      } catch (e) {
        // Fallback - this shouldn't happen but just in case
        print('Web navigation failed: $e');
      }
    }
  }
}
