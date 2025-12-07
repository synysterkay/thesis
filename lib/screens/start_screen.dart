import 'package:flutter/material.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/mobile_auth_provider.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationStatus();
    });
  }

  Future<void> _checkAuthenticationStatus() async {
    final authState = ref.read(mobileAuthStateProvider);

    await authState.when(
      data: (user) {
        if (user == null && mounted) {
          Navigator.of(context).pushReplacementNamed('/mobile-signin');
        }
      },
      loading: () async {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          final user = ref.read(mobileAuthStateProvider).value;
          if (user == null) {
            Navigator.of(context).pushReplacementNamed('/mobile-signin');
          }
        }
      },
      error: (error, stack) {
        print('Auth check error: $error');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/mobile-signin');
        }
      },
    );
  }

  Future<void> _handleStart() async {
    if (_isLoading) return;

    final user = ref.read(mobileAuthStateProvider).value;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to continue')),
        );
        Navigator.of(context).pushReplacementNamed('/mobile-signin');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Triggering Superwall campaign: campaign_trigger');

      await Superwall.shared.registerPlacement('campaign_trigger', feature: () {
        print('✅ Superwall feature callback triggered');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main-navigation');
        }
      });

      print('✅ Superwall registerPlacement called successfully');
    } catch (e) {
      print('❌ Error triggering Superwall: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Continuing to app...')),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main-navigation');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final padding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.08,
      vertical: isSmallScreen ? 16 : 24,
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacementNamed('/thesis-details');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/thesis-details');
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AI Essay Writer',
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: isSmallScreen ? 40 : 48,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      Text(
                        'Ready to Create?',
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        'Your AI-powered academic writing assistant is ready to help you create professional content.',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (!isSmallScreen) ...[
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactFeature('🎯', 'Smart Research'),
                            _buildCompactFeature('📝', 'Professional Format'),
                            _buildCompactFeature('⚡', 'Fast Generation'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactFeature('🎯', 'Research'),
                        _buildCompactFeature('📝', 'Format'),
                        _buildCompactFeature('⚡', 'Generate'),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Start Writing',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        style: TextStyle(
                          color: const Color(0xFF64748B).withOpacity(0.7),
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFeature(String emoji, String text) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
