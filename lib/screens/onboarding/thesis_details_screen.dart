import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

class ThesisDetailsScreen extends StatelessWidget {
  const ThesisDetailsScreen({Key? key}) : super(key: key);

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);
  static const errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Headline
              Text(
                "Humanized AI Thesis",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.left,
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                "See why our AI-powered approach with charts & tables outperforms traditional methods",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textSecondary,
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
                          "Months of manual research and writing",
                          "Struggling to create charts and tables",
                          "Risk of AI detection software flagging content",
                          "Difficulty maintaining proper academic structure",
                          "Hours formatting references and citations",
                        ],
                        isGrayscale: true,
                        icon: Icons.schedule,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400)),

                      // Divider with arrow
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: borderColor,
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
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
                                color: borderColor,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 600)),

                      // AFTER section
                      _buildSection(
                        title: "HUMANIZED AI THESIS",
                        items: [
                          "Complete thesis with charts & tables in minutes",
                          "100% undetectable AI content that passes all scans",
                          "Professional visual data with charts & graphs",
                          "Perfect academic structure with proper citations",
                          "Instant formatting according to academic standards",
                          "Humanized content undetectable by AI scanners",
                        ],
                        isGrayscale: false,
                        icon: Icons.psychology,
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 800)),
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
                    colors: [primaryColor, Color(0xFF1D4ED8)],
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
                        // Navigate to MainNavigationScreen with thesis form when user has access
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/main-navigation',
                          (route) => false,
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
                    "Create Humanized AI Thesis",
                    style: GoogleFonts.inter(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isGrayscale ? Color(0xFFF1F5F9) : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isGrayscale ? Color(0xFFCBD5E1) : primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGrayscale
                ? Colors.black.withOpacity(0.05)
                : primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: isGrayscale
                      ? Color(0xFFE2E8F0)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isGrayscale ? Color(0xFF64748B) : primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isGrayscale ? Color(0xFF64748B) : primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color:
                isGrayscale ? Color(0xFFCBD5E1) : primaryColor.withOpacity(0.2),
          ),

          const SizedBox(height: 20),

          // List items
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      child: Icon(
                        isGrayscale ? Icons.close : Icons.check_circle,
                        size: 18,
                        color: isGrayscale ? errorColor : accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          color: isGrayscale ? Color(0xFF64748B) : textPrimary,
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
