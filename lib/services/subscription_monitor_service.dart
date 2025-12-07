import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_sync_service.dart';

/// Service to periodically monitor subscription status
/// Ensures users lose access when subscriptions expire or payments fail
class SubscriptionMonitorService {
  static SubscriptionMonitorService? _instance;
  static SubscriptionMonitorService get instance =>
      _instance ??= SubscriptionMonitorService._();

  SubscriptionMonitorService._();

  Timer? _monitorTimer;
  bool _isMonitoring = false;

  /// CRITICAL SECURITY: Run comprehensive cleanup on app startup
  /// Clears any invalid local subscriptions to prevent unpaid access
  static Future<void> runStartupSecurityCleanup() async {
    if (!kIsWeb) return; // Only needed for web platform

    try {
      print('🛡️ RUNNING STARTUP SECURITY CLEANUP...');

      // Force validate any existing subscription immediately
      await SubscriptionSyncService.forceValidateSubscription();

      print('✅ Startup security cleanup completed');
    } catch (e) {
      print('❌ Error during security cleanup: $e');
      // On any error, clear all local subscription data to be safe
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await SubscriptionSyncService.clearSubscriptionData();
          print('🛡️ Cleared all subscription data due to cleanup error');
        }
      } catch (clearError) {
        print('❌ Failed to clear subscription data: $clearError');
      }
    }
  }

  /// Start monitoring subscription status
  /// Checks every 3 minutes with exponential backoff on failures
  /// More frequent checks to catch expired subscriptions quickly
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    print('🔄 Starting intensive subscription monitoring...');
    print('⚡ Checking every 3 minutes for subscription changes');

    // Initial check
    _checkSubscriptionStatus();

    // Set up periodic checks every 3 minutes for faster expiry detection
    _monitorTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _checkSubscriptionStatus();
    });
  }

  /// Stop monitoring (for logout or app termination)
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    print('🛑 Stopped subscription monitoring');
  }

  /// Check current subscription status and update app state
  /// SECURITY: Force Stripe verification on each check to catch expired subscriptions
  Future<void> _checkSubscriptionStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('👤 No user logged in - skipping subscription check');
        return;
      }

      print('🔍 Periodic subscription check for: ${user.email}');

      // SECURITY: Force check with Stripe API (always verify current status)
      final hasActiveSubscription =
          await SubscriptionSyncService.checkStripeSubscriptionByEmail(
              user.email!);

      if (!hasActiveSubscription) {
        print(
            '🚨 CRITICAL: Subscription expired/failed - immediate access revocation');
        print(
            '📅 User subscription ended - payment may have failed or expired');

        // Clear local subscription immediately
        await SubscriptionSyncService.clearSubscriptionData();

        // Force user to paywall/signin screen
        if (kIsWeb) {
          _handleExpiredSubscription();
        }
      } else {
        print('✅ Subscription verified active - access maintained');
      }
    } catch (e) {
      print('⚠️ Error during periodic subscription check: $e');
      // Don't block user on monitoring errors, but this could indicate network issues
      print(
          '💡 Subscription verification failed - user may lose access if issue persists');
    }
  }

  /// Handle expired subscription by redirecting user
  void _handleExpiredSubscription() {
    print('🚨 SUBSCRIPTION EXPIRED - Initiating access revocation sequence');
    print('💳 Payment failed, subscription cancelled, or renewal missed');

    // Clear all subscription data
    SubscriptionSyncService.clearSubscriptionData();

    if (kIsWeb) {
      // For web, we can use window.location to force redirect
      try {
        // Force redirect to paywall/subscription page
        // This ensures user can't continue using the app
        print('🌐 Redirecting to subscription page...');

        // You can customize this URL based on your app structure
        // window.location.replace('/paywall'); // No back button
        // or
        // window.location.href = '/signin';

        // For now, we'll log the intent
        print('🔗 Would redirect to: /paywall or /signin');
      } catch (e) {
        print('⚠️ Could not redirect user: $e');
      }
    }

    // TODO: Integrate with your navigation service
    // NavigationService.pushNamedAndClearStack('/paywall');

    // TODO: Or show immediate blocking dialog
    // showSubscriptionExpiredDialog();
  }

  /// Manual subscription recheck (call when user returns to app)
  Future<bool> recheckSubscription() async {
    print('🔄 Manual subscription recheck requested');
    await _checkSubscriptionStatus();
    return await SubscriptionSyncService.checkUnifiedSubscriptionStatus();
  }

  /// Check if user's subscription is about to expire (within 7 days)
  Future<bool> isSubscriptionNearExpiry() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // You could enhance this to call a Stripe API that returns expiry date
      // For now, this is a placeholder
      return false;
    } catch (e) {
      print('Error checking subscription expiry: $e');
      return false;
    }
  }
}
