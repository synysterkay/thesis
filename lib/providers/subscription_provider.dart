import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// Simplified subscription status enum
enum SubscriptionStatus {
  unknown,
  active,
  inactive,
  expired,
  cancelled,
}

// Subscription state class
class SubscriptionState {
  final SubscriptionStatus status;
  final bool isActive;
  final bool isLoading;
  final String? error;
  final DateTime? lastChecked;
  final Map<String, dynamic>? subscriptionInfo;
  final String? userId;

  const SubscriptionState({
    this.status = SubscriptionStatus.unknown,
    this.isActive = false,
    this.isLoading = false,
    this.error,
    this.lastChecked,
    this.subscriptionInfo,
    this.userId,
  });

   SubscriptionState copyWith({
    SubscriptionStatus? status,
    bool? isActive,
    bool? isLoading,
    String? error,
    DateTime? lastChecked,
    Map<String, dynamic>? subscriptionInfo,
    String? userId,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastChecked: lastChecked ?? this.lastChecked,
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'SubscriptionState(userId: $userId, status: $status, isActive: $isActive, isLoading: $isLoading, error: $error)';
  }
}

// Subscription status notifier
class SubscriptionStatusNotifier extends StateNotifier<SubscriptionState> {
  final AuthService _authService;
  bool _disposed = false;

  SubscriptionStatusNotifier(this._authService) : super(const SubscriptionState(isLoading: true)) {
    _initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_disposed) return;
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _loadCachedSubscriptionStatus(currentUser.uid);
      } else {
        if (!_disposed) {
          state = const SubscriptionState(isLoading: false);
        }
      }

