import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({Key? key}) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with SingleTickerProviderStateMixin {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  String get _nativeAdUnitId {
    if (Platform.isAndroid) {
      return AdConfig.admobNativeAdAndroid;
    } else if (Platform.isIOS) {
      return AdConfig.admobNativeAdIOS;
    }
    throw UnsupportedError('Unsupported platform');
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadAd();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _animation =
        Tween<double>(begin: -1.0, end: 2.0).animate(_animationController);
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'customNative',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return SizedBox(
        height: 310,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: [
                    _animation.value - 0.3,
                    _animation.value,
                    _animation.value + 0.3,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Container(
                color: const Color(0xFF171717),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 310,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
