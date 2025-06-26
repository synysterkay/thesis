import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

final appsflyerProvider = Provider<AppsflyerSdk?>((ref) => null);

class AppsFlyerNotifier extends StateNotifier<AppsflyerSdk?> {
  AppsFlyerNotifier() : super(null);

  void setAppsFlyerSdk(AppsflyerSdk sdk) {
    state = sdk;
  }
}

final appsflyerNotifierProvider = StateNotifierProvider<AppsFlyerNotifier, AppsflyerSdk?>((ref) {
  return AppsFlyerNotifier();
});
