# Apple Sign-In Setup Guide

This guide explains how Apple Sign-In has been integrated into the thesis generator mobile app and what additional configuration is needed for production.

## What Has Been Implemented

### 1. Dependencies Added
- `sign_in_with_apple: ^6.1.3` - For Apple Sign-In functionality
- `crypto: ^3.0.3` - For secure nonce generation

### 2. Code Changes

#### Mobile Auth Service (`lib/services/mobile_auth_service.dart`)
- Added `signInWithApple()` method that handles the complete Apple Sign-In flow
- Implements secure nonce generation using SHA-256 hashing
- Handles iOS availability checks
- Properly manages user display names for new users
- Comprehensive error handling for all Apple Sign-In scenarios

#### Mobile Sign-In Screen (`lib/screens/mobile_signin_screen.dart`)
- Added Apple Sign-In button (iOS only)
- Integrated with existing authentication flow
- Proper error handling and user feedback
- Follows the same pattern as Google Sign-In for consistency

#### iOS Configuration (`ios/Runner/Info.plist`)
- Added CFBundleURLTypes for Apple Sign-In callback handling
- Configured with app bundle identifier: `com.thesis.generator.ai`

## Required Setup in Xcode

### Step 1: Enable Sign in with Apple Capability

1. Open the iOS project in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Select the **Runner** target in the project navigator

3. Go to the **Signing & Capabilities** tab

4. Click the **+ Capability** button

5. Search for and add **Sign in with Apple**

### Step 2: Configure Bundle Identifier

Ensure your bundle identifier matches what's configured:
- Bundle Identifier: `com.thesis.generator.ai`
- This must match the identifier in Info.plist

### Step 3: Apple Developer Portal Configuration

1. Go to [Apple Developer Portal](https://developer.apple.com)

2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**

3. Select your app's identifier (`com.thesis.generator.ai`)

4. Enable **Sign in with Apple** capability

5. Click **Save**

### Step 4: Configure Services ID (Optional - for Web)

If you want to support Apple Sign-In on the web version:

1. Create a new **Services ID** in Apple Developer Portal
2. Configure it with your web domain
3. Set up return URLs for your web application

## Testing Apple Sign-In

### Requirements for Testing
- **iOS 13.0 or later** - Apple Sign-In is only available on iOS 13+
- **Real device recommended** - Some features may not work properly in simulator
- **Apple ID** - You'll need a valid Apple ID to test sign-in

### Testing Steps

1. Build and run the app on a device:
   ```bash
   flutter run -d <device-id>
   ```

2. Navigate to the sign-in screen

3. Tap the **Continue with Apple** button (only visible on iOS)

4. Follow the Apple authentication flow

5. On first sign-in, you can choose to:
   - Share your email or hide it (Apple will provide a private relay email)
   - Share your name or not

### Expected Behavior

✅ **Success Flow:**
- User taps Apple Sign-In button
- iOS native Apple Sign-In sheet appears
- User authenticates with Face ID/Touch ID or password
- App receives authentication credentials
- User is signed in and redirected to start screen
- User data is saved for Superwall subscription tracking

❌ **Error Scenarios Handled:**
- User cancels sign-in → "Apple Sign-In was cancelled"
- Network error → "Network error. Please check your internet connection"
- iOS version too old → "Apple Sign-In is not available. Please use iOS 13 or later"
- Configuration error → Detailed error message

## Firebase Console Configuration

### Enable Apple Sign-In Provider

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Apple** provider
5. Configure with your Apple Developer Team ID and Services ID (if using web)

### Add iOS App to Firebase

Ensure your iOS app is registered in Firebase:
- Bundle ID: `com.thesis.generator.ai`
- Download and replace `GoogleService-Info.plist` if needed

## Security Considerations

### Nonce Generation
The implementation uses a cryptographically secure nonce:
```dart
String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
```

This nonce is SHA-256 hashed before being sent to Apple and validated by Firebase.

### Privacy
- Apple Sign-In allows users to hide their email address
- When hiding email, Apple provides a private relay email (`privaterelay.appleid.com`)
- Your app must respect this privacy choice
- Users can revoke access at any time through iOS Settings

## Troubleshooting

### "Apple Sign-In is not available"
- Ensure the device is running iOS 13 or later
- Test on a real device, not simulator

### "Invalid credentials" or Sign-In Fails
- Verify the Sign in with Apple capability is added in Xcode
- Check that the bundle identifier matches everywhere
- Ensure Apple Sign-In is enabled in Firebase Console
- Verify the Services ID configuration (if using web)

### "Network error" or Timeout
- Check device internet connection
- Verify Firebase project configuration
- Check Apple Developer Portal status

### Sign-In Button Not Appearing
- The Apple Sign-In button only shows on iOS devices
- The code checks `Platform.isIOS` before displaying the button

## Code Integration Points

### User Session Management
After successful Apple Sign-In:
```dart
await UserPersistenceService.saveUserSession(user);
```

### Superwall Integration
User identity is set for subscription tracking:
```dart
await SuperwallService.setUserIdentity(user);
```

### Navigation Flow
```dart
Navigator.of(context).pushReplacementNamed('/start');
```

## Additional Resources

- [Apple Sign-In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Apple Sign-In Guide](https://firebase.google.com/docs/auth/ios/apple)
- [sign_in_with_apple Package](https://pub.dev/packages/sign_in_with_apple)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)

## Notes

- Apple Sign-In is **required** for apps that offer other social login options (like Google)
- Must be prominently displayed alongside other sign-in options
- Cannot be hidden or made less prominent than other social login buttons
- App Store Review will reject apps that don't comply with these requirements

## Production Checklist

Before submitting to App Store:

- [ ] Sign in with Apple capability added in Xcode
- [ ] Bundle identifier matches everywhere
- [ ] Tested on real iOS device (iOS 13+)
- [ ] Apple provider enabled in Firebase Console
- [ ] Apple Developer Portal identifier configured
- [ ] Privacy policy updated to mention Apple Sign-In
- [ ] App Store listing mentions Apple Sign-In
- [ ] Tested both "Share Email" and "Hide Email" flows
- [ ] Tested account deletion/revocation
- [ ] Error handling tested thoroughly
