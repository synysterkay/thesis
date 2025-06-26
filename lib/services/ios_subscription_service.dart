import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../widgets/ios_subscription_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../constants/store_products.dart';
import 'package:flutter/services.dart';
import 'base_subscription_service.dart';
import '../services/navigation_service.dart'; // Add this import


class IOSSubscriptionService implements BaseSubscriptionService {
  static const String IOS_SHARED_SECRET = '9cbd4820b9c74a358b51a75d55609ff0';
  static const String KEY_ID = '21645757';
  static const String ISSUER_ID = '0728c8cd-f60f-465e-8b5d-631d730c71b2';
  static const String APP_ID = '6739264844';
  static const String BUNDLE_ID = BaseSubscriptionService.PACKAGE_NAME;
  static const String _productionVerifyURL = 'https://buy.itunes.apple.com/verifyReceipt';
  static const String _sandboxVerifyURL = 'https://sandbox.itunes.apple.com/verifyReceipt';

  final _subscriptionController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get subscriptionStream => _subscriptionController.stream;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Set<String> get _productIds => {
    StoreProducts.monthlySubIOS,
    StoreProducts.yearlySubIOS
  };
  @override
  Future<bool> verifySubscriptionState() async {
    final isValid = await isSubscribed();
    _subscriptionController.add(isValid);
    return isValid; // Return the boolean value
  }
  @override
  Future<void> initialize() async {
    try {
      final isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        _subscriptionController.add(false);
        return;
      }

      // Initialize the purchase stream first
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          print('Purchase Stream Error: $error');
          _subscriptionController.add(false);
        },
      );

      // Check subscription status using verifySubscriptionState
      await verifySubscriptionState();

    } catch (e) {
      print('Initialization Error: $e');
      _subscriptionController.add(false);
    }
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    print('🔍 Starting iOS product fetch with currency check...');

    if (!await _iap.isAvailable()) {
      print('❌ iOS Store not available');
      return [];
    }

    try {
      print('📱 Verifying StoreKit connection...');
      final storeKitAvailable = await _iap.isAvailable();
      print('💳 StoreKit status: $storeKitAvailable');

      int attempts = 0;
      while (attempts < 3) {
        print('📦 Attempt ${attempts + 1}: Querying iOS products: $_productIds');
        final response = await _iap.queryProductDetails(_productIds);

        if (response.productDetails.isNotEmpty) {
          print('✅ iOS Products found: ${response.productDetails.length}');
          print('💰 iOS Product prices:');
          for (var product in response.productDetails) {
            print('   ${product.id}: ${product.price} (${product.currencyCode})');
          }
          return response.productDetails;
        }

        attempts++;
        if (attempts < 3) {
          print('⏳ Retrying iOS product fetch in 1 second...');
          await Future.delayed(Duration(seconds: 1));
        }
      }

      print('⚠️ No iOS products found after $attempts attempts');
      return [];
    } catch (e) {
      print('❌ iOS Product fetch error: $e');
      return [];
    }
  }

  @override
  Future<void> purchaseSubscription(ProductDetails product, [BuildContext? context]) async {
    print('Starting iOS subscription purchase for product: ${product.id}');

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      throw PlatformException(
          code: 'NO_NETWORK',
          message: 'Please check your internet connection'
      );
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null,
    );

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        print('Initiating iOS purchase attempt ${retryCount + 1}');

        // Don't notify UI that purchase is in progress yet
        // We'll only set subscription state to true after verification

        final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        print('iOS Purchase result: $success');

        if (success) {
          // Verify purchase immediately
          final isValid = await verifySubscriptionState();

          if (isValid) {
            // Save subscription state to preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('ios_is_subscribed', true);

            // Now notify UI that subscription is active
            _subscriptionController.add(true);

            // Force global subscription state update
            if (context != null) {
              // Use the provided context to access the ProviderContainer
              final container = ProviderScope.containerOf(context);
              container.read(subscriptionProvider.notifier).setSubscribed(true);
            }
          }
          return;
        }

        retryCount++;
      } catch (e) {
        print('iOS Purchase attempt ${retryCount + 1} failed: $e');
        _subscriptionController.add(false);
        retryCount++;
        if (retryCount >= 3) rethrow;
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }



  @override
  Future<bool> verifyPurchases() async {
    if (!await _iap.isAvailable()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final receiptData = prefs.getString('ios_receipt_data');

    if (receiptData == null) return false;

    try {
      final verificationData = {
        'receipt-data': receiptData,
        'password': IOS_SHARED_SECRET,
      };

      // Try production verification first
      var response = await http.post(
        Uri.parse(_productionVerifyURL),
        body: jsonEncode(verificationData),
      );

      var responseData = jsonDecode(response.body);

      // If status is 21007, it's a sandbox receipt - retry with sandbox URL
      if (responseData['status'] == 21007) {
        response = await http.post(
          Uri.parse(_sandboxVerifyURL),
          body: jsonEncode(verificationData),
        );
        responseData = jsonDecode(response.body);
      }

      final isValid = responseData['status'] == 0;

      if (isValid) {
        await prefs.setBool('ios_is_subscribed', true);
        _subscriptionController.add(true);
      }

      return isValid;
    } catch (e) {
      print('iOS Purchase verification failed: $e');
      return false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Immediately notify subscribers
        _subscriptionController.add(true);

        // Save purchase details first
        await _savePurchaseDetails(purchase);

        // Verify the purchase
        final isValid = await _verifyPurchase(purchase);

        if (!isValid) {
          _subscriptionController.add(false);
          continue;
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final verificationData = {
        'receipt-data': purchase.verificationData.serverVerificationData,
        'password': IOS_SHARED_SECRET,
      };

      final response = await http.post(
        Uri.parse(_productionVerifyURL),
        body: jsonEncode(verificationData),
      );

      final responseData = jsonDecode(response.body);
      return responseData['status'] == 0;
    } catch (e) {
      print('iOS verification failed: $e');
      return false;
    }
  }

  Future<void> _savePurchaseDetails(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ios_subscription_id', purchase.productID);
    await prefs.setString('ios_purchase_date', DateTime.now().toIso8601String());
    await prefs.setBool('ios_is_subscribed', true);
    await prefs.setString(
      'ios_receipt_data',
      purchase.verificationData.serverVerificationData,
    );
  }

  Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('ios_is_subscribed') ?? false;

    if (!isSubscribed) return false;

    final receiptData = prefs.getString('ios_receipt_data');
    if (receiptData == null) return false;

    try {
      final verificationData = {
        'receipt-data': receiptData,
        'password': IOS_SHARED_SECRET,
      };

      final response = await http.post(
        Uri.parse(_productionVerifyURL),
        body: jsonEncode(verificationData),
      );

      final responseData = jsonDecode(response.body);
      return responseData['status'] == 0;
    } catch (e) {
      print('iOS Subscription verification failed: $e');
      return false;
    }
  }



  Future<void> showSubscriptionDialog(BuildContext context) async {
    print('Starting iOS subscription dialog flow');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF48B0)),
      ),
    );

    print('Fetching iOS products...');
    final products = await getProducts();
    print('iOS Products fetched: ${products.length}');

    Navigator.pop(context);

    if (products.isEmpty) {
      print('No iOS products available');
      final isStoreAvailable = await InAppPurchase.instance.isAvailable();
      print('iOS Store available: $isStoreAvailable');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load subscription options')),
      );
      return;
    }

    print('Showing iOS subscription dialog with ${products.length} products');
    return showDialog(
      context: context,
      builder: (dialogContext) => IOSSubscriptionDialog(
        products: products,
        onSubscribe: (productId) async {
          final product = products.firstWhere((p) => p.id == productId);
          await purchaseSubscription(product, context); // Pass the original context
          Navigator.pop(dialogContext);
        },
      ),
    );
  }


  @override
  void dispose() {
    _subscriptionController.close();
    _subscription.cancel();
  }
}
