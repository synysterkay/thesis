import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class BaseSubscriptionService {
  static const String PACKAGE_NAME = 'com.thesis.generator.ai';
  static const String SUBSCRIPTION_ID = 'thesis';
  Future<bool> verifyPurchases();
  Stream<bool> get subscriptionStream;

  Future<void> initialize();

  Future<List<ProductDetails>> getProducts();

  // Update this method signature to include the optional BuildContext parameter
  Future<void> purchaseSubscription(ProductDetails product, [BuildContext? context]);

  Future<bool> isSubscribed();

  Future<void> verifySubscriptionState();

  Future<void> showSubscriptionDialog(BuildContext context);

  void dispose();
}
