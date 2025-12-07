# Fix Apple Sign-In Error 1000

Error 1000 from Apple Sign-In means the capability isn't properly configured in Xcode.

## Quick Fix Steps:

### 1. Open Xcode Project
```bash
open ios/Runner.xcworkspace
```

### 2. Enable Sign In with Apple Capability
1. In Xcode, select the **Runner** project in the navigator
2. Select the **Runner** target
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **"Sign in with Apple"**
6. Make sure it shows as enabled with no errors

### 3. Verify Bundle ID
1. Still in **Signing & Capabilities** tab
2. Verify your Bundle Identifier is: `com.thesis.generator.ai`
3. Make sure **Automatically manage signing** is checked
4. Your Team should be selected (536UU66TYY)

### 4. Check Apple Developer Portal
1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Find your Bundle ID: `com.thesis.generator.ai`
3. Click on it and ensure **Sign In with Apple** capability is enabled
4. If not enabled, enable it and click **Save**

### 5. Regenerate Provisioning Profile
1. In Xcode, go to **Preferences** > **Accounts**
2. Select your Apple ID
3. Click **Download Manual Profiles**
4. Or click the **-** button next to old profiles to remove them
5. Clean build: Product > Clean Build Folder (⌘⇧K)

### 6. Rebuild
```bash
flutter clean
cd ios && pod install && cd ..
flutter run
```

## Alternative: Temporarily Disable Apple Sign-In

If you want to test without Apple Sign-In while fixing the configuration:

The app already hides the Apple Sign-In button on non-iOS devices. To temporarily disable it on iOS:
- Just use Google Sign-In or Email/Password instead
- Apple Sign-In will show again once properly configured

## Common Causes:
- ✗ Sign In with Apple capability not added in Xcode
- ✗ Bundle ID not registered in Apple Developer Portal
- ✗ Capability not enabled in Apple Developer Portal for the Bundle ID
- ✗ Using wrong provisioning profile
- ✗ App not properly signed
