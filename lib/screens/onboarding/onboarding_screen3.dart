import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'subject_selection_screen.dart';
import 'dart:math' as math;

class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  final List<Map<String, dynamic>> _academicFormats = [
    {'icon': Icons.format_list_numbered, 'text': 'APA Format', 'color': Colors.blue},
    {'icon': Icons.format_quote, 'text': 'MLA Style', 'color': Colors.green},
    {'icon': Icons.menu_book, 'text': 'Chicago Style', 'color': Colors.orange},
    {'icon': Icons.school, 'text': 'Harvard Style', 'color': Colors.purple},
    {'icon': Icons.description, 'text': 'IEEE Format', 'color': Colors.red},
  ];

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
    const SizedBox(height: 30),

    Text(
    "Perfect Thesis for",
    style: GoogleFonts.lato(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ).animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

    const SizedBox(height: 8),

    Text(
    "Every Academic Need",
    style: GoogleFonts.lato(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: secondaryColor,
    fontStyle: FontStyle.italic,
    ),
    ).animate()
        .fadeIn(delay: const Duration(milliseconds: 400))
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

    const SizedBox(height: 20),

    Text(
    "Whether it's a bachelor's thesis, master's dissertation, or doctoral research, we've got formats and structures that match your academic requirements.",
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
    final size = 8.0 + (index % 4) * 4.0;
    final isSquare = index % 3 == 0;

    return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
    final value = (_animationController.value + (index / 30)) % 1.0;
    final fallSpeed = 0.3 + (index % 5) * 0.1;
    final swayAmount = 50.0 + (index % 3) * 20.0;

    final x = MediaQuery.of(context).size.width / 2 - 150 +
    (index % 10) * 30.0 +
        math.sin(value * math.pi * 2) * swayAmount;

    final y = -50 + value * 400 * fallSpeed;

    final angle = value * math.pi * (index % 4);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: [
              primaryColor,
              secondaryColor,
              Colors.blue,
              Colors.purple,
              Colors.indigo,
              Colors.teal,
              Colors.pink,
            ][index % 7].withOpacity(0.7),
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isSquare ? BorderRadius.circular(2) : null,
          ),
        ),
      ),
    );
    },
    );
    }),

      Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.format_align_left,
                  color: primaryColor,
                  size: 24,
                ),
                Text(
                  "Citation Formats",
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...List.generate(_academicFormats.length > 3 ? 3 : _academicFormats.length, (index) {
              final format = _academicFormats[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: format['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: format['color'].withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      format['icon'],
                      color: format['color'],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      format['text'],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: format['color'].withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: format['color'].withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Supported",
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: format['color'],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(delay: Duration(milliseconds: 600 + (index * 150)))
                  .slideX(
                begin: 0.3,
                end: 0,
                delay: Duration(milliseconds: 600 + (index * 150)),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuad,
              );
            }),
          ],
        ),
      ).animate()
          .fadeIn(delay: const Duration(milliseconds: 600))
          .scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
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
            width: index == 2 ? 24 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: index == 2
                  ? primaryColor
                  : Colors.grey[700],
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 1600 + (index * 100)),
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
                builder: (context) => const SubjectSelectionScreen(),
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
                "Get Started",
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
          .fadeIn(delay: const Duration(milliseconds: 1700))
          .shimmer(
        delay: const Duration(milliseconds: 2000),
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

