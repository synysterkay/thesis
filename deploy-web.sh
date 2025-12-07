
#!/bin/bash

echo "🏗️  Building Flutter web..."
flutter build web --release

echo "📦 Copying API functions..."
cp -r api build/web/

echo "📦 Copying API dependencies..."
cp -r api/node_modules build/web/api/ 2>/dev/null || echo "No node_modules found, will install..."

echo "📋 Copying configuration..."
cp vercel.json build/web/

echo "🔧 Ensuring API dependencies are installed..."
cd api
npm install
cd ..

echo "📦 Copying installed dependencies to build..."
cp -r api/node_modules build/web/api/

echo "🚀 Deploying to Vercel..."
cd build/web
vercel --prod
cd ../..

echo "✅ Deployment complete!"
