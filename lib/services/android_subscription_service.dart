import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../widgets/android_subscription_dialog.dart';
import '../constants/store_products.dart';
import 'package:flutter/services.dart';
import 'base_subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';

class AndroidSubscriptionService implements BaseSubscriptionService {
  static const String PACKAGE_NAME = 'com.thesis.generator.ai';
  static const String SUBSCRIPTION_ID = 'thesis';

  final _subscriptionController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get subscriptionStream => _subscriptionController.stream;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Set<String> get _productIds => {
    StoreProducts.monthlySubAndroid,
    StoreProducts.yearlySubAndroid
  };

  @override
  Future<void> initialize() async {
    print('⚙️ Initializing IAP');
    final isAvailable = await _iap.isAvailable();
    print('🔍 Store available: $isAvailable');

    if (isAvailable) {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
            (purchases) {
          print('📦 Purchase update received: ${purchases.length} items');
          _onPurchaseUpdate(purchases);
        },
        onDone: () {
          print('🔄 Purchase stream done');
          _subscription.cancel();
        },
        onError: (error) => print('❌ Purchase Error: $error'),
      );

      print('🔄 Verifying subscription state');
      await verifySubscriptionState();
    }
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    print('🔍 Starting product fetch with currency check...');

    if (!await _iap.isAvailable()) {
      print('❌ Store not available');
      return [];
    }

    try {
      print('📱 Verifying billing client connection...');
      final billingResult = await _iap.isAvailable();
      print('💳 Billing client status: $billingResult');

      int attempts = 0;
      while (attempts < 3) {
        print('📦 Attempt ${attempts + 1}: Querying products: $_productIds');
        final response = await _iap.queryProductDetails(_productIds);

        if (response.productDetails.isNotEmpty) {
          print('✅ Products found: ${response.productDetails.length}');
          print('💰 Product prices:');
          for (var product in response.productDetails) {
            print('   ${product.id}: ${product.price} (${product.currencyCode})');
          }
          return response.productDetails;
        }

        attempts++;
        if (attempts < 3) {
          print('⏳ Retrying product fetch in 1 second...');
          await Future.delayed(Duration(seconds: 1));
        }
      }

      print('⚠️ No products found after $attempts attempts');
      return [];
    } catch (e) {
      print('❌ Product fetch error: $e');
      return [];
    }
  }

  @override
  Future<void> purchaseSubscription(ProductDetails product, [BuildContext? context]) async {
    print('Starting subscription purchase for product: ${product.id}');

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
        print('Initiating subscription purchase attempt ${retryCount + 1}');
        final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        print('Purchase result: $success');

        if (success) {
          // If context is provided, update the subscription state in the provider
          if (context != null) {
            final container = ProviderScope.containerOf(context);
            container.read(subscriptionProvider.notifier).setSubscribed(true);
          }
          return;
        }

        retryCount++;
      } catch (e) {
        print('Purchase attempt ${retryCount + 1} failed: $e');
        retryCount++;
        if (retryCount >= 3) rethrow;
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }


  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        await _savePurchaseDetails(purchase);
        _subscriptionController.add(true);
      }
    }
  }

  Future<void> _savePurchaseDetails(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_id', purchase.productID);
    await prefs.setString('purchase_token', purchase.purchaseID ?? '');
    await prefs.setString('purchase_date', DateTime.now().toIso8601String());
    await prefs.setBool('is_subscribed', true);
  }

  @override
  Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('is_subscribed') ?? false;

    if (isSubscribed) {
      try {
        final purchaseToken = prefs.getString('purchase_token');
        final subscriptionId = prefs.getString('subscription_id');

        if (purchaseToken != null && subscriptionId != null) {
          final purchaseResponse = await _iap.queryProductDetails(_productIds);

          final validPurchase = purchaseResponse.productDetails.any((product) =>
          product.id == subscriptionId
          );

          if (!validPurchase) {
            await prefs.setBool('is_subscribed', false);
            return false;
          }
          return true;
        }
      } catch (e) {
        print('Subscription verification failed: $e');
      }
    }
    return false;
  }

  @override
  Future<bool> verifyPurchases() async {
    if (!await _iap.isAvailable()) {
      return false;
    }

    try {
      final purchaseDetails = await _iap.purchaseStream.first;

      final hasValidSubscription = purchaseDetails.any((purchase) =>
      purchase.status == PurchaseStatus.purchased &&
          !purchase.pendingCompletePurchase &&
          _productIds.contains(purchase.productID)
      );

      if (hasValidSubscription) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_subscribed', true);
        _subscriptionController.add(true);
      }

      return hasValidSubscription;
    } catch (e) {
      print('Purchase verification failed: $e');
      return false;
    }
  }

  Future<void> verifySubscriptionState() async {
    final isValid = await isSubscribed();
    _subscriptionController.add(isValid);
  }

  Future<void> showSubscriptionDialog(BuildContext context) async {

    final hasActiveSubscription = await verifyPurchases();

    if (hasActiveSubscription) {
      // Navigate to premium features directly
      Navigator.of(context).pushReplacementNamed('/premium');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF48B0)),
      ),
    );

    print('Fetching products...');
    final products = await getProducts();
    print('Products fetched: ${products.length}');

    Navigator.pop(context);

    if (products.isEmpty) {
      print('No products available - checking store configuration');
      final isStoreAvailable = await InAppPurchase.instance.isAvailable();
      print('Store available: $isStoreAvailable');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load subscription options')),
      );
      return;
    }

    print('Showing subscription dialog with ${products.length} products');
    return showDialog(
      context: context,
      builder: (context) => AndroidSubscriptionDialog(
        products: products,
        onSubscribe: (productId) async {
          final product = products.firstWhere((p) => p.id == productId);
          await purchaseSubscription(product);
          Navigator.pop(context);
        },
      ),
    );
  }

  void dispose() {
    _subscriptionController.close();
    _subscription.cancel();
  }
}