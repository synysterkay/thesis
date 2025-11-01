import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'thesis_form_screen.dart';
import '../widgets/native_ad_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:thesis_generator/screens/onboarding/subject_selection_screen.dart';

class OnBoardScreen extends ConsumerStatefulWidget {
  const OnBoardScreen({super.key});

  @override
  ConsumerState<OnBoardScreen> createState() => _OnBoardScreenState();
}

class _OnBoardScreenState extends ConsumerState<OnBoardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);
  late List<Map<String, String>> pages;

  final Gradient buttonGradient = const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pages = [
      {
        'title': 'Humanized AI Academic Writing',
        'description':
            'Create undetectable AI-powered thesis with professional charts and tables',
        'image': 'assets/onboard1.jpg',
      },
      {
        'title': 'Visual Data Excellence',
        'description':
            'Generate well-structured content with comprehensive charts, graphs, and visual data',
        'image': 'assets/onboard2.jpg',
      },
      {
        'title': 'Professional PDF Export',
        'description':
            'Export your humanized thesis with charts & tables in professional PDF format',
        'image': 'assets/onboard3.jpg',
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubjectSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          onPageChanged: (int page) {
            setState(() => _currentPage = page);
          },
          itemBuilder: (context, index) => _buildPage(pages[index]),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                page['title']!,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              Text(
                page['description']!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: surfaceColor,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(page['image']!, fit: BoxFit.cover),
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: _currentPage == index
                              ? buttonGradient
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFFCBD5E1),
                                    const Color(0xFFCBD5E1)
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _currentPage == pages.length - 1
                        ? _finishOnboarding
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        _currentPage == pages.length - 1
                            ? 'Start Creating'
                            : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        // Only show native ad on Android devices
        if (!Platform.isIOS) ...[
          const SizedBox(height: 24), // Add extra spacing before the ad
          const SizedBox(
            width: double.infinity,
            child: NativeAdWidget(),
          )
        ]
      ],
    );
  }
}
