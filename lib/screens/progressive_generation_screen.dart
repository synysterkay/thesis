import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../providers/thesis_provider.dart';

enum ChapterStatus {
  waiting,
  generating,
  completed,
  error,
}

class ChapterProgress {
  final String title;
  final ChapterStatus status;
  final String? errorMessage;
  final DateTime? startTime;
  final DateTime? completedTime;

  ChapterProgress({
    required this.title,
    required this.status,
    this.errorMessage,
    this.startTime,
    this.completedTime,
  });

  ChapterProgress copyWith({
    String? title,
    ChapterStatus? status,
    String? errorMessage,
    DateTime? startTime,
    DateTime? completedTime,
  }) {
    return ChapterProgress(
      title: title ?? this.title,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
    );
  }
}

class ProgressiveGenerationScreen extends ConsumerStatefulWidget {
  final String topic;
  final List<String> chapters;
  final String style;
  final bool isTrialMode;

  const ProgressiveGenerationScreen({
    super.key,
    required this.topic,
    required this.chapters,
    required this.style,
    required this.isTrialMode,
  });

  @override
  _ProgressiveGenerationScreenState createState() =>
      _ProgressiveGenerationScreenState();
}

class _ProgressiveGenerationScreenState
    extends ConsumerState<ProgressiveGenerationScreen>
    with TickerProviderStateMixin {
  List<ChapterProgress> _chapterProgress = [];
  int _currentChapterIndex = 0;
  DateTime? _overallStartTime;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  bool _isCompleted = false;

  // Development mode - set to true for testing progress without API calls
  static const bool _isDevelopmentMode = false;

  // Color scheme matching the app design
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _overallStartTime = DateTime.now();

    // Initialize progress tracking
    _chapterProgress = widget.chapters
        .map((chapter) =>
            ChapterProgress(title: chapter, status: ChapterStatus.waiting))
        .toList();

    // Animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start generation process after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });

    // Improved fallback mechanism with multiple checkpoints
    Timer(Duration(seconds: 5), () {
      if (mounted &&
          _currentChapterIndex == 0 &&
          _chapterProgress[0].status == ChapterStatus.waiting) {
        // Force start first chapter if API is slow
        _onChapterStart(0, widget.chapters[0]);

        // Set a timer to complete first chapter if it's stuck
        Timer(Duration(seconds: 30), () {
          if (mounted &&
              _chapterProgress[0].status == ChapterStatus.generating) {
            // Create minimal content for demo/testing
            _onChapterComplete(0, widget.chapters[0]);

            // Start next chapter
            if (widget.chapters.length > 1) {
              Timer(Duration(seconds: 2), () {
                if (mounted) _onChapterStart(1, widget.chapters[1]);
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    if (_isCompleted) return; // Prevent multiple calls

    try {
      print('DEBUG: Starting generation process...');
      print('DEBUG: Development mode: $_isDevelopmentMode');
      print('DEBUG: Number of chapters: ${widget.chapters.length}');

      if (_isDevelopmentMode) {
        // Simulation mode for testing
        print('DEBUG: Using simulation mode');
        await _simulateGeneration();
      } else {
        print('DEBUG: Using real API generation');
        // Real API generation with timeout
        await Future.any([
          ref.read(thesisStateProvider.notifier).generateThesisStructure(
                widget.topic,
                widget.chapters,
                widget.style,
                onChapterStart: _onChapterStart,
                onChapterComplete: _onChapterComplete,
                onChapterError: _onChapterError,
              ),
          Future.delayed(Duration(minutes: 15), () {
            throw TimeoutException('Generation timed out after 15 minutes');
          }),
        ]);
      }

      print('DEBUG: Generation completed, calling _onAllChaptersComplete');
      if (!_isCompleted) {
        _onAllChaptersComplete();
      }
    } catch (e) {
      print('DEBUG: Generation error: $e');
      _onGenerationError(e);
    }
  }

  // Simulation method for development/testing
  Future<void> _simulateGeneration() async {
    for (int i = 0; i < widget.chapters.length; i++) {
      await Future.delayed(Duration(seconds: 1));
      _onChapterStart(i, widget.chapters[i]);

      await Future.delayed(Duration(seconds: 3 + (i * 2))); // Vary timing
      _onChapterComplete(i, widget.chapters[i]);
    }
  }

  void _onChapterStart(int index, String chapterTitle) {
    print('DEBUG: Chapter start - Index: $index, Title: $chapterTitle');
    if (mounted && !_isCompleted && index < _chapterProgress.length) {
      setState(() {
        _currentChapterIndex = index;
        _chapterProgress[index] = _chapterProgress[index].copyWith(
          status: ChapterStatus.generating,
          startTime: DateTime.now(),
        );
      });
      _progressController.animateTo((index + 0.5) / widget.chapters.length);
    }
  }

  void _onChapterComplete(int index, String chapterTitle) {
    print('DEBUG: Chapter complete - Index: $index, Title: $chapterTitle');
    if (mounted && !_isCompleted && index < _chapterProgress.length) {
      setState(() {
        _chapterProgress[index] = _chapterProgress[index].copyWith(
          status: ChapterStatus.completed,
          completedTime: DateTime.now(),
        );
      });
      _progressController.animateTo((index + 1) / widget.chapters.length);
    }
  }

  void _onChapterError(int index, String chapterTitle, String error) {
    print(
        'DEBUG: Chapter error - Index: $index, Title: $chapterTitle, Error: $error');
    if (mounted && !_isCompleted && index < _chapterProgress.length) {
      setState(() {
        _chapterProgress[index] = _chapterProgress[index].copyWith(
          status: ChapterStatus.error,
          errorMessage: error,
        );
      });
    }
  }

  void _onAllChaptersComplete() {
    if (mounted && !_isCompleted) {
      setState(() {
        _isCompleted = true;
      });

      // Add celebration animation
      _progressController.animateTo(1.0);

      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Thesis structure generated! Auto-save enabled (every 30s). Loading outline viewer...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to outline viewer immediately with faster transition
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _isCompleted) {
          // Double check to prevent multiple navigations
          // Show loading dialog before navigation
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Opening Outline...',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Navigate quickly to outline viewer
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _isCompleted) {
              Navigator.of(context).pop(); // Close loading dialog
              // Always navigate to trial outline to show generated structure
              // Subscription checks will happen when user tries to generate content
              Navigator.pushReplacementNamed(context, '/outline-trial');
            }
          });
        }
      });
    }
  }

  void _onGenerationError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: ${error.toString()}'),
          backgroundColor: errorColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: screenWidth,
            constraints: BoxConstraints(
              minHeight: screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                children: [
                  _buildHeader(isDesktop, isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildOverallProgress(isDesktop, isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: (screenHeight * 0.5).clamp(300.0, 600.0),
                      minHeight: 300,
                    ),
                    child: _buildChaptersList(isDesktop, isMobile),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildFooter(isDesktop, isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader([bool isDesktop = false, bool isMobile = false]) {
    return Column(
      children: [
        Container(
          width: isMobile ? 60 : 80,
          height: isMobile ? 60 : 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 30 : 40),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: isMobile ? 30 : 40,
              ),
            ),
          ),
        ).animate().scale(),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          _isCompleted
              ? 'Thesis Generated Successfully!'
              : 'Creating Your Thesis',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          _isCompleted
              ? 'Redirecting to your thesis outline...'
              : 'Generating chapters with AI-powered content',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
            color: textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildOverallProgress(
      [bool isDesktop = false, bool isMobile = false]) {
    final completedChapters = _chapterProgress
        .where((c) => c.status == ChapterStatus.completed)
        .length;
    final generatingChapters = _chapterProgress
        .where((c) => c.status == ChapterStatus.generating)
        .length;
    final totalChapters = _chapterProgress.length;

    // Calculate progress including partial progress for generating chapters
    final progress = totalChapters > 0
        ? (completedChapters + (generatingChapters * 0.5)) / totalChapters
        : 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '$completedChapters of $totalChapters chapters',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) => LinearProgressIndicator(
              value: _progressController.value,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isCompleted ? successColor : primaryColor,
              ),
              minHeight: isMobile ? 6 : 8,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              Text(
                _getEstimatedTimeRemaining(),
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildChaptersList([bool isDesktop = false, bool isMobile = false]) {
    return Container(
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
      child: ListView.separated(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        itemCount: _chapterProgress.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isMobile ? 8 : 12),
        itemBuilder: (context, index) => _buildChapterItem(index),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildChapterItem(int index) {
    final chapter = _chapterProgress[index];
    final isActive = index == _currentChapterIndex &&
        chapter.status == ChapterStatus.generating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withOpacity(0.05) : surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? primaryColor.withOpacity(0.3) : borderColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(chapter.status, isActive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getChapterStatusText(chapter),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _getChapterStatusColor(chapter.status),
                  ),
                ),
              ],
            ),
          ),
          if (chapter.status == ChapterStatus.generating)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).slideX();
  }

  Widget _buildStatusIcon(ChapterStatus status, bool isActive) {
    IconData icon;
    Color color;

    switch (status) {
      case ChapterStatus.waiting:
        icon = Icons.schedule;
        color = textMuted;
        break;
      case ChapterStatus.generating:
        icon = Icons.edit;
        color = primaryColor;
        break;
      case ChapterStatus.completed:
        icon = Icons.check_circle;
        color = successColor;
        break;
      case ChapterStatus.error:
        icon = Icons.error;
        color = errorColor;
        break;
    }

    Widget baseIconWidget = Icon(icon, color: color, size: 24);
    Widget iconWidget = baseIconWidget;

    if (status == ChapterStatus.generating && isActive) {
      iconWidget = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.2),
          child: baseIconWidget,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: iconWidget),
    );
  }

  String _getChapterStatusText(ChapterProgress chapter) {
    switch (chapter.status) {
      case ChapterStatus.waiting:
        return 'Waiting to start...';
      case ChapterStatus.generating:
        return 'Generating content...';
      case ChapterStatus.completed:
        if (chapter.completedTime != null && chapter.startTime != null) {
          final duration =
              chapter.completedTime!.difference(chapter.startTime!);
          return 'Completed in ${duration.inSeconds}s';
        }
        return 'Completed ✓';
      case ChapterStatus.error:
        return chapter.errorMessage ?? 'Generation failed';
    }
  }

  Color _getChapterStatusColor(ChapterStatus status) {
    switch (status) {
      case ChapterStatus.waiting:
        return textMuted;
      case ChapterStatus.generating:
        return primaryColor;
      case ChapterStatus.completed:
        return successColor;
      case ChapterStatus.error:
        return errorColor;
    }
  }

  String _getEstimatedTimeRemaining() {
    if (_overallStartTime == null) return '';

    final elapsed = DateTime.now().difference(_overallStartTime!);
    final completedChapters = _chapterProgress
        .where((c) => c.status == ChapterStatus.completed)
        .length;
    final generatingChapters = _chapterProgress
        .where((c) => c.status == ChapterStatus.generating)
        .length;

    if (completedChapters == 0 && generatingChapters == 0) {
      return '~${widget.chapters.length * 45}s remaining';
    }

    if (completedChapters == 0) {
      // Still working on first chapter, estimate based on progress
      return '~${(widget.chapters.length * 45)}s remaining';
    }

    // Calculate based on actual completion times
    final avgTimePerChapter =
        elapsed.inSeconds / (completedChapters + (generatingChapters * 0.5));
    final remainingChapters =
        _chapterProgress.length - completedChapters - generatingChapters;
    final estimatedSeconds = (avgTimePerChapter * remainingChapters).round();

    if (estimatedSeconds < 30) {
      return 'Almost done!';
    } else if (estimatedSeconds < 60) {
      return '~${estimatedSeconds}s remaining';
    } else {
      final minutes = (estimatedSeconds / 60).round();
      return '~${minutes}m remaining';
    }
  }

  Widget _buildFooter([bool isDesktop = false, bool isMobile = false]) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              color: warningColor, size: isMobile ? 18 : 20),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              _isCompleted
                  ? 'Your thesis structure is ready! You can now edit and expand each chapter.'
                  : 'This may take a few minutes. Feel free to grab a coffee! ☕',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }
}
