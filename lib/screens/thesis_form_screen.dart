import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/thesis_provider.dart';
import '../services/gemini_service.dart';
import '../providers/loading_provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';
import 'package:flutter/services.dart';
import '../widgets/loading_overlay.dart';
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

  // Updated color scheme to match landing page
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Enjoying Thesis Generator?',
                  style: GoogleFonts.inter(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your review helps us improve!',
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.inter(color: textMuted),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await reviewService.openStoreListing();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Rate Now',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
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
      final shouldLeave = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor),
          ),
          title: Text(
            'Leave Thesis Generator?',
            style: GoogleFonts.inter(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Your progress will be lost. Are you sure you want to leave?',
            style: GoogleFonts.inter(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Stay',
                style: GoogleFonts.inter(color: textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Leave',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldLeave == true) {
        if (kIsWeb) {
          html.window.location.href = '/';
        }
      }
      return false;
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderColor),
          ),
          title: Text(
            'We Value Your Feedback',
            style: GoogleFonts.inter(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Would you like to rate our app before leaving?',
            style: GoogleFonts.inter(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: Text(
                'No, Exit',
                style: GoogleFonts.inter(color: textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _reviewService.openStoreListing();
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Rate App',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
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
    return WillPopScope(
      onWillPop: () async {
        await _handleBackPress();
        return false;
      },
      child: Scaffold(
        backgroundColor: surfaceColor,
        body: SafeArea(
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
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (!kIsWeb)
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
              onPressed: _handleBackPress,
            ),
          ).animate().fadeIn(delay: 200.ms),
        
        if (kIsWeb)
          const SizedBox(width: 48),
        
        Expanded(
          child: Text(
            'Create Thesis',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
        ),
        
        Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            key: const Key('api-key-button'),
            icon: const Icon(Icons.key, color: Colors.white, size: 20),
            onPressed: _showApiKeyDialog,
            tooltip: kIsWeb 
              ? 'Use Your Own API Key for Faster Generation' 
              : 'Use Your Own API',
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        title: Text(
          'Use Your Own API',
          style: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Use your own API for fast generation—its free!',
          style: GoogleFonts.inter(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/apiKey');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Set Up',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicField() {
    return Container(
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
      child: TextFormField(
        controller: _topicController,
        key: const Key('thesis-topic-field'),
        style: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Research Topic',
          hintText: 'Enter your research topic',
          labelStyle: GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.inter(
            color: textMuted,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: primaryColor,
              size: 20,
            ),
          ),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Please enter a topic' : null,
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Create Sections',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGeneratedContent() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.list_alt,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Created Sections',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ..._buildChapterFields(),
      const SizedBox(height: 24),
      _buildDropdowns(),
      const SizedBox(height: 24),
      _buildSubmitButton(),
    ];
  }

  List<Widget> _buildChapterFields() {
    return _chapterControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                key: Key('chapter-field-$idx'),
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Section ${idx + 1}',
                  labelStyle: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: backgroundColor,
                  contentPadding: const EdgeInsets.all(12),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter section title' : null,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                onPressed: () => _removeChapter(idx),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDropdowns() {
    return Column(
      children: [
        Container(
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
          child: DropdownButtonFormField<String>(
            key: const Key('writing-style-dropdown'),
            value: _selectedStyle,
            dropdownColor: backgroundColor,
            style: GoogleFonts.inter(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Academic Style',
              labelStyle: GoogleFonts.inter(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: backgroundColor,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.style,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
            items: ['Academic', 'Technical', 'Analytical'].map((style) {
              return DropdownMenuItem(
                value: style,
                child: Text(style, style: GoogleFonts.inter(color: textPrimary)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStyle = value!),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: DropdownButtonFormField<String>(
            key: const Key('format-dropdown'),
            value: _selectedFormat,
            dropdownColor: backgroundColor,
            style: GoogleFonts.inter(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Format',
              labelStyle: GoogleFonts.inter(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: backgroundColor,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
            items: ['APA', 'MLA', 'Chicago'].map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format, style: GoogleFonts.inter(color: textPrimary)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedFormat = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Create Structure',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ORIGINAL FUNCTIONALITY - UNCHANGED
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
          SnackBar(content: Text('Error creating structure: ${e.toString()}')),
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

