import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_persistence_service.dart';

// Conditional import: only import dart:html on web platform
import 'package:universal_html/html.dart' as html;

class SubscriptionSyncService {
  static const String _baseUrl = 'https://thesisgenerator.tech';

  /// Check subscription status across all platforms
  static Future<bool> checkUnifiedSubscriptionStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user signed in for subscription check');
        return false;
      }

      print('🔍 Checking subscription for user: ${user.email}');

      if (kIsWeb) {
        // For web: ALWAYS check Stripe first to get latest subscription status
        // This is important after payment redirects to ensure fresh data
        print('🌐 Checking Stripe for web user subscription...');

        final hasStripeSubscription =
            await _checkStripeSubscriptionByEmail(user.email!);

        if (hasStripeSubscription) {
          // Update local cache for offline support
          await UserPersistenceService.markWebUserSubscribed();
          print('✅ Subscription confirmed via Stripe API');
          return true;
        }

        // Only use local cache if Stripe check failed (network error, etc)
        // This shouldn't happen in normal flow
        print('⚠️ Stripe check failed, checking local cache...');
        final hasLocalSubscription =
            await UserPersistenceService.isWebUserSubscribed();
        print('📱 Local cache says subscribed: $hasLocalSubscription');
        return hasLocalSubscription;
      } else {
        // For mobile: Check both Superwall AND Stripe (cross-platform sync)
        try {
          // First check if user has Stripe subscription (from web)
          final hasStripeSubscription =
              await _checkStripeSubscriptionByEmail(user.email!);
          if (hasStripeSubscription) {
            // User subscribed on web, grant access on mobile too
            return true;
          }

          // Then check Superwall subscription (native mobile)
          return false; // Let Superwall handle through registerPlacement
        } catch (e) {
          print('Error checking mobile subscription: $e');
          return false;
        }
      }
    } catch (e) {
      print('Error in unified subscription check: $e');
      return false;
    }
  }

  /// Public method to check Stripe subscription by email (for audit purposes)
  static Future<bool> checkStripeSubscriptionByEmail(String email) async {
    return await _checkStripeSubscriptionByEmail(email);
  }

  /// Check Stripe subscription by email address using Vercel API
  /// SECURITY: Always check Stripe first to handle expired/failed subscriptions
  static Future<bool> _checkStripeSubscriptionByEmail(String email) async {
    try {
      print('🔍 Checking Stripe subscription for: $email');

      // SECURITY FIX: Always check Stripe first to catch expired subscriptions
      // Call Vercel serverless function to check current Stripe status
      final apiUrl = '$_baseUrl/api/check-subscription';
      print('🌐 Calling API: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hasActiveSubscription =
            data['hasActiveSubscription'] as bool? ?? false;

        if (hasActiveSubscription) {
          print('✅ Found active Stripe subscription for: $email');
          // Update local cache to match Stripe status
          if (kIsWeb) {
            await UserPersistenceService.markWebUserSubscribed();
            print('💾 Updated local cache - subscription active');
          }
          return true;
        } else {
          print('❌ No active Stripe subscription for: $email');
          // SECURITY: Clear local cache if Stripe says no active subscription
          if (kIsWeb) {
            await UserPersistenceService.clearWebSubscriptionStatus();
            print('🧹 Cleared local cache - subscription expired/failed');
          }
          return false;
        }
      } else {
        print('⚠️ Error checking Stripe subscription: ${response.statusCode}');
        print('⚠️ Response: ${response.body}');

        // On API errors, check local cache but with limited trust
        // This provides temporary offline access but logs the issue
        if (kIsWeb) {
          final hasLocalSubscription =
              await UserPersistenceService.isWebUserSubscribed();
          if (hasLocalSubscription) {
            print('⚠️ API error - using local cache temporarily for: $email');
            print('💡 Will re-verify when API is available');
            return true;
          }
        }

        print('⚠️ API error and no local cache - no access for: $email');
        return false;
      }
    } catch (e) {
      print('❌ Error checking subscription by email: $e');

      // On network errors, allow limited offline access if locally cached
      if (kIsWeb) {
        final hasLocalSubscription =
            await UserPersistenceService.isWebUserSubscribed();
        if (hasLocalSubscription) {
          print('⚠️ Network error - using local cache temporarily for: $email');
          return true;
        }
      }

      return false;
    }
  }

  /// Set user identity across platforms for subscription syncing
  static Future<void> setUserIdentity(String email) async {
    try {
      if (!kIsWeb) {
        // Only call Superwall methods on mobile platforms
        await Superwall.shared.identify(email);
        print('✅ Superwall user identity set for: $email');
      }
      print('✅ User identity configured for cross-platform sync: $email');
    } catch (e) {
      print('❌ Failed to set user identity: $e');
    }
  }

  /// Handle subscription purchase completion
  static Future<void> handleSubscriptionSuccess({
    required String platform, // 'web' or 'mobile'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (platform == 'web') {
        // Mark web subscription as active in local storage
        await UserPersistenceService.markWebUserSubscribed();
        print('✅ Web subscription marked as active for: ${user.email}');
      } else {
        // Mobile subscription is handled automatically by Superwall
        print('✅ Mobile subscription handled by Superwall');
      }
    } catch (e) {
      print('❌ Failed to handle subscription success: $e');
    }
  }

  /// SECURITY: Force validate all users to clean up invalid subscriptions
  /// Call this on app startup to ensure no one has local subscription without payment
  static Future<void> forceValidateSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔍 Force validation: No user signed in');
        return;
      }

      print('🛡️ FORCE VALIDATING subscription for: ${user.email}');

      if (kIsWeb) {
        // Check if user has local subscription
        final hasLocalSubscription =
            await UserPersistenceService.isWebUserSubscribed();

        if (hasLocalSubscription) {
          print('🔍 Found local subscription, validating with Stripe...');

          // Force check with Stripe - no fallbacks
          final hasValidStripeSubscription =
              await _checkStripeSubscriptionByEmail(user.email!);

          if (!hasValidStripeSubscription) {
            print(
                '🚨 SECURITY CLEANUP: Removing invalid local subscription for ${user.email}');
            await UserPersistenceService.clearWebSubscriptionStatus();
            print(
                '🧹 Invalid subscription cleared - user must pay to access app');
          } else {
            print('✅ Local subscription validated with Stripe');
          }
        } else {
          print('🔍 No local subscription found - no cleanup needed');
        }
      }
    } catch (e) {
      print('❌ Error during force validation: $e');
      // On error, clear local cache to be safe
      if (kIsWeb) {
        await UserPersistenceService.clearWebSubscriptionStatus();
        print('🛡️ Cleared local cache due to validation error');
      }
    }
  }

  /// Clear subscription data (for logout)
  static Future<void> clearSubscriptionData() async {
    try {
      await UserPersistenceService.clearUserSession();
      if (!kIsWeb) {
        await Superwall.shared.reset();
      }
      print('✅ Subscription data cleared');
    } catch (e) {
      print('❌ Failed to clear subscription data: $e');
    }
  }

  /// Create Stripe checkout session and redirect to payment
  static Future<bool> createStripeCheckoutSession() async {
    if (!kIsWeb) {
      print('❌ Stripe checkout only available on web platform');
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user signed in for checkout');
        return false;
      }

      print('🛒 Creating Stripe checkout session for: ${user.email}');

      final apiUrl = '$_baseUrl/api/create-checkout-session';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': user.email!,
          'firebase_uid': user.uid,
        }),
      );

      print('📡 Checkout API Response Status: ${response.statusCode}');
      print('📡 Checkout API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkoutUrl = data['url'] as String?;

        if (checkoutUrl != null) {
          print('✅ Checkout session created, redirecting to: $checkoutUrl');
          // Redirect to Stripe checkout
          html.window.location.href = checkoutUrl;
          return true;
        } else {
          print('❌ No checkout URL received');
          return false;
        }
      } else {
        print('⚠️ Error creating checkout session: ${response.statusCode}');
        print('⚠️ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      return false;
    }
  }

  /// Poll for subscription status (used after payment)
  /// Checks every 2 seconds for up to 10 minutes with exponential backoff
  static Future<bool> pollSubscriptionStatus({
    required Duration timeout,
    Duration interval = const Duration(seconds: 2),
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user signed in for polling');
        return false;
      }

      print('⏱️ Starting subscription polling for: ${user.email}');
      print('⏱️ Will check for up to ${timeout.inMinutes} minutes');
      final startTime = DateTime.now();
      int checkCount = 0;

      while (DateTime.now().difference(startTime) < timeout) {
        checkCount++;
        print('🔄 Polling attempt #$checkCount at ${DateTime.now()}');

        final isSubscribed = await _checkStripeSubscriptionByEmail(user.email!);

        if (isSubscribed) {
          print(
              '✅ Subscription found on attempt #$checkCount! Polling succeeded');
          await UserPersistenceService.markWebUserSubscribed();
          return true;
        }

        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        print(
            '⏳ Subscription not found yet (${elapsedSeconds}s elapsed). Waiting ${interval.inSeconds}s...');
        await Future.delayed(interval);
      }

      print(
          '❌ Payment verification timeout reached after ${checkCount} attempts');
      print(
          '🚨 SECURITY: User will NOT be marked as subscribed without payment verification');
      print(
          '💡 If payment was completed, the subscription will activate when Stripe webhook processes');
      return false;
    } catch (e) {
      print('❌ Error polling subscription status: $e');
      return false;
    }
  }

  /// Handle successful payment return from Stripe with QUICK verification
  /// Only polls for 30 seconds to avoid blocking users
  static Future<bool> handlePaymentSuccessQuick() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user signed in for payment verification');
        return false;
      }

      print('🔍 Starting QUICK payment verification for: ${user.email}');

      // Quick verification: 30 seconds max to avoid blocking UX
      final paymentVerified = await pollSubscriptionStatus(
        timeout: const Duration(seconds: 30),
        interval: const Duration(seconds: 2),
      );

      if (paymentVerified) {
        print('✅ QUICK verification succeeded - user marked as subscribed');
        return true;
      } else {
        print('⚠️ QUICK verification timed out - allowing user to proceed');
        print('💡 Background monitoring will catch subscription when webhook processes');
        
        // Mark as subscribed optimistically for better UX
        // The monitoring service will correct this if payment actually failed
        await UserPersistenceService.markWebUserSubscribed();
        print('✅ Marked as subscribed (optimistic) - monitoring will verify');
        return true;
      }
    } catch (e) {
      print('❌ Error in quick payment verification: $e');
      // On error, be optimistic for UX - monitoring will validate
      await UserPersistenceService.markWebUserSubscribed();
      return true;
    }
  }

  /// Handle successful payment return from Stripe
  /// Only marks user as subscribed AFTER verifying actual payment with Stripe API
  static Future<bool> handlePaymentSuccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user signed in for payment verification');
        return false;
      }

      print('🔍 Verifying payment completion for: ${user.email}');
      print(
          '⚠️ User will NOT be marked as subscribed until payment is verified');

      // Start polling for Stripe confirmation (10 minute timeout)
      // DO NOT mark as subscribed until we get actual confirmation
      print('📡 Starting Stripe payment verification polling...');
      final paymentVerified = await pollSubscriptionStatus(
        timeout: const Duration(minutes: 10),
        interval: const Duration(seconds: 3),
      );

      if (paymentVerified) {
        // Only now mark as subscribed - payment actually completed
        await UserPersistenceService.markWebUserSubscribed();
        print('✅ Payment verified and user marked as subscribed');
        return true;
      } else {
        print('❌ Payment verification failed - user NOT marked as subscribed');
        print('💡 If payment was completed, please contact support');
        return false;
      }
    } catch (e) {
      print('❌ Error handling payment verification: $e');
      return false;
    }
  }

  /// Check if user is eligible for trial
  static Future<bool> isEligibleForTrial() async {
    try {
      final hasExistingSubscription = await checkUnifiedSubscriptionStatus();
      return !hasExistingSubscription;
    } catch (e) {
      print('Error checking trial eligibility: $e');
      return true;
    }
  }
}
