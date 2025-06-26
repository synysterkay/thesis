import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
      
      // Check if first time user (web-safe)
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('first_time') ?? true;
      
      if (mounted) {
        if (isFirstTime) {
          // For web, skip onboarding and go directly to thesis form
          if (kIsWeb) {
            Navigator.pushReplacementNamed(context, '/thesis-form');
          } else {
            // For mobile, check platform safely
            bool isIOS = false;
            try {
              isIOS = Platform.isIOS;
            } catch (e) {
              // Fallback for unsupported platforms
              isIOS = false;
            }
            
            if (isIOS) {
              Navigator.pushReplacementNamed(context, '/onboarding1');
            } else {
              Navigator.pushReplacementNamed(context, '/thesis-form');
            }
          }
          await prefs.setBool('first_time', false);
        } else {
          Navigator.pushReplacementNamed(context, '/thesis-form');
        }
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
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // App Title
            const Text(
              'Thesis Generator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'AI-Powered Academic Writing',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
            ),
          ],
        ),
      ),
    );
  }
}
