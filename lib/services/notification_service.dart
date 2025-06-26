import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'navigation_service.dart';

class NotificationService {
  static const String oneSignalAppId = "2bf37a32-a17f-4587-9cbb-9c0017a73415";

  static Future<void> initialize() async {
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    // Handle notifications when app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Handle when user taps notification
    OneSignal.Notifications.addClickListener((event) {
      if (event.notification.additionalData != null) {
        final data = event.notification.additionalData!;
        final route = data['route'] as String? ?? '/thesis-form';
        NavigationService.navigatorKey.currentState?.pushNamed(route);
      }
    });
  }
}
