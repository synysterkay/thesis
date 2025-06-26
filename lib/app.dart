import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/navigation_service.dart';
import 'screens/splash_screen.dart';
import 'screens/thesis_form_screen.dart';
import 'screens/outline_viewer_screen.dart';
import 'screens/export_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/language_selection_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/chapter_editor_screen.dart';
import 'screens/onboard_screen.dart';
import 'providers/locale_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'providers/analytics_provider.dart';
import 'screens/api_key_screen.dart';
// New onboarding screens
import 'screens/onboarding/onboarding_screen1.dart';
import 'screens/onboarding/onboarding_screen2.dart';
import 'screens/onboarding/onboarding_screen3.dart';
import 'screens/onboarding/subject_selection_screen.dart';
import 'screens/onboarding/academic_level_screen.dart';
import 'screens/onboarding/page_count_screen.dart';
import 'screens/onboarding/processing_screen.dart';
import 'screens/onboarding/thesis_preview_screen.dart';
import 'screens/onboarding/thesis_details_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// Only import html for web-specific functionality
import 'package:universal_html/html.dart' as html show window, document;

class MyApp extends ConsumerWidget {
  final String initialRoute;
  const MyApp({
    super.key,
   this.initialRoute = '/thesis-form', 
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final analytics = ref.watch(analyticsProvider);

    // Determine the initial route based on platform
    String effectiveInitialRoute = _determineInitialRoute();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es'),
        Locale('fr'),
        Locale('zh'),
        Locale('hi'),
      ],
      theme: _buildAppTheme(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      initialRoute: effectiveInitialRoute,
      routes: _buildAppRoutes(),
      onGenerateRoute: _handleDynamicRoutes,
      onUnknownRoute: _handleUnknownRoute,
      builder: (context, child) {
        return _AppWrapper(child: child);
      },
    );
  }

  /// Determine the initial route based on platform and URL
  String _determineInitialRoute() {
    if (kIsWeb) {
      try {
        // Simple web routing - avoid complex HTML operations
        if (initialRoute == '/thesis-form' || initialRoute.contains('thesis')) {
          return '/thesis-form';
        }

        // Default web route - go directly to thesis form
        return '/thesis-form';
      } catch (e) {
        debugPrint('Error determining web route: $e');
        return '/thesis-form';
      }
    } else {
      // Mobile app - use splash screen
      return initialRoute.isEmpty ? '/' : initialRoute;
    }
  }

  /// Build the app theme
  ThemeData _buildAppTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF9D4EDD),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9D4EDD),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9D4EDD),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9D4EDD),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9D4EDD)),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF9D4EDD),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[700],
        thickness: 1,
      ),
    );
  }

  /// Build all app routes
  Map<String, WidgetBuilder> _buildAppRoutes() {
    return {
      '/': (context) => const SplashScreen(),
      '/language': (context) => const LanguageSelectionScreen(),
      '/onboard': (context) => const OnBoardScreen(),
      '/thesis-form': (context) => const ThesisFormScreen(),
      '/apiKey': (context) => const ApiKeyScreen(),
      '/outline': (context) => const OutlineViewerScreen(),
      '/export': (context) => const ExportScreen(),

      // New onboarding flow routes
      '/onboarding1': (context) => const OnboardingScreen1(),
      '/onboarding2': (context) => const OnboardingScreen2(),
      '/onboarding3': (context) => const OnboardingScreen3(),
      '/subject-selection': (context) => const SubjectSelectionScreen(),
      '/academic-level': (context) => const AcademicLevelScreen(),
      '/page-count': (context) => const PageCountScreen(),
      '/processing': (context) => const ProcessingScreen(),
      '/thesis-preview': (context) => const ThesisPreviewScreen(),
      '/thesis-details': (context) => const ThesisDetailsScreen(),
    };
  }

  /// Handle dynamic routes with parameters
  Route<dynamic>? _handleDynamicRoutes(RouteSettings settings) {
    // Handle chapter editor with parameters
    if (settings.name == '/chapter-editor') {
      final args = settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        return MaterialPageRoute(
          builder: (context) => ChapterEditorScreen(
            chapterTitle: args['chapterTitle'] ?? 'Chapter',
            subheading: args['subheading'] ?? '',
            initialContent: args['initialContent'] ?? '',
            chapterIndex: args['chapterIndex'] ?? 0,
          ),
          settings: settings,
        );
      }
    }

    return null;
  }

  /// Handle unknown routes
  Route<dynamic> _handleUnknownRoute(RouteSettings settings) {
    debugPrint('Unknown route: ${settings.name}');

    return MaterialPageRoute(
      builder: (context) => const _NotFoundScreen(),
      settings: settings,
    );
  }
}

