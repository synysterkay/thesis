import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_screen2.dart';
import 'dart:math' as math;

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);
  static const accentColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "AI Thesis Generator",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                const SizedBox(height: 40),
                Text(
                  "Humanized AI-Powered\nThesis Creation",
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 16),
                Text(
                  "Undetectable AI Excellence",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    fontStyle: FontStyle.italic,
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 400))
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 24),
                Text(
                  "Generate professional academic theses with humanized AI content that's completely undetectable. Complete with charts, tables, and visual elements for maximum academic impact.",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                const SizedBox(height: 40),
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(15, (index) {
                        final size = 6.0 + (index % 3) * 3.0;
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final value =
                                (_animationController.value + (index / 15)) %
                                    1.0;
                            final x = math.sin(value * math.pi * 2) * 100;
                            final y = math.cos(value * math.pi * 2) * 100;

                            return Positioned(
                              left: MediaQuery.of(context).size.width / 2 -
                                  24 +
                                  x,
                              top: 100 + y,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    primaryColor,
                                    accentColor,
                                    (index % 5) / 5,
                                  )!
                                      .withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: primaryColor.withOpacity(0.2),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: primaryColor,
                              size: 40,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: const Duration(milliseconds: 600))
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                              ),
                          const SizedBox(height: 20),
                          ...[
                            "Humanized Content",
                            "Charts & Tables",
                            "Undetectable AI"
                          ]
                              .map((feature) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    feature,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                );
                              })
                              .toList()
                              .animate(
                                interval: 100.ms,
                              )
                              .fadeIn(
                                delay: const Duration(milliseconds: 700),
                              )
                              .moveY(
                                begin: 20,
                                end: 0,
                                delay: const Duration(milliseconds: 700),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuad,
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10,
                      width: index == 0 ? 24 : 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: index == 0 ? primaryColor : borderColor,
                      ),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 900 + (index * 100)),
                        );
                  }),
                ),
                const SizedBox(height: 24),
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
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen2(),
                        ),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 1000))
                    .shimmer(
                      delay: const Duration(milliseconds: 1500),
                      duration: const Duration(milliseconds: 1500),
                    ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
