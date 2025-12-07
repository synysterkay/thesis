# Mobile Google Sign-In Setup Guide

## Problem
The error "This android application is not registered to use OAuth2.0" occurs because the SHA-1 certificate fingerprint of your debug/release keystore doesn't match what's registered in Firebase Console.

## Solution Steps

### 1. Get Your Debug SHA-1 Certificate
Run this command in your terminal:

```bash
cd android
./gradlew signingReport
```

Or on macOS/Linux, you can use keytool directly:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

You'll see output like:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### 2. Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `thesis-generator-web`
3. Go to Project Settings (⚙️ icon)
4. Scroll down to "Your apps" section
5. Find your Android app: `com.thesis.generator.ai`
6. Click "Add fingerprint"
7. Paste your SHA-1 certificate from step 1
8. Click "Save"

### 3. Download Updated google-services.json

1. After adding the SHA-1, download the updated `google-services.json`
2. Replace the file at: `android/app/google-services.json`
3. The new file will include your debug certificate

### 4. For Release Builds

When you create a release build, you'll need to:

1. Get the SHA-1 of your **release keystore**:
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

2. Add this SHA-1 to Firebase Console (same steps as above)
3. Download updated `google-services.json` again

### 5. For Google Play Store

When you upload to Play Console, Google re-signs your app with their key. You need:

1. Go to Play Console → Your App → Setup → App integrity
2. Copy the "SHA-1 certificate fingerprint" under "App signing key certificate"
3. Add this SHA-1 to Firebase Console

## Current Configuration

Your `google-services.json` currently has these SHA-1 certificates registered:
- `e15b8a1960b8b660fe640392f38bc5cfdcc6a774`
- `ba72b84808c7532922a4ae3ebfd7e2e965241310`

You need to add your current debug certificate's SHA-1 to this list.

## Quick Fix for Development

If you want to test immediately without changing Firebase settings:

1. Use Email/Password authentication instead of Google Sign-In
2. The Mobile Auth Service supports both methods
3. Email auth doesn't require SHA-1 certificates

## Verification

After adding the SHA-1:
1. Wait 5-10 minutes for Firebase to propagate changes
2. Clean and rebuild your app:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

## Common Issues

### "Sign-in was cancelled"
- User clicked back or cancelled the Google account picker
- This is normal user behavior

### "Network error"
- Check internet connection
- Verify Google Play Services is up to date

### "Google Play Services error"
- Update Google Play Services on the device
- Some emulators don't have Google Play Services

### "api_not_connected"
- SHA-1 not registered in Firebase
- Wrong package name in Firebase
- Google services not properly configured

## Testing

To test if Google Sign-In is working:

1. Try on a real device (not emulator) with Google Play Services
2. Make sure device has internet connection
3. Ensure you have a Google account added to the device
4. Check logcat for detailed error messages:
```bash
adb logcat | grep -i "auth\|google\|sign"
```

## Mobile vs Web Auth Services

- **MobileAuthService**: For Android/iOS apps using Superwall
  - No Stripe subscription checks
  - Simple Firebase + Google Sign-In
  - Located at: `lib/services/mobile_auth_service.dart`

- **AuthService**: For web app using Stripe
  - Has Stripe subscription integration
  - Web-specific Google Sign-In flow
  - Located at: `lib/services/auth_service.dart`

The mobile sign-in screen now uses `MobileAuthService` which is optimized for mobile platforms.
