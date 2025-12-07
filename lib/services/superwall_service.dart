import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SuperwallService {
  /// Set user identity in Superwall to connect subscriptions with Gmail
  static Future<void> setUserIdentity(User user) async {
    try {
      if (user.email == null) {
        print('⚠️ User email is null, cannot set Superwall identity');
        return;
      }

      // Set user identity in Superwall with email as the unique identifier
      await Superwall.shared.identify(user.email!);

      // Set additional user attributes for better targeting and analytics
      final userAttributes = <String, Object>{
        'email': user.email!,
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'emailVerified': user.emailVerified,
        'creationTime': user.metadata.creationTime?.toIso8601String() ?? '',
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String() ?? '',
        'platform': kIsWeb ? 'web' : 'mobile',
      };

      await Superwall.shared.setUserAttributes(userAttributes);

      print('✅ Superwall user identity set for: ${user.email}');
      print('📋 User attributes: $userAttributes');
    } catch (e) {
      print('❌ Failed to set Superwall user identity: $e');
    }
  }

  /// Clear user identity when user signs out
  static Future<void> clearUserIdentity() async {
    try {
      await Superwall.shared.reset();
      print('✅ Superwall user identity cleared');
    } catch (e) {
      print('❌ Failed to clear Superwall user identity: $e');
    }
  }

  /// Check if user has active subscription via Superwall
  static Future<bool> checkSubscriptionStatus() async {
    try {
      // For now, we'll use Superwall's delegate methods to check subscription
      // This would typically be handled through Superwall's subscription delegate
      print('📊 Checking Superwall subscription status...');

      // Note: Actual subscription status checking would be implemented
      // through Superwall's delegate callbacks and stored locally
      return false; // Default to false until Superwall confirms subscription
    } catch (e) {
      print('❌ Failed to check Superwall subscription status: $e');
      return false;
    }
  }

  /// Track custom events for better user analytics
  static Future<void> trackEvent(String eventName,
      {Map<String, Object>? parameters}) async {
    try {
      // Track events through Superwall for analytics
      // Note: Event tracking may be handled differently in your Superwall version
      print('📈 Would track Superwall event: $eventName');
      if (parameters != null) {
        print('📋 Event parameters: $parameters');
      }

      // If your Superwall version supports direct event tracking, use:
      // await Superwall.shared.track(eventName, parameters: parameters ?? {});
    } catch (e) {
      print('❌ Failed to track Superwall event: $e');
    }
  }
}
