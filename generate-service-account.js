#!/usr/bin/env node

// This script helps generate Firebase Admin SDK service account key
// Run this script and follow the instructions to get the service account details

console.log(`
🔥 Firebase Service Account Setup
================================

To complete the email system setup, you need to:

1. Go to Firebase Console: https://console.firebase.google.com/project/thesis-generator-web
2. Navigate to: Project Settings (gear icon) → Service Accounts
3. Click "Generate new private key"
4. Download the JSON file
5. Extract the following values from the JSON:

Required Environment Variables for Vercel:
----------------------------------------
FIREBASE_PROJECT_ID=thesis-generator-web
FIREBASE_CLIENT_EMAIL=[from client_email field]
FIREBASE_PRIVATE_KEY=[from private_key field - keep the \\n characters]
GMAIL_USER=kaynelapps@gmail.com
GMAIL_PASS=mjuqzhfkrxnbojmj

6. Add these to your Vercel project settings:
   - Go to https://vercel.com/your-account/thesis-generator-web/settings/environment-variables
   - Add each variable above

7. Deploy the email system:
   vercel --prod

Alternative CLI Method:
---------------------
If you have Google Cloud SDK installed, you can also use:
gcloud iam service-accounts keys create service-account-key.json --iam-account=firebase-adminsdk-[suffix]@thesis-generator-web.iam.gserviceaccount.com

`);

// Check if gcloud CLI is available
const { execSync } = require('child_process');

try {
  execSync('which gcloud', { stdio: 'ignore' });
  console.log('✅ Google Cloud SDK is installed. You can use the gcloud method above.');
} catch (error) {
  console.log('❌ Google Cloud SDK not found. Please use the Firebase Console method.');
}

console.log('\nNext steps after getting the service account:');
console.log('1. Set up Vercel environment variables');
console.log('2. Deploy with: vercel --prod');
console.log('3. Test the email system');