import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/superwall_service.dart';
import '../services/subscription_sync_service.dart';

// Simple subscription status for Superwall integration
class SubscriptionStatus {
  final bool isActive;
  final String? userId;
  final String? planType;
  final DateTime? currentPeriodEnd;
  final String status;

  const SubscriptionStatus({
    required this.isActive,
    this.userId,
    this.planType,
    this.currentPeriodEnd,
    required this.status,
  });

  factory SubscriptionStatus.active(String userId) {
    return SubscriptionStatus(
      isActive: true,
      userId: userId,
      planType: 'superwall_managed',
      currentPeriodEnd:
          DateTime.now().add(const Duration(days: 365)), // Placeholder
      status: 'active',
    );
  }

  factory SubscriptionStatus.inactive() {
    return const SubscriptionStatus(
      isActive: false,
      userId: null,
      planType: null,
      currentPeriodEnd: null,
      status: 'inactive',
    );
  }
}

// Simplified subscription status provider for Superwall
// Superwall handles subscription management for all platforms including web
final subscriptionStatusProvider =
    StreamProvider<SubscriptionStatus>((ref) async* {
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    if (user == null) {
      yield SubscriptionStatus.inactive();
    } else {
      // On web, ALWAYS check Stripe for the authenticated user's subscription
      // This ensures we catch subscriptions even on page reload after payment
      try {
        print('📧 Checking subscription for authenticated user: ${user.email}');
        final hasActiveSubscription =
            await SubscriptionSyncService.checkUnifiedSubscriptionStatus();

        if (hasActiveSubscription) {
          print('✅ Subscription ACTIVE for ${user.email}');
          yield SubscriptionStatus.active(user.uid);
        } else {
          print('❌ No active subscription for ${user.email}');
          yield SubscriptionStatus.inactive();
        }
      } catch (e) {
        print('Error checking subscription status: $e');
        yield SubscriptionStatus.inactive();
      }
    }
  }
});

// Convenience providers
final isSubscribedProvider = Provider<bool>((ref) {
  final subscriptionStatus = ref.watch(subscriptionStatusProvider);
  return subscriptionStatus.when(
    data: (status) => status.isActive,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Subscription actions provider (simplified for Superwall)
final subscriptionActionsProvider = Provider<SubscriptionActions>((ref) {
  return SubscriptionActions();
});

class SubscriptionActions {
  // Since Superwall handles all subscription logic,
  // these methods are simplified stubs

  Future<void> refreshSubscriptionStatus() async {
    // No-op: Superwall handles subscription status
  }

  Future<String> createProSubscription() async {
    // Should not be called with Superwall integration
    throw UnimplementedError('Use Superwall for subscriptions');
  }

  Future<void> cancelSubscription() async {
    // Superwall handles cancellations
    throw UnimplementedError('Use Superwall dashboard for cancellations');
  }

  Future<void> handleSignOut() async {
    // Clear Superwall user identity before signing out
    await SuperwallService.clearUserIdentity();

    // Handle sign out - just sign out from Firebase
    await FirebaseAuth.instance.signOut();
  }
}
