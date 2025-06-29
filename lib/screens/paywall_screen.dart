import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }

  void _checkSubscriptionStatus() {
    if (!mounted || _hasNavigated) return;
    
    final isSubscribed = ref.read(isSubscribedProvider);
    if (isSubscribed) {
      setState(() => _hasNavigated = true);
      Navigator.of(context).pushReplacementNamed('/thesis-form');
    }
  }

  Future<void> _startThesis() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);

      final subscriptionService = ref.read(subscriptionServiceProvider);
      final subscriptionUrl = subscriptionService.getSubscriptionUrl();

      if (await canLaunchUrl(Uri.parse(subscriptionUrl))) {
        await launchUrl(
          Uri.parse(subscriptionUrl),
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          _showSubscriptionInstructions();
        }
      } else {
        throw 'Could not launch subscription page';
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorSnackBar(context, 'Failed to open subscription page');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSubscriptionInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Complete Your Subscription',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'After completing your subscription, return to this tab and click "Check Status" to continue.',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF667eea),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSubscriptionComplete() async {
    if (_isLoading || _hasNavigated) return;
    
    try {
      setState(() => _isLoading = true);

      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.refreshSubscriptionStatus();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final isSubscribed = ref.read(isSubscribedProvider);
      
      if (isSubscribed) {
        setState(() => _hasNavigated = true);
        Navigator.of(context).pushReplacementNamed('/thesis-form');
        AppErrorHandler.showSuccessSnackBar(context, 'Welcome! Your subscription is now active.');
      } else {
        AppErrorHandler.showInfoSnackBar(context, 'No active subscription found. Please complete your purchase first.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorSnackBar(context, 'Failed to check subscription status: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final subscriptionState = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI Thesis Generator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1a1a1a),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF6C757D),
            ),
            tooltip: 'Sign Out',
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              final subscriptionService = ref.read(subscriptionServiceProvider);

              await subscriptionService.handleSignOut();
              await authService.signOut();

              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/signin');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Welcome, ${user?.displayName ?? user?.email?.split('@').first ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to create your masterpiece?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Main hero section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    // Title
                    const Text(
                      'AI Thesis Generator',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Slogan
                    const Text(
                      'Transform Your Research into a Masterpiece with AI-Powered Precision!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Start button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _startThesis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF667eea),
                                                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Start Your Thesis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Subscription status card
              if (subscriptionState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEB2B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error: ${subscriptionState.error}',
                          style: const TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Features showcase
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Powerful Features for Academic Excellence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.1,
                      children: [
                        _buildFeatureCard(
                          '🤖',
                          'AI-Powered Writing',
                          'Advanced algorithms generate high-quality academic content',
                        ),
                        _buildFeatureCard(
                          '📚',
                          'Citation Formats',
                          'APA, MLA, Chicago styles with perfect formatting',
                        ),
                        _buildFeatureCard(
                          '⚡',
                          'Lightning Fast',
                          'Generate complete chapters in minutes, not days',
                        ),
                        _buildFeatureCard(
                          '🎯',
                          'Smart Structure',
                          'Logical flow and academic organization built-in',
                        ),
                        _buildFeatureCard(
                          '🔒',
                          'Privacy Protected',
                          'Your research stays confidential and secure',
                        ),
                        _buildFeatureCard(
                          '📱',
                          '24/7 Support',
                          'Expert assistance whenever you need help',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Check status button (secondary action)
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || subscriptionState.isLoading) ? null : _checkSubscriptionComplete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF667eea),
                      side: const BorderSide(color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: (_isLoading || subscriptionState.isLoading)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF667eea),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      (_isLoading || subscriptionState.isLoading) ? 'Checking...' : 'Check Status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Trust indicators
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Trusted by Students Worldwide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTrustItem('🔒', 'Secure'),
                        _buildTrustItem('⚡', 'Instant'),
                        _buildTrustItem('🎓', 'Academic'),
                        _buildTrustItem('🛡️', 'Guaranteed'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Testimonial
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '"This AI thesis generator saved me weeks of work! The quality is outstanding and the citations are perfect."',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1a1a1a),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '— Sarah M., PhD Student',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Terms and privacy
              Text(
                'By using our service, you agree to our Terms of Service and Privacy Policy. Your academic integrity is our priority.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

