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

  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);
  static const hoverColor = Color(0xFFB5179E);
  late List<Map<String, String>> pages;

  final Gradient buttonGradient = const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pages = [
      {
        'title': 'Academic Writing Assistant',
        'description': 'Create professional academic thesis with AI assistance',
        'image': 'assets/onboard1.jpg',
      },
      {
        'title': 'Smart Learning Framework',
        'description': 'Generate well-structured chapters and content automatically',
        'image': 'assets/onboard2.jpg',
      },
      {
        'title': 'Easy Export In PDF',
        'description': 'Export your thesis in professional PDF format',
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
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) => _buildPage(pages[index]),
          ),
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
              const SizedBox(height: 24),
              Text(
                page['title']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                            colors: [Colors.grey[800]!, Colors.grey[800]!],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: _currentPage == pages.length - 1
                          ? _finishOnboarding
                          : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: _currentPage == pages.length - 1
                          ? ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return buttonGradient.createShader(bounds);
                          },
                          child: Text(
                            'Start Learning',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          )
                      )
                          : Text(
                        'Next',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
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
