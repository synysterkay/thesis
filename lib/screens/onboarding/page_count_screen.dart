import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'processing_screen.dart';

class PageCountScreen extends StatefulWidget {
  const PageCountScreen({Key? key}) : super(key: key);

  @override
  State<PageCountScreen> createState() => _PageCountScreenState();
}

class _PageCountScreenState extends State<PageCountScreen> {
  final TextEditingController _pageController = TextEditingController();
  final FocusNode _pageFocusNode = FocusNode();
  bool _isInputValid = false;

  // Color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);

  // Predefined page count options
  final List<int> _quickPageOptions = [10, 20, 30, 50, 100];

  @override
  void initState() {
    super.initState();
    // Add listener to validate input
    _pageController.addListener(_validateInput);

    // Auto focus on the input field when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _pageController.text;
    if (text.isEmpty) {
      setState(() {
        _isInputValid = false;
      });
      return;
    }

    try {
      final pages = int.parse(text);
      setState(() {
        _isInputValid = pages > 0;
      });
    } catch (e) {
      setState(() {
        _isInputValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // Wrap with SingleChildScrollView to allow scrolling when keyboard appears
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top content section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.notebook(
                                  PhosphorIconsStyle.regular),
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Length",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 100)),

                      const SizedBox(height: 24),

                      // Headline
                      Text(
                        "How many pages do you need?",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 200)),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        "We'll generate content that fits your required length.",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 300)),

                      const SizedBox(height: 50),

                      // Page count input field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Enter page count",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ).animate().fadeIn(
                                delay: const Duration(milliseconds: 400)),

                            const SizedBox(height: 12),

                            // Custom page input field
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _pageFocusNode.hasFocus
                                      ? primaryColor
                                      : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.article(
                                        PhosphorIconsStyle.regular),
                                    size: 32,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _pageController,
                                      focusNode: _pageFocusNode,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        backgroundColor: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "0",
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFD1D5DB),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "pages",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(
                                delay: const Duration(milliseconds: 500)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Note
                      Text(
                        "Standard academic format: double-spaced, 12pt font",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 800)),

                      const SizedBox(height: 24),
                    ],
                  ),

                  // Bottom section with button
                  Column(
                    children: [
                      // CTA Button
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isInputValid
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProcessingScreen(),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _isInputValid
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF1D4ED8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFF3F4F6),
                                        Color(0xFFF3F4F6)
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Continue",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isInputValid
                                          ? Colors.white
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    PhosphorIcons.arrowRight(
                                        PhosphorIconsStyle.regular),
                                    size: 20,
                                    color: _isInputValid
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 900)),

                      const SizedBox(height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
