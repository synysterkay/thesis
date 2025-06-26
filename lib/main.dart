import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/error_screen.dart';
import 'dart:async';
import 'dart:io';
import 'app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/locale_provider.dart';
import 'firebase_options.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notification_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'providers/analytics_provider.dart';
import 'services/navigation_service.dart';
import 'services/gemini_service.dart';
import 'providers/gemini_provider.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

class InitializationException implements Exception {
  final String message;
  final dynamic originalError;
  InitializationException(this.message, this.originalError);
  @override
  String toString() => 'InitializationException: $message\nOriginal error: $originalError';
}

late FirebaseAnalytics analytics;
late AppsflyerSdk appsflyerSdk;

Future<void> initializeAppsFlyer() async {
  if (kIsWeb) return; // Skip on web
  
  final Map<String, dynamic> appsFlyerOptions = {
    "afDevKey": "2D7j92NP2LR5CSp95o3iX7",
    "afAppId": "id6739264844",
    "isDebug": false,
  };
  appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
  try {
    await appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true
    );
    print("✅ AppsFlyer SDK initialized successfully");
    appsflyerSdk.onInstallConversionData((res) {
      print("📊 Conversion data: $res");
    });
    appsflyerSdk.onAppOpenAttribution((res) {
      print("🔗 App open attribution: $res");
    });
    final appsFlyerUID = await appsflyerSdk.getAppsFlyerUID();
    print("🆔 AppsFlyer UID: $appsFlyerUID");
  } catch (e) {
    print("❌ AppsFlyer SDK initialization failed: $e");
  }
}

Future<void> initializeSuperwall() async {
  if (kIsWeb) return; // Skip on web
  
  // Determine Superwall API Key for platform
  String apiKey;
  try {
    apiKey = Platform.isIOS
        ? "pk_fedee2171cfccbd5de869601a33a9c196ec9b838c6f6edec"
        : "pk_73a34d6e8a5cc3d5a7244f23a39440becef5182393fe8f2c";
  } catch (e) {
    // Fallback for web or unsupported platforms
    apiKey = "pk_73a34d6e8a5cc3d5a7244f23a39440becef5182393fe8f2c";
  }

  await Superwall.configure(apiKey);
  print("✅ Superwall initialized successfully");
}

Future<void> requestTrackingPermission() async {
  if (kIsWeb) return; // Skip on web
  
  try {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  } catch (e) {
    print('Failed to request tracking authorization: $e');
  }
}

Future<void> requestPermissions() async {
  if (kIsWeb) return; // Skip on web
  
  try {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.photos.request();
      await Permission.videos.request();
    }
  } catch (e) {
    print('Failed to request permissions: $e');
  }
}

Future<void> _initializeHiveBox() async {
  const int maxRetries = 3;
  const boxName = 'thesisCache';
  for (int i = 0; i < maxRetries; i++) {
    try {
      await Hive.openBox(boxName);
      return;
    } catch (e) {
      if (i == maxRetries - 1) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          await Hive.openBox(boxName);
          return;
        } catch (finalError) {
          throw InitializationException('Failed to initialize Hive storage after multiple attempts', finalError);
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

Future<void> initializeServices() async {
  try {
    if (!kIsWeb) {
      await Hive.initFlutter();
      await _initializeHiveBox();
    }
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');
    if (savedLanguage != null) {
      final container = ProviderContainer();
      container.read(localeProvider.notifier).setLocale(savedLanguage.split('_')[0]);
    }
  } catch (e) {
    throw InitializationException('Failed to initialize services', e);
  }
}

Future<void> initializeAds() async {
  if (kIsWeb) return; // Skip on web
  
  await MobileAds.instance.initialize();
  await FacebookAudienceNetwork.init();
  final params = ConsentRequestParameters();
  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
        () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadConsentForm(
              (ConsentForm consentForm) async {
            consentForm.show((FormError? formError) {});
          },
              (error) => print('Consent form error: $error'),
        );
      }
    },
        (error) => print('Consent info update error: $error'),
  );
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['EMULATOR'],
      maxAdContentRating: MaxAdContentRating.g,
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    ),
  );
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ALWAYS start with the splash screen
    final String initialRoute = '/';

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    List<Override> overrides = [];
    if (!kIsWeb) { 
      // Initialize GeminiService
      final geminiService = GeminiService();
      await geminiService.initializeRemoteConfig();
      overrides.add(geminiServiceProvider.overrideWithValue(geminiService));

      analytics = FirebaseAnalytics.instance;
      await analytics.logAppOpen();

      await initializeAds();
      
      // Safe platform checks
      try {
        if (Platform.isIOS) {
          await requestTrackingPermission();
          await initializeAppsFlyer();
        }
      } catch (e) {
        print('Platform-specific initialization failed: $e');
      }
      
      await requestPermissions();
    }

    await initializeServices();
    await initializeSuperwall();

    final container = ProviderContainer(overrides: overrides);

    runApp(
      ProviderScope(
        parent: container,
        child: MyApp(initialRoute: initialRoute),
      ),
    );
  }, (error, stack) {
    debugPrint('💥 Fatal error: $error\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('A fatal error occurred: ${error.toString()}'),
          ),
        ),
      ),
    );
  });
}
