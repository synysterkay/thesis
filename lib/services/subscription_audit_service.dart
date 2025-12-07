/// Security audit service to identify and fix subscription discrepancies
/// This service helps detect users marked as subscribed without actual payment
import 'package:firebase_auth/firebase_auth.dart';
import 'user_persistence_service.dart';
import 'subscription_sync_service.dart';

class SubscriptionAuditService {
  /// Check if current user has a local subscription but no Stripe subscription
  /// This indicates they may have been incorrectly marked as subscribed
  static Future<SubscriptionAuditResult> auditCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return SubscriptionAuditResult(
          isValid: false,
          hasLocalSubscription: false,
          hasStripeSubscription: false,
          error: 'No authenticated user',
        );
      }

      print('🔍 Auditing subscription for: ${user.email}');

      // Check local subscription status
      final hasLocalSubscription =
          await UserPersistenceService.isWebUserSubscribed();
      print('📱 Local subscription: $hasLocalSubscription');

      // Check actual Stripe subscription
      final hasStripeSubscription =
          await SubscriptionSyncService.checkStripeSubscriptionByEmail(
              user.email!);
      print('💳 Stripe subscription: $hasStripeSubscription');

      final isValid = hasLocalSubscription == hasStripeSubscription;

      return SubscriptionAuditResult(
        isValid: isValid,
        hasLocalSubscription: hasLocalSubscription,
        hasStripeSubscription: hasStripeSubscription,
        userEmail: user.email!,
        discrepancyType:
            _getDiscrepancyType(hasLocalSubscription, hasStripeSubscription),
      );
    } catch (e) {
      print('❌ Error auditing subscription: $e');
      return SubscriptionAuditResult(
        isValid: false,
        hasLocalSubscription: false,
        hasStripeSubscription: false,
        error: e.toString(),
      );
    }
  }

  /// Fix subscription discrepancies for current user
  static Future<bool> fixSubscriptionDiscrepancy() async {
    try {
      final auditResult = await auditCurrentUser();

      if (auditResult.isValid) {
        print('✅ No discrepancy found - subscription is valid');
        return true;
      }

      print(
          '🚨 Subscription discrepancy detected: ${auditResult.discrepancyType}');

      switch (auditResult.discrepancyType) {
        case DiscrepancyType.localOnlyNoStripe:
          // User marked as subscribed locally but no Stripe subscription
          // This is the security issue we're fixing - clear local subscription
          print('🔒 SECURITY FIX: Clearing invalid local subscription');
          await UserPersistenceService.clearWebSubscriptionStatus();
          print('✅ Invalid local subscription cleared');
          return true;

        case DiscrepancyType.stripeOnlyNoLocal:
          // User has Stripe subscription but not marked locally
          // Mark them as subscribed locally
          print('📱 Updating local subscription status');
          await UserPersistenceService.markWebUserSubscribed();
          print('✅ Local subscription updated');
          return true;

        case DiscrepancyType.none:
          print('✅ Both subscriptions are correctly null - no fix needed');
          return true;
      }
    } catch (e) {
      print('❌ Error fixing subscription discrepancy: $e');
      return false;
    }
  }

  /// Helper to determine type of discrepancy
  static DiscrepancyType _getDiscrepancyType(bool hasLocal, bool hasStripe) {
    if (hasLocal && !hasStripe) {
      return DiscrepancyType.localOnlyNoStripe; // SECURITY ISSUE
    } else if (!hasLocal && hasStripe) {
      return DiscrepancyType.stripeOnlyNoLocal; // Missing local subscription
    } else if (!hasLocal && !hasStripe) {
      return DiscrepancyType.none; // Both correctly null
    } else {
      return DiscrepancyType.none; // Both true - valid
    }
  }

  /// Run audit and print detailed report
  static Future<void> printAuditReport() async {
    final result = await auditCurrentUser();

    print('\n' + '=' * 50);
    print('📊 SUBSCRIPTION AUDIT REPORT');
    print('=' * 50);
    print('👤 User: ${result.userEmail ?? 'Unknown'}');
    print('📱 Local subscription: ${result.hasLocalSubscription}');
    print('💳 Stripe subscription: ${result.hasStripeSubscription}');
    print('✅ Valid: ${result.isValid}');

    if (!result.isValid) {
      print('🚨 Discrepancy: ${result.discrepancyType}');
      switch (result.discrepancyType) {
        case DiscrepancyType.localOnlyNoStripe:
          print(
              '⚠️  SECURITY ISSUE: User marked as subscribed without payment');
          print('💡 Recommendation: Clear local subscription immediately');
          break;
        case DiscrepancyType.stripeOnlyNoLocal:
          print('💡 User has paid but not marked locally');
          print('💡 Recommendation: Update local subscription status');
          break;
        default:
          break;
      }
    }

    if (result.error != null) {
      print('❌ Error: ${result.error}');
    }
    print('=' * 50 + '\n');
  }
}

/// Result of subscription audit
class SubscriptionAuditResult {
  final bool isValid;
  final bool hasLocalSubscription;
  final bool hasStripeSubscription;
  final String? userEmail;
  final String? error;
  final DiscrepancyType discrepancyType;

  SubscriptionAuditResult({
    required this.isValid,
    required this.hasLocalSubscription,
    required this.hasStripeSubscription,
    this.userEmail,
    this.error,
    this.discrepancyType = DiscrepancyType.none,
  });
}

/// Types of subscription discrepancies
enum DiscrepancyType {
  none, // No discrepancy
  localOnlyNoStripe, // SECURITY ISSUE: Local subscription without payment
  stripeOnlyNoLocal, // Missing local subscription despite payment
}
