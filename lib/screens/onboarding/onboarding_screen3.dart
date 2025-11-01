import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'thesis_preview_screen.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({Key? key}) : super(key: key);

  // Modern conversion-focused color scheme
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF64748B);
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

              // Progress indicator
              Row(
                children: [
                  _buildProgressDot(true),
                  _buildProgressLine(true),
                  _buildProgressDot(true),
                  _buildProgressLine(true),
                  _buildProgressDot(true),
                ],
              ),
              
              const SizedBox(height: 40),

              // Final compelling headline
              Text(
                "Your Academic Success\nStarts Here",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 16),

              // Urgency message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [warningColor.withOpacity(0.1), primaryColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: warningColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Limited Time Offer",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join thousands of students who've already transformed their academic performance",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              const SizedBox(height: 32),

              // Final value proposition
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFinalBenefit(
                        icon: Icons.verified_user,
                        title: "Undetectable AI Technology",
                        description: "Our advanced humanization ensures your thesis passes all AI detection tools",
                        guarantee: "100% Guarantee",
                        color: accentColor,
                        delay: 600,
                      ),
                      
                      _buildFinalBenefit(
                        icon: Icons.insert_chart_outlined,
                        title: "Professional Visual Elements",
                        description: "Automatic generation of charts, graphs, and data tables that impress professors",
                        guarantee: "Stand Out Visually",
                        color: primaryColor,
                        delay: 800,
                      ),
                      
                      _buildFinalBenefit(
                        icon: Icons.schedule,
                        title: "Instant Academic Results",
                        description: "Generate a complete, publication-ready thesis in minutes, not months",
                        guarantee: "Save 200+ Hours",
                        color: Color(0xFF8B5CF6),
                        delay: 1000,
                      ),

                      const SizedBox(height: 24),

                      // Testimonial/Social proof
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: List.generate(5, (index) => 
                                Icon(Icons.star, color: Colors.amber, size: 20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '"This app saved my entire semester. The thesis looked so professional with all the charts and data - my professor was amazed!"',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: textPrimary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "- Sarah M., Harvard Student",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
                    ],
                  ),
                ),
              ),

              // Final CTA with maximum urgency
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    Text(
                      "Ready to Transform Your Academic Life?",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join 50,000+ successful students worldwide",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: [primaryColor, Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ThesisPreviewScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Start My Humanized Thesis Now",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.rocket_launch, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "🔒 Secure • ⚡ Instant • ✅ Guaranteed",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 1600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : borderColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? primaryColor : borderColor,
      ),
    );
  }

  Widget _buildFinalBenefit({
    required IconData icon,
    required String title,
    required String description,
    required String guarantee,
    required Color color,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
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
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    guarantee,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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