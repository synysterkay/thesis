import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/thesis_metadata.dart';
import '../services/firebase_user_service.dart';

// Define a callback type for navigation
typedef NavigationCallback = void Function(int index);

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final NavigationCallback? onNavigate;

  const HomeDashboardScreen({
    super.key,
    this.onNavigate,
  });

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(user),
            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // Recent Activity
            _buildRecentActivity(),
            const SizedBox(height: 32),

            // Statistics
            _buildStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(User? user) {
    final userName = user?.displayName ?? 'User';
    final timeOfDay = _getTimeOfDay();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$timeOfDay, $userName!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to work on your thesis today?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: PhosphorIcons.plus(PhosphorIconsStyle.fill),
                title: 'New Thesis',
                subtitle: 'Start writing',
                color: primaryColor,
                onTap: () {
                  // Navigate to New tab (index 1)
                  widget.onNavigate?.call(1);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: PhosphorIcons.clockCounterClockwise(
                    PhosphorIconsStyle.fill),
                title: 'My Theses',
                subtitle: 'View history',
                color: Colors.teal,
                onTap: () {
                  // Navigate to History tab (index 2)
                  widget.onNavigate?.call(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to thesis history (tab index 2)
                widget.onNavigate?.call(2);
              },
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<ThesisMetadata>>(
          future: _getRecentTheses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: snapshot.data!
                  .take(3)
                  .map((thesis) => _buildActivityItem(thesis))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(ThesisMetadata thesis) {
    bool isInProgress = thesis.status == 'in_progress' ||
        (thesis.progressPercentage > 0 && thesis.progressPercentage < 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => _navigateToThesis(thesis),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                PhosphorIcons.article(PhosphorIconsStyle.fill),
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thesis.title.isNotEmpty ? thesis.title : thesis.topic,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Last updated ${_formatDate(thesis.lastUpdated)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      if (isInProgress) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${thesis.progressPercentage.toStringAsFixed(0)}% Complete',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isInProgress) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: thesis.progressPercentage / 100,
                      backgroundColor: borderColor,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isInProgress)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.fill),
                color: textMuted,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.article(PhosphorIconsStyle.regular),
            size: 48,
            color: textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No theses yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first thesis to see it here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to New tab (index 1)
              widget.onNavigate?.call(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Start New Thesis',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ThesisMetadata>>(
          stream: FirebaseUserService.instance.getUserThesesStream(),
          builder: (context, snapshot) {
            final theses = snapshot.data ?? [];
            final totalTheses = theses.length;

            // Calculate total words from all theses
            int totalWords = 0;
            for (final thesis in theses) {
              totalWords += thesis.wordCount;
            }

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Theses',
                    value: totalTheses.toString(),
                    icon: PhosphorIcons.article(PhosphorIconsStyle.fill),
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Words Written',
                    value: _formatNumber(totalWords),
                    icon: PhosphorIcons.pencil(PhosphorIconsStyle.fill),
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else {
      return '$difference days ago';
    }
  }

  Future<List<ThesisMetadata>> _getRecentTheses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Get recent theses from Firebase
      final theses = await FirebaseUserService.instance.getUserTheses(user.uid);

      // Return up to 3 most recent theses, prioritizing in-progress ones
      theses.sort((a, b) {
        // First prioritize in-progress theses
        bool aInProgress = a.status == 'in_progress' ||
            (a.progressPercentage > 0 && a.progressPercentage < 100);
        bool bInProgress = b.status == 'in_progress' ||
            (b.progressPercentage > 0 && b.progressPercentage < 100);

        if (aInProgress && !bInProgress) return -1;
        if (!aInProgress && bInProgress) return 1;

        // Then sort by last updated
        return b.lastUpdated.compareTo(a.lastUpdated);
      });

      return theses.take(3).toList();
    } catch (e) {
      print('Error getting recent theses: $e');
      return [];
    }
  }

  void _navigateToThesis(ThesisMetadata thesis) {
    // Navigate to the appropriate screen based on thesis status
    if (thesis.status == 'completed' || thesis.progressPercentage >= 100) {
      // Navigate to export screen
      Navigator.pushNamed(
        context,
        '/export-trial',
        arguments: {'thesisId': thesis.id},
      );
    } else if (thesis.status == 'in_progress' ||
        thesis.progressPercentage > 0) {
      // Navigate to outline viewer to continue work
      Navigator.pushNamed(
        context,
        '/outline-trial',
        arguments: {'thesisId': thesis.id},
      );
    } else {
      // Navigate to thesis form to edit or start
      Navigator.pushNamed(
        context,
        '/thesis-form-trial',
        arguments: {'thesisId': thesis.id},
      );
    }
  }
}
