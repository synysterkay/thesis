import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/thesis_provider.dart';
import '../services/gemini_service.dart';
import '../providers/loading_provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';
import 'package:flutter/services.dart';
import '../widgets/loading_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_key_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window; // Only for web

class ThesisFormScreen extends ConsumerStatefulWidget {
  const ThesisFormScreen({super.key});
  @override
  _ThesisFormScreenState createState() => _ThesisFormScreenState();
}

class _ThesisFormScreenState extends ConsumerState<ThesisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  List<TextEditingController> _chapterControllers = [];
  String _selectedStyle = 'Academic';
  String _selectedFormat = 'APA';
  bool _chaptersGenerated = false;
  final ReviewService _reviewService = ReviewService();
  int _generateClickCount = 0;

  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
  }



  Future<void> _showCustomReviewDialog() async {
    final reviewService = ReviewService();
    final prefs = await SharedPreferences.getInstance();
    int usageCount = (prefs.getInt('usage_count') ?? 0) + 1;
    await prefs.setInt('usage_count', usageCount);

    if (usageCount == 1 && mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: secondaryColor,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Enjoying Thesis Generator?',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Your review helps us improve!',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.lato(color: Colors.white70),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await reviewService.openStoreListing();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Rate Now',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn().scale(),
      );
    }
  }

  Future<bool> _handleBackPress() async {
  if (kIsWeb) {
    // For web, show a simple confirmation and redirect to landing page
    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        title: Text(
          'Leave Thesis Generator?',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to leave?',
          style: GoogleFonts.lato(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Stay',
              style: GoogleFonts.lato(color: Colors.white70),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Leave',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      // Redirect to landing page
      if (kIsWeb) {
        html.window.location.href = '/';
      }
    }
    return false;
  } else {
    // For mobile, show the review dialog as before
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        title: Text(
          'We Value Your Feedback',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Would you like to rate our app before leaving?',
          style: GoogleFonts.lato(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
            child: Text(
              'No, Exit',
              style: GoogleFonts.lato(color: Colors.white70),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _reviewService.openStoreListing();
                SystemNavigator.pop();
              },
              child: Text(
                'Rate App',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return false;
  }
}


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        await _handleBackPress();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.grey[900]!],
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTopicField(),
                  const SizedBox(height: 24),
                  if (!_chaptersGenerated)
                    _buildGenerateButton()
                  else
                    ..._buildGeneratedContent(),
                ].animate(interval: 100.ms).fadeIn().slideY(),
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildHeader() {
  return Row(
    children: [
      // 🔥 Only show back button on mobile platforms
      if (!kIsWeb)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _handleBackPress,
        ).animate().fadeIn(delay: 200.ms),
      
      // 🔥 For web, add some left padding to balance the layout
      if (kIsWeb)
        const SizedBox(width: 48), // Same width as IconButton to maintain balance
      
      Expanded(
        child: Text(
          'Create Thesis',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ),
      
      // API Key button with enhanced styling and animation
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: buttonGradient,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: IconButton(
          key: const Key('api-key-button'),
          icon: const Icon(Icons.key, color: Colors.white),
          onPressed: _showApiKeyDialog,
          tooltip: kIsWeb 
            ? 'Use Your Own API Key for Faster Generation' 
            : 'Use Your Own API',
        ),
      )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true, min: 0.0, max: 1.0),
        )
        .fadeIn(delay: 200.ms)
        .then(delay: 500.ms)
        .shimmer(duration: 1500.ms, curve: Curves.easeInOut)
        .then(delay: 1000.ms)
        .scale(
          duration: 400.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
        ),
    ],
  );
}





  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Your Own API'),
        content: const Text('Use your own API for fast generation—it’s free!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/apiKey');
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicField() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
      child: TextFormField(
        controller: _topicController,
        key: const Key('thesis-topic-field'),
        style: GoogleFonts.lato(color: Colors.white),
        decoration: InputDecoration(
          labelText: l10n.thesisTopic,
          hintText: l10n.enterThesisTopic,
          labelStyle: GoogleFonts.lato(color: secondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: secondaryColor),
          ),
        ),
        validator: (value) => value?.isEmpty ?? true ? l10n.pleaseEnterTopic : null,
      ),
    );
  }

  Widget _buildGenerateButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: buttonGradient,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _generateChapters,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.generateChapters,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGeneratedContent() {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.generatedChapters,
        style: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 16),
      ..._buildChapterFields(),
      SizedBox(height: 24),
      _buildDropdowns(),
      SizedBox(height: 24),
      _buildSubmitButton(),
    ];
  }

  List<Widget> _buildChapterFields() {
    final l10n = AppLocalizations.of(context)!;
    return _chapterControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      return Container(
        margin: EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                key: Key('chapter-field-$idx'),
                style: GoogleFonts.lato(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.chapter(idx + 1),
                  labelStyle: GoogleFonts.lato(color: secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? l10n.pleaseEnterChapterTitle : null,
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: secondaryColor),
              onPressed: () => _removeChapter(idx),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDropdowns() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
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
          child: DropdownButtonFormField<String>(
            key: const Key('writing-style-dropdown'),
            value: _selectedStyle,
            dropdownColor: Colors.grey[900],
            style: GoogleFonts.lato(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.writingStyle,
              labelStyle: GoogleFonts.lato(color: secondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: secondaryColor),
              ),
            ),
            items: ['Academic', 'Technical', 'Analytical'].map((style) {
              return DropdownMenuItem(
                  value: style,
                  child: Text(style, style: GoogleFonts.lato(color: Colors.white))
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStyle = value!),
          ),
        ),
        SizedBox(height: 16),
        Container(
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
          child: DropdownButtonFormField<String>(
            key: const Key('format-dropdown'),
            value: _selectedFormat,
            dropdownColor: Colors.grey[900],
            style: GoogleFonts.lato(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.format,
              labelStyle: GoogleFonts.lato(color: secondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: secondaryColor),
              ),
            ),
            items: ['APA', 'MLA', 'Chicago'].map((format) {
              return DropdownMenuItem(
                  value: format,
                  child: Text(format, style: GoogleFonts.lato(color: Colors.white))
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedFormat = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
    gradient: buttonGradient,
    boxShadow: [
    BoxShadow(
    color: primaryColor.withOpacity(0.3),
    blurRadius: 12,
    spreadRadius: -2,
    ),
    ],
    ),
    child: ElevatedButton(
    onPressed: _submitForm,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    ),
    child: Text(
    l10n.generateThesis,
    style: GoogleFonts.lato(
    fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    ),
    ),
    );
  }

  Future<void> _generateChapters() async {
    if (_topicController.text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _generateClickCount = (prefs.getInt('generate_click_count') ?? 0) + 1;
    await prefs.setInt('generate_click_count', _generateClickCount);

    if (_generateClickCount == 2) {
      await _showCustomReviewDialog();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingOverlay(
        initialMessage: 'Generating chapters',
      ),
    );

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final suggestedChapters = await geminiService.suggestChapters(_topicController.text);

      Navigator.of(context).pop();

      setState(() {
        _chapterControllers = suggestedChapters
            .map((chapter) => TextEditingController(text: chapter))
            .toList();
        _chaptersGenerated = true;
      });
    } catch (e) {
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate chapters: $e')),
        );
      }
    }
  }

  void _removeChapter(int index) {
    setState(() {
      _chapterControllers[index].dispose();
      _chapterControllers.removeAt(index);
    });
  }

  void _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      try {
        final chapters = _chapterControllers.map((c) => c.text).toList();
        ref.read(thesisStateProvider.notifier).generateThesis(
          _topicController.text,
          chapters,
          _selectedStyle,
        );
        ref.read(loadingStateProvider.notifier).state = true;
        Navigator.pushReplacementNamed(context, '/outline');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneratingThesis(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    for (var controller in _chapterControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