      // Listen to auth state changes
      _authService.authStateChanges.listen((user) {
        if (!_disposed) {
          _handleAuthStateChange(user);
        }
      });
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Initialization failed: ${e.toString()}',
        );
      }
    }
  }

  // Handle auth state changes
  void _handleAuthStateChange(User? user) async {
    if (_disposed) return;
    
    try {
      if (user == null) {
        // User signed out - clear subscription data
        state = const SubscriptionState(isLoading: false);
        await _clearCachedSubscriptionStatus();
      } else {
        // User signed in - load their subscription status
        state = state.copyWith(isLoading: true, userId: user.uid);
        await _loadCachedSubscriptionStatus(user.uid);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Auth state change error: ${e.toString()}',
        );
      }
    }
  }

  // Load cached subscription status from SharedPreferences (per user)
  Future<void> _loadCachedSubscriptionStatus(String userId) async {
    if (_disposed) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStatus = prefs.getString('subscription_status_$userId');
      final cachedIsActive = prefs.getBool('subscription_is_active_$userId') ?? false;
      final cachedLastChecked = prefs.getString('subscription_last_checked_$userId');

      if (!_disposed) {
        if (cachedStatus != null) {
          final status = _parseSubscriptionStatus(cachedStatus);
          final lastChecked = cachedLastChecked != null
              ? DateTime.tryParse(cachedLastChecked)
              : null;

          state = state.copyWith(
            status: status,
            isActive: cachedIsActive,
            isLoading: false,
            lastChecked: lastChecked,
            userId: userId,
            error: null,
          );
        } else {
          // No cached data, set default inactive state
          state = state.copyWith(
            status: SubscriptionStatus.inactive,
            isActive: false,
            isLoading: false,
            userId: userId,
            error: null,
          );
        }
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          status: SubscriptionStatus.inactive,
          isActive: false,
          isLoading: false,
          userId: userId,
          error: 'Failed to load cached status: ${e.toString()}',
        );
      }
    }
  }

  // Save subscription status to SharedPreferences (per user)
  Future<void> _saveSubscriptionStatus() async {
    if (_disposed || state.userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_status_${state.userId}', state.status.toString());
      await prefs.setBool('subscription_is_active_${state.userId}', state.isActive);
      await prefs.setString('subscription_last_checked_${state.userId}', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently handle save errors
    }
  }

  // Clear cached subscription status
  Future<void> _clearCachedSubscriptionStatus() async {
    if (_disposed) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('subscription_'));

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Silently handle clear errors
    }
  }

  // Refresh subscription status from Superwall
  Future<void> refreshSubscriptionStatus() async {
    if (_disposed) return;
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    if (!_disposed) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Check subscription status with Superwall
      final isSubscribed = await _checkSuperwallSubscription(currentUser.uid);
      
      if (!_disposed) {
        final newStatus = isSubscribed ? SubscriptionStatus.active : SubscriptionStatus.inactive;
        
        state = state.copyWith(
          status: newStatus,
          isActive: isSubscribed,
          isLoading: false,
          lastChecked: DateTime.now(),
          error: null,
        );

        await _saveSubscriptionStatus();
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to refresh subscription: ${e.toString()}',
        );
      }
    }
  }

  // Check subscription with Superwall API
  Future<bool> _checkSuperwallSubscription(String userId) async {
    try {
      // TODO: Replace with actual Superwall API endpoint
      final response = await http.get(
        Uri.parse('https://api.superwall.com/v1/subscription/status'),
        headers: {
          'Authorization': 'pk_gW6qbHLvmI-CGjwQTvwXZ',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_subscribed'] ?? false;
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, return false if API check fails
      // In production, you might want to handle this differently
      return false;
    }
  }

  // Manually activate subscription (called when user returns from successful payment)
  void activateSubscription() {
    if (_disposed) return;
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    state = state.copyWith(
      status: SubscriptionStatus.active,
      isActive: true,
      lastChecked: DateTime.now(),
      error: null,
      userId: currentUser.uid,
    );

    _saveSubscriptionStatus();
  }

  // Manually deactivate subscription
  void deactivateSubscription() {
    if (_disposed) return;
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    state = state.copyWith(
      status: SubscriptionStatus.inactive,
      isActive: false,
      lastChecked: DateTime.now(),
      error: null,
      userId: currentUser.uid,
    );

    _saveSubscriptionStatus();
  }

  // Update subscription status manually
  void updateSubscriptionStatus(SubscriptionStatus status) {
    if (_disposed) return;
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final isActive = status == SubscriptionStatus.active;

    state = state.copyWith(
      status: status,
      isActive: isActive,
      lastChecked: DateTime.now(),
      error: null,
      userId: currentUser.uid,
    );

    _saveSubscriptionStatus();
  }

  // Clear subscription data (for sign out)
  Future<void> clearSubscriptionData() async {
    if (_disposed) return;
    
    try {
      await _clearCachedSubscriptionStatus();
      state = const SubscriptionState();
    } catch (e) {
      // Silently handle errors
    }
  }

  // Parse subscription status from string
  SubscriptionStatus _parseSubscriptionStatus(String statusString) {
    switch (statusString) {
      case 'SubscriptionStatus.active':
        return SubscriptionStatus.active;
      case 'SubscriptionStatus.inactive':
        return SubscriptionStatus.inactive;
      case 'SubscriptionStatus.expired':
        return SubscriptionStatus.expired;
      case 'SubscriptionStatus.cancelled':
        return SubscriptionStatus.cancelled;
      case 'SubscriptionStatus.unknown':
      default:
        return SubscriptionStatus.unknown;
    }
  }
}

// Subscription status provider - now with AuthService dependency
final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusNotifier, SubscriptionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SubscriptionStatusNotifier(authService);
});

// Is subscribed provider
final isSubscribedProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionStatusProvider);
  return subscriptionState.isActive;
});

// Subscription loading provider
final isSubscriptionLoadingProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionStatusProvider);
  return subscriptionState.isLoading;
});

// Subscription error provider
final subscriptionErrorProvider = Provider<String?>((ref) {
  final subscriptionState = ref.watch(subscriptionStatusProvider);
  return subscriptionState.error;
});

// Subscription info provider
final subscriptionInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final subscriptionState = ref.watch(subscriptionStatusProvider);
  return subscriptionState.subscriptionInfo;
});

// Current subscription user ID provider
final subscriptionUserIdProvider = Provider<String?>((ref) {
  final subscriptionState = ref.watch(subscriptionStatusProvider);
  return subscriptionState.userId;
});

