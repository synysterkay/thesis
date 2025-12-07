# 🔧 URGENT: Fix Google Sign-In OAuth Error

## ❌ Current Problem
Your app shows this error:
```
This android application is not registered to use OAuth2.0, please confirm 
the package name and SHA-1 certificate fingerprint match what you registered 
in Google Developer Console.
```

## 🔍 Root Cause
Your debug certificate SHA-1 is **NOT** registered in Firebase Console.

### Your Current Debug SHA-1:
```
35:2E:1A:40:9C:EB:66:A0:99:AE:8C:A3:FE:A2:CE:CE:7A:0C:21:88
```

### SHA-1s Currently in google-services.json:
```
e15b8a1960b8b660fe640392f38bc5cfdcc6a774
ba72b84808c7532922a4ae3ebfd7e2e965241310
```

Your debug SHA-1 is missing!

## ✅ Solution (5 minutes)

### Step 1: Add SHA-1 to Firebase
1. Go to: https://console.firebase.google.com/project/thesis-generator-web/settings/general
2. Scroll to "Your apps" section
3. Find Android app: `com.thesis.generator.ai`
4. Click "Add fingerprint" button
5. Paste this: `35:2E:1A:40:9C:EB:66:A0:99:AE:8C:A3:FE:A2:CE:CE:7A:0C:21:88`
6. Click "Save"

### Step 2: Download New google-services.json
1. In Firebase Console, still in Project Settings
2. Click the download icon next to your Android app
3. Download `google-services.json`
4. Replace the file at: `android/app/google-services.json`

### Step 3: Rebuild App
```bash
flutter clean
flutter pub get
flutter run
```

## 🎯 What We Changed

### Created Mobile-Specific Auth Service
- **File**: `lib/services/mobile_auth_service.dart`
- **Purpose**: Simplified auth for mobile (no Stripe checks)
- **Features**: 
  - Google Sign-In optimized for mobile
  - Better error messages
  - Superwall integration ready

### Created Mobile Auth Provider
- **File**: `lib/providers/mobile_auth_provider.dart`
- **Purpose**: Provides mobile auth service to widgets
- **Usage**: Use `mobileAuthServiceProvider` instead of `authServiceProvider`

### Updated Mobile Sign-In Screen
- **File**: `lib/screens/mobile_signin_screen.dart`
- **Change**: Now uses `mobileAuthServiceProvider`
- **Benefit**: Cleaner separation between web and mobile auth

### Documentation
- **MOBILE_GOOGLE_SIGNIN_SETUP.md**: Comprehensive setup guide
- **get-sha1.sh**: Script to quickly get SHA-1 certificates

## 🔄 Architecture Overview

```
Web App (Stripe)          Mobile App (Superwall)
     ↓                           ↓
AuthService              MobileAuthService
     ↓                           ↓
authServiceProvider      mobileAuthServiceProvider
     ↓                           ↓
SignInScreen            MobileSignInScreen
```

## 🧪 Testing

### After adding SHA-1 to Firebase:

1. **Clean build**:
```bash
flutter clean
rm -rf build/
flutter pub get
```

2. **Run on real device** (emulators might not have Google Play Services):
```bash
flutter run --release
```

3. **Test Google Sign-In**:
   - Tap "Sign in with Google"
   - Select a Google account
   - Should successfully sign in

### If still having issues:

1. **Check SHA-1 is added**:
   - Go to Firebase Console
   - Verify SHA-1 appears in the fingerprints list

2. **Wait 5-10 minutes**:
   - Firebase needs time to propagate changes

3. **Check device**:
   - Ensure Google Play Services is updated
   - Check internet connection
   - Try different Google account

4. **View detailed logs**:
```bash
flutter run --verbose
# In another terminal:
adb logcat | grep -i "auth\|google\|sign"
```

## 📱 Alternative: Use Email/Password

While waiting for SHA-1 setup, you can test with email/password:
- Email auth doesn't require SHA-1 certificates
- Works immediately
- Toggle "Sign up" mode in the sign-in screen

## 🎉 Expected Result

After fixing SHA-1:
1. ✅ Google Sign-In will work
2. ✅ User will be authenticated in Firebase
3. ✅ Superwall will track the user
4. ✅ App will navigate to start screen

## 📞 Support

If you still have issues after following these steps:
1. Check `MOBILE_GOOGLE_SIGNIN_SETUP.md` for detailed troubleshooting
2. Run `./get-sha1.sh` to verify your SHA-1
3. Verify package name is `com.thesis.generator.ai` in Firebase

---

**Last Updated**: November 5, 2025
**Your Debug SHA-1**: `35:2E:1A:40:9C:EB:66:A0:99:AE:8C:A3:FE:A2:CE:CE:7A:0C:21:88`
