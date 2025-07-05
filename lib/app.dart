import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/navigation_service.dart';
import 'screens/splash_screen.dart';
import 'screens/initialization_screen.dart';
import 'screens/thesis_form_screen.dart';
import 'screens/outline_viewer_screen.dart';
import 'screens/export_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/language_selection_screen.dart';
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
// Auth and subscription screens
import 'screens/signin_screen.dart';
import 'screens/paywall_screen.dart';
// Providers
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
// Widgets
import 'widgets/protected_route.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// Only import html for web-specific functionality
import 'package:universal_html/html.dart' as html show window, document;

class MyApp extends ConsumerWidget {
  final String initialRoute;
  const MyApp({
    super.key,
    this.initialRoute = '/initialization',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: _buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      initialRoute: '/initialization',
      routes: _buildAppRoutes(),
      onGenerateRoute: _handleDynamicRoutes,
      onUnknownRoute: _handleUnknownRoute,
      builder: (context, child) {
        return _AppWrapper(child: child);
      },
    );
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
      cardTheme: CardThemeData(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
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
      '/initialization': (context) => const InitializationScreen(),
      '/signin': (context) => const SignInScreen(),
      '/paywall': (context) => const PaywallScreen(),
      '/language': (context) => const LanguageSelectionScreen(),
      '/onboard': (context) => const OnBoardScreen(),
      '/thesis-form': (context) => const ProtectedRoute(
        child: ThesisFormScreen(),
        requiresSubscription: true,
      ),
      '/apiKey': (context) => const ProtectedRoute(
        child: ApiKeyScreen(),
        requiresSubscription: true,
      ),
      '/outline': (context) => const ProtectedRoute(
        child: OutlineViewerScreen(),
        requiresSubscription: true,
      ),
      '/export': (context) => const ProtectedRoute(
        child: ExportScreen(),
        requiresSubscription: true,
      ),

      // New onboarding flow routes
      '/onboarding1': (context) => const ProtectedRoute(
        child: OnboardingScreen1(),
        requiresSubscription: true,
      ),
      '/onboarding2': (context) => const ProtectedRoute(
        child: OnboardingScreen2(),
        requiresSubscription: true,
      ),
      '/onboarding3': (context) => const ProtectedRoute(
        child: OnboardingScreen3(),
        requiresSubscription: true,
      ),
      '/subject-selection': (context) => const ProtectedRoute(
        child: SubjectSelectionScreen(),
        requiresSubscription: true,
      ),
      '/academic-level': (context) => const ProtectedRoute(
        child: AcademicLevelScreen(),
        requiresSubscription: true,
      ),
      '/page-count': (context) => const ProtectedRoute(
        child: PageCountScreen(),
        requiresSubscription: true,
      ),
      '/processing': (context) => const ProtectedRoute(
        child: ProcessingScreen(),
        requiresSubscription: true,
      ),
      '/thesis-preview': (context) => const ProtectedRoute(
        child: ThesisPreviewScreen(),
        requiresSubscription: true,
      ),
      '/thesis-details': (context) => const ProtectedRoute(
        child: ThesisDetailsScreen(),
        requiresSubscription: true,
      ),
    };
  }

  /// Handle dynamic routes with parameters
  Route<dynamic>? _handleDynamicRoutes(RouteSettings settings) {
    // Handle chapter editor with parameters
    if (settings.name == '/chapter-editor') {
      final args = settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        return MaterialPageRoute(
          builder: (context) => ProtectedRoute(
            requiresSubscription: true,
            child: ChapterEditorScreen(
              chapterTitle: args['chapterTitle'] ?? 'Chapter',
              subheading: args['subheading'] ?? '',
              initialContent: args['initialContent'] ?? '',
              chapterIndex: args['chapterIndex'] ?? 0,
            ),
          ),
          settings: settings,
        );
      }
    }

    return null;
  }

  /// Handle unknown routes
  Route<dynamic> _handleUnknownRoute(RouteSettings settings) {
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/initialization',
                      (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Go to App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                try {
                  html.window.location.href = 'index.html';
                } catch (e) {
                  // Fallback: try to navigate within the app
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/initialization',
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

  /// Get platform-specific configuration
  static Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': 'web',
      'isWeb': true,
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
}

/// Error handling utilities
class AppErrorHandler {
  /// Handle and log errors
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    final errorMessage = error.toString();
    final contextInfo = context ?? 'Unknown';

    print('❌ Error in $contextInfo: $errorMessage');

    if (stackTrace != null) {
      print('📋 Stack trace: $stackTrace');
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

