import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:thesis_generator/screens/thesis_form_screen.dart';

class ThesisDetailsScreen extends StatelessWidget {
  const ThesisDetailsScreen({Key? key}) : super(key: key);

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const SizedBox(height: 40),

    // Headline
    Text(
    "AI Thesis",
    style: GoogleFonts.lato(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    textAlign: TextAlign.left,
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

    const SizedBox(height: 16),

    // Subtitle
    Text(
    "Compare the difference with traditional thesis writing",
    style: GoogleFonts.lato(
    fontSize: 16,
    color: Colors.grey[400],
    ),
    textAlign: TextAlign.left,
    ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

    const SizedBox(height: 40),

    // BEFORE/AFTER sections
    Expanded(
    child: SingleChildScrollView(
    child: Column(
    children: [
    // BEFORE section
    _buildSection(
    title: "TRADITIONAL WAY",
      items: [
        "Weeks or months of research and writing",
        "Struggling to find relevant academic sources",
        "Difficulty maintaining proper academic structure",
        "Stress about meeting formatting requirements",
        "Uncertainty about plagiarism and originality",
      ],
      isGrayscale: true,
      icon: Icons.hourglass_empty,
    ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

      // Divider with arrow
      Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_downward,
                color: primaryColor,
                size: 24,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

      // AFTER section
      _buildSection(
        title: "AI THESIS",
        items: [
          "Complete thesis generated in minutes",
          "Automatically integrated academic citations",
          "Perfect structure with all required sections",
          "Proper formatting according to academic standards",
          "100% original content that passes plagiarism checks",
        ],
        isGrayscale: false,
        icon: Icons.auto_awesome,
      ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
    ],
    ),
    ),
    ),

      // CTA Button
      Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Superwall.shared.registerPlacement(
              'campaign_trigger',
              feature: () {
                // Navigate to ThesisFormScreen when user has access
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ThesisFormScreen()),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            "Access Ai Thesis",
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),

    ],
    ),
        ),
        ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required bool isGrayscale,
    required IconData icon,
  }) {
    final Color baseColor = isGrayscale ? Colors.grey : primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isGrayscale ? Colors.grey.shade900 : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGrayscale ? Colors.grey.shade800 : primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGrayscale
                ? Colors.black.withOpacity(0.2)
                : primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isGrayscale ? Colors.grey.shade800 : primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isGrayscale ? Colors.grey.shade500 : primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isGrayscale ? Colors.grey.shade500 : primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            color: isGrayscale ? Colors.grey.shade800 : primaryColor.withOpacity(0.2),
          ),

          const SizedBox(height: 24),

          // List items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Icon(
                    isGrayscale ? Icons.remove_circle : Icons.check_circle,
                    size: 18,
                    color: isGrayscale ? Colors.grey.shade600 : primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      height: 1.5,
                      color: isGrayscale ? Colors.grey.shade400 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

