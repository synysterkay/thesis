import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class AdManager {
  static String get nativeAdUnitId {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isAndroid) {
      return AdConfig.admobNativeAdAndroid;
    } else if (Platform.isIOS) {
      return AdConfig.admobNativeAdIOS;
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isAndroid) {
      return AdConfig.admobInterstitialAdAndroid;
    } else if (Platform.isIOS) {
      return AdConfig.admobInterstitialAdIOS;
    }
    return '';
  }

  static Future<InterstitialAd?> loadInterstitialAd() async {
    if (kIsWeb) {
      return null;
    }

    final completer = Completer<InterstitialAd>();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded successfully');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  static Future<NativeAd?> loadNativeAd() async {
    if (kIsWeb) {
      return null;
    }

    final completer = Completer<NativeAd>();

    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'customNative',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('Native ad loaded successfully');
          completer.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed to load: $error');
          ad.dispose();
          completer.completeError(error);
        },
      ),
    );

    ad.load();
    return completer.future;
  }
}
