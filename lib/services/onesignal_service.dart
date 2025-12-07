import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// OneSignal Service for managing push notifications and user engagement
/// Connects with Firebase to sync user data and trigger automated notifications
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static const String appId = '4b4333e8-9e9d-4636-974b-b7950b3341d2';
  static const String restApiKey =
      'os_v2_app_g2icp4vjzfgdzeruayxhqura4ebyq3cyeuyewofdnxfahb7i5x4tbixt4hjlcornqqgxdm2lzh5ouogqged66tjidgurtll2dhjyopi';

  bool _isInitialized = false;
  String? _currentUserId;

  /// Initialize OneSignal SDK
  Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 OneSignal: Skipping initialization on web platform');
      return;
    }

    if (_isInitialized) {
      print('✅ OneSignal already initialized');
      return;
    }

    try {
      print('🔔 Initializing OneSignal...');

      // Initialize OneSignal
      OneSignal.initialize(appId);

      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');

      // Listen to Firebase Auth state changes
      _listenToAuthChanges();
    } catch (e) {
      print('❌ Failed to initialize OneSignal: $e');
    }
  }

  /// Setup notification click and received handlers
  void _setupNotificationHandlers() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print('🔔 Notification clicked: ${event.notification.title}');
      _handleNotificationClick(event.notification);
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print(
          '🔔 Notification received in foreground: ${event.notification.title}');
      // You can modify the notification or prevent it from displaying
      event.notification.display();
    });
  }

  /// Handle notification click actions
  void _handleNotificationClick(OSNotification notification) {
    final additionalData = notification.additionalData;
    if (additionalData == null) return;

    // Handle different notification types with deep linking
    final notificationType = additionalData['type'];
    final thesisId = additionalData['thesisId'];

    print('🔗 Notification type: $notificationType, thesisId: $thesisId');

    // You can add navigation logic here based on notification type
    // Example: Navigate to specific thesis, export screen, etc.
  }

  /// Listen to Firebase Auth changes and sync with OneSignal
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setUser(user);
      } else {
        clearUser();
      }
    });
  }

  /// Set user identity in OneSignal when user logs in
  Future<void> setUser(User user) async {
    if (kIsWeb) return;
    if (!_isInitialized) return;

    try {
      _currentUserId = user.uid;

      // Set external user ID
      await OneSignal.login(user.uid);

      // Set user email for email notifications
      if (user.email != null) {
        OneSignal.User.addEmail(user.email!);
        print('✅ OneSignal email set: ${user.email}');
      }

      // Set user tags for segmentation
      await _setUserTags(user);

      // Sync user to Firestore
      await _syncUserToFirestore(user);

      print('✅ OneSignal user set: ${user.email} (Push + Email enabled)');
    } catch (e) {
      print('❌ Failed to set OneSignal user: $e');
    }
  }

  /// Set user tags for targeted notifications
  Future<void> _setUserTags(User user) async {
    final tags = {
      'user_id': user.uid,
      'email': user.email ?? '',
      'created_at': user.metadata.creationTime?.toIso8601String() ?? '',
      'last_sign_in': user.metadata.lastSignInTime?.toIso8601String() ?? '',
      'platform': 'flutter',
    };

    await OneSignal.User.addTags(tags);
    print('✅ OneSignal tags set: $tags');
  }

  /// Sync user data to Firestore for Firebase Functions triggers
  Future<void> _syncUserToFirestore(User user) async {
    try {
      final oneSignalId = OneSignal.User.pushSubscription.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'userId': user.uid,
        'oneSignalId': oneSignalId,
        'oneSignalSubscribed': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User synced to Firestore with OneSignal ID: $oneSignalId');
    } catch (e) {
      print('❌ Failed to sync user to Firestore: $e');
    }
  }

  /// Clear user identity when user logs out
  Future<void> clearUser() async {
    if (kIsWeb) return;
    if (!_isInitialized) return;

    try {
      await OneSignal.logout();
      _currentUserId = null;
      print('✅ OneSignal user cleared');
    } catch (e) {
      print('❌ Failed to clear OneSignal user: $e');
    }
  }

  /// Update user tags (for segmentation and targeting)
  Future<void> updateUserTags(Map<String, dynamic> tags) async {
    if (kIsWeb) return;
    if (!_isInitialized) return;

    try {
      await OneSignal.User.addTags(tags);
      print('✅ User tags updated: $tags');
    } catch (e) {
      print('❌ Failed to update user tags: $e');
    }
  }

  /// Track thesis generation start
  Future<void> trackThesisStarted(String thesisId, String topic) async {
    await updateUserTags({
      'last_thesis_id': thesisId,
      'last_thesis_topic': topic,
      'last_thesis_started': DateTime.now().toIso8601String(),
      'thesis_status': 'started',
    });
  }

  /// Track thesis generation progress
  Future<void> trackThesisProgress(
      String thesisId, int progressPercentage) async {
    await updateUserTags({
      'last_thesis_id': thesisId,
      'last_thesis_progress': progressPercentage.toString(),
      'last_activity': DateTime.now().toIso8601String(),
    });
  }

  /// Track thesis completion
  Future<void> trackThesisCompleted(String thesisId) async {
    await updateUserTags({
      'last_thesis_id': thesisId,
      'thesis_status': 'completed',
      'last_thesis_completed': DateTime.now().toIso8601String(),
      'last_activity': DateTime.now().toIso8601String(),
    });
  }

  /// Track thesis export
  Future<void> trackThesisExported(String thesisId, String format) async {
    await updateUserTags({
      'last_thesis_id': thesisId,
      'thesis_status': 'exported',
      'last_export_format': format,
      'last_thesis_exported': DateTime.now().toIso8601String(),
      'last_activity': DateTime.now().toIso8601String(),
    });
  }

  /// Track subscription status
  Future<void> trackSubscriptionStatus(bool isSubscribed) async {
    await updateUserTags({
      'is_subscribed': isSubscribed.toString(),
      'subscription_updated': DateTime.now().toIso8601String(),
    });
  }

  /// Get notification permission status
  Future<bool> getNotificationPermissionStatus() async {
    if (kIsWeb) return false;
    if (!_isInitialized) return false;

    try {
      return await OneSignal.Notifications.permission;
    } catch (e) {
      print('❌ Failed to get notification permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    if (!_isInitialized) return false;

    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      print('❌ Failed to request notification permission: $e');
      return false;
    }
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (kIsWeb) return;

    try {
      final oneSignalId = OneSignal.User.pushSubscription.id;
      print('🧪 Sending test notification to: $oneSignalId');
      // You would call your backend API or Firebase Function here
    } catch (e) {
      print('❌ Failed to send test notification: $e');
    }
  }
}
