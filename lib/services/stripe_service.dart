import 'package:cloud_functions/cloud_functions.dart';

class StripeService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Create Stripe Checkout URL using your payment link
  static Future<String> createCheckoutSession({
    required String userEmail,
    required String userId,
    String? priceId,
  }) async {
    try {
      // Using your existing payment link - we'll test if it's in test mode
      const String basePaymentLink =
          'https://buy.stripe.com/28EbJ12rz8xD3gPaOHfrW06';

      // Build URL with parameters for email prefilling
      final Map<String, String> params = {
        'prefilled_email': userEmail,
        // Note: For automatic redirection after payment, you'll need to configure
        // the success and cancel URLs in your Stripe Dashboard for this payment link
        // Success URL should be: ${_getBaseUrl()}/payment-success
        // Cancel URL should be: ${_getBaseUrl()}/paywall
      };

      final Uri uri = Uri.parse(basePaymentLink).replace(
        queryParameters: params,
      );

      return uri.toString();
    } catch (e) {
      throw Exception('Failed to create checkout session: ${e.toString()}');
    }
  }

  /// Create trial checkout using payment link (trials need to be configured in Stripe)
  static Future<String> createTrialCheckoutSession({
    required String userEmail,
    required String userId,
    int trialDays = 7,
  }) async {
    try {
      // For now, use the same payment link
      // You'll need to create a separate Stripe payment link with trial if needed
      const String basePaymentLink =
          'https://buy.stripe.com/28EbJ12rz8xD3gPaOHfrW06';

      final String checkoutUrl =
          '$basePaymentLink?prefilled_email=${Uri.encodeComponent(userEmail)}';

      return checkoutUrl;
    } catch (e) {
      throw Exception(
          'Failed to create trial checkout session: ${e.toString()}');
    }
  }

  /// Check if user has active subscription via Firebase Function
  static Future<bool> checkSubscriptionStatus(String userId) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('checkSubscriptionStatus');

      final response = await callable.call({
        'userId': userId,
      });

      final data = response.data as Map<String, dynamic>;
      return data['isActive'] as bool? ?? false;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }

  /// Get customer portal URL for subscription management
  static Future<String> createPortalSession({
    required String customerId,
  }) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('createPortalSession');

      final response = await callable.call({
        'customerId': customerId,
        'returnUrl': '${_getBaseUrl()}/dashboard',
      });

      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } catch (e) {
      throw Exception('Failed to create portal session: ${e.toString()}');
    }
  }

  static String _getBaseUrl() {
    // Return your app's actual domain
    return 'https://thesisgenerator.tech';
  }
}
