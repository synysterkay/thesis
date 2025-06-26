import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/base_subscription_service.dart';

class SubscriptionState {
  final bool isSubscribed;
  final List<ProductDetails> products;
  final BaseSubscriptionService? service;

  SubscriptionState({
    this.isSubscribed = false,
    this.products = const [],
    this.service,
  });

  SubscriptionState copyWith({
    bool? isSubscribed,
    List<ProductDetails>? products,
    BaseSubscriptionService? service,
  }) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      products: products ?? this.products,
      service: service ?? this.service,
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(SubscriptionState()) {
    _loadSavedSubscriptionState();
  }

  Future<void> _loadSavedSubscriptionState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSubscriptionState = prefs.getBool('is_subscribed') ?? false;
    state = state.copyWith(isSubscribed: savedSubscriptionState);
  }

  Future<void> _saveSubscriptionState(bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', isSubscribed);
  }

  void setService(BaseSubscriptionService service) {
    if (service == null) return;

    state = state.copyWith(service: service);

    // Add immediate status check
    checkSubscription();

    service.subscriptionStream.listen(
          (isSubscribed) {
        setSubscribed(isSubscribed);
        // Force UI refresh
        state = state.copyWith(isSubscribed: isSubscribed);
      },
      onError: (_) => setSubscribed(false),
      cancelOnError: false,
    );
  }


  Future<void> checkSubscription() async {
    if (state.service == null) {
      setSubscribed(false);
      return;
    }

    try {
      final isSubscribed = await state.service!.isSubscribed();
      await _saveSubscriptionState(isSubscribed);
      state = state.copyWith(isSubscribed: isSubscribed);
    } catch (e) {
      print('Check subscription error: $e');
      setSubscribed(false);
    }
  }

  void setProducts(List<ProductDetails> products) {
    state = state.copyWith(products: products);
  }

  void setSubscribed(bool value) async {
    await _saveSubscriptionState(value);
    state = state.copyWith(isSubscribed: value);
  }
  void refreshSubscriptionStatus() async {
    if (state.service == null) return;

    final isSubscribed = await state.service!.isSubscribed();
    await _saveSubscriptionState(isSubscribed);
    state = state.copyWith(isSubscribed: isSubscribed);
  }
}