/// App wrapper for global functionality
class _AppWrapper extends StatelessWidget {
  final Widget? child;

  const _AppWrapper({this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// 404 Not Found Screen
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Color(0xFF9D4EDD),
            ),
            const SizedBox(height: 24),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The page you are looking for doesn\'t exist or has been moved.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (kIsWeb) {
                  // For web, navigate to thesis form
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/thesis-form',
                        (route) => false,
                  );
                } else {
                  // For mobile, go to splash screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                        (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.home),
              label: Text(kIsWeb ? 'Go to App' : 'Go Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  try {
                    html.window.location.href = 'index.html';
                  } catch (e) {
                    debugPrint('Failed to navigate to landing page: $e');
                    // Fallback: try to navigate within the app
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/thesis-form',
                          (route) => false,
                    );
                  }
                },
                child: const Text(
                  '← Back to Landing Page',
                  style: TextStyle(color: Color(0xFFFF48B0)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// App configuration and utilities
class AppConfig {
  static const String appName = 'Thesis Generator';
  static const String version = '12.0.0+12';
  static const Color primaryColor = Color(0xFF9D4EDD);
  static const Color secondaryColor = Color(0xFFFF48B0);

  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Get platform-specific configuration
  static Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': kIsWeb ? 'web' : 'mobile',
      'isWeb': kIsWeb,
      'isDebug': kDebugMode,
      'version': version,
      'appName': appName,
    };
  }

  /// Get supported locales
  static List<Locale> get supportedLocales => const [
    Locale('en', 'US'),
    Locale('es'),
    Locale('fr'),
    Locale('zh'),
    Locale('hi'),
  ];

  /// Get theme colors
  static Map<String, Color> get themeColors => {
    'primary': primaryColor,
    'secondary': secondaryColor,
    'background': Colors.black,
    'surface': Colors.grey[900]!,
    'error': Colors.red[400]!,
    'onPrimary': Colors.white,
    'onSecondary': Colors.white,
    'onBackground': Colors.white,
    'onSurface': Colors.white,
    'onError': Colors.white,
  };
}

/// Navigation utilities
class AppNavigation {
  /// Navigate to thesis form with optional parameters
  static void navigateToThesisForm(BuildContext context, {
    String? topic,
    List<String>? chapters,
  }) {
    if (topic != null || chapters != null) {
      Navigator.pushNamed(
        context,
        '/thesis-form',
        arguments: {
          if (topic != null) 'topic': topic,
          if (chapters != null) 'chapters': chapters,
        },
      );
    } else {
      Navigator.pushNamed(context, '/thesis-form');
    }
  }

  /// Navigate to chapter editor
  static void navigateToChapterEditor(
      BuildContext context, {
        required String chapterTitle,
        required String subheading,
        required String initialContent,
        required int chapterIndex,
      }) {
    Navigator.pushNamed(
      context,
      '/chapter-editor',
      arguments: {
        'chapterTitle': chapterTitle,
        'subheading': subheading,
        'initialContent': initialContent,
        'chapterIndex': chapterIndex,
      },
    );
  }

  /// Navigate back with result
  static void navigateBackWithResult(BuildContext context, dynamic result) {
    Navigator.of(context).pop(result);
  }

