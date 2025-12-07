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

  /// Send welcome push notification + email (immediate after signup)
  Future<void> _setupWelcomeNotification(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasReceivedWelcome = prefs.getBool('welcome_notification_sent') ?? false;

      if (!hasReceivedWelcome) {
        // Wait 30 seconds before sending welcome (user has time to explore)
        await Future.delayed(const Duration(seconds: 30));

        final emailContent = '''
          <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h1 style="color: #2563EB;">🎓 Welcome to Thesis Generator!</h1>
              <p>Hi ${user.displayName ?? 'there'},</p>
              <p>We're thrilled to have you on board! You're just minutes away from generating your first professionally-written thesis.</p>
              
              <div style="background: #f8fafc; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h2 style="margin-top: 0; color: #1e40af;">Here's what you can do:</h2>
                <ul>
                  <li>✨ Generate complete, well-structured theses in minutes</li>
                  <li>📝 AI-powered content for all chapters</li>
                  <li>📄 Export to PDF or Word format</li>
                  <li>🎯 Perfect for students and researchers</li>
                </ul>
              </div>
              
              <p style="text-align: center; margin: 30px 0;">
                <a href="https://thesisgenerator.tech" style="background: linear-gradient(135deg, #2563EB, #1D4ED8); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold;">
                  Start Creating Your Thesis
                </a>
              </p>
              
              <p style="color: #64748b; font-size: 14px;">
                Need help? Just reply to this email or check our <a href="https://thesisgenerator.tech/help">help center</a>.
              </p>
              
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 30px 0;">
              
              <p style="color: #94a3b8; font-size: 12px; text-align: center;">
                © 2025 Thesis Generator. All rights reserved.
              </p>
            </div>
          </body>
          </html>
        ''';

        await _sendCombinedNotification(
          userId: user.uid,
          pushHeading: '🎓 Welcome to Thesis Generator!',
          pushContent:
              'Let\'s create your first thesis in minutes. Tap to get started!',
          emailSubject: '🎓 Welcome to Thesis Generator - Let\'s Get Started!',
          emailContent: emailContent,
          data: {'type': 'welcome', 'route': '/thesis-form'},
        );

        await prefs.setBool('welcome_notification_sent', true);
        print('✅ Welcome notification + email sent');
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

  /// Send thesis completion notification + email
  Future<void> _sendThesisCompletionNotification(
      User user, String thesisId, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationKey = 'completion_notification_$thesisId';
      final hasNotified = prefs.getBool(notificationKey) ?? false;

      if (!hasNotified) {
        final emailContent = '''
          <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h1 style="color: #16a34a;">🎉 Your Thesis is Complete!</h1>
              <p>Great news, ${user.displayName ?? 'there'}!</p>
              <p>Your thesis <strong>"$title"</strong> has been fully generated and is ready for review.</p>
              
              <div style="background: #f0fdf4; border-left: 4px solid #16a34a; padding: 20px; margin: 20px 0;">
                <h3 style="margin-top: 0; color: #15803d;">✅ What's Next?</h3>
                <ol>
                  <li>Review your thesis content</li>
                  <li>Make any necessary edits</li>
                  <li>Export to PDF or Word format</li>
                  <li>Submit with confidence!</li>
                </ol>
              </div>
              
              <p style="text-align: center; margin: 30px 0;">
                <a href="https://thesisgenerator.tech/export?thesisId=$thesisId" style="background: linear-gradient(135deg, #16a34a, #15803d); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold;">
                  Review & Export Your Thesis
                </a>
              </p>
              
              <p style="color: #64748b;">
                💡 <strong>Pro tip:</strong> Export your thesis in multiple formats to ensure compatibility with your institution's requirements.
              </p>
              
              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 30px 0;">
              
              <p style="color: #94a3b8; font-size: 12px; text-align: center;">
                © 2025 Thesis Generator. All rights reserved.
              </p>
            </div>
          </body>
          </html>
        ''';

        await _sendCombinedNotification(
          userId: user.uid,
          pushHeading: '🎉 Your Thesis is Ready!',
          pushContent:
              '"$title" is fully generated and ready to export. Tap to review!',
          emailSubject: '🎉 Your Thesis "$title" is Complete!',
          emailContent: emailContent,
          data: {
            'type': 'thesis_complete',
            'thesisId': thesisId,
            'route': '/export',
          },
        );

        await prefs.setBool(notificationKey, true);
        print('✅ Thesis completion notification + email sent for: $title');
      }
    } catch (e) {
      print('❌ Failed to send completion notification: $e');
    }
  }         'thesisId': thesisId,
            'route': '/outline',
          },
        );

        await prefs.setInt(reminderKey, now);
        print('✅ Incomplete thesis reminder scheduled for: $title');
      }
    } catch (e) {
      print('❌ Failed to schedule incomplete thesis reminder: $e');
    }
  }

  /// Send thesis completion notification
  Future<void> _sendThesisCompletionNotification(
  /// Check for user inactivity and send re-engagement notifications + emails
  Future<void> _checkInactivity(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityKey = 'last_activity_${user.uid}';
      final lastActivity = prefs.getInt(lastActivityKey) ??
          DateTime.now().millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceActivity = (now - lastActivity) / 86400000;

      // 3-day inactive notification + email
      if (daysSinceActivity >= 3 && daysSinceActivity < 4) {
        final hasIncompleteTheses = await _hasIncompleteTheses(user);

        if (hasIncompleteTheses) {
          final emailContent = '''
            <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
              <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #2563EB;">💡 Your Thesis is Waiting!</h1>
                <p>Hi ${user.displayName ?? 'there'},</p>
                <p>We noticed you have an incomplete thesis. Students who finish their thesis save 10+ hours of work!</p>
                
                <div style="background: #eff6ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
                  <h3 style="margin-top: 0; color: #1e40af;">📊 Did You Know?</h3>
                  <ul>
                    <li>Completing your thesis now saves you from last-minute stress</li>
                    <li>Our AI generates professional content in minutes</li>
                    <li>Export in multiple formats when you're ready</li>
                  </ul>
                </div>
                
                <p style="text-align: center; margin: 30px 0;">
                  <a href="https://thesisgenerator.tech/history" style="background: linear-gradient(135deg, #2563EB, #1D4ED8); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold;">
                    Continue Your Thesis
                  </a>
                </p>
              </div>
            </body>
            </html>
          ''';

          await _sendCombinedNotification(
            userId: user.uid,
            pushHeading: '💡 Save Time on Your Thesis',
            pushContent:
                'Students who complete their thesis save 10+ hours. Continue yours now!',
            emailSubject: '💡 Your Thesis is Waiting - Let\'s Finish It!',
            emailContent: emailContent,
            data: {'type': 'reengagement_3day', 'route': '/history'},
          );
          print('✅ 3-day re-engagement notification + email sent');
        }
      }

      // 7-day inactive notification + email
      if (daysSinceActivity >= 7 && daysSinceActivity < 8) {
        final emailContent = '''
          <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h1 style="color: #2563EB;">🎯 We Miss You!</h1>
              <p>Hi ${user.displayName ?? 'there'},</p>
              <p>It's been a week since we last saw you. Need help with a research paper, essay, or thesis?</p>
              
              <div style="background: #f8fafc; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="margin-top: 0;">✨ What We Can Help With:</h3>
                <ul>
                  <li>📝 Research Papers</li>
                  <li>📚 Thesis & Dissertations</li>
                  <li>✍️ Essays & Articles</li>
                  <li>📊 Literature Reviews</li>
                </ul>
              </div>
              
              <p style="text-align: center; margin: 30px 0;">
                <a href="https://thesisgenerator.tech" style="background: linear-gradient(135deg, #2563EB, #1D4ED8); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold;">
                  Create New Thesis
                </a>
              </p>
              
              <p style="color: #64748b; font-size: 14px;">
                🎁 <strong>Special offer:</strong> Come back now and save time on your next project!
              </p>
            </div>
          </body>
          </html>
        ''';

        await _sendCombinedNotification(
          userId: user.uid,
          pushHeading: '🎯 Need a Research Paper?',
          pushContent:
              'Essay? Thesis? Research paper? We\'re here to help. Open now!',
          emailSubject: '🎯 We Miss You! Need Help with Your Writing?',
          emailContent: emailContent,
          data: {'type': 'reengagement_7day', 'route': '/thesis-form'},
        );
        print('✅ 7-day re-engagement notification + email sent');
      }
    } catch (e) {
      print('❌ Failed to check inactivity: $e');
    }
  }     final status = doc.data()?['status'] ?? '';

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
      _inactivityTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
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

  /// Send email notification via OneSignal REST API
  Future<void> _sendEmailNotification({
    required String userId,
    required String subject,
    required String emailContent,
    String? preheader,
  }) async {
    try {
      // Get user's email from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final email = userDoc.data()?['email'];

      if (email == null) {
        print('⚠️ User has no email, skipping email notification');
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
          'include_email_tokens': [email],
          'email_subject': subject,
          'email_body': emailContent,
          'email_preheader': preheader ?? subject,
          'template_id': null, // You can create templates in OneSignal dashboard
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully: $subject to $email');
      } else {
        print(
            '❌ Failed to send email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending email notification: $e');
    }
  }

  /// Send combined push + email notification
  Future<void> _sendCombinedNotification({
    required String userId,
    required String pushHeading,
    required String pushContent,
    required String emailSubject,
    required String emailContent,
    Map<String, dynamic>? data,
  }) async {
    // Send both push and email in parallel
    await Future.wait([
      _sendPushNotification(
        userId: userId,
        heading: pushHeading,
        content: pushContent,
        data: data,
      ),
      _sendEmailNotification(
        userId: userId,
        subject: emailSubject,
        emailContent: emailContent,
      ),
    ]);
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
