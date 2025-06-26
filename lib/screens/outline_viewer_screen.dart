import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/thesis_provider.dart';
import '../providers/loading_provider.dart';
import '../services/navigation_service.dart';
import '../services/gemini_service.dart';
import 'chapter_editor_screen.dart';
import 'dart:async';
import '../screens/export_screen.dart';
import 'thesis_form_screen.dart';


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
  const OutlineViewerScreen({super.key});
  @override
  _OutlineViewerScreenState createState() => _OutlineViewerScreenState();
}
class _OutlineViewerScreenState extends ConsumerState<OutlineViewerScreen> {
  final GeminiService _geminiService = GeminiService();
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
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);
  static const hoverColor = Color(0xFFB5179E);

  Timer? _generateAllCountdownTimer;
  Duration _generateAllRemainingTime = const Duration(minutes: 30);
  String get generateAllFormattedTime {
    final minutes = _generateAllRemainingTime.inMinutes;
    final seconds = _generateAllRemainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    loadingMessages = [
      l10n.loadingMessage1,
      l10n.loadingMessage2,
      l10n.loadingMessage3,
      l10n.loadingMessage4,
      l10n.loadingMessage5,
      l10n.loadingMessage6,
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateInitialContent();
    });
  }
  Future<void> _generateInitialContent() async {
    final thesisState = ref.read(thesisStateProvider);
    await thesisState.whenData((thesis) async {
      try {
        int totalSections = 0;
        int completedSections = 0;

        for (var chapter in thesis.chapters) {
          if (chapter.title.toLowerCase().contains('introduction') ||
              chapter.title.toLowerCase().contains('conclusion')) {
            totalSections++;
          } else {
            totalSections += chapter.subheadings.length;
          }
        }

        for (var chapterIndex = 0; chapterIndex < thesis.chapters.length; chapterIndex++) {
          final chapter = thesis.chapters[chapterIndex];
          if (chapter.title.toLowerCase().contains('introduction') ||
              chapter.title.toLowerCase().contains('conclusion')) {
            await _generateContent(
                chapter.title,
                chapterIndex,
                thesis,
                completedSections++,
                totalSections
            );
          } else {
            for (var subheading in chapter.subheadings) {
              await _generateContent(
                  subheading,
                  chapterIndex,
                  thesis,
                  completedSections++,
                  totalSections
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => currentlyGenerating = '');
        }
      }
    });
  }

  Future<void> _generateContent(String title, int chapterIndex, thesis, int completed, int total) async {
    try {
      setState(() {
        loadingStates[title] = true;
        currentStep = title;
        generationSteps.add(title);
      });

      // Generate content with retry logic
      String content = '';
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          content = await _geminiService.generateChapterContent(
            thesis.topic,
            title,
            thesis.writingStyle,
          );

          if (content.isNotEmpty && content.length >= 500) {
            break;
          }
        } catch (e) {
          print('Attempt $attempt failed: $e');
          await Future.delayed(Duration(seconds: 30));
        }
      }

      if (content.isEmpty) {
        throw Exception('Failed to generate valid content after multiple attempts');
      }

      if (mounted && content.isNotEmpty) {
        await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
          chapterIndex,
          title,
          content,
        );

        setState(() {
          loadingStates[title] = false;
          currentStep = '';
        });
      }
    } catch (e) {
      print('Error generating content: $e');
      setState(() {
        loadingStates[title] = false;
        currentStep = '';
      });
      throw Exception('Failed to generate content: $e');
    }
  }


  Widget _buildGenerationSteps() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...generationSteps.map((step) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                step,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            )).toList(),
            if (currentStep.isNotEmpty)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    currentStep,
                    style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationStatus() {
    if (currentlyGenerating.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryColor),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: generateAllProgress / 100,
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                strokeWidth: 2,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentlyGenerating,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${generateAllProgress.toStringAsFixed(0)}%',
                      style: GoogleFonts.lato(
                        color: secondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: secondaryColor),
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThesisFormScreen()),
        ),
      ),
      title: Text(
        l10n.thesis,
        style: GoogleFonts.lato(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
      ),
      centerTitle: false,
      actions: [
        if (!isGeneratingAll)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              icon: Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(l10n.generateAll,
                  style: GoogleFonts.lato(color: Colors.white)),
              onPressed: () => _handleGenerateAll(context),
            ),
          ),
        if (isGeneratingAll)
          Expanded(
            child: Center(
              child: Text(
                generateAllFormattedTime,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
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
    final isGenerated = notifier.isSubheadingGenerated(chapterTitle, subheading);
    final isIntroduction = chapterTitle.toLowerCase().contains('introduction');
    final isConclusion = chapterTitle.toLowerCase().contains('conclusion');

    // Calculate chapter and subheading numbers
    final chapterNumber = chapterIndex + 1;
    final subheadingNumber = subheadings.indexOf(subheading) + 1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          isIntroduction || isConclusion ?
          '$chapterNumber.0 $chapterTitle' :
          '$chapterNumber.$subheadingNumber $subheading',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: isGenerated ? Colors.white : Colors.grey,
          ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: isGenerated
                  ? Icon(Icons.check_circle, color: secondaryColor)
                  : Icon(Icons.circle_outlined, color: Colors.grey),
              onPressed: () {
                if (!isGenerated) {
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
            IconButton(
              icon: Icon(Icons.refresh, color: secondaryColor),
              onPressed: () => _handleRegenerateOutlines(
                context,
                chapterTitle,
                chapterIndex,
                thesis.topic,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          )
              : Icon(Icons.edit, color: isGenerated ? secondaryColor : Colors.grey),
          onPressed: isGenerated
              ? () => _handleSubheadingTap(
            context,
            chapterTitle,
            isIntroduction || isConclusion ? chapterTitle : subheading,
            chapterIndex,
            thesis.topic,
            thesis.writingStyle,
          )
              : null,
        ),
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
      final newOutlines = await _geminiService.regenerateChapterOutlines(
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
            content: Text('Outlines regenerated successfully'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to regenerate outlines: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loadingStates[chapterTitle] = false);
    }
  }

  Future<void> _handleGenerateAll(BuildContext context) async {
    if (isGeneratingAll) return;

    final l10n = AppLocalizations.of(context)!;
    final thesisState = ref.read(thesisStateProvider);

    await thesisState.whenData((thesis) async {
      setState(() {
        isGeneratingAll = true;
        currentlyGenerating = l10n.generatingContent;
        startGenerateAllCountdown();
        generationSteps.clear();
      });

      try {
        int totalSections = _calculateTotalSections(thesis);
        int completedSections = 0;
        List<String> failedSections = [];

        // Process each chapter
        for (var i = 0; i < thesis.chapters.length; i++) {
          final chapter = thesis.chapters[i];

          // Skip References chapter
          if (chapter.title.toLowerCase().contains('references')) {
            continue;
          }

          setState(() {
            currentlyGenerating = 'Generating: ${chapter.title}';
          });

          if (_isSpecialChapter(chapter.title)) {
            await _generateSpecialChapterContent(
                chapter, i, thesis, ++completedSections, totalSections
            );
            await Future.delayed(Duration(seconds: 45));
          } else {
            for (var subheading in chapter.subheadings) {
              try {
                final content = await _geminiService.retryGenerateContent(
                  thesis.topic,
                  subheading,
                  thesis.writingStyle,
                );

                await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
                  i, subheading, content,
                );

                setState(() {
                  completedSections++;
                  generateAllProgress = (completedSections / totalSections) * 100;
                  generationSteps.add(subheading);
                });

                await Future.delayed(Duration(seconds: 45));
              } catch (e) {
                failedSections.add(subheading);
                print('Failed to generate $subheading: $e');
              }
            }
          }
        }

        // Handle completion
        if (mounted) {
          if (failedSections.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ExportScreen()),
            );
          } else {
            await _retryFailedSections(failedSections, thesis);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${failedSections.length} sections need attention')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneratingContent(e.toString()))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isGeneratingAll = false;
            currentlyGenerating = '';
            currentStep = '';
          });
          _generateAllCountdownTimer?.cancel();
        }
      }
    });
  }




  bool _isSpecialChapter(String title) {
    return title.toLowerCase().contains('introduction') ||
        title.toLowerCase().contains('conclusion');
  }

  Future<void> _generateSpecialChapterContent(
      dynamic  chapter,
      int chapterIndex,
      dynamic thesis,
      int completedSections,
      int totalSections,
      ) async {
    setState(() {
      loadingStates[chapter.title] = true;
      currentStep = chapter.title;
    });

    final content = await _geminiService.retryGenerateContent(
      thesis.topic,
      chapter.title,
      thesis.writingStyle,
    );

    await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
      chapterIndex,
      chapter.title,
      content,
    );

    setState(() {
      loadingStates[chapter.title] = false;
      generationSteps.add(chapter.title);
    });

    _updateGenerationProgress(completedSections / totalSections, chapter.title);
  }

  Future<void> _generateRegularChapterContent(
      dynamic  chapter,
      int chapterIndex,
      dynamic thesis,
      int completedSections,
      int totalSections,
      ) async {
    for (var subheading in chapter.subheadings) {
      if (!mounted) return;

      setState(() {
        loadingStates[subheading] = true;
        currentStep = subheading;
      });

      final content = await _geminiService.retryGenerateContent(
        thesis.topic,
        subheading,
        thesis.writingStyle,
      );

      await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
        chapterIndex,
        subheading,
        content,
      );

      setState(() {
        loadingStates[subheading] = false;
        generationSteps.add(subheading);
      });

      _updateGenerationProgress(completedSections / totalSections, subheading);
    }
  }

  void _showGenerationComplete(BuildContext context, AppLocalizations l10n, List<String> failedSections) {
    if (failedSections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.generatedSuccessfully,
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: primaryColor,
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExportScreen()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generation completed with ${failedSections.length} sections requiring attention',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleGenerationError(BuildContext context, AppLocalizations l10n, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.errorGeneratingContent(error.toString()),
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: hoverColor,
      ),
    );
  }

  void _cleanupGeneration() {
    if (mounted) {
      setState(() {
        isGeneratingAll = false;
        currentlyGenerating = '';
        currentStep = '';
      });
      _generateAllCountdownTimer?.cancel();
    }
  }


  Future<void> _retryFailedSections(List<String> failedSections, dynamic thesis) async {
    for (var section in failedSections) {
      try {
        final content = await _geminiService.retryGenerateContent(
          thesis.topic,
          section,
          thesis.writingStyle,
        );

        // Update content in thesis state
        final chapterIndex = thesis.chapters.indexWhere((c) => c.title == section);
        if (chapterIndex != -1) {
          await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
            chapterIndex,
            section,
            content,
          );
        }
      } catch (e) {
        print('Final retry failed for $section: $e');
      }
    }
  }




  void _updateGenerationProgress(double progress, String currentItem) {
    setState(() {
      currentStep = currentItem;
      generateAllProgress = (progress * 100).roundToDouble();
    });
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


  List<Widget> _buildChapterContent(dynamic chapter, int chapterIndex, dynamic thesis) {
    if (chapter.title.toLowerCase().contains('references')) {
      return [
        ListTile(
          title: Text(
            'References will be automatically generated',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey,
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
    final existingContent = ref.read(thesisStateProvider.notifier)
        .getSubheadingContent(chapterIndex, subheading);

    if (existingContent != null && existingContent.isNotEmpty) {
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

    setState(() => loadingStates[subheading] = true);
    try {
      final content = await _geminiService.generateChapterContent(
        topic,
        '$chapterTitle - $subheading',
        writingStyle,
      );

      await ref.read(thesisStateProvider.notifier).updateSubheadingContent(
        chapterIndex,
        subheading,
        content,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterEditorScreen(
              chapterTitle: chapterTitle,
              subheading: subheading,
              initialContent: content,
              chapterIndex: chapterIndex,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate content: $e')),
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
          currentMessageIndex = (currentMessageIndex + 1) % loadingMessages.length;
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


  void startGenerateAllCountdown() {
    _generateAllRemainingTime = const Duration(minutes: 30);
    _generateAllCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_generateAllRemainingTime.inSeconds > 0) {
            _generateAllRemainingTime = Duration(seconds: _generateAllRemainingTime.inSeconds - 1);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  void _handleExport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final thesisState = ref.read(thesisStateProvider);

    thesisState.whenData((thesis) {
      if (thesis == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No thesis data available')),
        );
        return;
      }

      // Check if generation is complete
      if (isGeneratingAll) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait for generation to complete')),
        );
        return;
      }

      // Validate content before navigation
      bool isComplete = true;
      String missingSection = '';

      for (var chapter in thesis.chapters) {
        if (chapter.title.toLowerCase().contains('references')) continue;

        if (chapter.title.toLowerCase().contains('introduction') ||
            chapter.title.toLowerCase().contains('conclusion')) {
          if (chapter.subheadingContents.isEmpty) {
            isComplete = false;
            missingSection = chapter.title;
            break;
          }
        } else {
          for (var subheading in chapter.subheadings) {
            if (!chapter.subheadingContents.containsKey(subheading) ||
                chapter.subheadingContents[subheading]?.isEmpty == true) {
              isComplete = false;
              missingSection = subheading;
              break;
            }
          }
        }
      }

      if (isComplete) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ExportScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing content for: $missingSection'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final thesisState = ref.watch(thesisStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey[900]!],
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
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chapter ${chapterNumber}. ${chapter.title}',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!chapter.title.toLowerCase().contains('references'))
                            IconButton(
                              icon: loadingStates[chapter.title] == true
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                                ),
                              )
                                  : Icon(Icons.refresh, color: secondaryColor),
                              onPressed: () => _handleRegenerateOutlines(
                                context,
                                chapter.title,
                                index,
                                thesis.topic,
                              ),
                            ),
                        ],
                      ),
                      collapsedIconColor: secondaryColor,
                      iconColor: secondaryColor,
                      children: _buildChapterContent(chapter, index, thesis),
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideY();
                },
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error',
                    style: GoogleFonts.lato(color: secondaryColor)),
              ),
              loading: () {
                if (_countdownTimer == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    startCountdown();
                    startLoadingMessages();
                  });
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        formattedTime,
                        style: GoogleFonts.lato(
                          color: secondaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          loadingMessages[currentMessageIndex],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ).animate().fadeIn(),
                    ],
                  ),
                );
              },
            ),
          ),
          if (generationSteps.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildGenerationSteps(),
            ),
          if (currentlyGenerating.isNotEmpty)
            Positioned(
              bottom: generationSteps.isNotEmpty ? 200 : 20,
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
    _generateAllCountdownTimer?.cancel();
    messageTimer?.cancel();
    super.dispose();
  }
}

