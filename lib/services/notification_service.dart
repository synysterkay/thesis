import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'navigation_service.dart';

class NotificationService {
  static const String oneSignalAppId = "2bf37a32-a17f-4587-9cbb-9c0017a73415";
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

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
        final thesisId = data['thesisId'] as String?;

        if (thesisId != null && route.contains('export')) {
          NavigationService.navigatorKey.currentState?.pushNamed(
            '/export-trial',
            arguments: {'thesisId': thesisId},
          );
        } else if (thesisId != null && route.contains('outline')) {
          NavigationService.navigatorKey.currentState?.pushNamed(
            '/outline-trial',
            arguments: {'thesisId': thesisId},
          );
        } else {
          NavigationService.navigatorKey.currentState?.pushNamed(route);
        }
      }
    });
  }

  /// Send generation complete notification
  Future<void> sendGenerationCompleteNotification(
      String thesisTopic, String thesisId) async {
    // For now, we'll use a simple approach
    // In a real implementation, this would send a push notification
    print('🎉 Thesis Generation Complete: "$thesisTopic" is ready for export');

    // TODO: Implement actual notification sending
    // This could be done through OneSignal's REST API or other notification service
  }

  /// Send progress notification (optional)
  Future<void> sendProgressNotification(
      String thesisTopic, double progress) async {
    print(
        'Generating "$thesisTopic": ${progress.toStringAsFixed(0)}% complete');

    // TODO: Implement actual progress notification
  }

  /// Cancel progress notification
  Future<void> cancelProgressNotification(String thesisTopic) async {
    // OneSignal doesn't have a direct cancel method for local notifications
    // This would be handled by the notification system automatically
  }

  /// Set user ID for targeted notifications
  Future<void> setUserId(String userId) async {
    await OneSignal.login(userId);
  }

  /// Send notification to specific user (for server-side use)
  static Future<void> sendNotificationToUser(
    String userId, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be called from a server/cloud function
    // Implementation depends on your backend setup
  }
}
