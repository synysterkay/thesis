import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPersistenceService {
  static const String _keyUserEmail = 'user_email';
  static const String _keyWebSubscriptionStatus = 'web_subscription_status';
  static const String _keyLastLoginDate = 'last_login_date';

  /// Save user information for persistence
  static Future<void> saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, user.email ?? '');
    await prefs.setString(_keyLastLoginDate, DateTime.now().toIso8601String());

    // Note: Web subscription status is only set after successful Stripe payment
    // in markWebUserSubscribed(), not during authentication
  }

  /// Check if user has a saved session
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_keyUserEmail);
      final lastLogin = prefs.getString(_keyLastLoginDate);

      if (email == null || email.isEmpty || lastLogin == null) {
        return false;
      }

      // Check if login was within the last 30 days
      try {
        final loginDate = DateTime.parse(lastLogin);
        final daysSinceLogin = DateTime.now().difference(loginDate).inDays;
        return daysSinceLogin <= 30;
      } catch (e) {
        return false;
      }
    } catch (e) {
      print('Error checking valid session: $e');
      // On mobile browsers, SharedPreferences might have issues
      return false;
    }
  }

  /// Get saved user email
  static Future<String?> getSavedUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Check web subscription status (for web platform only)
  static Future<bool> isWebUserSubscribed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyWebSubscriptionStatus) ?? false;
    } catch (e) {
      print('Error checking web subscription status: $e');
      // On mobile browsers, SharedPreferences might have issues
      // Return false as fallback
      return false;
    }
  }

  /// Mark web user as subscribed after Stripe payment
  static Future<void> markWebUserSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWebSubscriptionStatus, true);
  }

  /// Clear web subscription status when subscription expires/fails
  static Future<void> clearWebSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWebSubscriptionStatus);
  }

  /// Clear user session (for logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyWebSubscriptionStatus);
    await prefs.remove(_keyLastLoginDate);
  }

  /// Update last login date
  static Future<void> updateLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLoginDate, DateTime.now().toIso8601String());
  }
}
