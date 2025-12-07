import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'onesignal_service.dart';

/// Mobile-specific authentication service
/// This service is designed for mobile apps using Superwall for subscriptions
/// It doesn't handle Stripe subscription checks like the web auth service
class MobileAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  MobileAuthService() {
    // Initialize Google Sign-In for mobile
    // No web clientId needed - using default Android/iOS configuration
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user in OneSignal
      if (result.user != null) {
        await OneSignalService().setUser(result.user!);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user in OneSignal
      if (result.user != null) {
        await OneSignalService().setUser(result.user!);
      }

      return result.user;l result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with Google - Mobile only
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        throw Exception('Sign-in cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Ensure we have both tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception(
            'Failed to obtain authentication tokens. Please make sure you have added your SHA-1 certificate to Firebase Console. See MOBILE_GOOGLE_SIGNIN_SETUP.md for instructions.');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result =
          await _auth.signInWithCredential(credential);

      // Set user in OneSignal
      if (result.user != null) {
        await OneSignalService().setUser(result.user!);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      if (e.code == 'invalid-credential') {
        throw Exception(
            'OAuth configuration error. Please add your app\'s SHA-1 certificate to Firebase Console. See MOBILE_GOOGLE_SIGNIN_SETUP.md for detailed instructions.');
      }
      throw _handleAuthException(e);
    } catch (e) {
      // Handle other errors (Google Sign-In errors, network errors, etc.)
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('cancelled')) {
        throw Exception('Sign-in was cancelled');
      } else if (e.toString().contains('network_error') ||
          e.toString().contains('NETWORK_ERROR')) {
        throw Exception('Network error. Please check your internet connection');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception(
            'Google Sign-In failed. Please make sure Google Play Services is up to date');
      } else if (e.toString().contains('api_not_connected')) {
        throw Exception(
            'Google Play Services connection failed. This usually means your SHA-1 certificate is not registered in Firebase Console. See MOBILE_GOOGLE_SIGNIN_SETUP.md for setup instructions.');
      } else if (e.toString().contains('PlatformException')) {
        throw Exception(
            'Platform error. Please ensure Google Play Services is installed and your SHA-1 certificate is registered in Firebase Console.');
      } else if (e.toString().contains('10:')) {
        // Error code 10 is a common Google Sign-In error for configuration issues
        throw Exception(
            'Google Sign-In configuration error. Your app\'s SHA-1 certificate must be registered in Firebase Console. Run: cd android && ./gradlew signingReport to get your SHA-1, then add it to Firebase Console.');
      }
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign in with Apple - iOS only
  Future<User?> signInWithApple() async {
    try {
      // Check if running on iOS
      if (!Platform.isIOS) {
        throw Exception('Apple Sign-In is only available on iOS devices');
      }

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
            'Apple Sign-In is not available on this device. Please ensure you are using iOS 13 or later and that the Sign In with Apple capability is enabled in Xcode.');
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      print('🍎 Starting Apple Sign-In request...');

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('🍎 Apple credential received');

      // Create an OAuthCredential from the credential returned by Apple
      // Sign in to Firebase with the Apple credential
      final UserCredential result =
          await _auth.signInWithCredential(oauthCredential);

      // Set user in OneSignal
      if (result.user != null) {
        await OneSignalService().setUser(result.user!);
      }

      // Update display name if this is a new user and we have the name from Apple
      if (result.additionalUserInfo?.isNewUser ?? false) {
      final UserCredential result =
          await _auth.signInWithCredential(oauthCredential);

      // Update display name if this is a new user and we have the name from Apple
      if (result.additionalUserInfo?.isNewUser ?? false) {
        final fullName = appleCredential.givenName != null ||
                appleCredential.familyName != null
            ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim()
            : null;

        if (fullName != null && fullName.isNotEmpty) {
          await result.user?.updateDisplayName(fullName);
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle all errors including Apple Sign-In specific errors
      final errorStr = e.toString();
      print('🍎 Apple Sign-In error: $errorStr');

      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        throw Exception('Apple Sign-In was cancelled');
      } else if (errorStr.contains('1000')) {
        // Error 1000 is typically a configuration issue
        throw Exception('Apple Sign-In configuration error. Please ensure:\n'
            '1. Sign In with Apple capability is enabled in Xcode\n'
            '2. Your Apple Developer account has the correct Bundle ID registered\n'
            '3. The app is properly signed with a valid provisioning profile');
      } else if (errorStr.contains('failed')) {
        throw Exception('Apple Sign-In failed. Please try again');
  // Sign out
  Future<void> signOut() async {
    try {
      // Clear OneSignal user first
      await OneSignalService().clearUser();

      // Sign out from both Firebase and Google
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }uture<void> signOut() async {
    try {
      // Sign out from both Firebase and Google
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get user data for Superwall identification
  Map<String, dynamic> getUserDataForSuperwall() {
    final user = _auth.currentUser;
    if (user == null) return {};

    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'emailVerified': user.emailVerified,
      'photoURL': user.photoURL ?? '',
      'createdAt': user.metadata.creationTime?.toIso8601String() ?? '',
      'lastSignIn': user.metadata.lastSignInTime?.toIso8601String() ?? '',
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'unknown',
      'isAnonymous': user.isAnonymous,
    };
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Sign out from Google first
      await _googleSignIn.signOut();

      // Delete the Firebase user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'This operation requires recent authentication. Please sign in again and try again.');
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Get user photo URL
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  // Reload current user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      default:
        return e.message ?? 'Authentication failed. Please try again';
    }
  }
}