// Combined auth and subscription provider
final userAccessProvider = Provider<UserAccessState>((ref) {
  final authState = ref.watch(authStateProvider);
  final subscriptionState = ref.watch(subscriptionStatusProvider);

  return authState.when(
    loading: () => const UserAccessState(isLoading: true),
    error: (error, stack) => UserAccessState(
      isLoading: false,
      error: error.toString(),
    ),
    data: (user) {
      if (user == null) {
        return const UserAccessState(
          isLoading: false,
          isSignedIn: false,
        );
      }

      return UserAccessState(
        isLoading: subscriptionState.isLoading,
        isSignedIn: true,
        isSubscribed: subscriptionState.isActive,
        user: user,
        subscriptionStatus: subscriptionState.status,
        subscriptionUserId: subscriptionState.userId,
        error: subscriptionState.error,
      );
    },
  );
});

// User access state class
class UserAccessState {
  final bool isLoading;
  final bool isSignedIn;
  final bool isSubscribed;
  final User? user;
  final SubscriptionStatus? subscriptionStatus;
  final String? subscriptionUserId;
  final String? error;

  const UserAccessState({
    this.isLoading = false,
    this.isSignedIn = false,
    this.isSubscribed = false,
    this.user,
    this.subscriptionStatus,
    this.subscriptionUserId,
    this.error,
  });

  bool get hasFullAccess => isSignedIn && isSubscribed;
  bool get needsSignIn => !isSignedIn;
  bool get needsSubscription => isSignedIn && !isSubscribed;
  bool get userIdsMatch => user?.uid == subscriptionUserId;

  @override
  String toString() {
    return 'UserAccessState(isLoading: $isLoading, isSignedIn: $isSignedIn, isSubscribed: $isSubscribed, hasFullAccess: $hasFullAccess, userIdsMatch: $userIdsMatch)';
  }
}

// Subscription service provider for additional functionality
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SubscriptionService(ref, authService);
});

// Subscription service class
class SubscriptionService {
  final Ref _ref;
  final AuthService _authService;

  // Superwall subscription URL
  static const String subscriptionUrl = 'https://thesisgenerator.superwall.app/sub_campaign';

  SubscriptionService(this._ref, this._authService);

  // Get subscription URL with user context
  String getSubscriptionUrl() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      // Add user context to URL if needed
      final baseUrl = subscriptionUrl;
      final userId = currentUser.uid;
      final email = currentUser.email ?? '';

      // You can add query parameters if your Superwall campaign supports them
      return '$baseUrl?user_id=$userId&email=${Uri.encodeComponent(email)}';
    }
    return subscriptionUrl;
  }

  // Handle successful subscription (called when user returns from payment)
  void handleSuccessfulSubscription() {
    try {
      _ref.read(subscriptionStatusProvider.notifier).activateSubscription();
    } catch (e) {
      // Handle error silently
    }
  }

  // Handle user sign out
  Future<void> handleSignOut() async {
    try {
      // Clear subscription data
      await _ref.read(subscriptionStatusProvider.notifier).clearSubscriptionData();
    } catch (e) {
      // Handle error silently
    }
  }

  // Handle user sign in
  Future<void> handleSignIn(User user) async {
    try {
      // The subscription status will be automatically loaded by the notifier
      // when it detects the auth state change
      
      // Wait a bit for the subscription status to be loaded
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      // Handle error silently
    }
  }

  // Refresh subscription status from Superwall
  Future<void> refreshSubscriptionStatus() async {
    try {
      await _ref.read(subscriptionStatusProvider.notifier).refreshSubscriptionStatus();
    } catch (e) {
      // Handle error silently
    }
  }

  // Activate subscription for testing
  void activateSubscriptionForTesting() {
    try {
      _ref.read(subscriptionStatusProvider.notifier).activateSubscription();
    } catch (e) {
      // Handle error silently
    }
  }

  // Deactivate subscription for testing
  void deactivateSubscriptionForTesting() {
    try {
      _ref.read(subscriptionStatusProvider.notifier).deactivateSubscription();
    } catch (e) {
      // Handle error silently
    }
  }
}

