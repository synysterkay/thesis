import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/thesis_provider.dart';
import '../models/thesis.dart';
import '../widgets/auto_save_indicator.dart';
import 'dart:math' as math;

class ThesisDashboardScreen extends ConsumerStatefulWidget {
  const ThesisDashboardScreen({super.key});

  @override
  _ThesisDashboardScreenState createState() => _ThesisDashboardScreenState();
}

class _ThesisDashboardScreenState extends ConsumerState<ThesisDashboardScreen> {
  // Color constants
  static const primaryColor = Color(0xFF2563EB);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final thesisState = ref.watch(thesisStateProvider);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildAppBar(),
      body: thesisState.when(
        data: (thesis) => _buildDashboardContent(thesis),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Thesis Dashboard',
        style: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        const AutoSaveIndicator(),
        const SizedBox(width: 8),
        const SaveStatusWidget(),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.refresh, color: primaryColor),
          onPressed: () => ref.refresh(thesisStateProvider),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDashboardContent(Thesis thesis) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(thesis),
          SizedBox(height: 32),
          _buildProgressSection(thesis),
          SizedBox(height: 32),
          _buildChaptersGrid(thesis),
          SizedBox(height: 32),
          _buildActionButtons(thesis),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Thesis thesis) {
    final stats = _calculateThesisStats(thesis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Overall Progress',
              '${stats.overallProgress.toStringAsFixed(0)}%',
              Icons.analytics,
              primaryColor,
              stats.overallProgress / 100,
            ),
            _buildStatCard(
              'Chapters Complete',
              '${stats.completedChapters}/${stats.totalChapters}',
              Icons.book,
              Colors.green,
              stats.completedChapters / stats.totalChapters,
            ),
            _buildStatCard(
              'Word Count',
              '${stats.estimatedWordCount.toStringAsFixed(0)}',
              Icons.text_fields,
              Colors.blue,
              math.min(
                  stats.estimatedWordCount / 50000, 1.0), // Assuming 50k target
            ),
            _buildStatCard(
              'Time Remaining',
              stats.estimatedTimeRemaining,
              Icons.schedule,
              Colors.orange,
              1.0 - (stats.overallProgress / 100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, double progress) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildProgressSection(Thesis thesis) {
    final stats = _calculateThesisStats(thesis);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress Timeline',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats.overallProgress.toStringAsFixed(0)}% Complete',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildProgressBar(stats.overallProgress / 100),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressLabel(
                  'Not Started', stats.notStartedChapters, Colors.grey),
              _buildProgressLabel(
                  'In Progress', stats.inProgressChapters, primaryColor),
              _buildProgressLabel(
                  'Completed', stats.completedChapters, Colors.green),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLabel(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersGrid(Thesis thesis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapters',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: thesis.chapters.length,
          itemBuilder: (context, index) {
            final chapter = thesis.chapters[index];
            final chapterProgress =
                _getChapterCompletionPercentage(chapter, index);
            return _buildChapterCard(chapter, index + 1, chapterProgress);
          },
        ),
      ],
    );
  }

  Widget _buildChapterCard(
      dynamic chapter, int chapterNumber, double progress) {
    final status = _getChapterStatus(progress);
    final statusColor = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 16,
                ),
              ),
              Spacer(),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Chapter $chapterNumber',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            chapter.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: statusColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (chapterNumber * 100).ms).slideY(begin: 0.3);
  }

  Widget _buildActionButtons(Thesis thesis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Continue Writing',
                Icons.edit,
                primaryColor,
                () => _navigateToOutlineViewer(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Generate All',
                Icons.auto_awesome,
                Colors.green,
                () => _navigateToProgressiveGeneration(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Export Thesis',
                Icons.download,
                Colors.blue,
                () => _navigateToExport(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Settings',
                Icons.settings,
                Colors.grey,
                () => _showSettings(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.inter(
              color: textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '$error',
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(thesisStateProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  ThesisStats _calculateThesisStats(Thesis thesis) {
    int completedChapters = 0;
    int inProgressChapters = 0;
    int notStartedChapters = 0;
    double totalProgress = 0;
    int estimatedWordCount = 0;

    for (int i = 0; i < thesis.chapters.length; i++) {
      final chapter = thesis.chapters[i];
      final chapterProgress = _getChapterCompletionPercentage(chapter, i);

      if (chapterProgress >= 100) {
        completedChapters++;
      } else if (chapterProgress > 0) {
        inProgressChapters++;
      } else {
        notStartedChapters++;
      }

      totalProgress += chapterProgress;

      // Estimate word count (rough estimate)
      if (chapter.title.toLowerCase().contains('introduction') ||
          chapter.title.toLowerCase().contains('conclusion')) {
        estimatedWordCount +=
            (chapterProgress / 100 * 1500).round(); // ~1500 words
      } else if (!chapter.title.toLowerCase().contains('references')) {
        estimatedWordCount +=
            (chapterProgress / 100 * chapter.subheadings.length * 800)
                .round(); // ~800 words per section
      }
    }

    final overallProgress = totalProgress / thesis.chapters.length;
    final remainingProgress = 100 - overallProgress;
    final estimatedHoursRemaining =
        (remainingProgress / 100 * 8); // Rough estimate

    String timeRemaining;
    if (estimatedHoursRemaining < 1) {
      timeRemaining = '< 1 hour';
    } else if (estimatedHoursRemaining < 24) {
      timeRemaining = '${estimatedHoursRemaining.round()} hours';
    } else {
      final days = (estimatedHoursRemaining / 24).round();
      timeRemaining = '$days days';
    }

    return ThesisStats(
      totalChapters: thesis.chapters.length,
      completedChapters: completedChapters,
      inProgressChapters: inProgressChapters,
      notStartedChapters: notStartedChapters,
      overallProgress: overallProgress,
      estimatedWordCount: estimatedWordCount.toDouble(),
      estimatedTimeRemaining: timeRemaining,
    );
  }

  double _getChapterCompletionPercentage(dynamic chapter, int chapterIndex) {
    final notifier = ref.read(thesisStateProvider.notifier);

    if (chapter.title.toLowerCase().contains('references')) {
      return 100.0;
    }

    if (chapter.title.toLowerCase().contains('introduction') ||
        chapter.title.toLowerCase().contains('conclusion')) {
      return notifier.isSubheadingGenerated(chapter.title, chapter.title)
          ? 100.0
          : 0.0;
    }

    if (chapter.subheadings.isEmpty) return 0.0;

    int generatedCount = 0;
    for (String subheading in chapter.subheadings) {
      if (notifier.isSubheadingGenerated(chapter.title, subheading)) {
        generatedCount++;
      }
    }

    return (generatedCount / chapter.subheadings.length * 100);
  }

  String _getChapterStatus(double progress) {
    if (progress >= 100) return 'completed';
    if (progress > 0) return 'in_progress';
    return 'not_started';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.radio_button_checked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  // Navigation methods
  void _navigateToOutlineViewer() {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isTrialMode = currentRoute?.contains('trial') ?? false;

    Navigator.pushNamed(
      context,
      isTrialMode ? '/outline-trial' : '/outline',
    );
  }

  void _navigateToProgressiveGeneration() {
    // Navigate to outline viewer where they can use "Generate All"
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isTrialMode = currentRoute?.contains('trial') ?? false;

    Navigator.pushNamed(
      context,
      isTrialMode ? '/outline-trial' : '/outline',
    );
  }

  void _navigateToExport() {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isTrialMode = currentRoute?.contains('trial') ?? false;

    Navigator.pushNamed(
      context,
      isTrialMode ? '/export-trial' : '/export',
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AutoSaveSettings(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final backup = await ref
                              .read(thesisStateProvider.notifier)
                              .createBackup();
                          // TODO: Implement backup download/sharing
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Backup created successfully'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating backup: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.backup, size: 16),
                      label: Text(
                        'Create Backup',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );
  }
}

class ThesisStats {
  final int totalChapters;
  final int completedChapters;
  final int inProgressChapters;
  final int notStartedChapters;
  final double overallProgress;
  final double estimatedWordCount;
  final String estimatedTimeRemaining;

  ThesisStats({
    required this.totalChapters,
    required this.completedChapters,
    required this.inProgressChapters,
    required this.notStartedChapters,
    required this.overallProgress,
    required this.estimatedWordCount,
    required this.estimatedTimeRemaining,
  });
}
