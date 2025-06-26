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

class _OnboardingScreen1State extends State<OnboardingScreen1> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
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
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "AI Thesis",
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 40),
                  Text(
                    "AI-Powered Thesis Generator",
                    style: GoogleFonts.lato(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate()
                      .fadeIn(delay: const Duration(milliseconds: 300))
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 16),
                  Text(
                    "Academic Excellence",
                    style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate()
                      .fadeIn(delay: const Duration(milliseconds: 400))
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 24),
                  Text(
                    "We create personalized thesis content tailored to your subject, academic level, and research goals.",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 40),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(20, (index) {
                          final size = 8.0 + (index % 3) * 4.0;
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final value = (_animationController.value + (index / 20)) % 1.0;
                              final x = math.sin(value * math.pi * 2) * 120;
                              final y = math.cos(value * math.pi * 2) * 120;

                              return Positioned(
                                left: MediaQuery.of(context).size.width / 2 - 24 + x,
                                top: 100 + y,
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      primaryColor,
                                      secondaryColor,
                                      (index % 5) / 5,
                                    )!.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
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
                                color: Colors.black,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
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
                            ).animate()
                                .fadeIn(delay: const Duration(milliseconds: 600))
                                .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                            ),
                            const SizedBox(height: 20),
                            ...["Professional", "Academic", "Customizable"].map((feature) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  feature,
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList().animate(
                              interval: 100.ms,
                            ).fadeIn(
                              delay: const Duration(milliseconds: 700),
                            ).moveY(
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
                          color: index == 0
                              ? primaryColor
                              : Colors.grey[700],
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
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                  ).animate()
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
      ),
    );
  }
}
