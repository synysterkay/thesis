import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/thesis_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/deepseek_service.dart';
import '../services/background_generation_service.dart';
import '../widgets/auto_save_indicator.dart';
import 'chapter_editor_screen.dart';
import 'main_navigation_screen.dart';
import 'dart:async';

class GenerationProgress {
  final String sectionTitle;
  final int completedSections;
  final int totalSections;
  final double progress;
  final List<String> generatedSections;
  final List<String> failedSections;

  GenerationProgress({
    required this.sectionTitle,
    required this.completedSections,
    required this.totalSections,
    required this.progress,
    required this.generatedSections,
    required this.failedSections,
  });
}

class OutlineViewerScreen extends ConsumerStatefulWidget {
  final String? thesisId;

  const OutlineViewerScreen({super.key, this.thesisId});

  @override
  _OutlineViewerScreenState createState() => _OutlineViewerScreenState();
}

class _OutlineViewerScreenState extends ConsumerState<OutlineViewerScreen> {
  final DeepSeekService _deepseekService = DeepSeekService();
  Map<String, bool> loadingStates = {};
  bool isGeneratingAll = false;
  String currentlyGenerating = '';
  List<String> generationSteps = [];
  String currentStep = '';
  double generateAllProgress = 0.0;
  late List<String> loadingMessages;
  int currentMessageIndex = 0;
  Timer? messageTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 7);

  String get formattedTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Updated color scheme to match new design
  static const primaryColor = Color(0xFF6366F1);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadingMessages = [
      'Analyzing your topic...',
      'Generating chapter structure...',
      'Creating content outline...',
      'Organizing sections...',
      'Finalizing structure...',
      'Almost ready...',
    ];
  }

  @override
  void initState() {
    super.initState();

    // Load thesis if thesisId is provided
    if (widget.thesisId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(thesisStateProvider.notifier)
              .loadThesisById(widget.thesisId!);
        }
      });
    }

    // Show immediate feedback and outline without heavy content generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Show successful loading message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  widget.thesisId != null
                      ? '✅ Thesis loaded! Continue where you left off'
                      : '✅ Thesis outline loaded! Auto-save every 30s',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(seconds: 3),
          ),
        );
      }
      // No heavy content generation - outline shows immediately
      // Content will be generated on-demand when user expands chapters
    });
  }

  Widget _buildGenerationSteps() {
    final generationState = ref.watch(generationStateProvider);
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...generationState.generationSteps
                .map((step) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        step,
                        style: GoogleFonts.inter(
                          color: textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            if (generationState.currentStep.isNotEmpty)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      generationState.currentStep,
                      style:
                          GoogleFonts.inter(color: textPrimary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationStatus() {
    final generationState = ref.watch(generationStateProvider);
    if (generationState.currentlyGenerating.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Show a pulsing indicator when progress is 0 to indicate loading
              generationState.progress <= 0
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : CircularProgressIndicator(
                      value: generationState.progress / 100,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 2,
                    ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generationState.currentlyGenerating,
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (generationState.currentStep.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        generationState.currentStep,
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          generationState.progress <= 0
                              ? 'Starting...'
                              : '${generationState.progress.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (generationState.progress <= 0) ...[
                          SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  PreferredSizeWidget _buildAppBar() {
    final generationState = ref.watch(generationStateProvider);
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textPrimary),
        onPressed: () {
          // Check if we're in trial mode by examining the current route
          final currentRoute = ModalRoute.of(context)?.settings.name;
          final isTrialMode = currentRoute == '/outline-trial';

          // Navigate back to appropriate thesis form route
          Navigator.pushReplacementNamed(
              context, isTrialMode ? '/thesis-form-trial' : '/thesis-form');
        },
      ),
      title: Text(
        'Academic Structure',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        // Auto-save indicator
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: AutoSaveIndicator(),
        ),
        // Dashboard Icon
        IconButton(
          icon: Icon(Icons.dashboard_outlined, color: primaryColor),
          onPressed: () {
            final currentRoute = ModalRoute.of(context)?.settings.name;
            final isTrialMode = currentRoute == '/outline-trial';
            Navigator.pushNamed(
              context,
              isTrialMode ? '/dashboard-trial' : '/dashboard',
            );
          },
          tooltip: 'View Dashboard',
        ),
        if (!generationState.isGeneratingAll)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              icon: Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                'Generate All',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _handleGenerateAll(context),
            ),
          ),
        if (generationState.isGeneratingAll)
          Expanded(
            child: Center(
              child: Text(
                'Generating...',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubheadingTile(String chapterTitle, List<String> subheadings,
      String subheading, int chapterIndex, bool isLoading, thesis) {
    final notifier = ref.read(thesisStateProvider.notifier);
    final isGenerated =
        notifier.isSubheadingGenerated(chapterTitle, subheading);
    final isIntroduction = chapterTitle.toLowerCase().contains('introduction');
    final isConclusion = chapterTitle.toLowerCase().contains('conclusion');

    // Calculate chapter and subheading numbers
    final chapterNumber = chapterIndex + 1;
    final subheadingNumber = subheadings.indexOf(subheading) + 1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          isIntroduction || isConclusion
              ? '$chapterNumber.0 $chapterTitle'
              : '$chapterNumber.$subheadingNumber $subheading',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isGenerated
                ? Colors.green.shade700
                : isLoading
                    ? primaryColor
                    : textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isGenerated
                ? Colors.green.withOpacity(0.1)
                : isLoading
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isGenerated
                  ? Colors.green
                  : isLoading
                      ? primaryColor
                      : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
              : Icon(
                  isGenerated ? Icons.check_circle : Icons.circle_outlined,
                  color: isGenerated ? Colors.green : Colors.grey,
                  size: 18,
                ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.refresh, color: primaryColor, size: 20),
              onPressed: () => _handleRegenerateOutlines(
                context,
                chapterTitle,
                chapterIndex,
                thesis.topic,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isGenerated ? Colors.green : textMuted,
                size: 20,
              ),
              onPressed: isGenerated
                  ? () => _handleSubheadingTap(
                        context,
                        chapterTitle,
                        isIntroduction || isConclusion
                            ? chapterTitle
                            : subheading,
                        chapterIndex,
                        thesis.topic,
                        thesis.writingStyle,
                      )
                  : null,
            ),
          ],
        ),
        onTap: () {
          if (!isGenerated && !isLoading) {
            _handleSubheadingTap(
              context,
              chapterTitle,
              isIntroduction || isConclusion ? chapterTitle : subheading,
              chapterIndex,
              thesis.topic,
              thesis.writingStyle,
            );
          }
        },
      ),
    ).animate().fadeIn().slideX();
  }

  Future<void> _handleRegenerateOutlines(
    BuildContext context,
    String chapterTitle,
    int chapterIndex,
    String topic,
  ) async {
    setState(() => loadingStates[chapterTitle] = true);
    try {
      final newOutlines = await _deepseekService.regenerateChapterOutlines(
        topic,
        chapterTitle,
      );
      if (newOutlines.isNotEmpty) {
        await ref.read(thesisStateProvider.notifier).updateChapterOutlines(
              chapterIndex,
              newOutlines,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Outlines regenerated successfully',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to regenerate outlines: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() => loadingStates[chapterTitle] = false);
    }
  }

  Future<void> _handleGenerateAll(BuildContext context) async {
    final generationState = ref.read(generationStateProvider);
    if (generationState.isGeneratingAll) return;

    // Check subscription status before generating all content
    final subscriptionStatus = ref.read(subscriptionStatusProvider);
    final isSubscribed = subscriptionStatus.when(
      data: (status) => status.isActive,
      loading: () => false,
      error: (_, __) => false,
    );

    // Check if user is in trial mode by examining the current route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isTrialMode = currentRoute == '/outline-trial';

    // If not subscribed AND not in trial mode, show paywall
    if (!isSubscribed && !isTrialMode) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }

    final thesisState = ref.read(thesisStateProvider);
    await thesisState.whenData((thesis) async {
      try {
        // Show confirmation dialog
        final confirmed =
            await _showGenerationConfirmationDialog(context, thesis);
        if (!confirmed) return;

        // Start background generation
        final jobId = await BackgroundGenerationService.instance
            .startBackgroundGeneration(thesis);

        print('Started background generation with job ID: $jobId');

        // Show success message and redirect to history
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🚀 Generation started! Check the History tab to track progress and get notified when complete.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: Duration(seconds: 3),
            ),
          );

          // Auto-redirect to history screen after 2 seconds
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              // Navigate to main navigation with history tab selected
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigationScreen(
                    isTrialMode: isTrialMode,
                    initialIndex: 2, // History tab index
                  ),
                ),
              );
            }
          });
        }
      } catch (e) {
        print('Error starting background generation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to start generation: $e',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    });
  }

  Future<bool> _showGenerationConfirmationDialog(
      BuildContext context, dynamic thesis) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rocket_launch,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title
                    Text(
                      'Start Background Generation?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),

                    // Description
                    Text(
                      'Your thesis will be generated in the background. You\'ll receive a notification when it\'s complete and can continue working on other projects.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),

                    // Estimated time
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Estimated time: ${_estimateGenerationTime(thesis)} minutes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: borderColor),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: buttonGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Start Generation',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  int _estimateGenerationTime(dynamic thesis) {
    // Calculate estimated time based on number of sections
    int totalSections = _calculateTotalSections(thesis);
    return (totalSections * 2)
        .clamp(5, 45); // 2 minutes per section, 5-45 minutes
  }

  int _calculateTotalSections(dynamic thesis) {
    int total = 0;
    for (var chapter in thesis.chapters) {
      if (chapter.title.toLowerCase().contains('introduction') ||
          chapter.title.toLowerCase().contains('conclusion')) {
        total += 1;
      } else {
        total += chapter.subheadings.length as int;
      }
    }
    return total;
  }

  // Helper method to calculate chapter completion percentage
  double _getChapterCompletionPercentage(dynamic chapter, int chapterIndex) {
    final notifier = ref.read(thesisStateProvider.notifier);

    // For references chapter, always show as complete
    if (chapter.title.toLowerCase().contains('references')) {
      return 100.0;
    }

    // For introduction/conclusion, check if the main content is generated
    if (chapter.title.toLowerCase().contains('introduction') ||
        chapter.title.toLowerCase().contains('conclusion')) {
      return notifier.isSubheadingGenerated(chapter.title, chapter.title)
          ? 100.0
          : 0.0;
    }

    // For regular chapters, calculate based on subheadings
    if (chapter.subheadings.isEmpty) return 0.0;

    int generatedCount = 0;
    for (String subheading in chapter.subheadings) {
      if (notifier.isSubheadingGenerated(chapter.title, subheading)) {
        generatedCount++;
      }
    }

    return (generatedCount / chapter.subheadings.length * 100);
  }

  List<Widget> _buildChapterContent(
      dynamic chapter, int chapterIndex, dynamic thesis) {
    if (chapter.title.toLowerCase().contains('references')) {
      return [
        ListTile(
          title: Text(
            'References will be automatically generated',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    if (chapter.title.toLowerCase().contains('introduction') ||
        chapter.title.toLowerCase().contains('conclusion')) {
      return [
        _buildSubheadingTile(
          chapter.title,
          [],
          chapter.title,
          chapterIndex,
          loadingStates[chapter.title] ?? false,
          thesis,
        ),
      ];
    }

    return chapter.subheadings.map<Widget>((subheading) {
      return _buildSubheadingTile(
        chapter.title,
        chapter.subheadings,
        subheading,
        chapterIndex,
        loadingStates[subheading] ?? false,
        thesis,
      );
    }).toList();
  }

  Future<void> _handleSubheadingTap(
    BuildContext context,
    String chapterTitle,
    String subheading,
    int chapterIndex,
    String topic,
    String writingStyle,
  ) async {
    final existingContent = ref
        .read(thesisStateProvider.notifier)
        .getSubheadingContent(chapterIndex, subheading);

    if (existingContent != null && existingContent.isNotEmpty) {
      // Content already exists, go directly to editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterEditorScreen(
            chapterTitle: chapterTitle,
            subheading: subheading,
            initialContent: existingContent,
            chapterIndex: chapterIndex,
          ),
        ),
      );
      return;
    }

    // Check subscription status before generating content
    final subscriptionStatus = ref.read(subscriptionStatusProvider);
    final isSubscribed = subscriptionStatus.when(
      data: (status) => status.isActive,
      loading: () => false,
      error: (_, __) => false,
    );

    // Check if user is in trial mode by examining the current route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isTrialMode = currentRoute == '/outline-trial';

    // If not subscribed AND not in trial mode, show paywall
    if (!isSubscribed && !isTrialMode) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }

    // Show generating dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Generating Section Content',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Creating content for "$subheading"...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => loadingStates[subheading] = true);

    try {
      // Use the new generateSectionContent method
      await ref.read(thesisStateProvider.notifier).generateSectionContent(
            chapterIndex,
            subheading,
          );

      // Get the generated content
      final content = ref
          .read(thesisStateProvider.notifier)
          .getSubheadingContent(chapterIndex, subheading);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to editor with generated content
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterEditorScreen(
              chapterTitle: chapterTitle,
              subheading: subheading,
              initialContent: content ?? '',
              chapterIndex: chapterIndex,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate content: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() => loadingStates[subheading] = false);
    }
  }

  void startLoadingMessages() {
    currentMessageIndex = 0;
    messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          currentMessageIndex =
              (currentMessageIndex + 1) % loadingMessages.length;
        });
      }
    });
  }

  void startCountdown() {
    _remainingTime = const Duration(minutes: 7);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thesisState = ref.watch(thesisStateProvider);
    final generationState = ref.watch(generationStateProvider);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [surfaceColor, backgroundColor],
              ),
            ),
            child: thesisState.when(
              data: (thesis) => ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 16),
                itemCount: thesis.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = thesis.chapters[index];
                  final chapterNumber = index + 1;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Status Icon
                              Container(
                                margin: EdgeInsets.only(right: 12),
                                child: () {
                                  final percentage =
                                      _getChapterCompletionPercentage(
                                          chapter, index);
                                  final chapterKey = 'chapter_${index}';
                                  final isGenerating =
                                      loadingStates[chapterKey] == true;

                                  if (isGenerating) {
                                    return SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor),
                                      ),
                                    );
                                  } else if (percentage >= 100) {
                                    return Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    );
                                  } else if (percentage > 0) {
                                    return Icon(
                                      Icons.radio_button_checked,
                                      color: primaryColor,
                                      size: 20,
                                    );
                                  } else {
                                    return Icon(
                                      Icons.radio_button_unchecked,
                                      color: textMuted,
                                      size: 20,
                                    );
                                  }
                                }(),
                              ),
                              Expanded(
                                child: Text(
                                  'Chapter ${chapterNumber}. ${chapter.title}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: () {
                                      final percentage =
                                          _getChapterCompletionPercentage(
                                              chapter, index);
                                      if (percentage >= 100)
                                        return Colors.green.shade700;
                                      if (percentage > 0) return primaryColor;
                                      return textPrimary;
                                    }(),
                                  ),
                                ),
                              ),
                              // Regenerate Outlines Button
                              if (!chapter.title
                                  .toLowerCase()
                                  .contains('references'))
                                IconButton(
                                  icon: loadingStates[chapter.title] == true
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    primaryColor),
                                          ),
                                        )
                                      : Icon(Icons.refresh,
                                          color: primaryColor),
                                  onPressed: () => _handleRegenerateOutlines(
                                    context,
                                    chapter.title,
                                    index,
                                    thesis.topic,
                                  ),
                                ),
                            ],
                          ),
                          // Chapter Progress Indicator
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final percentage =
                                            _getChapterCompletionPercentage(
                                                chapter, index);
                                        return Container(
                                          width: constraints.maxWidth *
                                              (percentage / 100),
                                          decoration: BoxDecoration(
                                            color: percentage >= 100
                                                ? Colors.green
                                                : percentage > 0
                                                    ? primaryColor
                                                    : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${_getChapterCompletionPercentage(chapter, index).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getChapterCompletionPercentage(
                                                chapter, index) >=
                                            100
                                        ? Colors.green
                                        : _getChapterCompletionPercentage(
                                                    chapter, index) >
                                                0
                                            ? primaryColor
                                            : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      collapsedIconColor: primaryColor,
                      iconColor: primaryColor,
                      children: _buildChapterContent(chapter, index, thesis),
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideY();
                },
              ),
              error: (error, stack) => Center(
                child: Container(
                  margin: EdgeInsets.all(32),
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref.refresh(thesisStateProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () {
                if (_countdownTimer == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    startCountdown();
                    startLoadingMessages();
                  });
                }
                return Container(
                  color: surfaceColor,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            formattedTime,
                            style: GoogleFonts.inter(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              loadingMessages[currentMessageIndex],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ).animate().fadeIn(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (generationState.generationSteps.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildGenerationSteps(),
            ),
          if (generationState.currentlyGenerating.isNotEmpty)
            Positioned(
              bottom: generationState.generationSteps.isNotEmpty ? 200 : 20,
              left: 0,
              right: 0,
              child: _buildGenerationStatus(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    messageTimer?.cancel();
    super.dispose();
  }
}
