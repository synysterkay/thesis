#!/bin/bash

# Script to get SHA-1 certificate for Google Sign-In setup
# This helps fix the "not registered to use OAuth2.0" error

echo "🔍 Getting SHA-1 Certificate for Google Sign-In Setup"
echo "======================================================"
echo ""

# Check if we're in the right directory
if [ ! -d "android" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "📱 Getting Debug SHA-1 Certificate..."
echo ""

# Method 1: Using gradlew signingReport
if [ -f "android/gradlew" ]; then
    echo "Method 1: Using Gradle Signing Report"
    echo "--------------------------------------"
    cd android
    ./gradlew signingReport | grep -A 3 "Variant: debug" | grep "SHA-1"
    cd ..
    echo ""
fi

# Method 2: Using keytool directly
echo "Method 2: Using keytool (Debug Keystore)"
echo "----------------------------------------"
if [ -f "$HOME/.android/debug.keystore" ]; then
    keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" || echo "Could not read debug keystore"
else
    echo "Debug keystore not found at $HOME/.android/debug.keystore"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Copy one of the SHA-1 fingerprints above"
echo "2. Go to Firebase Console: https://console.firebase.google.com/"
echo "3. Select your project: thesis-generator-web"
echo "4. Go to Project Settings ⚙️"
echo "5. Scroll to 'Your apps' → Android app"
echo "6. Click 'Add fingerprint'"
echo "7. Paste the SHA-1 and save"
echo "8. Download the updated google-services.json"
echo "9. Replace android/app/google-services.json with the new file"
echo "10. Run: flutter clean && flutter pub get"
echo ""
echo "📖 For detailed instructions, see: MOBILE_GOOGLE_SIGNIN_SETUP.md"
