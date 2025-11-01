import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);

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
      backgroundColor: Colors.black,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Headline
                      Text(
                        "How many pages do you need?",
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 200)),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        "We'll generate content that fits your required length.",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.left,
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
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Enter page count",
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(
                                delay: const Duration(milliseconds: 400)),

                            const SizedBox(height: 12),

                            // Custom page input field
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _pageFocusNode.hasFocus
                                      ? primaryColor
                                      : Colors.grey[800]!,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
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
                                      style: GoogleFonts.lato(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "0",
                                        hintStyle: GoogleFonts.lato(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "pages",
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      color: Colors.grey[500],
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

                      // Note moved up from bottom
                      Text(
                        "Standard academic format: double-spaced, 12pt font",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey[600],
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: _isInputValid
                                ? [primaryColor, Color(0xFF1D4ED8)]
                                : [Colors.grey[700]!, Colors.grey[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: _isInputValid
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
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
                            disabledForegroundColor: Colors.grey[600],
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            "Continue",
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
