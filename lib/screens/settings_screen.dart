import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDarkMode = false;
  bool _enableNotifications = true;
  bool _autoSave = true;

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
                    _buildSection('Appearance', [
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: _isDarkMode,
                        onChanged: (value) =>
                            setState(() => _isDarkMode = value),
                        icon: Icons.dark_mode,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Notifications', [
                      _buildSwitchTile(
                        title: 'Enable Notifications',
                        subtitle: 'Receive app notifications',
                        value: _enableNotifications,
                        onChanged: (value) =>
                            setState(() => _enableNotifications = value),
                        icon: Icons.notifications,
                      ),
                    ]),
                    const SizedBox(height: 24),
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
    required ValueChanged<bool> onChanged,
    required IconData icon,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }
}
