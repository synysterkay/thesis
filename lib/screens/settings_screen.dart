import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/local_notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _enableNotifications = true;
  bool _autoSave = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isIOS) {
      _loadNotificationSettings();
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (kIsWeb || !Platform.isIOS) return; // Only load on iOS

    final notificationsEnabled =
        await LocalNotificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _enableNotifications = notificationsEnabled;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await LocalNotificationService.setNotificationsEnabled(value);

      if (mounted) {
        setState(() {
          _enableNotifications = value;
          _isLoading = false;
        });

        // Show a test notification when enabling notifications
        if (value) {
          await LocalNotificationService.showNotification(
            id: 999,
            title: '🔔 Notifications Enabled',
            body:
                'You will now receive helpful notifications about your thesis progress!',
            payload: 'settings_test',
          );
        }

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Notifications enabled successfully!'
                  : 'Notifications disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    String url;

    if (kIsWeb) {
      // Web - redirect to Product Hunt
      url =
          'https://www.producthunt.com/products/thesisgenerator-tech?utm_source=other&utm_medium=social';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android - redirect to Google Play Store
      url =
          'https://play.google.com/store/apps/details?id=com.thesis.generator.ai';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS - redirect to App Store
      url = 'https://apps.apple.com/app/thesis-generator-essay-ai/id6739264844';
    } else {
      // Fallback to Product Hunt for other platforms
      url =
          'https://www.producthunt.com/products/thesisgenerator-tech?utm_source=other&utm_medium=social';
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open rating page: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize your app preferences and configurations',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Settings Content
              Expanded(
                child: ListView(
                  children: [
                    _buildSection('App Support', [
                      _buildActionTile(
                        title: 'Rate this App',
                        subtitle: 'Help us by leaving a review',
                        icon: Icons.star,
                        onTap: _rateApp,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Only show notifications section on iOS for Google Play compliance
                    if (!kIsWeb && Platform.isIOS) ...[
                      _buildSection('Notifications', [
                        _buildSwitchTile(
                          title: 'Enable Notifications',
                          subtitle: _isLoading
                              ? 'Updating...'
                              : 'Receive helpful thesis progress notifications (iOS only)',
                          value: _enableNotifications,
                          onChanged: _isLoading
                              ? null
                              : (value) => _toggleNotifications(value),
                          icon: Icons.notifications,
                          isLoading: _isLoading,
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    _buildSection('General', [
                      _buildSwitchTile(
                        title: 'Auto Save',
                        subtitle: 'Automatically save your work',
                        value: _autoSave,
                        onChanged: (value) => setState(() => _autoSave = value),
                        icon: Icons.save,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: Colors.grey[600],
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.deepPurple,
            ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
