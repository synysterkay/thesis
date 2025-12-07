# Email System Migration: Firebase to Vercel + Firebase Free Plan

## 🎯 Problem Solved
Your current email system uses Firebase Cloud Functions, which require a paid plan for external API calls (Gmail SMTP). This migration moves email sending to Vercel functions while keeping subscriber data in Firebase (free plan).

## ✅ New Architecture
- **Vercel Functions**: Handle email sending (no Firebase paid plan needed)
- **Firebase Firestore (Free)**: Store email subscribers and tracking data
- **Gmail SMTP**: Send emails via Vercel functions
- **Vercel Cron Jobs**: Automated follow-up emails

## 🚀 Setup Instructions

### 1. Environment Variables (Vercel Dashboard)
Add these to your Vercel project settings:

```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=thesis-generator-web
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xyz@thesis-generator-web.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-private-key-from-service-account\n-----END PRIVATE KEY-----"

# Gmail Configuration (Already working values from your current system)
GMAIL_USER=kaynelapps@gmail.com
GMAIL_PASSWORD=mjuqzhfkrxnbojmj

# Cron Job Security
CRON_SECRET=thesis-email-cron-secret-2024
```

### 2. Gmail App Password Setup
1. Enable 2-factor authentication on your Gmail account
2. Go to Google Account settings > Security > App passwords
3. Generate an app password for "Mail"
4. Use this app password (not your regular password) in `GMAIL_PASSWORD`

### 3. Firebase Service Account Setup
1. Go to Firebase Console > Project Settings > Service Accounts
2. Click "Generate new private key"
3. Copy the values to your Vercel environment variables:
   - `project_id` → `FIREBASE_PROJECT_ID`
   - `client_email` → `FIREBASE_CLIENT_EMAIL`
   - `private_key` → `FIREBASE_PRIVATE_KEY`

### 4. Deploy to Vercel
```bash
# Deploy your project
vercel --prod

# The following endpoints will be available:
# https://thesis-generator-ai.vercel.app/api/add-subscriber
# https://thesis-generator-ai.vercel.app/api/send-welcome-email
# https://thesis-generator-ai.vercel.app/api/send-followup-emails
```

## 📧 Email Flow

### 1. Subscription Process
```
User subscribes → /api/add-subscriber → Store in Firebase → Trigger welcome email
```

### 2. Welcome Email (Immediate)
- Sent immediately when user subscribes
- Contains getting started guide and app link

### 3. Follow-up Emails (Automated)
- **Day 2**: Social proof email (10,000+ students success stories)
- **Day 4**: Urgency email (don't fall behind messaging)
- **Cron Job**: Runs every 6 hours to send scheduled emails

## 🔗 Integration with Your App

### Frontend Integration
Replace Firebase function calls with Vercel API calls:

```dart
// OLD: Firebase function
final response = await http.post(
  Uri.parse('https://your-region-project.cloudfunctions.net/addSubscriber'),
  body: json.encode({'email': email, 'thesisTopic': topic}),
);

// NEW: Vercel function
final response = await http.post(
  Uri.parse('https://thesis-generator-ai.vercel.app/api/add-subscriber'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({'email': email, 'thesisTopic': topic}),
);
```

## 📊 Firebase Firestore Schema

### Collection: `email_subscribers`
```javascript
{
  email: "user@example.com",
  thesisTopic: "AI in Education",
  source: "app", // or "web", "trial", etc.
  subscribedAt: Timestamp,
  emailsSent: 1,
  lastEmailSent: Timestamp,
  status: "active", // or "unsubscribed"
  
  // Email sequence tracking
  welcomeEmailSent: true,
  proofEmailSent: false,
  urgencyEmailSent: false,
  finalEmailSent: false
}
```

## 💰 Cost Benefits
- **Firebase**: FREE (Firestore free tier: 50k reads/writes per day)
- **Vercel**: FREE (100k function invocations per month)
- **Gmail**: FREE (standard Gmail account)
- **Total Cost**: $0/month for reasonable usage

## 🔄 Migration Steps

1. **Set up environment variables** in Vercel
2. **Deploy the new functions** to Vercel
3. **Test email sending** with a test subscriber
4. **Update your app** to use new API endpoints
5. **Set up cron job** for automated emails
6. **Disable old Firebase functions** (optional)

## 🧪 Testing

### Test Subscription
```bash
curl -X POST https://thesis-generator-ai.vercel.app/api/add-subscriber \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","thesisTopic":"AI Research"}'
```

### Test Welcome Email
```bash
curl -X POST https://thesis-generator-ai.vercel.app/api/send-welcome-email \
  -H "Content-Type: application/json" \
  -d '{"subscriberId":"doc-id","email":"test@example.com","thesisTopic":"AI Research"}'
```

## 🚨 Important Notes

1. **Gmail Limits**: 500 emails per day for regular Gmail accounts
2. **Vercel Limits**: 100k function invocations per month (free tier)
3. **Firebase Limits**: 50k document reads/writes per day (free tier)
4. **Cron Jobs**: Run every 6 hours, limited to 50 emails per run

## 🎉 Benefits

✅ **No Firebase paid plan required**
✅ **Works with Firebase free tier**
✅ **Automated email sequences**
✅ **Reliable email delivery**
✅ **Easy to maintain and update**
✅ **Cost-effective solution**

This setup gives you a professional email marketing system at zero cost!