import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onesignal_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Automated Notification Service
/// Monitors user activity and triggers OneSignal notifications based on behavior
/// This replaces Firebase Cloud Functions since we're on the free tier
class NotificationAutomationService {
  static final NotificationAutomationService _instance =
      NotificationAutomationService._internal();
  factory NotificationAutomationService() => _instance;
  NotificationAutomationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OneSignalService _oneSignal = OneSignalService();

  static const String oneSignalAppId = '4b4333e8-9e9d-4636-974b-b7950b3341d2';
  static const String oneSignalRestApiKey =
      'os_v2_app_g2icp4vjzfgdzeruayxhqura4ebyq3cyeuyewofdnxfahb7i5x4tbixt4hjlcornqqgxdm2lzh5ouogqged66tjidgurtll2dhjyopi';

  Timer? _inactivityTimer;
  StreamSubscription? _thesisListener;

  /// Initialize the automation service
  Future<void> initialize(User user) async {
    print('🤖 Initializing Notification Automation Service for ${user.email}');

    // Start monitoring for automated notifications
    await _setupWelcomeNotification(user);
    await _monitorThesisProgress(user);
    await _setupInactivityMonitoring(user);
    await _checkForIncompleteTheses(user);
  }

  /// Send welcome push notification (30 seconds after signup)
  Future<void> _setupWelcomeNotification(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasReceivedWelcome =
          prefs.getBool('welcome_notification_sent') ?? false;

      if (!hasReceivedWelcome) {
        // Wait 30 seconds before sending welcome (user has time to explore)
        await Future.delayed(const Duration(seconds: 30));

        await _sendPushNotification(
          userId: user.uid,
          heading: '🎓 Welcome to Thesis Generator!',
          content:
              'Let\'s create your first thesis in minutes. Tap to get started!',
          data: {'type': 'welcome', 'route': '/thesis-form'},
        );

        await prefs.setBool('welcome_notification_sent', true);
        print('✅ Welcome notification sent');
      }
    } catch (e) {
      print('❌ Failed to send welcome notification: $e');
    }
  }

  /// Monitor thesis progress and send notifications
  Future<void> _monitorThesisProgress(User user) async {
    try {
      _thesisListener?.cancel();
      _thesisListener = _firestore
          .collection('theses')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified ||
              change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            final thesisId = change.doc.id;
            final status = data['status'] ?? '';
            final progress = (data['progressPercentage'] ?? 0.0) as double;
            final title = data['title'] ?? 'Your thesis';

            // Incomplete thesis reminder (started but not finished)
            if (progress > 0 && progress < 100 && status != 'completed') {
              await _scheduleIncompleteThesisReminder(
                  user, thesisId, title, progress);
            }

            // Generation complete notification
            if (status == 'completed' || progress >= 100) {
              await _sendThesisCompletionNotification(user, thesisId, title);
            }

            // Export reminder (completed but not exported)
            if (status == 'completed' && status != 'exported') {
              await _scheduleExportReminder(user, thesisId, title);
            }
          }
        }
      });

      print('✅ Thesis progress monitoring enabled');
    } catch (e) {
      print('❌ Failed to setup thesis monitoring: $e');
    }
  }

  /// Send thesis completion notification
  Future<void> _sendThesisCompletionNotification(
      User user, String thesisId, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationKey = 'completion_notification_$thesisId';
      final hasNotified = prefs.getBool(notificationKey) ?? false;

      if (!hasNotified) {
        await _sendPushNotification(
          userId: user.uid,
          heading: '🎉 Your Thesis is Ready!',
          content:
              '"$title" is fully generated and ready to export. Tap to review!',
          data: {
            'type': 'thesis_complete',
            'thesisId': thesisId,
            'route': '/export',
          },
        );

        await prefs.setBool(notificationKey, true);
        print('✅ Thesis completion notification sent for: $title');
      }
    } catch (e) {
      print('❌ Failed to send completion notification: $e');
    }
  }

  /// Schedule incomplete thesis reminder
  Future<void> _scheduleIncompleteThesisReminder(
      User user, String thesisId, String title, double progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderKey = 'incomplete_reminder_$thesisId';
      final lastReminder = prefs.getInt(reminderKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only send reminder once per 24 hours
      if (now - lastReminder > 86400000) {
        await _sendPushNotification(
          userId: user.uid,
          heading: '📝 Continue Your Thesis',
          content:
              '"$title" is ${progress.toInt()}% complete. Let\'s finish it!',
          data: {
            'type': 'incomplete_thesis',
            'thesisId': thesisId,
            'route': '/outline',
          },
        );

        await prefs.setInt(reminderKey, now);
        print('✅ Incomplete thesis reminder sent for: $title');
      }
    } catch (e) {
      print('❌ Failed to schedule incomplete thesis reminder: $e');
    }
  }

  /// Schedule export reminder
  Future<void> _scheduleExportReminder(
      User user, String thesisId, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderKey = 'export_reminder_$thesisId';
      final hasSent = prefs.getBool(reminderKey) ?? false;

      if (!hasSent) {
        // Wait 1 hour before sending export reminder
        await Future.delayed(const Duration(hours: 1));

        // Verify thesis is still not exported
        final doc = await _firestore.collection('theses').doc(thesisId).get();
        final status = doc.data()?['status'] ?? '';

        if (status != 'exported') {
          await _sendPushNotification(
            userId: user.uid,
            heading: '📄 Don\'t Forget to Export',
            content:
                'Your thesis "$title" is ready. Export it as PDF or Word now!',
            data: {
              'type': 'export_reminder',
              'thesisId': thesisId,
              'route': '/export',
            },
          );

          await prefs.setBool(reminderKey, true);
          print('✅ Export reminder sent for: $title');
        }
      }
    } catch (e) {
      print('❌ Failed to schedule export reminder: $e');
    }
  }

  /// Setup inactivity monitoring (3-day and 7-day re-engagement)
  Future<void> _setupInactivityMonitoring(User user) async {
    try {
      _inactivityTimer?.cancel();

      // Check every 6 hours for inactivity
      _inactivityTimer =
          Timer.periodic(const Duration(hours: 6), (timer) async {
        await _checkInactivity(user);
      });

      print('✅ Inactivity monitoring enabled');
    } catch (e) {
      print('❌ Failed to setup inactivity monitoring: $e');
    }
  }

  /// Check for user inactivity and send re-engagement notifications
  Future<void> _checkInactivity(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityKey = 'last_activity_${user.uid}';
      final lastActivity = prefs.getInt(lastActivityKey) ??
          DateTime.now().millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceActivity = (now - lastActivity) / 86400000;

      // 3-day inactive notification
      if (daysSinceActivity >= 3 && daysSinceActivity < 4) {
        final hasIncompleteTheses = await _hasIncompleteTheses(user);

        if (hasIncompleteTheses) {
          await _sendPushNotification(
            userId: user.uid,
            heading: '💡 Save Time on Your Thesis',
            content:
                'Students who complete their thesis save 10+ hours. Continue yours now!',
            data: {'type': 'reengagement_3day', 'route': '/history'},
          );
          print('✅ 3-day re-engagement notification sent');
        }
      }

      // 7-day inactive notification
      if (daysSinceActivity >= 7 && daysSinceActivity < 8) {
        await _sendPushNotification(
          userId: user.uid,
          heading: '🎯 Need a Research Paper?',
          content:
              'Essay? Thesis? Research paper? We\'re here to help. Open now!',
          data: {'type': 'reengagement_7day', 'route': '/thesis-form'},
        );
        print('✅ 7-day re-engagement notification sent');
      }
    } catch (e) {
      print('❌ Failed to check inactivity: $e');
    }
  }

  /// Update last activity timestamp
  Future<void> updateLastActivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastActivityKey = 'last_activity_${user.uid}';
      await prefs.setInt(
          lastActivityKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Failed to update last activity: $e');
    }
  }

  /// Check for incomplete theses
  Future<void> _checkForIncompleteTheses(User user) async {
    try {
      // Wait 2 hours before checking
      await Future.delayed(const Duration(hours: 2));

      final theses = await _firestore
          .collection('theses')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['draft', 'in_progress']).get();

      if (theses.docs.isNotEmpty) {
        final thesis = theses.docs.first;
        final title = thesis.data()['title'] ?? 'Your thesis';

        await _sendPushNotification(
          userId: user.uid,
          heading: '📝 Your Thesis Awaits',
          content: 'Complete your outline for "$title" and we\'ll generate it!',
          data: {
            'type': 'incomplete_thesis',
            'thesisId': thesis.id,
            'route': '/outline',
          },
        );
        print('✅ Incomplete thesis check notification sent');
      }
    } catch (e) {
      print('❌ Failed to check incomplete theses: $e');
    }
  }

  /// Check if user has incomplete theses
  Future<bool> _hasIncompleteTheses(User user) async {
    try {
      final theses = await _firestore
          .collection('theses')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['draft', 'in_progress']).limit(1).get();

      return theses.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Send push notification via OneSignal REST API
  Future<void> _sendPushNotification({
    required String userId,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's OneSignal ID from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final oneSignalId = userDoc.data()?['oneSignalId'];

      if (oneSignalId == null) {
        print('⚠️ User has no OneSignal ID, skipping notification');
        return;
      }

      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'include_player_ids': [oneSignalId],
          'headings': {'en': heading},
          'contents': {'en': content},
          'data': data ?? {},
          'ios_badgeType': 'Increase',
          'ios_badgeCount': 1,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully: $heading');
      } else {
        print(
            '❌ Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  /// Send milestone notification
  Future<void> sendMilestoneNotification(
      User user, String milestone, String message) async {
    await _sendPushNotification(
      userId: user.uid,
      heading: '🏆 $milestone',
      content: message,
      data: {'type': 'milestone', 'route': '/history'},
    );
  }

  /// Send thesis word count milestone
  Future<void> sendWordCountMilestone(
      User user, String thesisId, int wordCount) async {
    await _sendPushNotification(
      userId: user.uid,
      heading: '📈 Impressive Progress!',
      content: 'Your thesis has reached $wordCount words. Keep going!',
      data: {
        'type': 'word_count_milestone',
        'thesisId': thesisId,
        'route': '/outline',
      },
    );
  }

  /// Dispose and cleanup
  void dispose() {
    _inactivityTimer?.cancel();
    _thesisListener?.cancel();
  }
}
