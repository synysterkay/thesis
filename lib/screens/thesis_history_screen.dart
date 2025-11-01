import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/thesis_metadata.dart';
import '../services/firebase_user_service.dart';
import '../services/background_generation_service.dart';

class ThesisHistoryScreen extends ConsumerStatefulWidget {
  const ThesisHistoryScreen({super.key});

  @override
  ConsumerState<ThesisHistoryScreen> createState() =>
      _ThesisHistoryScreenState();
}

class _ThesisHistoryScreenState extends ConsumerState<ThesisHistoryScreen> {
  String _searchQuery = '';
  String _sortBy = 'lastUpdated';

  @override
  void initState() {
    super.initState();
    // Clean up orphaned generation jobs on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupOrphanedJobs();
    });
  }

  Future<void> _cleanupOrphanedJobs() async {
    try {
      await BackgroundGenerationService.instance.cleanupOrphanedJobs();
    } catch (e) {
      print('Warning: Failed to cleanup orphaned jobs: $e');
      // Don't show error to user - this is background cleanup
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Please log in to view your thesis history',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

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
                'My Theses',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Currently Generating Section
              _buildCurrentlyGeneratingSection(),

              // Recent Generation Jobs Section
              _buildRecentGenerationJobsSection(),

              // Search and Filter Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search theses...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                        prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                            color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _sortBy,
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortBy = newValue!;
                      });
                    },
                    items: <String>['lastUpdated', 'title', 'dateCreated']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'lastUpdated'
                              ? 'Last Updated'
                              : value == 'title'
                                  ? 'Title'
                                  : 'Date Created',
                          style: GoogleFonts.inter(color: Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thesis List
              Expanded(
                child: StreamBuilder<List<ThesisMetadata>>(
                  stream: FirebaseUserService.instance.getUserThesesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading theses',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error
                                      .toString()
                                      .contains('permission-denied')
                                  ? 'Please check your internet connection and try again'
                                  : 'Please try again later',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {}); // Trigger rebuild to retry
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.fileText(),
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No theses found',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by creating your first thesis',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    List<ThesisMetadata> theses = snapshot.data!;

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      theses = theses
                          .where((thesis) =>
                              thesis.title
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              (thesis.topic
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase())))
                          .toList();
                    }

                    // Apply sorting
                    theses.sort((a, b) {
                      switch (_sortBy) {
                        case 'title':
                          return a.title.compareTo(b.title);
                        case 'dateCreated':
                          return b.createdAt.compareTo(a.createdAt);
                        default: // lastUpdated
                          return b.lastUpdated.compareTo(a.lastUpdated);
                      }
                    });

                    return ListView.builder(
                      itemCount: theses.length,
                      itemBuilder: (context, index) {
                        final thesis = theses[index];
                        final isIncomplete = thesis.status == 'in_progress' &&
                            thesis.progressPercentage < 100;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isIncomplete
                                  ? Colors.grey[300]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          color: isIncomplete ? Colors.grey[50] : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              thesis.title.isNotEmpty
                                  ? thesis.title
                                  : thesis.topic,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isIncomplete
                                    ? Colors.grey[500]
                                    : Colors.grey[800],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  thesis.subject?.isNotEmpty == true
                                      ? 'Subject: ${thesis.subject}'
                                      : (thesis.title.isNotEmpty
                                          ? 'Topic: ${thesis.topic}'
                                          : ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last updated: ${_formatDate(thesis.lastUpdated)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (thesis.progressPercentage > 0 &&
                                    thesis.progressPercentage < 100) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value:
                                              thesis.progressPercentage / 100,
                                          backgroundColor: Colors.grey[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _getStatusColor(thesis.status),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${thesis.progressPercentage.toStringAsFixed(0)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _getStatusColor(thesis.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (thesis.status == 'in_progress' ||
                                    (thesis.progressPercentage > 0 &&
                                        thesis.progressPercentage < 100))
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _continueGeneration(thesis),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: Text(
                                        'Continue',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(thesis.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getStatusText(thesis.status),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getStatusColor(thesis.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _showRenameDialog(thesis),
                                  icon: Icon(
                                    PhosphorIcons.pencil(),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  PhosphorIcons.caretRight(),
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            onTap: isIncomplete
                                ? null // Disable tap for incomplete theses
                                : () => _openThesis(thesis),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentlyGeneratingSection() {
    return StreamBuilder<List<GenerationJob>>(
      stream: BackgroundGenerationService.instance
          .getActiveGenerationJobs()
          .timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          print('DEBUG: Stream timeout, retrying...');
          sink.addError('Stream timeout');
        },
      ).handleError((error) {
        print('ERROR: Stream error handled: $error');
        // Return empty list instead of throwing error
        return <GenerationJob>[];
      }),
      builder: (context, snapshot) {
        print(
            'DEBUG: History screen - Stream state: ${snapshot.connectionState}');

        if (snapshot.hasError) {
          print('ERROR: History stream error: ${snapshot.error}');
          // Show a minimal retry option instead of hiding completely
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.grey[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connection issue. Pull to refresh.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          print('DEBUG: History screen - No data yet, showing loading');
          // Show a subtle loading indicator
          return Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking for active generations...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final activeJobs = snapshot.data!;
        print(
            'DEBUG: History screen - Received ${activeJobs.length} active jobs');

        if (activeJobs.isEmpty) {
          print('DEBUG: History screen - No active jobs, hiding section');
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently Generating',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ...activeJobs.map((job) => _buildGeneratingJobCard(job)).toList(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildGeneratingJobCard(GenerationJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated charging icon
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1 + (value * 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.lightning(),
                      color: Colors.orange,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<ThesisMetadata?>(
                      future: _getThesisMetadata(job.thesisId),
                      builder: (context, thesisSnapshot) {
                        final thesisTitle =
                            thesisSnapshot.data?.title ?? 'Unknown Thesis';
                        return Text(
                          thesisTitle,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.currentStep,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${job.progress.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~${job.estimatedDuration - ((DateTime.now().difference(job.startedAt).inMinutes))} min left',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stop/Cancel button
                  SizedBox(
                    width: 80,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _showCancelConfirmation(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        'Stop',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: job.progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${job.completedSections}/${job.totalSections} sections',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (job.status == 'queued')
                Text(
                  'Queue position: ${job.queuePosition}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGenerationJobsSection() {
    return StreamBuilder<List<GenerationJob>>(
      stream: BackgroundGenerationService.instance.getAllGenerationJobs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentJobs = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Generation Jobs',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: _showAllGenerationJobs,
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentJobs.map((job) => _buildCompletedJobCard(job)).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCompletedJobCard(GenerationJob job) {
    Color statusColor;
    IconData statusIcon;

    switch (job.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = PhosphorIcons.checkCircle();
        break;
      case 'cancelled':
        statusColor = Colors.orange;
        statusIcon = PhosphorIcons.xCircle();
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = PhosphorIcons.warning();
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = PhosphorIcons.question();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<ThesisMetadata?>(
                  future: _getThesisMetadata(job.thesisId),
                  builder: (context, thesisSnapshot) {
                    final thesisTitle =
                        thesisSnapshot.data?.title ?? 'Unknown Thesis';
                    return Text(
                      thesisTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.status.substring(0, 1).toUpperCase()}${job.status.substring(1)} • ${_formatRelativeTime(job.startedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (job.status == 'completed')
            Text(
              '${job.progress.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical(),
                size: 16, color: Colors.grey[600]),
            onSelected: (action) async {
              if (action == 'delete') {
                await _confirmDeleteJob(job);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.trash(), size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllGenerationJobs() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Generation Jobs',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(PhosphorIcons.x()),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<GenerationJob>>(
                  stream: BackgroundGenerationService.instance
                      .getAllGenerationJobs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading generation jobs',
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      );
                    }

                    final jobs = snapshot.data ?? [];
                    if (jobs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.clock(),
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No generation jobs found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        return _buildCompletedJobCard(jobs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteJob(GenerationJob job) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Generation Job?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete this generation job record. The thesis content will not be affected.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await BackgroundGenerationService.instance.deleteGenerationJob(job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Generation job deleted',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete job: $e',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Future<void> _showCancelConfirmation(GenerationJob job) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Generation?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this thesis generation?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Progress will be lost and cannot be recovered.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Continue Generation',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Cancel Generation',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await _cancelGeneration(job.id);
    }
  }

  Future<void> _cancelGeneration(String jobId) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cancelling generation...',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      await BackgroundGenerationService.instance.cancelGenerationJob(jobId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Generation cancelled successfully',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to cancel generation: ${e.toString()}',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<ThesisMetadata?> _getThesisMetadata(String thesisId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final theses = await FirebaseUserService.instance.getUserTheses(user.uid);
      return theses.firstWhere(
        (thesis) => thesis.id == thesisId,
        orElse: () => ThesisMetadata(
          id: thesisId,
          userId: user.uid,
          title: 'Unknown Thesis',
          topic: '',
          studyLevel: '',
          language: '',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
      case 'exported':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'draft':
        return 'Draft';
      case 'exported':
        return 'Exported';
      default:
        return status;
    }
  }

  void _continueGeneration(ThesisMetadata thesis) {
    // Navigate to outline viewer in trial mode to continue generation
    Navigator.pushNamed(
      context,
      '/outline-trial',
      arguments: {'thesisId': thesis.id},
    );
  }

  void _openThesis(ThesisMetadata thesis) {
    // Navigate to the appropriate screen based on thesis status
    print(
        'DEBUG: Opening thesis ${thesis.id} - status: "${thesis.status}", progress: ${thesis.progressPercentage}%');

    if (thesis.status == 'completed' || thesis.progressPercentage >= 100) {
      // Navigate to export screen with debug info
      print('DEBUG: Navigating to export screen for thesis: ${thesis.id}');
      Navigator.pushNamed(
        context,
        '/export-trial',
        arguments: {'thesisId': thesis.id},
      ).then((_) {
        print('DEBUG: Returned from export screen');
      }).catchError((error) {
        print('DEBUG: Error navigating to export screen: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening thesis for export. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else if (thesis.status == 'in_progress' ||
        thesis.progressPercentage > 0) {
      // Navigate to outline viewer to continue work
      print(
          'DEBUG: Navigating to outline viewer for in-progress thesis: ${thesis.id}');
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

  /// Show rename dialog for thesis
  void _showRenameDialog(ThesisMetadata thesis) {
    final TextEditingController _titleController = TextEditingController(
      text: thesis.title.isNotEmpty ? thesis.title : thesis.topic,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Rename Thesis',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Thesis Title',
              labelStyle: GoogleFonts.inter(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
            ),
            style: GoogleFonts.inter(),
            maxLength: 100,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = _titleController.text.trim();
                if (newTitle.isNotEmpty && newTitle != thesis.title) {
                  try {
                    await FirebaseUserService.instance.renameThesis(
                      thesis.id,
                      newTitle,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thesis renamed successfully!',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to rename thesis. Please try again.',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        );
      },
    );
  }
}
