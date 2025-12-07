import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/native_ad_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:thesis_generator/screens/onboarding/subject_selection_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnBoardScreen extends ConsumerStatefulWidget {
  const OnBoardScreen({super.key});

  @override
  ConsumerState<OnBoardScreen> createState() => _OnBoardScreenState();
}

class _OnBoardScreenState extends ConsumerState<OnBoardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<Map<String, String>> pages;

  final Gradient buttonGradient = const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _checkIfShouldSkipOnboarding();
  }

  /// Check if user has already completed onboarding and should skip to appropriate screen
  Future<void> _checkIfShouldSkipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTimeUser = prefs.getBool('first_time_user') ?? true;

    if (mounted) {
      if (isFirstTimeUser) {
        // First time users: Continue with onboarding flow
        // Will go to subject selection screen after completing onboarding
        return;
      } else {
        // Returning users: Check authentication status
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // User is already signed in: go directly to start screen
          Navigator.pushReplacementNamed(context, '/start');
        } else {
          // User is not signed in: go to mobile sign-in
          Navigator.pushReplacementNamed(context, '/mobile-signin');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pages = [
      {
        'title': 'Create Professional Academic Thesis With AI Assistance',
        'icon': 'graduationCap',
      },
      {
        'title': 'Generate Well-Structured Chapters And Content Automatically',
        'icon': 'article',
      },
      {
        'title': 'Export Your Thesis In Professional PDF Format',
        'icon': 'filePdf',
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

    // Mark user as no longer first time (completed onboarding)
    await prefs.setBool('first_time_user', false);

    if (mounted) {
      // First time completing onboarding: continue to subject selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubjectSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  Text(
                    page['title']!,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(),
                  SizedBox(height: isSmallScreen ? 20 : 32),
                  Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 80 : 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconForPage(page['icon']!),
                      size: isSmallScreen ? 40 : 50,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn().scale(),
                  SizedBox(height: isSmallScreen ? 20 : 32),
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
                              color: _currentPage == index
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey[300],
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
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentPage == pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 40),
                ],
              ),
            ),
          ),
        ),
        // Only show native ad on Android devices
        if (!Platform.isIOS) ...[
          const SizedBox(
            width: double.infinity,
            child: NativeAdWidget(),
          )
        ]
      ],
    );
  }

  IconData _getIconForPage(String iconName) {
    switch (iconName) {
      case 'graduationCap':
        return PhosphorIcons.graduationCap(PhosphorIconsStyle.regular);
      case 'article':
        return PhosphorIcons.article(PhosphorIconsStyle.regular);
      case 'filePdf':
        return PhosphorIcons.filePdf(PhosphorIconsStyle.regular);
      default:
        return PhosphorIcons.graduationCap(PhosphorIconsStyle.regular);
    }
  }
}
