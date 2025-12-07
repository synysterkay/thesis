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
import '../utils/web_navigation.dart';
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
          WebNavigation.redirectToHome();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

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
            child: Column(
              children: [
                // Header (fixed at top)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildHeader(),
                ),

                // Main content (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Compact hero section
                        _buildCompactHero(isSmallScreen),
                        const SizedBox(height: 24),

                        // Topic field (prioritized)
                        _buildTopicField(),
                        const SizedBox(height: 24),

                        if (!_chaptersGenerated)
                          _buildGenerateButton()
                        else
                          ..._buildGeneratedContent(),

                        const SizedBox(height: 40), // Bottom padding
                      ].animate(interval: 100.ms).fadeIn().slideY(),
                    ),
                  ),
                ),
              ],
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

  Widget _buildCompactHero(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.05),
            Colors.purple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),

          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Human-Written Quality',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI undetectable • Academic grade • Research-based',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 10);
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simplified, more prominent header
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would you like to research?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Describe your topic or research question',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enhanced input field with better prominence
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Explicitly set to white
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _topicController,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'e.g., "The impact of artificial intelligence on modern education systems" or "Sustainable energy solutions for urban development"',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: textMuted,
                height: 1.4,
              ),
              border: InputBorder.none,
              fillColor: Colors.white, // Ensure fill color is white
              filled: true,
              contentPadding: const EdgeInsets.all(20),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                  color: primaryColor.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your research topic';
              }
              if (value.trim().length < 10) {
                return 'Please provide more details about your topic';
              }
              return null;
            },
            onChanged: (value) {
              // Real-time character count or suggestions could go here
            },
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 20),

        // Quick suggestion chips
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTopicSuggestion('Technology & AI'),
            _buildTopicSuggestion('Environmental Science'),
            _buildTopicSuggestion('Business Management'),
            _buildTopicSuggestion('Psychology'),
          ],
        ).animate().fadeIn(delay: 400.ms),

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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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

  Widget _buildTopicSuggestion(String topic) {
    return GestureDetector(
      onTap: () {
        if (_topicController.text.isEmpty) {
          // Could set a template or help user get started
          _showTopicSuggestions(topic);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              size: 12,
              color: primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              topic,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopicSuggestions(String category) {
    // This could show a dialog with example topics for the category
    final Map<String, List<String>> suggestions = {
      'Technology & AI': [
        'The impact of artificial intelligence on modern education',
        'Machine learning applications in healthcare diagnostics',
        'Cybersecurity challenges in the digital age',
      ],
      'Environmental Science': [
        'Climate change effects on biodiversity conservation',
        'Renewable energy solutions for sustainable development',
        'Ocean pollution and marine ecosystem protection',
      ],
      'Business Management': [
        'Digital transformation strategies in modern enterprises',
        'Leadership styles and organizational performance',
        'Supply chain optimization in global markets',
      ],
      'Psychology': [
        'Social media impact on adolescent mental health',
        'Cognitive behavioral therapy effectiveness studies',
        'Workplace stress and employee wellbeing programs',
      ],
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category Topics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions[category]!
              .map((topic) => ListTile(
                    title: Text(topic),
                    onTap: () {
                      _topicController.text = topic;
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
