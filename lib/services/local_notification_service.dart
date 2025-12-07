import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _notificationEnabledKey = 'notifications_enabled';

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (kIsWeb) return; // Local notifications don't work on web

    // Only initialize notifications on iOS for Google Play compliance
    if (!Platform.isIOS) return;

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for iOS only
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Check if notifications are enabled in settings
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true; // Default to enabled
  }

  /// Enable or disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);

    if (!enabled) {
      // Cancel all scheduled notifications when disabled
      await cancelAllNotifications();
    }
  }

  /// Show an immediate notification (iOS only for Google Play compliance)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications

    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Schedule a notification for later (iOS only for Google Play compliance)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications

    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a specific notification by ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Show helpful notifications for thesis generation
  static Future<void> showThesisGenerationComplete() async {
    await showNotification(
      id: 1,
      title: '🎓 Thesis Generation Complete!',
      body: 'Your thesis has been successfully generated. Tap to view.',
      payload: 'thesis_complete',
    );
  }

  /// Show reminder to save work
  static Future<void> showSaveReminder() async {
    await showNotification(
      id: 2,
      title: '💾 Don\'t forget to save!',
      body: 'Remember to save your thesis progress regularly.',
      payload: 'save_reminder',
    );
  }

  /// Schedule daily writing reminder
  static Future<void> scheduleDailyWritingReminder() async {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + 1,
      9, // 9 AM
      0,
    );

    await scheduleNotification(
      id: 3,
      title: '✍️ Time to write!',
      body: 'Continue working on your thesis. Every word counts!',
      scheduledDate: scheduledDate,
      payload: 'daily_reminder',
    );
  }

  // ============================================
  // RETENTION NOTIFICATION SYSTEM
  // ============================================

  static const String _lastNotificationDateKey = 'last_notification_date';
  static const String _notificationIndexKey = 'notification_index';

  /// List of retention messages to rotate through
  static const List<Map<String, String>> _retentionMessages = [
    {
      'title': '🎓 Your thesis awaits!',
      'body':
          'Every great achievement starts with a single step. Continue your academic journey today!',
    },
    {
      'title': '✍️ Time to shine academically!',
      'body':
          'Your future success depends on the work you do today. Let\'s make progress on your thesis!',
    },
    {
      'title': '📚 Knowledge is power!',
      'body':
          'Transform your ideas into a brilliant thesis. Your academic dreams are within reach!',
    },
    {
      'title': '🌟 You\'re closer than you think!',
      'body':
          'Each word you write brings you closer to graduation. Don\'t give up on your goals!',
    },
    {
      'title': '🚀 Launch your academic success!',
      'body':
          'Your thesis is the key to your future. Take 10 minutes today to make meaningful progress!',
    },
    {
      'title': '💡 Brilliant ideas need action!',
      'body':
          'Turn your research into reality. Your thesis won\'t write itself - but we\'re here to help!',
    },
    {
      'title': '🎯 Stay focused on your goal!',
      'body':
          'Success is a series of small wins. Add another chapter to your academic success story!',
    },
    {
      'title': '⭐ You\'re meant for greatness!',
      'body':
          'Your dedication will pay off. Let\'s continue building your masterpiece thesis together!',
    },
    {
      'title': '🔥 Keep the momentum going!',
      'body':
          'You\'ve come so far already. Don\'t let your hard work go to waste - continue today!',
    },
    {
      'title': '🏆 Champions finish what they start!',
      'body':
          'Your thesis is your ticket to success. Make today count towards your academic victory!',
    },
    {
      'title': '📝 Your story deserves to be told!',
      'body':
          'Every thesis tells a unique story. What will yours say about your dedication and brilliance?',
    },
    {
      'title': '🌈 Success is just around the corner!',
      'body':
          'The finish line is closer than it appears. Take another step forward in your thesis journey!',
    },
    {
      'title': '💪 You have the strength to succeed!',
      'body':
          'Academic challenges are meant to be conquered. Show your thesis who\'s in charge!',
    },
    {
      'title': '🎨 Create your academic masterpiece!',
      'body':
          'Your thesis is your canvas. Paint a picture of excellence that reflects your hard work!',
    },
    {
      'title': '⚡ Energize your academic goals!',
      'body':
          'Procrastination is the enemy of progress. Strike while the iron is hot and continue writing!',
    },
    {
      'title': '🌅 New day, new opportunities!',
      'body':
          'Today is perfect for making thesis progress. Your future self will thank you for starting now!',
    },
    {
      'title': '🎪 Make academics exciting again!',
      'body':
          'Learning should be thrilling! Rediscover the joy of research and writing with your thesis.',
    },
    {
      'title': '🗝️ Unlock your potential!',
      'body':
          'Your thesis is the key that unlocks countless opportunities. Don\'t keep success waiting!',
    },
    {
      'title': '🌸 Let your ideas bloom!',
      'body':
          'Like flowers in spring, your ideas need nurturing. Water them with dedication today!',
    },
    {
      'title': '🎭 Play the role of a scholar!',
      'body':
          'You\'re the protagonist in your academic story. What amazing chapter will you write today?',
    },
  ];

  /// Get the next retention message to show
  static Future<Map<String, String>> _getNextRetentionMessage() async {
    final prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt(_notificationIndexKey) ?? 0;

    // Get the message for current index
    final message =
        _retentionMessages[currentIndex % _retentionMessages.length];

    // Update index for next time
    await prefs.setInt(
        _notificationIndexKey, (currentIndex + 1) % _retentionMessages.length);

    return message;
  }

  /// Check if we should send a retention notification today
  static Future<bool> _shouldSendRetentionNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationDate = prefs.getString(_lastNotificationDateKey);
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

    return lastNotificationDate != today;
  }

  /// Mark that we've sent a notification today
  static Future<void> _markNotificationSent() async {
    final prefs = await SharedPreferences.getInstance();
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    await prefs.setString(_lastNotificationDateKey, today);
  }

  /// Schedule the next retention notification (iOS only)
  static Future<void> scheduleNextRetentionNotification() async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications

    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    final shouldSend = await _shouldSendRetentionNotification();
    if (!shouldSend) return; // Already sent today

    // Schedule for a random time between 10 AM and 6 PM tomorrow
    final random = Random();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final randomHour = 10 + random.nextInt(8); // 10 AM to 6 PM
    final randomMinute = random.nextInt(60);

    final scheduledDate = tomorrow.add(Duration(
      hours: randomHour,
      minutes: randomMinute,
    ));

    final message = await _getNextRetentionMessage();

    await scheduleNotification(
      id: 1000 + (DateTime.now().millisecondsSinceEpoch % 1000), // Unique ID
      title: message['title']!,
      body: message['body']!,
      scheduledDate: scheduledDate,
      payload: 'retention_notification',
    );

    await _markNotificationSent();
    print('📅 Retention notification scheduled for: $scheduledDate');
  }

  /// Schedule multiple retention notifications (for the next 7 days) - iOS only
  static Future<void> scheduleWeeklyRetentionNotifications() async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications

    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Cancel any existing retention notifications
    for (int i = 1000; i < 1007; i++) {
      await cancelNotification(i);
    }

    final random = Random();
    final now = DateTime.now();

    for (int day = 1; day <= 7; day++) {
      final targetDate = DateTime(now.year, now.month, now.day + day);
      final randomHour = 10 + random.nextInt(8); // 10 AM to 6 PM
      final randomMinute = random.nextInt(60);

      final scheduledDate = targetDate.add(Duration(
        hours: randomHour,
        minutes: randomMinute,
      ));

      final messageIndex = (day - 1) % _retentionMessages.length;
      final message = _retentionMessages[messageIndex];

      await scheduleNotification(
        id: 1000 + day - 1, // IDs 1000-1006
        title: message['title']!,
        body: message['body']!,
        scheduledDate: scheduledDate,
        payload: 'retention_notification_day_$day',
      );
    }

    print('📅 Weekly retention notifications scheduled for next 7 days');
  }

  /// Send an immediate retention notification (for testing)
  static Future<void> sendTestRetentionNotification() async {
    final message = await _getNextRetentionMessage();

    await showNotification(
      id: 9999,
      title: message['title']!,
      body: message['body']!,
      payload: 'test_retention',
    );
  }

  /// Initialize retention notification system (iOS only)
  static Future<void> initializeRetentionSystem() async {
    if (kIsWeb || !Platform.isIOS) return; // Only iOS notifications

    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Schedule weekly notifications
    await scheduleWeeklyRetentionNotifications();

    print('✅ Retention notification system initialized');
  }

  /// Reset retention notification system (useful for testing)
  static Future<void> resetRetentionSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationDateKey);
    await prefs.remove(_notificationIndexKey);

    // Cancel all retention notifications
    for (int i = 1000; i < 1010; i++) {
      await cancelNotification(i);
    }

    print('🔄 Retention notification system reset');
  }
}
