import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a small delay for splash effect
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      if (kIsWeb) {
        // Web: skip onboarding and go directly to thesis form
        Navigator.pushReplacementNamed(context, '/thesis-form');
        return;
      }

      // Check if user has completed onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool('hasCompletedOnboarding') ?? false;

      if (Platform.isIOS) {
        if (hasCompletedOnboarding) {
          // Second time user - check authentication
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // User is signed in - go to start screen
            Navigator.pushReplacementNamed(context, '/start');
          } else {
            // User not signed in - go to sign in screen
            Navigator.pushReplacementNamed(context, '/mobile-signin');
          }
        } else {
          // First time user - show onboarding
          Navigator.pushReplacementNamed(context, '/onboarding1');
        }
      } else {
        // Android: Go to old onboarding screen
        Navigator.pushReplacementNamed(context, '/onboard');
      }
    } catch (e) {
      print('Splash screen error: $e');
      // Fallback: go directly to thesis form
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/thesis-form');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.graduationCap(PhosphorIconsStyle.regular),
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // App Title
              const Text(
                'Thesis Generator & AI Essay Writer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'AI-Powered Academic Writing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF4A5568),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
