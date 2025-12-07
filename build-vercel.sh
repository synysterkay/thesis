#!/bin/bash

echo "🚀 Starting Flutter Web Build for Vercel..."

# Create Flutter template if it doesn't exist
if [ ! -f "web/flutter_template.html" ]; then
    echo "📝 Creating Flutter template..."
    cat > web/flutter_template.html << 'FLUTTER_TEMPLATE'
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Thesis Generator">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="thesis_generator">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Thesis Generator</title>

  <style>
    .loading {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background-color: #ffffff;
    }
    .spinner {
      width: 50px;
      height: 50px;
      border: 5px solid #f3f3f3;
      border-top: 5px solid #2196F3;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>

  <script>
    const firebaseConfig = {
      apiKey: "AIzaSyBbErRqwrcX6-ogwmnmr98E3Q4H8KP4w9Q",
      authDomain: "thesis-generator-web.firebaseapp.com",
      projectId: "thesis-generator-web",
      storageBucket: "thesis-generator-web.firebasestorage.app",
      messagingSenderId: "1098826060423",
      appId: "1:1098826060423:web:7ee70dc121234297f05e22",
      measurementId: "G-BY0DNNV0K3"
    };
  </script>

  <script type="module">
    import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
    import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
    import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';

    const app = initializeApp(firebaseConfig);
    window.fbApp = app;
  </script>
</head>
<body>
<div class="loading">
  <div class="spinner"></div>
</div>

<script src="flutter.js" defer></script>
<script>
  window.addEventListener('load', async function() {
    var loading = document.querySelector('.loading');

    _flutter = {
      loader: {
        serviceWorker: {
          serviceWorkerVersion: null
        }
      }
    };

    var scriptLoaderPromise = new Promise((resolve) => {
      var scriptElement = document.createElement('script');
      scriptElement.src = 'main.dart.js';
      scriptElement.type = 'application/javascript';
      document.body.append(scriptElement);

      scriptElement.addEventListener('load', () => {
        loading.style.display = 'none';
        resolve();
      });
    });

    await scriptLoaderPromise;
  });
</script>

</body>
</html>
FLUTTER_TEMPLATE
fi

# Backup your current index.html (landing page)
echo "💾 Backing up landing page..."
if [ -f "web/index.html" ]; then
    cp web/index.html web/index_backup.html
else
    echo "❌ No index.html found in web/ directory!"
    exit 1
fi

# Temporarily replace index.html with Flutter template for build
echo "🔄 Setting up Flutter template for build..."
cp web/flutter_template.html web/index.html

# Clean and get dependencies
echo "📦 Preparing Flutter project..."
flutter clean
flutter pub get

# Generate localization files
echo "🌍 Generating localization files..."
flutter gen-l10n

if [ $? -ne 0 ]; then
    echo "❌ Localization generation failed!"
    # Restore original index.html
    cp web/index_backup.html web/index.html
    rm web/index_backup.html
    exit 1
fi

echo "✅ Localization files generated successfully!"

# Build for web with correct base href for Vercel
echo "🔨 Building Flutter web app..."
flutter build web --release --base-href "/"

if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed!"
    # Restore original index.html
    cp web/index_backup.html web/index.html
    rm web/index_backup.html
    exit 1
fi

echo "✅ Flutter build completed successfully!"

# Restore your original landing page
echo "🔄 Restoring original landing page..."
cp web/index_backup.html web/index.html
rm web/index_backup.html

# Set up final deployment structure
echo "📁 Setting up deployment files..."

# Move Flutter build to app.html
cp build/web/index.html build/web/app.html

# Copy your landing page as index.html
cp web/index.html build/web/index.html

# Create directories if they don't exist
mkdir -p build/web/css
mkdir -p build/web/js

# Copy CSS and JS if they exist
if [ -d "web/css" ]; then
    echo "📄 Copying CSS files..."
    cp -r web/css/* build/web/css/
fi

if [ -d "web/js" ]; then
    echo "📄 Copying JS files..."
    cp -r web/js/* build/web/js/
fi

# Copy success and cancel pages for Stripe
if [ -f "web/success.html" ]; then
    echo "💳 Copying Stripe success page..."
    cp web/success.html build/web/
fi

if [ -f "web/cancel.html" ]; then
    echo "💳 Copying Stripe cancel page..."
    cp web/cancel.html build/web/
fi

# Copy legal pages
if [ -f "web/privacy.html" ]; then
    echo "📄 Copying privacy page..."
    cp web/privacy.html build/web/
fi

if [ -f "web/terms.html" ]; then
    echo "📄 Copying terms page..."
    cp web/terms.html build/web/
fi

if [ -f "web/contact.html" ]; then
    echo "📄 Copying contact page..."
    cp web/contact.html build/web/
fi

if [ -f "web/academic-integrity.html" ]; then
    echo "📄 Copying academic integrity page..."
    cp web/academic-integrity.html build/web/
fi

if [ -f "web/cookies.html" ]; then
    echo "📄 Copying cookies page..."
    cp web/cookies.html build/web/
fi

# Copy other assets
if [ -f "web/favicon.png" ]; then
    echo "🖼️ Copying favicon..."
    cp web/favicon.png build/web/
fi

if [ -f "web/favicon.ico" ]; then
    echo "🖼️ Copying favicon.ico..."
    cp web/favicon.ico build/web/
fi

# Copy any other web assets
if [ -d "web/assets" ]; then
    echo "📁 Copying additional assets..."
    cp -r web/assets build/web/
fi

if [ -d "web/images" ]; then
    echo "🖼️ Copying images..."
    cp -r web/images build/web/
fi

# Verify critical files exist
echo "🔍 Verifying deployment files..."
if [ ! -f "build/web/index.html" ]; then
    echo "❌ Missing index.html!"
    exit 1
fi

if [ ! -f "build/web/app.html" ]; then
    echo "❌ Missing app.html!"
    exit 1
fi

if [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Missing main.dart.js!"
    exit 1
fi

# API functions will be automatically detected by Vercel in the api/ directory
echo "📧 API functions ready in api/ directory for Vercel"
echo "✅ Email API functions: add-subscriber, send-welcome-email, send-followup-emails"

echo "✅ Build preparation complete for Vercel!"
echo ""
echo "📋 Final structure:"
echo "   - index.html (your landing page)"
echo "   - app.html (Flutter app)"
echo "   - success.html (Stripe success page)"
echo "   - cancel.html (Stripe cancel page)"
echo "   - privacy.html, terms.html, contact.html (legal pages)"
echo "   - main.dart.js (Flutter compiled code)"
echo "   - css/ (landing page styles)"
echo "   - js/ (landing page scripts)"
echo "   - api/ (email functions: add-subscriber, send-welcome-email, send-followup-emails)"
echo "   - All other Flutter assets"
echo ""
echo "🎉 Ready for Vercel deployment with email system!"