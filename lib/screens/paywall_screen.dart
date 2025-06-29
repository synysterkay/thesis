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

  Future<void> _openSubscriptionPage() async {
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Complete Your Subscription',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: const Text(
          'After completing your subscription, return to this tab and click "Check Subscription Status" to continue.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(fontSize: 16),
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

      // Refresh subscription status from Superwall
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.refreshSubscriptionStatus();

      // Wait a moment for the state to update
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Subscription Required',
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome message
                Text(
                  'Welcome, ${user?.displayName ?? user?.email?.split('@').first ?? 'User'}!',
                  style: AppTheme.headingStyle.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Subscription status card
                if (subscriptionState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error: ${subscriptionState.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Premium unlock message
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Logo with rounded corners
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9D4EDD).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if image fails to load
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Unlock Premium Features',
                        style: AppTheme.subheadingStyle.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Subscribe to access unlimited thesis generation, advanced AI features, and premium templates.',
                        style: AppTheme.bodyStyle.copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _openSubscriptionPage,
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(const Color(0xFF9D4EDD)),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.launch, size: 20),
                        label: Text(
                          _isLoading ? 'Opening...' : 'Subscribe Now',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: (_isLoading || subscriptionState.isLoading) ? null : _checkSubscriptionComplete,
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        icon: (_isLoading || subscriptionState.isLoading)
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF9D4EDD),
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.refresh, size: 20),
                        label: Text(
                          (_isLoading || subscriptionState.isLoading) ? 'Checking...' : 'Check Subscription Status',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Features grid
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Features:',
                        style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildFeatureCard('✨', 'Unlimited Generation', 'Create as many thesis as you need'),
                          _buildFeatureCard('🤖', 'Advanced AI', 'Premium writing assistance'),
                          _buildFeatureCard('📚', 'Premium Templates', 'Professional academic formats'),
                          _buildFeatureCard('📊', 'Citation Management', 'Automatic reference handling'),
                          _buildFeatureCard('💾', 'Cloud Storage', 'Save and sync your work'),
                          _buildFeatureCard('📱', 'Priority Support', '24/7 customer assistance'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Terms and privacy
                Text(
                  'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription will auto-renew unless cancelled.',
                  style: AppTheme.captionStyle.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String description) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTheme.captionStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
