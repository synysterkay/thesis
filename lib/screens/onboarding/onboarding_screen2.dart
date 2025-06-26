import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_screen3.dart';
import 'dart:math' as math;

class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  final List<Map<String, dynamic>> _thesisElements = [
    {'icon': Icons.psychology, 'text': 'AI-Generated', 'color': Colors.deepPurple},
    {'icon': Icons.auto_awesome, 'text': 'Professional', 'color': Colors.pink},
    {'icon': Icons.school, 'text': 'Academic', 'color': Colors.indigo},
    {'icon': Icons.format_quote, 'text': 'Citations', 'color': Colors.amber},
    {'icon': Icons.format_align_left, 'text': 'Structured', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
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

    Text(
    "Revolutionize Your Research",
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
    "Say Goodbye to Writer's Block",
    style: GoogleFonts.lato(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: secondaryColor,
    fontStyle: FontStyle.italic,
    ),
    ).animate()
        .fadeIn(delay: const Duration(milliseconds: 400))
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

    const SizedBox(height: 24),

    Text(
    "Break free from academic stress! Discover how AI can help you create well-structured, professionally written thesis content.",
    style: GoogleFonts.lato(
    fontSize: 16,
    color: Colors.grey[400],
    height: 1.5,
    ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

      const SizedBox(height: 30),

      Container(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(20, (index) {
              final size = 6.0 + (index % 4) * 3.0;
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final value = (_animationController.value + (index / 20)) % 1.0;
                  final radius = 80.0 + (value * 100);
                  final angle = value * math.pi * 2 * (1 + index / 10);
                  final x = math.cos(angle) * radius;
                  final y = math.sin(angle) * radius;

                  return Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 24 + x,
                    top: 100 + y,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          primaryColor,
                          secondaryColor,
                          (index % 7) / 7,
                        )!.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade600,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.do_not_disturb,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Endless Research & Drafting",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(delay: const Duration(milliseconds: 600))
                    .slideX(
                  begin: -0.5,
                  end: 0,
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                ),

                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: primaryColor,
                    size: 32,
                  ),
                ).animate()
                    .fadeIn(delay: const Duration(milliseconds: 800))
                    .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "AI-Powered Thesis Creation",
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _thesisElements.map((element) {
                          final index = _thesisElements.indexOf(element);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: element['color'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: element['color'].withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  element['icon'],
                                  color: element['color'],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  element['text'],
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: element['color'],
                                  ),
                                ),
                              ],
                            ),
                          ).animate()
                              .fadeIn(delay: Duration(milliseconds: 1000 + (index * 100)))
                              .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            delay: Duration(milliseconds: 1000 + (index * 100)),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuad,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(delay: const Duration(milliseconds: 900))
                    .slideY(
                  begin: 0.5,
                  end: 0,
                  delay: const Duration(milliseconds: 900),
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
            width: index == 1 ? 24 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: index == 1
                  ? primaryColor
                  : Colors.grey[700],
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 1300 + (index * 100)),
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
                builder: (context) => const OnboardingScreen3(),
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
          .fadeIn(delay: const Duration(milliseconds: 1400))
          .shimmer(
        delay: const Duration(milliseconds: 1800),
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

