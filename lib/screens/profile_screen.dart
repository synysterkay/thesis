import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedStudyLevel = 'Undergraduate';
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _studyLevels = [
    'High School',
    'Undergraduate',
    'Graduate/Master\'s',
    'PhD/Doctorate',
    'Post-Doctorate',
    'Professional',
  ];

  // Color scheme
  static const primaryColor = Color(0xFF2563EB);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _nicknameController.text =
                  data['nickname'] ?? user.displayName ?? '';
              _selectedStudyLevel = data['studyLevel'] ?? 'Undergraduate';
            });
          }
        } else {
          // Initialize with user's display name if available
          _nicknameController.text = user.displayName ?? '';
        }
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': _nicknameController.text.trim(),
          'studyLevel': _selectedStudyLevel,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      _showSnackBar('Error saving profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sign Out',
      content: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      } catch (e) {
        _showSnackBar('Error signing out: $e', isError: true);
      }
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Profile',
      content:
          'This will permanently delete your account and all associated data. This action cannot be undone.',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete user data from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // Delete the user account
          await user.delete();

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      } catch (e) {
        _showSnackBar('Error deleting profile: $e', isError: true);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: GoogleFonts.inter(
                color: isDestructive ? Colors.red : primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Profile',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your account information and preferences',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Picture Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                PhosphorIcons.user(PhosphorIconsStyle.fill),
                                size: 64,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.email ?? 'No email',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nickname Field
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(),
                          textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: textPrimary,
                                displayColor: textPrimary,
                              ),
                        ),
                        child: _buildTextField(
                          controller: _nicknameController,
                          label: 'Nickname',
                          icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a nickname';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Study Level Dropdown
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(),
                          textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: textPrimary,
                                displayColor: textPrimary,
                              ),
                        ),
                        child: _buildDropdownField(
                          label: 'Level of Studies',
                          icon: PhosphorIcons.graduationCap(
                              PhosphorIconsStyle.regular),
                          value: _selectedStudyLevel,
                          items: _studyLevels,
                          onChanged: (value) {
                            if (mounted) {
                              setState(() => _selectedStudyLevel = value!);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(PhosphorIcons.floppyDisk(
                                  PhosphorIconsStyle.fill)),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Profile',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Actions Section
                      _buildSectionTitle('Account Actions'),
                      const SizedBox(height: 16),

                      // Sign Out Button
                      _buildActionTile(
                        icon: PhosphorIcons.signOut(PhosphorIconsStyle.fill),
                        title: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        onTap: _signOut,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),

                      // Delete Profile Button
                      _buildActionTile(
                        icon: PhosphorIcons.trash(PhosphorIconsStyle.fill),
                        title: 'Delete Profile',
                        subtitle:
                            'Permanently delete your account and all data',
                        onTap: _deleteProfile,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: GoogleFonts.inter(color: textMuted),
          floatingLabelStyle: GoogleFonts.inter(color: primaryColor),
          fillColor: Colors.white,
          filled: true,
        ),
        style: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: GoogleFonts.inter(color: textMuted),
          floatingLabelStyle: GoogleFonts.inter(color: primaryColor),
          fillColor: Colors.white,
          filled: true,
        ),
        style: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
        ),
        dropdownColor: Colors.white,
        iconEnabledColor: textMuted,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.inter(
                color: textPrimary,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        trailing: Icon(
          PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
          color: textMuted,
          size: 16,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
