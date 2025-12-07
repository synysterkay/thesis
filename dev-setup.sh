#!/bin/bash

# Development setup script for Thesis Generator

echo "🎓 Setting up Thesis Generator development environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install
# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "Please login to Firebase:"
    firebase login
fi

# Initialize Firebase project (if not already initialized)
if [ ! -f "firebase.json" ]; then
    echo "🔥 Initializing Firebase project..."
    firebase init
else
    echo "✅ Firebase project already initialized"
fi

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p web/js
mkdir -p web/css
mkdir -p web/images
mkdir -p functions
mkdir -p tests
mkdir -p docs
mkdir -p scripts

# Set up Git hooks
echo "🪝 Setting up Git hooks..."
npm run setup:hooks

# Start Firebase emulators
echo "🚀 Starting Firebase emulators..."
firebase emulators:start --only auth,firestore,hosting &

# Wait for emulators to start
sleep 5

echo "✅ Development environment setup complete!"
echo ""
echo "🌐 Your app is running at:"
echo "   - Hosting: http://localhost:5000"
echo "   - Emulator UI: http://localhost:4000"
echo ""
echo "📝 Available commands:"
echo "   npm run dev          - Start development server"
echo "   npm run firebase:emulators - Start Firebase emulators"
echo "   npm run build        - Build for production"
echo "   npm run deploy       - Deploy to Firebase"
echo ""
echo "Happy coding! 🎉"
