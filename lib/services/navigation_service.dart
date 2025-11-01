import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateToHome() {
    navigatorKey.currentState?.pushReplacementNamed(AppRoutes.home);
  }

  static void navigateToOnboard() {
    navigatorKey.currentState?.pushReplacementNamed(AppRoutes.onboard);
  }

  static void navigateToOutline() {
    navigatorKey.currentState?.pushNamed(AppRoutes.outline);
  }

  static void navigateToExport() {
    navigatorKey.currentState?.pushNamed(AppRoutes.export);
  }
}
