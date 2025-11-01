import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/thesis_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';
import 'package:flutter/services.dart';
import '../widgets/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window; // Only for web
import 'progressive_generation_screen.dart';

class ThesisFormScreen extends ConsumerStatefulWidget {
  final String? thesisId;

  const ThesisFormScreen({super.key, this.thesisId});
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
                  child: Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                const SizedBox(height: 32),
                _buildHeroSection(),
                const SizedBox(height: 32),
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
              icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.fill),
                  color: textPrimary, size: 20),
              onPressed: _handleBackPress,
            ),
          ).animate().fadeIn(delay: 200.ms),
        if (kIsWeb) const SizedBox(width: 48),
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
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.05),
            Colors.purple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // AI Shield Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 32,
            ),
          ).animate().scale(delay: 200.ms),

          const SizedBox(height: 20),

          // Main Heading
          Text(
            '100% Human-Written Quality',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 20),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Advanced AI that writes like a human. Completely undetectable by AI detection tools.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 20),

          const SizedBox(height: 24),

          // Feature Pills
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildFeaturePill(
                '🛡️ AI Undetectable',
                Colors.green,
                500,
              ),
              _buildFeaturePill(
                '🎓 Academic Grade',
                Colors.blue,
                600,
              ),
              _buildFeaturePill(
                '⚡ 10x Faster',
                Colors.orange,
                700,
              ),
              _buildFeaturePill(
                '🔬 Research-Based',
                Colors.purple,
                800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String text, Color color, int delay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.8),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced section header
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.pencil(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'What would you like to research?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  'Our AI will generate a human-quality thesis that passes all detection tools',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Enhanced input field
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _topicController,
            key: const Key('thesis-topic-field'),
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g., "The impact of social media on mental health among teenagers" or "Renewable energy solutions for urban sustainability"',
              hintStyle: GoogleFonts.inter(
                color: textMuted,
                fontSize: 14,
                height: 1.4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: backgroundColor,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a research topic' : null,
          ),
        ),

        // Trust indicators
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTrustIndicator(
              PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
              'AI Undetectable',
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildTrustIndicator(
              PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
              'Academic Quality',
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildTrustIndicator(
              PhosphorIcons.lightning(PhosphorIconsStyle.fill),
              'Fast Delivery',
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustIndicator(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
              child: Icon(
                PhosphorIcons.listBullets(PhosphorIconsStyle.fill),
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
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter section title'
                    : null,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(PhosphorIcons.minusCircle(PhosphorIconsStyle.fill),
                    color: Colors.red, size: 20),
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
                child: Icon(
                  PhosphorIcons.palette(PhosphorIconsStyle.fill),
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
            items: ['Academic', 'Technical', 'Analytical'].map((style) {
              return DropdownMenuItem(
                value: style,
                child:
                    Text(style, style: GoogleFonts.inter(color: textPrimary)),
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
                child: Icon(
                  PhosphorIcons.quotes(PhosphorIconsStyle.fill),
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
            items: ['APA', 'MLA', 'Chicago'].map((format) {
              return DropdownMenuItem(
                value: format,
                child:
                    Text(format, style: GoogleFonts.inter(color: textPrimary)),
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
      final deepseekService = ref.read(deepseekServiceProvider);
      final suggestedChapters =
          await deepseekService.suggestChapters(_topicController.text);
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

        // Check if we're in trial mode by examining the current route
        final currentRoute = ModalRoute.of(context)?.settings.name;
        final isTrialMode = currentRoute == '/thesis-form-trial';

        // Navigate to progressive generation screen instead of direct generation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProgressiveGenerationScreen(
              topic: _topicController.text,
              chapters: chapters,
              style: _selectedStyle,
              isTrialMode: isTrialMode,
            ),
          ),
        );
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
