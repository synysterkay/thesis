import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'thesis_details_screen.dart';

class ThesisPreviewScreen extends StatelessWidget {
  const ThesisPreviewScreen({Key? key}) : super(key: key);

  // Color scheme matching app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFEF4444);

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

              // Compelling headline
              Text(
                "Your AI Thesis is Ready\nto Impress Professors",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 16),

              // Value proposition
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "100% Undetectable AI • Professional Charts & Tables",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              const SizedBox(height: 32),

              // What you get preview
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What You Get:",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCard(
                        icon:
                            PhosphorIcons.chartLine(PhosphorIconsStyle.regular),
                        title: "Professional Data Visualization",
                        description:
                            "Charts, graphs, and tables that make your research stand out",
                        color: primaryColor,
                        delay: 600,
                      ),
                      _buildFeatureCard(
                        icon: PhosphorIcons.brain(PhosphorIconsStyle.regular),
                        title: "Humanized AI Writing",
                        description:
                            "Undetectable by any AI detection software - guaranteed",
                        color: accentColor,
                        delay: 800,
                      ),
                      _buildFeatureCard(
                        icon: PhosphorIcons.graduationCap(
                            PhosphorIconsStyle.regular),
                        title: "Academic Excellence",
                        description:
                            "Perfect citations, formatting, and scholarly tone",
                        color: const Color(0xFF8B5CF6),
                        delay: 1000,
                      ),
                      _buildFeatureCard(
                        icon:
                            PhosphorIcons.lightning(PhosphorIconsStyle.regular),
                        title: "Instant Generation",
                        description:
                            "Complete thesis ready in minutes, not months",
                        color: warningColor,
                        delay: 1200,
                      ),
                    ],
                  ),
                ),
              ),

              // CTA
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ThesisDetailsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create My Humanized Thesis",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIcons.arrowRight(
                                  PhosphorIconsStyle.regular),
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 1400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(
          begin: 0.3,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
        );
  }
}
