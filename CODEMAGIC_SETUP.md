# CodeMagic CI/CD Setup Guide

## Overview
This guide will help you set up continuous integration and deployment for the Thesis Generator app using CodeMagic.

## Prerequisites
- GitHub repository: https://github.com/synysterkay/thesis
- CodeMagic account
- App Store Connect account (for iOS)
- Google Play Console account (for Android)

## Configuration Files
The `codemagic.yaml` file includes three workflows:

1. **ios-workflow**: Builds and publishes iOS app to TestFlight
2. **android-workflow**: Builds and publishes Android app to Google Play (internal track)
3. **build-all**: Builds both platforms simultaneously (triggered by version tags)

## Step 1: Connect Repository to CodeMagic

1. Log in to [CodeMagic](https://codemagic.io/)
2. Click "Add application"
3. Select "GitHub" as repository provider
4. Authorize CodeMagic to access your GitHub account
5. Select repository: `synysterkay/thesis`
6. Choose "Flutter App" as project type
7. Select the branch: `main`

## Step 2: Configure App Store Connect Integration (iOS)

### 2.1 Generate App Store Connect API Key
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to: **Users and Access** → **Keys** (under Integrations)
3. Click **+** to create a new key
4. Give it a name: "CodeMagic CI/CD"
5. Select role: **App Manager** or **Admin**
6. Download the `.p8` file
7. Note down:
   - **Key ID** (e.g., ABC123XYZ)
   - **Issuer ID** (found at the top of the page)

### 2.2 Add to CodeMagic
1. In CodeMagic dashboard, go to **Teams** → **Integrations**
2. Click **App Store Connect**
3. Upload your `.p8` key file
4. Enter **Key ID** and **Issuer ID**
5. Save as integration name: "codemagic" (matches yaml config)

### 2.3 Verify App in App Store Connect
- Ensure app exists with Bundle ID: `com.thesis.generator.ai`
- App Store ID: `6739264844` (already in codemagic.yaml)

## Step 3: Configure Google Play Integration (Android)

### 3.1 Create Service Account
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Navigate to: **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
   - Name: "CodeMagic Publisher"
   - Role: **Service Account User**
5. Click **Create Key** → Choose **JSON**
6. Download the JSON file

### 3.2 Link to Google Play Console
1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to: **Setup** → **API access**
3. Click **Link** next to your service account
4. Grant permissions:
   - **Admin** (View app information and download bulk reports)
   - **Release to production, exclude devices, and use Play App Signing**
   - **Releases**: Create, read, update

### 3.3 Add to CodeMagic
1. In CodeMagic, go to your app settings
2. Navigate to **Environment variables**
3. Create a new **group** named: `google_play`
4. Add variable:
   - Name: `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`
   - Value: Paste entire contents of JSON file
   - Secure: ✅ (enable)

## Step 4: Set Up Code Signing

### 4.1 iOS Code Signing (Automatic)
CodeMagic will automatically:
- Fetch signing certificates from App Store Connect
- Create provisioning profiles
- Configure Xcode project

No manual action needed! ✨

### 4.2 Android Code Signing

#### Option A: Use Existing Keystore
1. Locate your keystore file (e.g., `thesis-key.jks`)
2. In CodeMagic, go to **Code signing identities**
3. Click **Add key**
4. Upload keystore file
5. Fill in:
   - **Keystore password**
   - **Key alias**
   - **Key password**
6. Save as reference: `keystore_reference`

#### Option B: Create New Keystore
```bash
# Run locally to create keystore
keytool -genkey -v -keystore thesis-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias thesis
```

Then follow Option A steps to upload.

## Step 5: Configure Environment Variables

### 5.1 Required Variables
In CodeMagic app settings → **Environment variables**:

1. **DEEPSEEK_API_KEY**
   - Value: Your DeepSeek API key (from `.env` file)
   - Secure: ✅

2. **ONESIGNAL_APP_ID** (already in yaml)
   - Value: `4b4333e8-9e9d-4636-974b-b7950b3341d2`
   - Note: Already configured in yaml, but can add as backup

### 5.2 Optional Variables
- `TEAM_ID`: Apple Developer Team ID (auto-detected)
- `PROVISIONING_PROFILE_SPECIFIER`: Profile name (auto-managed)

## Step 6: Add Firebase Configuration Files

### 6.1 iOS Firebase Config
Verify file exists in repository:
```
ios/Runner/GoogleService-Info.plist
```

### 6.2 Android Firebase Config
Verify file exists in repository:
```
android/app/google-services.json
```

⚠️ **Important**: These files MUST be committed to your GitHub repository. CodeMagic builds in a clean environment and needs these files.

## Step 7: Trigger Your First Build

### Manual Trigger
1. Go to CodeMagic dashboard
2. Select your app
3. Click **Start new build**
4. Select workflow:
   - `ios-workflow` for iOS only
   - `android-workflow` for Android only
   - `build-all` for both platforms
5. Click **Start new build**

### Automatic Triggers

#### Push to Branch
- Pushing to `main`, `develop`, or `release/*` branches will trigger:
  - `ios-workflow`
  - `android-workflow`

#### Version Tags
Create a version tag to build both platforms:
```bash
git tag v12.0.0
git push origin v12.0.0
```

This triggers the `build-all` workflow.

#### Platform-Specific Tags
```bash
# iOS only
git tag ios-v21.0.0
git push origin ios-v21.0.0

# Android only
git tag android-v28.0
git push origin android-v28.0
```

## Step 8: Monitor Build Progress

1. In CodeMagic dashboard, click on running build
2. View real-time logs for each script step
3. Check for errors:
   - ✅ Green checkmarks = success
   - ❌ Red X = failure
   - 🟡 Yellow warning = completed with warnings

## Build Artifacts

After successful build, download artifacts:

### iOS
- `build/ios/ipa/*.ipa` - App Store build
- Automatically uploaded to TestFlight

### Android
- `build/app/outputs/apk/release/app-release.apk` - APK for direct install
- `build/app/outputs/bundle/release/app-release.aab` - App Bundle for Play Store
- Automatically uploaded to Google Play (internal track)

## Publishing

### iOS (TestFlight)
1. Build automatically submits to TestFlight
2. Apple reviews the build (usually 24-48 hours)
3. Once approved, distribute to beta testers
4. In App Store Connect:
   - Add testers to "App Store Connect Users" group
   - They'll receive email to install via TestFlight

### Android (Google Play Internal Track)
1. Build submits as draft to internal track
2. Review in Play Console
3. Promote to closed/open testing or production when ready

## Troubleshooting

### iOS Build Fails at Code Signing
**Solution**: 
- Verify App Store Connect API key is valid
- Check bundle identifier matches: `com.thesis.generator.ai`
- Ensure app exists in App Store Connect

### Android Build Fails at Signing
**Solution**:
- Verify keystore credentials in CodeMagic
- Check reference name is `keystore_reference`
- Ensure Google Play service account has correct permissions

### Firebase Configuration Not Found
**Solution**:
- Commit and push Firebase config files:
  ```bash
  git add ios/Runner/GoogleService-Info.plist
  git add android/app/google-services.json
  git commit -m "Add Firebase configuration files"
  git push
  ```

### Environment Variable Not Set
**Solution**:
- Check variable names match exactly (case-sensitive)
- Ensure variables are in correct group (`google_play` for Android)
- Verify secure variables are marked as "Secure"

### Build Number Conflicts
**Solution**:
The yaml automatically increments build numbers using timestamp:
```bash
agvtool new-version -all $(($(date +%s)/100))
```
No manual intervention needed.

## Post-Deployment

### Monitor App Performance
1. **OneSignal Dashboard**: Track push notification delivery
2. **Firebase Console**: Monitor user engagement, crashes
3. **App Store Connect**: Review TestFlight feedback
4. **Google Play Console**: Check crash reports, ANRs

### Update Version Numbers
When releasing new version:

1. Update `pubspec.yaml`:
```yaml
version: 12.1.0+13  # New version + build number
```

2. Update iOS version:
```bash
cd ios
agvtool new-marketing-version 22.0.0
cd ..
```

3. Update Android version in `android/app/build.gradle`:
```gradle
versionCode 29
versionName "29.0"
```

4. Commit and create tag:
```bash
git add .
git commit -m "Bump version to 12.1.0"
git tag v12.1.0
git push origin main --tags
```

## Workflow Customization

### Modify Build Triggers
Edit `codemagic.yaml` triggers:

```yaml
triggering:
  events:
    - push        # Build on every push
    - tag         # Build on tags
    - pull_request  # Build on PRs
  branch_patterns:
    - pattern: 'main'
      include: true
```

### Change Publishing Behavior

#### iOS: Auto-submit to App Store
```yaml
publishing:
  app_store_connect:
    submit_to_testflight: true
    submit_to_app_store: true  # Enable this
```

#### Android: Publish to Production
```yaml
publishing:
  google_play:
    track: production  # Change from 'internal'
    submit_as_draft: false
```

## Security Best Practices

1. ✅ Never commit API keys to repository
2. ✅ Use CodeMagic environment variables for secrets
3. ✅ Enable "Secure" flag for sensitive variables
4. ✅ Rotate API keys periodically
5. ✅ Use service accounts with minimal permissions
6. ✅ Review build logs before sharing (may contain secrets)

## Additional Resources

- [CodeMagic Documentation](https://docs.codemagic.io/)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

## Support

For CodeMagic-specific issues:
- Email: support@codemagic.io
- Slack: [CodeMagic Community](https://codemagic.slack.com/)

For app-specific issues:
- Contact: anaskay.13@gmail.com

---

## Quick Reference

### Build Status Badge
Add to your `README.md`:
```markdown
[![Codemagic build status](https://api.codemagic.io/apps/<app-id>/status_badge.svg)](https://codemagic.io/apps/<app-id>/builds)
```

### Common Commands
```bash
# Trigger build via CLI (install codemagic-cli-tools first)
codemagic builds start --app-id <app-id> --workflow ios-workflow

# Download artifacts
codemagic artifacts download --build-id <build-id>

# Check build status
codemagic builds get --build-id <build-id>
```

---

**Last Updated**: 2025
**CodeMagic Version**: YAML-based workflows
**App Version**: 12.0.0 (iOS: 21.0.0, Android: 28.0)