  /// Navigate to route and clear stack
  static void navigateAndClearStack(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
          (route) => false,
    );
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Handle web-specific navigation (simplified)
  static void handleWebNavigation(String path) {
    if (!kIsWeb) return;

    try {
      // Simple URL update without complex operations
      if (kDebugMode) {
        debugPrint('Web navigation to: $path');
      }
    } catch (e) {
      debugPrint('Failed to update web navigation: $e');
    }
  }
}

/// App state management utilities
class AppState {
  /// Check if app is running in PWA mode (simplified)
  static bool get isPWA {
    if (!kIsWeb) return false;

    try {
      // Simplified PWA detection
      return false; // Default to false to avoid complex web API calls
    } catch (e) {
      return false;
    }
  }

  /// Get device type (simplified)
  static String get deviceType {
    if (!kIsWeb) return 'mobile';

    try {
      // Simplified device detection
      return 'web';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get screen size category
  static String getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return 'small';
    } else if (width < 1024) {
      return 'medium';
    } else {
      return 'large';
    }
  }

  /// Check if dark mode is preferred
  static bool isDarkModePreferred(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}

/// Performance monitoring utilities
class AppPerformance {
  static final Map<String, DateTime> _timers = {};

  /// Start performance timer
  static void startTimer(String name) {
    _timers[name] = DateTime.now();
    if (kDebugMode) {
      debugPrint('⏱️ Started timer: $name');
    }
  }

  /// End performance timer and log duration
  static Duration? endTimer(String name) {
    final startTime = _timers.remove(name);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('⏱️ Timer $name: ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Log memory usage (debug only)
  static void logMemoryUsage(String context) {
    if (!kDebugMode) return;

    try {
      // This is a placeholder - actual memory monitoring would require platform channels
      debugPrint('💾 Memory check: $context');
    } catch (e) {
      debugPrint('Failed to log memory usage: $e');
    }
  }

  /// Log app lifecycle event
  static void logLifecycleEvent(String event) {
    if (kDebugMode) {
      debugPrint('🔄 Lifecycle: $event at ${DateTime.now()}');
    }
  }
}

/// Error handling utilities
class AppErrorHandler {
  /// Handle and log errors
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    final errorMessage = error.toString();
    final contextInfo = context ?? 'Unknown';

    debugPrint('❌ Error in $contextInfo: $errorMessage');

    if (stackTrace != null && kDebugMode) {
      debugPrint('📋 Stack trace: $stackTrace');
    }

    // Log to analytics if available
    _logErrorToAnalytics(errorMessage, contextInfo);
  }

  /// Log error to analytics
  static void _logErrorToAnalytics(String error, String context) {
    try {
      // This would integrate with your analytics provider
      if (kDebugMode) {
        debugPrint('📊 Would log error to analytics: $context - $error');
      }
    } catch (e) {
      debugPrint('Failed to log error to analytics: $e');
    }
  }

  /// Show user-friendly error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success message
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show info message
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF9D4EDD),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Loading state management
class AppLoading {
  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF9D4EDD),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show loading overlay
  static Widget buildLoadingOverlay({String? message}) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF9D4EDD),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme utilities
class AppTheme {
  static const Color primaryColor = Color(0xFF9D4EDD);
  static const Color secondaryColor = Color(0xFFFF48B0);
  static const Color backgroundColor = Colors.black;
  static final Color surfaceColor = Colors.grey[900]!;

  /// Get gradient for buttons
  static LinearGradient get buttonGradient => const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get text styles
  static TextStyle get headingStyle => const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get subheadingStyle => const TextStyle(
    color: Colors.white70,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyStyle => const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );

  static TextStyle get captionStyle => const TextStyle(
    color: Colors.white54,
    fontSize: 14,
  );

  /// Get input decoration
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
    );
  }

  /// Get card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  /// Get button style
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 4,
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
}

/// Responsive utilities
class AppResponsive {
  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  /// Get responsive width
  static double getResponsiveWidth(BuildContext context, {double maxWidth = 800}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > maxWidth ? maxWidth : screenWidth;
  }
}

