import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/subscription_provider.dart';

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
      if (mounted && context.mounted) {
        // Route to mobile signin screen
        Navigator.of(context).pushReplacementNamed('/mobile-signin');
      }
    });
  }

  Widget _buildLoadingScreen({String? message, String? userInfo}) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    ),
                  ),
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
            Text(
              message ?? 'Loading...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a1a),
              ),
              textAlign: TextAlign.center,
            ),
            if (userInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                userInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
      backgroundColor: Colors.white,
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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

    // Use mobile auth provider (Superwall handles subscription)
    final authState = ref.watch(mobileAuthStateProvider);

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

        // User is signed in, subscription handled by Superwall - show content
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
      final user = ref.read(mobileCurrentUserProvider);
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/mobile-signin');
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
    final user = ref.read(mobileCurrentUserProvider);
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
      Navigator.of(context).pushReplacementNamed('/mobile-signin');
    } else if (!isUserSubscribed(ref)) {
      // Superwall handles subscription
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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF667eea),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
