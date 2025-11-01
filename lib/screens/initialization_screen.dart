import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  const InitializationScreen({super.key});

  @override
  ConsumerState<InitializationScreen> createState() =>
      _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _progressValue;
  late Animation<double> _fadeOpacity;
  late Animation<double> _pulseScale;

  String _currentMessage = 'Initializing AI Essay Writer...';
  String _currentTip = 'Setting up your thesis generator workspace';

  final List<String> _loadingMessages = [
    'Initializing AI Essay Writer...',
    'Checking authentication...',
    'Loading AI essay generator preferences...',
    'Verifying thesis generator subscription...',
    'Almost ready for AI written essays...'
  ];

  final List<String> _loadingTips = [
    'Setting up your thesis generator workspace',
    'Verifying your AI essay writer account',
    'Loading your AI essay generator preferences',
    'Checking thesis statement generator subscription',
    'Finalizing AI essay writer setup'
  ];

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
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
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

    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _logoController.forward();
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startInitialization() async {
    try {
      // Step 1: Initial setup
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || _hasNavigated) return;
      _updateMessage(1);

      // Step 2: Check authentication
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || _hasNavigated) return;
      final authState = ref.read(authStateProvider);

      await authState.when(
        data: (user) async {
          if (user != null) {
            // User is signed in
            _updateMessage(2);
            await Future.delayed(const Duration(milliseconds: 800));

            // Step 3: Check subscription if user is signed in
            _updateMessage(3);
            await Future.delayed(const Duration(milliseconds: 1000));

            final subscriptionState = ref.read(subscriptionStatusProvider);
            await subscriptionState.when(
              data: (status) async {
                _updateMessage(4);
                await Future.delayed(const Duration(milliseconds: 800));

                if (!mounted || _hasNavigated) return;

                _hasNavigated = true;
                if (status.isActive) {
                  await _navigateToScreen('/thesis-form');
                } else {
                  await _navigateToScreen('/paywall');
                }
              },
              loading: () async {
                // Wait a bit more for subscription to load
                await Future.delayed(const Duration(milliseconds: 1500));

                if (!mounted || _hasNavigated) return;

                final isSubscribed = ref.read(isSubscribedProvider);
                _updateMessage(4);
                await Future.delayed(const Duration(milliseconds: 500));

                _hasNavigated = true;
                if (isSubscribed) {
                  await _navigateToScreen('/thesis-form');
                } else {
                  await _navigateToScreen('/paywall');
                }
              },
              error: (error, stack) async {
                if (!mounted || _hasNavigated) return;

                _hasNavigated = true;
                // On subscription error, go to paywall to retry
                await _navigateToScreen('/paywall');
              },
            );
          } else {
            // User not signed in
            _updateMessage(2);
            await Future.delayed(const Duration(milliseconds: 800));

            _updateMessage(4);
            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted || _hasNavigated) return;

            _hasNavigated = true;
            await _navigateToScreen('/signin');
          }
        },
        loading: () async {
          // Wait for auth to load
          await Future.delayed(const Duration(milliseconds: 2000));

          if (!mounted || _hasNavigated) return;

          // If still loading after timeout, go to signin
          _hasNavigated = true;
          await _navigateToScreen('/signin');
        },
        error: (error, stack) async {
          if (!mounted || _hasNavigated) return;

          _hasNavigated = true;
          await _navigateToScreen('/signin');
        },
      );
    } catch (e) {
      print('❌ Initialization error: $e');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        if (context.mounted) {
          // Use a simpler error display
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Initialization failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _navigateToScreen('/signin');
      }
    }
  }

  void _updateMessage(int index) {
    if (mounted && index < _loadingMessages.length && !_hasNavigated) {
      setState(() {
        _currentMessage = _loadingMessages[index];
        _currentTip = _loadingTips[index];
      });
    }
  }

  Future<void> _navigateToScreen(String route) async {
    await _fadeController.forward();

    if (mounted && context.mounted) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOpacity.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 600 : screenWidth * 0.9,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(50),
                              border:
                                  Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.robot(
                                      PhosphorIconsStyle.regular),
                                  size: 16,
                                  color: const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI Essay Writer Powered',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Logo with animation
                          AnimatedBuilder(
                            animation: _logoScale,
                            builder: (context, child) {
                              return AnimatedBuilder(
                                animation: _pulseScale,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _logoScale.value * _pulseScale.value,
                                    child: Container(
                                      width: isDesktop ? 120 : 100,
                                      height: isDesktop ? 120 : 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB)
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF2563EB),
                                                Color(0xFF1D4ED8)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Icon(
                                            PhosphorIcons.graduationCap(
                                                PhosphorIconsStyle.regular),
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Brand title
                          Text(
                            'Thesis Generator & AI Essay Writer',
                            style: TextStyle(
                              fontSize: isDesktop ? 42 : 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Brand subtitle
                          Text(
                            'Generate complete, professionally written theses and AI-generated essays in minutes with our advanced thesis generator and AI essay writer technology.',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 18,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4A5568),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 48),

                          // Features preview
                          Wrap(
                            spacing: isDesktop ? 32 : 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeatureItem(
                                  PhosphorIcons.robot(
                                      PhosphorIconsStyle.regular),
                                  'AI Essay Generator'),
                              _buildFeatureItem(
                                  PhosphorIcons.book(
                                      PhosphorIconsStyle.regular),
                                  'Thesis Statement Generator'),
                              _buildFeatureItem(
                                  PhosphorIcons.pencil(
                                      PhosphorIconsStyle.regular),
                                  'Paper Writer AI'),
                              _buildFeatureItem(
                                  PhosphorIcons.lightning(
                                      PhosphorIconsStyle.regular),
                                  'AI Write Essay Instantly'),
                            ],
                          ),

                          const SizedBox(height: 64),

                          // Professional loading indicator
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Spinning indicator
                                const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2563EB)),
                                  ),
                                ),
                                // Center icon
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Loading text with animation
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _currentMessage,
                              key: ValueKey(_currentMessage),
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Progress bar
                          Container(
                            width: isDesktop ? 320 : 280,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
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
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF1D4ED8)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Loading tip
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _currentTip,
                              key: ValueKey(_currentTip),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Trust indicators
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Wrap(
                              spacing: isDesktop ? 32 : 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildTrustItem(
                                    PhosphorIcons.shield(
                                        PhosphorIconsStyle.regular),
                                    'Secure AI Essay Writer'),
                                _buildTrustItem(
                                    PhosphorIcons.lightning(
                                        PhosphorIconsStyle.regular),
                                    'Instant AI Written Essays'),
                                _buildTrustItem(
                                    PhosphorIcons.graduationCap(
                                        PhosphorIconsStyle.regular),
                                    'Academic Quality'),
                                _buildTrustItem(
                                    PhosphorIcons.checkCircle(
                                        PhosphorIconsStyle.regular),
                                    '7-Day Guarantee'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
