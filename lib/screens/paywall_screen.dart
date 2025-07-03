import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import 'dart:html' as html;

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasNavigated = false;
  String? _selectedPlan;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _checkSubscriptionStatus() {
    if (!mounted || _hasNavigated) return;

    final subscriptionStatus = ref.read(subscriptionStatusProvider);
    subscriptionStatus.when(
      data: (status) {
        if (status.isActive && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/thesis-form');
            }
          });
        }
      },
      loading: () {
        // Still loading, stay on paywall
      },
      error: (error, stack) {
        // Error loading subscription, stay on paywall
      },
    );
  }

  void _handleBackButton() {
    // Redirect to main website
    html.window.location.href = 'https://thesisgenerator.tech';
  }

  Future<void> _subscribeToPlan(String plan) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedPlan = plan;
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        if (mounted) {
          AppErrorHandler.showErrorSnackBar(
            context,
            'Please sign in first to subscribe to AI Essay Writer'
          );
          Navigator.of(context).pushReplacementNamed('/signin');
        }
        return;
      }

      final subscriptionActions = ref.read(subscriptionActionsProvider);
      
      // Use the correct method based on plan type
      String checkoutUrl;
      if (plan == 'weekly') {
        checkoutUrl = await subscriptionActions.createWeeklySubscription();
      } else if (plan == 'monthly') {
        checkoutUrl = await subscriptionActions.createMonthlySubscription();
      } else {
        throw Exception('Invalid plan type: $plan');
      }

      if (checkoutUrl.isNotEmpty) {
        // Redirect to Stripe checkout
        html.window.location.href = checkoutUrl;
      } else {
        throw Exception('Failed to create checkout session for AI Essay Writer');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorSnackBar(
          context,
          'Failed to start AI Essay Writer subscription: ${e.toString()}'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedPlan = null;
        });
      }
    }
  }

  Future<void> _checkSubscriptionComplete() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Force refresh subscription status using the actions provider
      final subscriptionActions = ref.read(subscriptionActionsProvider);
      await subscriptionActions.refreshSubscriptionStatus();
      
      // Invalidate the provider to force refresh
      ref.invalidate(subscriptionStatusProvider);
      
      // Wait a moment for the provider to refresh
      await Future.delayed(const Duration(milliseconds: 500));
      
      final subscriptionStatus = ref.read(subscriptionStatusProvider);
      await subscriptionStatus.when(
        data: (status) async {
          if (status.isActive) {
            setState(() => _hasNavigated = true);
            if (mounted) {
              AppErrorHandler.showSuccessSnackBar(
                context, 
                'Welcome to AI Essay Writer! Your subscription is now active.'
              );
              Navigator.of(context).pushReplacementNamed('/thesis-form');
            }
          } else {
            if (mounted) {
              AppErrorHandler.showErrorSnackBar(
                context,
                'Subscription not found. Please complete payment or contact support.'
              );
            }
          }
        },
        loading: () async {
          // Wait longer for loading
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            AppErrorHandler.showErrorSnackBar(
              context,
              'Still checking subscription status. Please try again in a moment.'
            );
          }
        },
        error: (error, stack) async {
          if (mounted) {
            AppErrorHandler.showErrorSnackBar(
              context,
              'Error checking subscription: ${error.toString()}'
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorSnackBar(
          context,
          'Failed to check subscription: ${e.toString()}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final user = ref.watch(authStateProvider).value;
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : 24,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          // Header with back button
                          Row(
                            children: [
                              IconButton(
                                onPressed: _handleBackButton,
                                icon: Icon(
                                  PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                                  size: 24,
                                  color: const Color(0xFF6B7280),
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (user != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFDBEAFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PhosphorIcons.user(PhosphorIconsStyle.regular),
                                        size: 16,
                                        color: const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.displayName ?? user.email?.split('@')[0] ?? 'User',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Hero section
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 800 : double.infinity,
                            ),
                            child: Column(
                              children: [
                                // Hero Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: const Color(0xFFDBEAFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PhosphorIcons.robot(PhosphorIconsStyle.regular),
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

                                // Welcome message
                                if (user != null) ...[
                                  Text(
                                    'Welcome back, ${user.displayName ?? user.email?.split('@')[0] ?? 'there'}!',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 48 : 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Choose your AI Essay Writer & Thesis Generator plan to start creating professional academic content',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 20 : 18,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4A5568),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  Text(
                                    'Thesis Generator & AI Essay Writer',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 48 : 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
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
                                ],

                                const SizedBox(height: 32),

                                // Features preview
                                Wrap(
                                  spacing: isDesktop ? 32 : 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildFeaturePreview(PhosphorIcons.robot(PhosphorIconsStyle.regular), 'AI Essay Generator'),
                                    _buildFeaturePreview(PhosphorIcons.book(PhosphorIconsStyle.regular), 'Thesis Statement Generator'),
                                    _buildFeaturePreview(PhosphorIcons.pencil(PhosphorIconsStyle.regular), 'Paper Writer AI'),
                                    _buildFeaturePreview(PhosphorIcons.lightning(PhosphorIconsStyle.regular), 'AI Write Essay Instantly'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Pricing section
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 1000 : double.infinity,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Choose Your AI Essay Writer & Thesis Generator Plan',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 36 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Professional AI essay generator and thesis statement generator with flexible pricing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF4A5568),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 48),

                                // Pricing cards
                                isDesktop
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _buildWeeklyPlan()),
                                          const SizedBox(width: 32),
                                          Expanded(child: _buildMonthlyPlan()),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildMonthlyPlan(),
                                          const SizedBox(height: 24),
                                          _buildWeeklyPlan(),
                                        ],
                                      ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Check subscription button
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 400 : double.infinity,
                            ),
                            child: SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: (_isLoading || subscriptionStatus.isLoading) 
                                    ? null 
                                    : _checkSubscriptionComplete,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: (_isLoading || subscriptionStatus.isLoading)
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2563EB),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular)),
                                label: Text(
                                  (_isLoading || subscriptionStatus.isLoading)
                                      ? 'Checking AI Essay Writer Status...'
                                      : 'I\'ve Completed Payment - Check Status',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Features showcase
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 1000 : double.infinity,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Powerful AI Essay Writer & Thesis Statement Generator Features',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 48),
                                _buildFeaturesGrid(isDesktop),
                              ],
                            ),
                          ),

                          const SizedBox(height: 64),

                          // Trust indicators
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 800 : double.infinity,
                            ),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Trusted by Students & Researchers Worldwide',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 24 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: isDesktop ? 48 : 24,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildTrustItem(PhosphorIcons.shield(PhosphorIconsStyle.regular), 'Secure AI Essay Writer'),
                                    _buildTrustItem(PhosphorIcons.lightning(PhosphorIconsStyle.regular), 'Instant AI Written Essays'),
                                    _buildTrustItem(PhosphorIcons.graduationCap(PhosphorIconsStyle.regular), 'Academic Quality Thesis Generator'),
                                    _buildTrustItem(PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.regular), '7-Day Guarantee'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '7-day money-back guarantee for AI essay writer • Cancel anytime • Secure payments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'We accept: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Icon(PhosphorIcons.creditCard(PhosphorIconsStyle.regular), size: 20, color: const Color(0xFF9CA3AF)),
                                        const SizedBox(width: 8),
                                        Icon(PhosphorIcons.bank(PhosphorIconsStyle.regular), size: 20, color: const Color(0xFF9CA3AF)),
                                        const SizedBox(width: 8),
                                        Icon(PhosphorIcons.deviceMobile(PhosphorIconsStyle.regular), size: 20, color: const Color(0xFF9CA3AF)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePreview(IconData icon, String text) {
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
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeeklyPlan() {
    final isSelected = _selectedPlan == 'weekly';
    final isLoading = _isLoading && isSelected;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly AI Essay Writer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$9.99',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '/week',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Perfect for short-term projects with our thesis generator and AI essay writer',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF4A5568),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Features
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Unlimited thesis generator access'),
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Advanced AI essay writer models (GPT-4)'),
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'All citation formats for AI written essays'),
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Priority AI essay generator processing'),
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Email support for thesis statement generator'),
              _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Export AI essay writer content to PDF & Word'),
            ],
          ),

          const SizedBox(height: 32),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _subscribeToPlan('weekly'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Choose Weekly AI Essay Writer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPlan() {
    final isSelected = _selectedPlan == 'monthly';
    final isLoading = _isLoading && isSelected;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Popular badge
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Most Popular AI Essay Writer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Plan header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Thesis Generator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$26.99',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '/month',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Best value for ongoing thesis work with our AI essay generator and paper writer AI',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

                           // Features
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Everything in Weekly AI Essay Writer'),
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Premium thesis statement generator models'),
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Advanced editing tools for AI written essays'),
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Plagiarism checker for AI essay generator content'),
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Priority support for thesis sentence generator'),
                  _buildFeatureItem(PhosphorIcons.check(PhosphorIconsStyle.regular), 'Collaboration features for paper writer AI'),
                ],
              ),

              const SizedBox(height: 32),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _subscribeToPlan('monthly'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Choose Monthly Thesis Generator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5568),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isDesktop) {
    return Column(
      children: [
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFeatureRow(PhosphorIcons.target(PhosphorIconsStyle.regular), 'Smart Thesis Statement Generator', 'Our AI essay writer automatically generates logical thesis statements and chapter outlines based on your topic using advanced artificial intelligence write essay technology.')),
                  const SizedBox(width: 32),
                  Expanded(child: _buildFeatureRow(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), 'AI Essay Writer Styles', 'Choose from Academic, Technical, or Analytical writing styles with our thesis sentence generator to match your requirements perfectly.')),
                ],
              )
            : Column(
                children: [
                  _buildFeatureRow(PhosphorIcons.target(PhosphorIconsStyle.regular), 'Smart Thesis Statement Generator', 'Our AI essay writer automatically generates logical thesis statements and chapter outlines based on your topic using advanced artificial intelligence write essay technology.'),
                  const SizedBox(height: 24),
                  _buildFeatureRow(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), 'AI Essay Writer Styles', 'Choose from Academic, Technical, or Analytical writing styles with our thesis sentence generator to match your requirements perfectly.'),
                ],
              ),
        const SizedBox(height: 24),
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFeatureRow(PhosphorIcons.quotes(PhosphorIconsStyle.regular), 'Citation Formats for AI Written Essays', 'Our paper writer AI supports APA, MLA, and Chicago citation styles for proper academic formatting in all AI essay generator content.')),
                  const SizedBox(width: 32),
                  Expanded(child: _buildFeatureRow(PhosphorIcons.lightning(PhosphorIconsStyle.regular), 'Instant AI Essay Generation', 'Generate complete thesis chapters and AI written essays in minutes with our advanced artificial intelligence writes essay technology.')),
                ],
              )
            : Column(
                children: [
                  _buildFeatureRow(PhosphorIcons.quotes(PhosphorIconsStyle.regular), 'Citation Formats for AI Written Essays', 'Our paper writer AI supports APA, MLA, and Chicago citation styles for proper academic formatting in all AI essay generator content.'),
                  const SizedBox(height: 24),
                  _buildFeatureRow(PhosphorIcons.lightning(PhosphorIconsStyle.regular), 'Instant AI Essay Generation', 'Generate complete thesis chapters and AI written essays in minutes with our advanced artificial intelligence writes essay technology.'),
                ],
              ),
        const SizedBox(height: 24),
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFeatureRow(PhosphorIcons.shield(PhosphorIconsStyle.regular), 'Privacy Focused AI Essay Writer', 'Your thesis generator and AI essay content is processed securely and never stored or shared with third parties.')),
                  const SizedBox(width: 32),
                  Expanded(child: _buildFeatureRow(PhosphorIcons.download(PhosphorIconsStyle.regular), 'Export AI Written Essays', 'Download your thesis statement generator results and AI essay writer content in multiple formats including PDF, Word, and plain text.')),
                ],
              )
            : Column(
                children: [
                  _buildFeatureRow(PhosphorIcons.shield(PhosphorIconsStyle.regular), 'Privacy Focused AI Essay Writer', 'Your thesis generator and AI essay content is processed securely and never stored or shared with third parties.'),
                  const SizedBox(height: 24),
                  _buildFeatureRow(PhosphorIcons.download(PhosphorIconsStyle.regular), 'Export AI Written Essays', 'Download your thesis statement generator results and AI essay writer content in multiple formats including PDF, Word, and plain text.'),
                ],
              ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
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
        const SizedBox(height: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

