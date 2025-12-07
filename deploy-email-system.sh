#!/bin/bash

echo "🚀 Thesis Generator Email System Deployment Guide"
echo "================================================="
echo ""

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm i -g vercel
    echo "✅ Vercel CLI installed"
else
    echo "✅ Vercel CLI found"
fi

echo ""
echo "📋 Required Environment Variables:"
echo "FIREBASE_PROJECT_ID=thesis-generator-web"
echo "FIREBASE_CLIENT_EMAIL=[from service account JSON]"
echo "FIREBASE_PRIVATE_KEY=[from service account JSON]" 
echo "GMAIL_USER=kaynelapps@gmail.com"
echo "GMAIL_PASS=mjuqzhfkrxnbojmj"
echo ""

echo "🔑 To get Firebase Service Account credentials:"
echo "1. Visit: https://console.firebase.google.com/project/thesis-generator-web/settings/serviceaccounts/adminsdk"
echo "2. Click 'Generate new private key'"
echo "3. Download the JSON file"
echo "4. Extract client_email and private_key values"
echo ""

echo "📝 Vercel Environment Variables Setup:"
echo "1. Run: vercel env add FIREBASE_PROJECT_ID"
echo "2. Run: vercel env add FIREBASE_CLIENT_EMAIL"
echo "3. Run: vercel env add FIREBASE_PRIVATE_KEY"
echo "4. Run: vercel env add GMAIL_USER"
echo "5. Run: vercel env add GMAIL_PASS"
echo ""

echo "🚀 Deploy Commands:"
echo "vercel --prod"
echo ""

echo "✅ Email System Features:"
echo "- /api/add-subscriber: Add users to email list"
echo "- /api/send-welcome-email: Send immediate welcome email"
echo "- /api/send-followup-emails: Automated follow-up sequence (runs every 6 hours)"
echo ""

echo "🧪 Test Endpoints After Deployment:"
echo "curl -X POST https://your-domain.vercel.app/api/add-subscriber \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"test@example.com\",\"name\":\"Test User\"}'"
echo ""

echo "📊 Monitor:"
echo "- Check Vercel Functions logs for execution status"
echo "- Monitor Firebase Firestore for subscriber data"
echo "- Verify Gmail account for sent emails"