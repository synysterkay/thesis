import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../app.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  const InitializationScreen({super.key});

  @override
  ConsumerState<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScale;
  late Animation<double> _progressValue;
  late Animation<double> _fadeOpacity;

  String _currentMessage = 'Initializing...';
  String _currentTip = 'Setting up your workspace';
  
  final List<String> _loadingMessages = [
    'Initializing...',
    'Checking authentication...',
    'Loading preferences...',
    'Setting up services...',
    'Almost ready...'
  ];

  final List<String> _loadingTips = [
    'Setting up your workspace',
    'Verifying your account',
    'Loading your preferences',
    'Preparing AI tools',
    'Finalizing setup'
  ];

  int _messageIndex = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _fadeOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _logoController.forward();
    _progressController.forward();
  }

  void _startInitialization() async {
    try {
      // Simulate initialization steps with proper timing
      await Future.delayed(const Duration(milliseconds: 500));
      _updateMessage(1);
      
      // Check authentication
      await Future.delayed(const Duration(milliseconds: 800));
      final user = ref.read(currentUserProvider);
      
      _updateMessage(2);
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (user != null) {
        // User is signed in, check subscription
        _updateMessage(3);
        await Future.delayed(const Duration(milliseconds: 700));
        
        final subscriptionService = ref.read(subscriptionServiceProvider);
        await subscriptionService.handleSignIn(user);
        
        _updateMessage(4);
        await Future.delayed(const Duration(milliseconds: 500));
        
        final isSubscribed = ref.read(isSubscribedProvider);
        
        if (!mounted || _hasNavigated) return;
        
        _hasNavigated = true;
        await _navigateToScreen(isSubscribed ? '/thesis-form' : '/paywall');
      } else {
        // User not signed in
        _updateMessage(4);
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted || _hasNavigated) return;
        
        _hasNavigated = true;
        await _navigateToScreen('/signin');
      }
    } catch (e) {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        AppErrorHandler.showErrorSnackBar(context, 'Initialization failed: ${e.toString()}');
        await _navigateToScreen('/signin');
      }
    }
  }

  void _updateMessage(int index) {
    if (mounted && index < _loadingMessages.length) {
      setState(() {
        _messageIndex = index;
        _currentMessage = _loadingMessages[index];
        _currentTip = _loadingTips[index];
      });
    }
  }

  Future<void> _navigateToScreen(String route) async {
    await _fadeController.forward();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOpacity.value,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animation
                    AnimatedBuilder(
                      animation: _logoScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to gradient container with icon if image fails
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Brand title
                    const Text(
                      'Thesis Generator',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Brand subtitle
                    Text(
                      'AI-Powered Academic Writing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Professional loading indicator
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spinning indicator
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                            ),
                          ),
                          // Center icon
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading text with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _currentMessage,
                        key: ValueKey(_currentMessage),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1a1a),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress bar
                    Container(
                      width: 280,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressValue,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressValue.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Loading tip
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _currentTip,
                        key: ValueKey(_currentTip),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Feature chips
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildFeatureChip('🤖 AI Powered', 0),
                          _buildFeatureChip('📚 Citations', 1),
                          _buildFeatureChip('⚡ Fast', 2),
                          _buildFeatureChip('🔒 Secure', 3),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final animationValue = (_logoController.value + delay) % 1.0;
                            final opacity = 0.3 + (0.7 * (1 - (animationValue - 0.5).abs() * 2));
                            
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF667eea).withOpacity(opacity.clamp(0.0, 1.0)),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureChip(String text, int index) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final delay = index * 0.3;
        final animationValue = (_logoController.value + delay) % 1.0;
        final translateY = 3 * (1 - (animationValue - 0.5).abs() * 2);
        
        return Transform.translate(
          offset: Offset(0, -translateY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      },
    );
  }
}
