import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'screens/error_screen.dart';
import 'screens/initialization_screen.dart'; // Add this import
import 'dart:async';
import 'dart:io';
import 'app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/locale_provider.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'services/local_notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'providers/analytics_provider.dart';
import 'services/navigation_service.dart';
import 'services/deepseek_service.dart';
import 'providers/deepseek_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/onesignal_service.dart';

class InitializationException implements Exception {
  final String message;
  final dynamic originalError;
  InitializationException(this.message, this.originalError);
  @override
  String toString() =>
      'InitializationException: $message\nOriginal error: $originalError';
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
        registerOnDeepLinkingCallback: true);
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
          throw InitializationException(
              'Failed to initialize Hive storage after multiple attempts',
              finalError);
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

Future<void> initializeSuperwall() async {
  if (kIsWeb) {
    // For web, skip native Superwall initialization to avoid platform exceptions
    print(
        '🌐 Skipping native Superwall initialization for Web (using direct URLs instead)');
    return;
  }

  try {
    String apiKey;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      apiKey =
          'pk_fedee2171cfccbd5de869601a33a9c196ec9b838c6f6edec'; // iOS API key
      print('🍎 Initializing Superwall for iOS with key: $apiKey');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      apiKey =
          'pk_73a34d6e8a5cc3d5a7244f23a39440becef5182393fe8f2c'; // Android API key
      print('🤖 Initializing Superwall for Android with key: $apiKey');
    } else {
      print('⚠️ Unsupported platform for Superwall');
      return;
    }

    // Configure Superwall - allow it to initialize asynchronously
    // Don't block app startup if Superwall takes time
    Superwall.configure(apiKey);

    print(
        '✅ Superwall configuration started for ${defaultTargetPlatform.name}');
  } catch (e) {
    print('❌ Failed to initialize Superwall (non-critical): $e');
    // Don't throw - allow app to continue without Superwall
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
      container
          .read(localeProvider.notifier)
          .setLocale(savedLanguage.split('_')[0]);
    }

    // Initialize Superwall
    await initializeSuperwall();

    // Initialize OneSignal for push notifications
    if (!kIsWeb) {
      await OneSignalService().initialize();
    }

    // Initialize Local Notifications
    if (!kIsWeb) {
      tz.initializeTimeZones(); // Initialize timezone data
    }
    await LocalNotificationService.initialize();

    // Initialize retention notification system
    await LocalNotificationService.initializeRetentionSystem();

    print('✅ Core services initialized successfully');
  } catch (e) {
    throw InitializationException('Failed to initialize services', e);
  }
}

Future<void> initializeAds() async {
  if (kIsWeb) return; // Skip on web

  try {
    await MobileAds.instance.initialize();

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

    print('✅ Ads initialized successfully');
  } catch (e) {
    print('❌ Ads initialization failed: $e');
  }
}

void main() {
  BindingBase.debugZoneErrorsAreFatal = false;
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    print('🚀 Starting Thesis Generator App...');

    if (kIsWeb) {
      // Configure Google Sign-In for web
      print('🔧 Configuring Google Sign-In for web...');
    }

    // Initialize Firebase first
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      throw InitializationException('Firebase initialization failed', e);
    }

    // Prepare provider overrides
    List<Override> overrides = [];

    if (!kIsWeb) {
      try {
        // Initialize DeepSeekService
        final deepseekService = DeepSeekService();
        await deepseekService.initializeRemoteConfig();
        overrides
            .add(deepseekServiceProvider.overrideWithValue(deepseekService));

        // Initialize Firebase Analytics
        analytics = FirebaseAnalytics.instance;
        await analytics.logAppOpen();
        print('✅ Firebase Analytics initialized');

        // Initialize ads
        await initializeAds();

        // Platform-specific initialization
        try {
          if (Platform.isIOS) {
            await requestTrackingPermission();
            await initializeAppsFlyer();
          }
        } catch (e) {
          print('❌ Platform-specific initialization failed: $e');
        }

        await requestPermissions();
      } catch (e) {
        print('❌ Mobile-specific initialization failed: $e');
      }
    }

    // Initialize core services
    await initializeServices();

    // Create provider container
    final container = ProviderContainer(overrides: overrides);

    // For web, use initialization screen
    // For mobile (iOS/Android), use splash screen
    final String initialRoute = kIsWeb ? '/initialization' : '/splash';

    print('✅ App initialization completed');
    print('📱 Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('🔗 Initial route: $initialRoute');

    runApp(
      ProviderScope(
        parent: container,
        child: MyApp(initialRoute: initialRoute),
      ),
    );
  }, (error, stack) {
    print('💥 Fatal error during app initialization: $error');
    print('📋 Stack trace: $stack');

    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'A fatal error occurred during startup: ${error.toString()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D4EDD),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
