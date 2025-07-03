import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/stripe_service.dart';
import '../providers/auth_provider.dart';

// Stripe service provider
final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService();
});

// Subscription status provider with better error handling
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  final stripeService = ref.watch(stripeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(SubscriptionStatus(
      isActive: false,
      userId: null,
      planType: null,
      currentPeriodEnd: null,
      status: 'not_authenticated',
    ));
  }

  return stripeService.subscriptionStatusStream();
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

final subscriptionPlanProvider = Provider<String?>((ref) {
  final subscriptionStatus = ref.watch(subscriptionStatusProvider);
  return subscriptionStatus.when(
    data: (status) => status.planType,
    loading: () => null,
    error: (_, __) => null,
  );
});

final subscriptionEndDateProvider = Provider<DateTime?>((ref) {
  final subscriptionStatus = ref.watch(subscriptionStatusProvider);
  return subscriptionStatus.when(
    data: (status) => status.currentPeriodEnd,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Subscription service provider (for compatibility)
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final stripeService = ref.watch(stripeServiceProvider);
  return SubscriptionService(stripeService);
});

// Subscription actions provider
final subscriptionActionsProvider = Provider<SubscriptionActions>((ref) {
  final stripeService = ref.watch(stripeServiceProvider);
  return SubscriptionActions(stripeService);
});

/// Subscription Service (for compatibility with existing code)
class SubscriptionService {
  final StripeService _stripeService;

  SubscriptionService(this._stripeService);

  Future<void> handleSignIn(User user) async {
    try {
      print('🔐 Handling sign in for user: ${user.uid}');
      await _stripeService.ensureCustomerExists();
      print('✅ Sign in handled successfully');
    } catch (e) {
      print('❌ Error handling sign in: $e');
      // Don't throw here, as this is not critical for sign in
    }
  }

  Future<void> handleSignOut() async {
    try {
      print('🔐 Handling sign out');
      // Clean up any local data if needed
      print('✅ Sign out handled successfully');
    } catch (e) {
      print('❌ Error handling sign out: $e');
      // Don't throw here, as this is not critical for sign out
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    await _stripeService.refreshSubscriptionStatus();
  }

  String getSubscriptionUrl() {
    return _stripeService.getPaymentLink('monthly');
  }
}

/// Subscription Actions
class SubscriptionActions {
  final StripeService _stripeService;

  SubscriptionActions(this._stripeService);

  Future<void> refreshSubscriptionStatus() async {
    await _stripeService.refreshSubscriptionStatus();
  }

  /// Get weekly payment link
  String getWeeklyPaymentLink() {
    return _stripeService.getPaymentLinkWithTracking('weekly');
  }

  /// Get monthly payment link
  String getMonthlyPaymentLink() {
    return _stripeService.getPaymentLinkWithTracking('monthly');
  }

  Future<String> createWeeklySubscription() async {
    try {
      // Option 1: Use checkout session (requires Stripe Extension setup)
      return await _stripeService.createCheckoutSession(
        priceId: StripeService.weeklyPriceId,
        successUrl: '${Uri.base.origin}/thesis-form?session_id={CHECKOUT_SESSION_ID}',
        cancelUrl: '${Uri.base.origin}/paywall',
      );
    } catch (e) {
      print('❌ Checkout session failed, falling back to payment link: $e');
      // Option 2: Fallback to payment link
      return getWeeklyPaymentLink();
    }
  }

  Future<String> createMonthlySubscription() async {
    try {
      // Option 1: Use checkout session (requires Stripe Extension setup)
      return await _stripeService.createCheckoutSession(
        priceId: StripeService.monthlyPriceId,
        successUrl: '${Uri.base.origin}/thesis-form?session_id={CHECKOUT_SESSION_ID}',
        cancelUrl: '${Uri.base.origin}/paywall',
      );
    } catch (e) {
      print('❌ Checkout session failed, falling back to payment link: $e');
      // Option 2: Fallback to payment link
      return getMonthlyPaymentLink();
    }
  }

  Future<String> getCustomerPortalUrl() async {
    return await _stripeService.getCustomerPortalUrl('${Uri.base.origin}/paywall');
  }

  Future<void> handleSignOut() async {
    // Clean up any local subscription data if needed
    print('🔐 Cleaning up subscription data on sign out');
  }

  Future<void> handleSignIn(User user) async {
    await _stripeService.ensureCustomerExists();
  }

  String getSubscriptionUrl() {
    return _stripeService.getPaymentLink('monthly');
  }

  /// Debug method to check subscription setup
  Future<Map<String, dynamic>> debugSubscriptionSetup() async {
    return await _stripeService.debugFirestoreStructure();
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    await _stripeService.cancelSubscription(subscriptionId);
  }

  /// Get subscription analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    return await _stripeService.getSubscriptionAnalytics();
  }
}
