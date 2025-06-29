import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/signin_screen.dart';
import '../screens/paywall_screen.dart';
import '../app.dart';

class ProtectedRoute extends ConsumerStatefulWidget {
  final Widget child;
  final bool requiresSubscription;
  final String? routeName;
  final bool showLoadingScreen;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.requiresSubscription = true,
    this.routeName,
    this.showLoadingScreen = true,
  });

  @override
  ConsumerState<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends ConsumerState<ProtectedRoute> {
  bool _hasNavigated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndSubscription();
    });
  }

  Future<void> _checkAuthAndSubscription() async {
    if (!mounted || _hasNavigated) return;

    try {
      // Small delay to allow providers to initialize
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;

      setState(() => _isCheckingAuth = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  void _navigateToSignIn() {
    if (_hasNavigated || !mounted) return;
    
    setState(() => _hasNavigated = true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    });
  }

  void _navigateToPaywall() {
    if (_hasNavigated || !mounted) return;
    
    setState(() => _hasNavigated = true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/paywall');
      }
    });
  }

  Widget _buildLoadingScreen({String? message, String? userInfo}) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF9D4EDD),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Loading...',
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            if (userInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                userInfo,
                style: AppTheme.captionStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen({
    required String title,
    required String message,
    required VoidCallback onRetry,
    Color iconColor = Colors.red,
    IconData icon = Icons.error_outline,
  }) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: AppTheme.primaryButtonStyle,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSyncError(User user, String subscriptionUserId) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Account Sync Issue',
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'There\'s a mismatch between your account and subscription data. Please sign out and sign back in to resolve this issue.',
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: AppTheme.captionStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auth User ID: ${user.uid}',
                      style: AppTheme.captionStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      'Subscription User ID: $subscriptionUserId',
                      style: AppTheme.captionStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final authService = ref.read(authServiceProvider);
                    final subscriptionService = ref.read(subscriptionServiceProvider);

                    await subscriptionService.handleSignOut();
                    await authService.signOut();

                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/signin');
                    }
                  } catch (e) {
                    if (mounted) {
                      AppErrorHandler.showErrorSnackBar(
                        context, 
                        'Sign out failed: ${e.toString()}'
                      );
                    }
                  }
                },
                style: AppTheme.primaryButtonStyle,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out & Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If still checking initial auth state, show loading
    if (_isCheckingAuth && widget.showLoadingScreen) {
      return _buildLoadingScreen(message: 'Initializing...');
    }

    final authState = ref.watch(authStateProvider);
    final subscriptionState = ref.watch(subscriptionStatusProvider);

    return authState.when(
      loading: () {
        if (!widget.showLoadingScreen) return widget.child;
        return _buildLoadingScreen(message: 'Authenticating...');
      },
      error: (error, stack) {
        return _buildErrorScreen(
          title: 'Authentication Error',
          message: 'Failed to authenticate: ${error.toString()}',
          onRetry: () => _navigateToSignIn(),
          iconColor: Colors.red,
        );
      },
      data: (user) {
        // User not signed in
        if (user == null) {
          _navigateToSignIn();
          return _buildLoadingScreen(message: 'Redirecting to sign in...');
        }

        // User is signed in, check subscription if required
        if (widget.requiresSubscription) {
          // Show loading while checking subscription
          if (subscriptionState.isLoading) {
            return _buildLoadingScreen(
              message: 'Checking subscription status...',
              userInfo: 'User: ${user.email ?? user.uid}',
            );
          }

          // Subscription error
          if (subscriptionState.error != null) {
            return _buildErrorScreen(
              title: 'Subscription Error',
              message: 'Failed to verify subscription: ${subscriptionState.error}',
              onRetry: () async {
                try {
                  final subscriptionService = ref.read(subscriptionServiceProvider);
                  await subscriptionService.refreshSubscriptionStatus();
                } catch (e) {
                  if (mounted) {
                    AppErrorHandler.showErrorSnackBar(
                      context, 
                      'Refresh failed: ${e.toString()}'
                    );
                  }
                }
              },
              iconColor: Colors.orange,
              icon: Icons.subscriptions,
            );
          }

          // Check for user ID mismatch (security check)
          if (subscriptionState.userId != null && 
              subscriptionState.userId != user.uid) {
            return _buildAccountSyncError(user, subscriptionState.userId!);
          }

          // User doesn't have active subscription
          if (!subscriptionState.isActive) {
            _navigateToPaywall();
            return _buildLoadingScreen(message: 'Redirecting to subscription...');
          }
        }

        // All checks passed - show protected content
        return widget.child;
      },
    );
  }
}

// Specialized protected routes for common use cases
class AuthProtectedRoute extends ProtectedRoute {
  const AuthProtectedRoute({
    super.key,
    required super.child,
    super.routeName,
    super.showLoadingScreen = true,
  }) : super(requiresSubscription: false);
}

class SubscriptionProtectedRoute extends ProtectedRoute {
  const SubscriptionProtectedRoute({
    super.key,
    required super.child,
    super.routeName,
    super.showLoadingScreen = true,
  }) : super(requiresSubscription: true);
}

// Route guard mixin for screens that need protection
mixin RouteGuardMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool get requiresAuth => true;
  bool get requiresSubscription => false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }

  void _checkAccess() {
    if (!mounted) return;

    if (requiresAuth) {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/signin');
        return;
      }
    }

    if (requiresSubscription) {
      final isSubscribed = ref.read(isSubscribedProvider);
      if (!isSubscribed) {
        Navigator.of(context).pushReplacementNamed('/paywall');
        return;
      }
    }
  }
}

// Utility class for route protection
class RouteProtection {
  static bool isUserAuthenticated(WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    return user != null;
  }

  static bool isUserSubscribed(WidgetRef ref) {
    return ref.read(isSubscribedProvider);
  }

  static bool hasFullAccess(WidgetRef ref) {
    return isUserAuthenticated(ref) && isUserSubscribed(ref);
  }

  static void navigateToAppropriateScreen(BuildContext context, WidgetRef ref) {
    if (!isUserAuthenticated(ref)) {
      Navigator.of(context).pushReplacementNamed('/signin');
    } else if (!isUserSubscribed(ref)) {
      Navigator.of(context).pushReplacementNamed('/paywall');
    } else {
      Navigator.of(context).pushReplacementNamed('/thesis-form');
    }
  }

  static Widget buildAccessDeniedScreen({
    required String title,
    required String message,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF9D4EDD),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: AppTheme.primaryButtonStyle,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
