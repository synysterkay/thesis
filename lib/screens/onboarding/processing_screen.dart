import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'thesis_preview_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({Key? key}) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  bool _showButton = false;
  bool _showResults = false;

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  // Random time saved between 10 and 20 hours
  final int _timeSavedHours = 10 + math.Random().nextInt(11);

  // Random quality percentage between 90% and 99%
  final int _qualityPercentage = 90 + math.Random().nextInt(10);

  // Animation controllers
  late AnimationController _timeController;
  late AnimationController _qualityController;
  late Animation<int> _timeAnimation;
  late Animation<int> _qualityAnimation;

  // Processing stages
  final List<String> _processingStages = [
    "Analyzing academic requirements...",
    "Researching relevant sources...",
    "Structuring thesis outline...",
    "Generating scholarly content...",
    "Applying citation format...",
    "Finalizing your thesis..."
  ];

  // Current stage being displayed
  int _currentStageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _timeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _qualityController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create animations
    _timeAnimation = IntTween(begin: 0, end: _timeSavedHours).animate(
        CurvedAnimation(parent: _timeController, curve: Curves.easeOut)
    );

    _qualityAnimation = IntTween(begin: 0, end: _qualityPercentage).animate(
        CurvedAnimation(parent: _qualityController, curve: Curves.easeOut)
    );

    // Cycle through processing stages
    _startStageCycle();

    // Start animations after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _timeController.forward();
        _qualityController.forward();
      }
    });

    // Show results after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResults = true;
        });
      }
    });

    // Show button after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  void _startStageCycle() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _currentStageIndex = (_currentStageIndex + 1) % _processingStages.length;
        });
        _startStageCycle();
      }
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: ConstrainedBox(
    constraints: BoxConstraints(
    minHeight: MediaQuery.of(context).size.height -
    MediaQuery.of(context).padding.top -
    MediaQuery.of(context).padding.bottom,
    ),
    child: Column(
    children: [
    const SizedBox(height: 30),

    // Headline
    Text(
    "Ai Thesis Generator…",
    style: GoogleFonts.lato(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    textAlign: TextAlign.center,
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

    const SizedBox(height: 12),

    // Copy text
    Text(
    "Our AI is crafting a high-quality thesis tailored to your specifications.",
    style: GoogleFonts.lato(
    fontSize: 16,
    color: Colors.grey[400],
    ),
    textAlign: TextAlign.center,
    ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

    const SizedBox(height: 40),

    // Time saved counter
    AnimatedBuilder(
    animation: _timeController,
    builder: (context, child) {
    return Column(
    children: [
    Text(
    "Time Saved",
    style: GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    ),
    ),
    const SizedBox(height: 8),
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    "${_timeAnimation.value}",
    style: GoogleFonts.lato(
    fontSize: 60,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    ),
    ),
    Text(
    "hrs",
    style: GoogleFonts.lato(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    ),
    ),
    ],
    ),
    const SizedBox(height: 4),
    Text(
    "of research & writing",
    style: GoogleFonts.lato(
    fontSize: 16,
    color: Colors.grey[400],
    ),
    ),
    ],
    );
    },
    ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

    const SizedBox(height: 40),

    // Quality counter
    AnimatedBuilder(
    animation: _qualityController,
    builder: (context, child) {
    return Column(
    children: [
    Text(
    "Academic Quality",
    style: GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    ),
    ),
    const SizedBox(height: 8),
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(
    "${_qualityAnimation.value}",
    style: GoogleFonts.lato(
    fontSize: 60,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    ),
    ),
    Text(
    "%",
    style: GoogleFonts.lato(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    ),
    ),
    ],
    ),
    ],
    );
    },
    ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

    const SizedBox(height: 30),

      // Current stage being processed
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Text(
          _processingStages[_currentStageIndex],
          key: ValueKey<int>(_currentStageIndex),
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),

      const SizedBox(height: 16),

      // Progress indicator
      Container(
        width: 200,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: 0,
              right: 200 - (200 * ((_currentStageIndex + 1) / _processingStages.length)),
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 40),

      // Academic features
      if (_showResults)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip("Citations", Icons.format_quote),
              _buildFeatureChip("Bibliography", Icons.menu_book),
              _buildFeatureChip("Structured", Icons.view_agenda),
              _buildFeatureChip("Research-Based", Icons.search),
              _buildFeatureChip("Plagiarism-Free", Icons.verified_user),
            ],
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 3000),
          duration: const Duration(milliseconds: 800),
        ),

      const SizedBox(height: 30),

      // Continue button
      if (_showButton)
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
                  builder: (context) => const ThesisPreviewScreen(),
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
            child: Text(
              "Start Your Thesis",
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 4000),
        ),

      const SizedBox(height: 20),
    ],
    ),
    ),
        ),
        ),
        ),
    );
  }

  Widget _buildFeatureChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

