import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  // Stripe Payment Links (replace with your actual payment links)
  static const String weeklyPaymentLink = 'https://buy.stripe.com/8x214n4zH5lr4kTaOHfrW01';
  static const String monthlyPaymentLink = 'https://buy.stripe.com/cNiaEXgip017eZxg91frW02';
  
  // Your price IDs for reference
  static const String weeklyPriceId = 'price_1RbhGMEHyyRHgrPiSXQFnnrT';
  static const String monthlyPriceId = 'price_1RbhH1EHyyRHgrPiijEs1rTB';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get payment link by plan type
  String getPaymentLink(String planType) {
    switch (planType.toLowerCase()) {
      case 'weekly':
        return weeklyPaymentLink;
      case 'monthly':
        return monthlyPaymentLink;
      default:
        throw Exception('Unknown plan type: $planType');
    }
  }

  /// Get current subscription status from Firestore (Stripe Extension structure)
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return SubscriptionStatus(
        isActive: false,
        userId: null,
        planType: null,
        currentPeriodEnd: null,
        status: 'not_authenticated',
      );
    }

    try {
      print('🔍 Checking subscription status for user: ${user.uid}');

      // Ensure customer document exists
      await ensureCustomerExists();

      // Get customer document
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        print('❌ No customer document found');
        return SubscriptionStatus(
          isActive: false,
          userId: user.uid,
          planType: null,
          currentPeriodEnd: null,
          status: 'no_customer',
        );
      }

      // Get active subscriptions from the customer's subscriptions subcollection
      final subscriptionsQuery = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .where('status', whereIn: ['active', 'trialing'])
          .get();

      if (subscriptionsQuery.docs.isEmpty) {
        print('❌ No active subscriptions found');
        
        // Check if there are any subscriptions at all
        final allSubscriptions = await _firestore
            .collection('customers')
            .doc(user.uid)
            .collection('subscriptions')
            .get();
            
        if (allSubscriptions.docs.isNotEmpty) {
          final lastSub = allSubscriptions.docs.first.data();
          print('📋 Last subscription status: ${lastSub['status']}');
        }
        
        return SubscriptionStatus(
          isActive: false,
          userId: user.uid,
          planType: null,
          currentPeriodEnd: null,
          status: 'no_active_subscription',
        );
      }

      // Get the most recent active subscription
      final subscriptionDoc = subscriptionsQuery.docs.first;
      final subscription = subscriptionDoc.data();
      
      print('✅ Found active subscription: ${subscriptionDoc.id}');
      print('📋 Subscription data: ${subscription.keys.toList()}');

      // Extract subscription details
      final status = subscription['status'] as String? ?? 'unknown';
      final currentPeriodEnd = subscription['current_period_end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (subscription['current_period_end'] as int) * 1000,
            )
          : null;

      // Get plan type from items
      String? planType;
      final items = subscription['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final firstItem = items.first as Map<String, dynamic>;
        final price = firstItem['price'] as Map<String, dynamic>?;
        if (price != null) {
          final priceId = price['id'] as String?;
          if (priceId != null) {
            planType = _getPlanTypeFromPriceId(priceId);
          }
        }
      }

      print('✅ Subscription details: $planType, status: $status, expires: $currentPeriodEnd');

      final isActive = status == 'active' || status == 'trialing';

      return SubscriptionStatus(
        isActive: isActive,
        userId: user.uid,
        planType: planType,
        currentPeriodEnd: currentPeriodEnd,
        status: status,
        subscriptionId: subscriptionDoc.id,
      );
    } catch (e) {
      print('❌ Error getting subscription status: $e');
      print('📋 Stack trace: ${StackTrace.current}');
      
      // Return error status instead of throwing
      return SubscriptionStatus(
        isActive: false,
        userId: user.uid,
        planType: null,
        currentPeriodEnd: null,
        status: 'error: ${e.toString()}',
      );
    }
  }

  /// Create checkout session using Firestore (for Stripe Extension)
  Future<String> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('🛒 Creating checkout session for user: ${user.uid}');
      
      // Ensure customer exists
      await ensureCustomerExists();

      // Create checkout session document
      final checkoutSessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add({
        'price': priceId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
        'mode': 'subscription',
        'allow_promotion_codes': true,
        'metadata': {
          'user_id': user.uid,
          'user_email': user.email ?? '',
          'created_at': DateTime.now().toIso8601String(),
        },
        'created': FieldValue.serverTimestamp(),
      });

      print('📝 Checkout session document created: ${checkoutSessionRef.id}');

      // Wait for the Stripe extension to populate the session URL
      for (int i = 0; i < 30; i++) { // Increased timeout
        await Future.delayed(const Duration(seconds: 1));
        
        final sessionDoc = await checkoutSessionRef.get();
        final data = sessionDoc.data();

        if (data != null) {
          print('📋 Session data keys: ${data.keys.toList()}');
          
          if (data['url'] != null) {
            final url = data['url'] as String;
            print('✅ Checkout URL created: $url');
            return url;
          }

          if (data['error'] != null) {
            final error = data['error'];
            print('❌ Checkout session error: $error');
            throw Exception('Checkout session error: $error');
          }
        }
        
        print('⏳ Waiting for checkout session... attempt ${i + 1}/30');
      }

      throw Exception('Timeout waiting for checkout session URL');
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      throw Exception('Failed to create checkout session: $e');
    }
  }

  /// Refresh subscription status (force reload from Firestore)
  Future<void> refreshSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('🔄 Refreshing subscription status for user: ${user.uid}');
      
      // Force refresh by getting fresh data
      await getSubscriptionStatus();
      
      print('✅ Subscription status refreshed');
    } catch (e) {
      print('❌ Error refreshing subscription status: $e');
      throw Exception('Failed to refresh subscription status: $e');
    }
  }

  /// Get customer portal URL using Firestore (for Stripe Extension)
  Future<String> getCustomerPortalUrl(String returnUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('🔗 Getting customer portal URL for user: ${user.uid}');

      // Create portal session document
      final portalSessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('portal_sessions')
          .add({
        'return_url': returnUrl,
        'created': FieldValue.serverTimestamp(),
      });

      print('📝 Portal session document created: ${portalSessionRef.id}');

      // Wait for the Stripe extension to populate the URL
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 1));
        
        final sessionDoc = await portalSessionRef.get();
        final data = sessionDoc.data();

        if (data != null) {
          if (data['url'] != null) {
            final url = data['url'] as String;
            print('✅ Portal URL created: $url');
            return url;
          }

          if (data['error'] != null) {
            final error = data['error'];
            print('❌ Portal session error: $error');
            throw Exception('Portal session error: $error');
          }
        }
        
        print('⏳ Waiting for portal session... attempt ${i + 1}/20');
      }

      throw Exception('Timeout waiting for portal session URL');
    } catch (e) {
      print('❌ Error getting customer portal URL: $e');
      throw Exception('Failed to get customer portal URL: $e');
    }
  }

  /// Listen to subscription changes
  Stream<SubscriptionStatus> subscriptionStatusStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(SubscriptionStatus(
        isActive: false,
        userId: null,
        planType: null,
        currentPeriodEnd: null,
        status: 'not_authenticated',
      ));
    }

    return _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('subscriptions')
        .snapshots()
        .asyncMap((_) async {
      try {
        return await getSubscriptionStatus();
      } catch (e) {
        print('❌ Error in subscription stream: $e');
        return SubscriptionStatus(
          isActive: false,
          userId: user.uid,
          planType: null,
          currentPeriodEnd: null,
          status: 'stream_error: ${e.toString()}',
        );
      }
    });
  }

  /// Create customer document if it doesn't exist
  Future<void> ensureCustomerExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final customerDocRef = _firestore.collection('customers').doc(user.uid);
      final customerDoc = await customerDocRef.get();

      if (!customerDoc.exists) {
        print('📝 Creating customer document for user: ${user.uid}');
        
        await customerDocRef.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'uid': user.uid,
          'created': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
        });

        print('✅ Customer document created');
      } else {
        // Update last sign in
        await customerDocRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        print('✅ Customer document updated');
      }
    } catch (e) {
      print('❌ Error ensuring customer exists: $e');
      // Don't throw here, as this is not critical
    }
  }

  /// Get plan type from price ID
  String _getPlanTypeFromPriceId(String priceId) {
    switch (priceId) {
      case weeklyPriceId:
        return 'weekly';
      case monthlyPriceId:
        return 'monthly';
      default:
        print('⚠️ Unknown price ID: $priceId');
        return 'unknown';
    }
  }

  /// Get payment link with user tracking
  String getPaymentLinkWithTracking(String planType, {Map<String, String>? metadata}) {
    final baseUrl = getPaymentLink(planType);
    final user = _auth.currentUser;
    
    if (user == null) return baseUrl;

    // Add client_reference_id to track the user
    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    queryParams['client_reference_id'] = user.uid;
    
    if (metadata != null) {
      metadata.forEach((key, value) {
        queryParams['metadata[$key]'] = value;
      });
    }

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Check if user has any subscription history
  Future<bool> hasSubscriptionHistory() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final subscriptionsQuery = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .limit(1)
          .get();

      return subscriptionsQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking subscription history: $e');
      return false;
    }
  }

  /// Get subscription analytics for user
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      final subscriptionsQuery = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .get();

      return {
        'customerExists': customerDoc.exists,
        'totalSubscriptions': subscriptionsQuery.docs.length,
        'subscriptions': subscriptionsQuery.docs.map((doc) => {
          'id': doc.id,
          'status': doc.data()['status'],
          'created': doc.data()['created'],
          'planType': doc.data()['items']?.isNotEmpty == true
              ? _getPlanTypeFromPriceId(doc.data()['items'][0]['price']['id'])
              : 'unknown',
        }).toList(),
      };
    } catch (e) {
      print('❌ Error getting subscription analytics: $e');
      return {'error': e.toString()};
    }
  }

  /// Cancel subscription (mark for cancellation at period end)
  Future<void> cancelSubscription(String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('❌ Requesting cancellation for subscription: $subscriptionId');

      // Update subscription document to request cancellation
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'cancel_at_period_end': true,
        'cancellation_requested': FieldValue.serverTimestamp(),
        'cancelled_by': 'user',
      });

      print('✅ Subscription cancellation requested');
    } catch (e) {
      print('❌ Error requesting subscription cancellation: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Get customer data
  Future<Map<String, dynamic>?> getCustomerData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      return customerDoc.exists ? customerDoc.data() : null;
    } catch (e) {
      print('❌ Error getting customer data: $e');
      return null;
    }
  }

  /// Debug method to check Firestore structure
  Future<Map<String, dynamic>> debugFirestoreStructure() async {
    final user = _auth.currentUser;
    if (user == null) return {'error': 'No authenticated user'};

    try {
      final result = <String, dynamic>{};
      
      // Check customer document
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();
      
      result['customer_exists'] = customerDoc.exists;
      if (customerDoc.exists) {
        result['customer_data'] = customerDoc.data();
      }

      // Check subscriptions
      final subscriptions = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .get();
      
      result['subscriptions_count'] = subscriptions.docs.length;
      result['subscriptions'] = subscriptions.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();

      // Check checkout sessions
      final checkoutSessions = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .limit(5)
          .get();
      
      result['checkout_sessions_count'] = checkoutSessions.docs.length;
      result['recent_checkout_sessions'] = checkoutSessions.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();

      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// Subscription Status Model
class SubscriptionStatus {
  final bool isActive;
  final String? userId;
  final String? planType;
  final DateTime? currentPeriodEnd;
  final String status;
  final String? subscriptionId;

  SubscriptionStatus({
    required this.isActive,
    required this.userId,
    required this.planType,
    required this.currentPeriodEnd,
    required this.status,
    this.subscriptionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'userId': userId,
      'planType': planType,
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'status': status,
      'subscriptionId': subscriptionId,
    };
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['isActive'] ?? false,
      userId: json['userId'],
      planType: json['planType'],
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'])
          : null,
      status: json['status'] ?? 'unknown',
      subscriptionId: json['subscriptionId'],
    );
  }

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, planType: $planType, status: $status, userId: $userId)';
  }

  /// Check if subscription is in a good state
  bool get isHealthy => !status.contains('error') && !status.contains('stream_error');

  /// Check if subscription is expired
  bool get isExpired {
    if (currentPeriodEnd == null) return false;
    return DateTime.now().isAfter(currentPeriodEnd!);
  }

  /// Get user-friendly status message
  String get friendlyStatus {
    switch (status) {
      case 'active':
        return 'Active';
      case 'trialing':
        return 'Trial Period';
      case 'past_due':
        return 'Payment Due';
      case 'canceled':
        return 'Cancelled';
      case 'unpaid':
        return 'Payment Failed';
      case 'incomplete':
        return 'Setup Incomplete';
      case 'incomplete_expired':
        return 'Setup Expired';
      case 'not_authenticated':
        return 'Not Signed In';
      case 'no_customer':
        return 'No Account';
      case 'no_active_subscription':
        return 'No Subscription';
      default:
        if (status.contains('error')) {
          return 'Error Loading';
        }
        return 'Unknown Status';
    }
  }
}
