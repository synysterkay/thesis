import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/mobile_auth_service.dart';

// Mobile auth service provider
final mobileAuthServiceProvider = Provider<MobileAuthService>((ref) {
  return MobileAuthService();
});

// Mobile auth state provider
final mobileAuthStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(mobileAuthServiceProvider);
  return authService.authStateChanges;
});

// Mobile current user provider
final mobileCurrentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(mobileAuthStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Mobile user signed in provider
final mobileIsSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(mobileCurrentUserProvider);
  return user != null;
});
