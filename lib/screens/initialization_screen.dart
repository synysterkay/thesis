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
  late Animation<double> _logoRotation;
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

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
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
    // Start message rotation
    _rotateMessages();
    
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

  void _rotateMessages() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !_hasNavigated) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
          _currentMessage = _loadingMessages[_messageIndex];
          _currentTip = _loadingTips[_messageIndex];
        });
        _rotateMessages();
      }
    });
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
      body: AnimatedBuilder(
        animation: _fadeOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOpacity.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animation
                    AnimatedBuilder(
                      animation: _logoScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9D4EDD),
                                    Color(0xFFFF48B0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF9D4EDD).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school,
                                size: 60,
                                color: Colors.white,
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
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Brand subtitle
                    const Text(
                      'AI-Powered Academic Writing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Animated spinner
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 30),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                            ),
                          ),
                          // Spinning indicator
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          // Pulsing center dot
                          AnimatedBuilder(
                            animation: _logoController,
                            builder: (context, child) {
                              return Container(
                                width: 8 + (4 * _logoRotation.value),
                                height: 8 + (4 * _logoRotation.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              );
                            },
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
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress bar
                    Container(
                      width: 250,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
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
                                  colors: [Colors.white, Color(0xFFF0F0F0)],
                                ),
                                borderRadius: BorderRadius.circular(2),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Feature chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureChip('🤖 AI Powered', 0),
                        _buildFeatureChip('📚 Citations', 1),
                        _buildFeatureChip('⚡ Fast', 2),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Loading dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final animationValue = (_logoRotation.value + delay) % 1.0;
                            final opacity = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));
                            final scale = 1.0 + (0.2 * (1 - (animationValue - 0.5).abs() * 2));
                            
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
                              ),
                              transform: Matrix4.identity()..scale(scale),
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
        final animationValue = (_logoRotation.value + delay) % 1.0;
        final translateY = 5 * (1 - (animationValue - 0.5).abs() * 2);
        
        return Transform.translate(
          offset: Offset(0, -translateY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Initialization state management
class InitializationState {
  final String message;
  final String tip;
  final double progress;
  final bool isComplete;
  final String? error;
  
  const InitializationState({
    required this.message,
    required this.tip,
    required this.progress,
    this.isComplete = false,
    this.error,
  });
  
  InitializationState copyWith({
    String? message,
    String? tip,
    double? progress,
    bool? isComplete,
    String? error,
  }) {
    return InitializationState(
      message: message ?? this.message,
      tip: tip ?? this.tip,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

// Initialization steps enum
enum InitializationStep {
  starting,
  checkingAuth,
  loadingPreferences,
  settingUpServices,
  finalizing,
  complete,
  error,
}

// Extension for initialization step descriptions
extension InitializationStepExtension on InitializationStep {
  String get message {
    switch (this) {
      case InitializationStep.starting:
        return 'Initializing...';
      case InitializationStep.checkingAuth:
        return 'Checking authentication...';
      case InitializationStep.loadingPreferences:
        return 'Loading preferences...';
      case InitializationStep.settingUpServices:
        return 'Setting up services...';
      case InitializationStep.finalizing:
        return 'Almost ready...';
      case InitializationStep.complete:
        return 'Ready!';
      case InitializationStep.error:
        return 'Something went wrong';
    }
  }
  
  String get tip {
    switch (this) {
      case InitializationStep.starting:
        return 'Setting up your workspace';
      case InitializationStep.checkingAuth:
        return 'Verifying your account';
      case InitializationStep.loadingPreferences:
        return 'Loading your preferences';
      case InitializationStep.settingUpServices:
        return 'Preparing AI tools';
      case InitializationStep.finalizing:
        return 'Finalizing setup';
      case InitializationStep.complete:
        return 'Welcome to Thesis Generator!';
      case InitializationStep.error:
        return 'Please try again';
    }
  }
  
  double get progress {
    switch (this) {
      case InitializationStep.starting:
        return 0.1;
      case InitializationStep.checkingAuth:
        return 0.3;
      case InitializationStep.loadingPreferences:
        return 0.5;
      case InitializationStep.settingUpServices:
        return 0.7;
      case InitializationStep.finalizing:
        return 0.9;
      case InitializationStep.complete:
        return 1.0;
      case InitializationStep.error:
        return 0.0;
    }
  }
}

