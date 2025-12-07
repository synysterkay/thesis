# Debug Payment Issue - Complete Guide

## What Happened
User paid successfully but the app redirected back to paywall instead of to main-navigation.

## Root Cause Investigation

### Step 1: Check Stripe Dashboard for Subscription
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Customers**
3. Search for the email address you used for payment
4. Open the customer record
5. Look at **Subscriptions** section - you should see an active subscription

**Check:**
- ✅ Is the subscription marked as "Active"?
- ✅ What is the subscription status?
- ✅ When did it start and when will it renew?

### Step 2: Check Webhook Events
1. In Stripe Dashboard, go to **Developers** → **Webhooks**
2. Click on the webhook URL: `https://thesisgenerator.tech/api/webhook`
3. Scroll down to **Events**
4. Look for recent events in this order:
   - `checkout.session.completed` - Payment was completed
   - `customer.subscription.created` - Subscription created
   - `customer.subscription.updated` - Subscription activated

**Check:**
- ✅ Are there webhook events for your email?
- ✅ Do they show as "Delivered"?
- ✅ Or are they showing "Failed"?

### Step 3: Check Subscription Sync Service Logs
The app should have printed detailed logs. Check browser console:

1. Open your browser's Developer Tools (F12)
2. Go to **Console** tab
3. Look for messages with these emojis:
   - 🛒 - Checkout started
   - 💳 - Payment success detected
   - ✅ - Subscription confirmed
   - ❌ - Errors
   - 🔍 - Subscription checks
   - ⏱️ - Polling in progress

**What to look for:**
- Look for "🔍 Checking Stripe subscription for: YOUR_EMAIL"
- Look for "✅ Found local web subscription" OR "❌ No active subscription found"

### Step 4: Test the API Directly
Use this command to test if the subscription check API works:

```bash
curl -X POST https://thesisgenerator.tech/api/check-subscription \
  -H "Content-Type: application/json" \
  -d '{"email":"YOUR_EMAIL_HERE"}'
```

**Expected response (if subscription exists):**
```json
{
  "hasActiveSubscription": true,
  "customerExists": true,
  "customerId": "cus_xxx",
  "customerEmail": "your@email.com",
  "subscriptionCount": 1,
  "subscriptions": [
    {
      "id": "sub_xxx",
      "status": "active",
      "priceId": "price_1SPWU1EHyyRHgrPieMZNbjTL",
      "current_period_start": 1700000000,
      "current_period_end": 1702678400
    }
  ]
}
```

## Common Issues & Solutions

### Issue 1: Email Mismatch
**Symptom:** Payment was charged but subscription not found

**Solution:**
- Check if the email used in Stripe matches the Firebase auth email
- The system now converts emails to lowercase, but make sure they match exactly
- Try logging in with the exact same email you used for payment

### Issue 2: Webhook Not Received
**Symptom:** Events show "Failed" in Stripe Webhook Events

**Solution:**
1. Verify the webhook URL is correct in Stripe Dashboard (should be `https://thesisgenerator.tech/api/webhook`)
2. Check that `STRIPE_WEBHOOK_SECRET` is set in Vercel environment variables
3. The webhook needs exactly 30 seconds to complete - if slower, Stripe retries

### Issue 3: Subscription Verification Timeout
**Symptom:** "Processing your subscription" takes forever, then shows paywall

**Solution:**
- The new version polls for up to 10 minutes (was 5 minutes)
- This gives Stripe time to process the webhook
- The local cache should mark you as subscribed immediately

### Issue 4: Stripe API Rate Limiting
**Symptom:** API returns errors about rate limits

**Solution:**
- This is rare but happens when checking subscription too frequently
- The new polling interval is 2 seconds (was 3 seconds) but with better logging

## Step-by-Step Testing

### Test 1: Fresh Payment
1. Log out of the app
2. Visit https://thesisgenerator.tech
3. Click "Start Now"
4. Log in with **NEW** email address (different from before)
5. Use test card: `4242 4242 4242 4242`
6. Expiry: Any future date (e.g., 12/25)
7. CVC: Any 3 digits (e.g., 123)
8. **DON'T** click back button - wait for redirect

### Test 2: Check Subscription Immediately
After payment redirects back:
1. Open Developer Tools (F12)
2. Copy the email you used
3. In **Console**, run:
```javascript
const email = "YOUR_EMAIL_HERE";
fetch('https://thesisgenerator.tech/api/check-subscription', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email })
}).then(r => r.json()).then(d => console.log(JSON.stringify(d, null, 2)));
```

4. Check the output - should show `"hasActiveSubscription": true`

### Test 3: Check Local Storage
In browser console, run:
```javascript
const stored = localStorage.getItem('thesis_web_subscription_status');
console.log('Stored subscription:', stored);
```

Should show: `true` (as a string)

## Information to Send if Still Broken

If the issue persists, gather this information:

1. **Email used for payment:** _______________
2. **Payment timestamp:** _______________
3. **Browser console logs** (copy full output):
   - Screenshot or text of logs with 🔍, ✅, or ❌ symbols
4. **API check result** (run the curl command above):
   - Copy the full JSON response
5. **Stripe Webhook Status:**
   - Do webhook events show as "Delivered" or "Failed"?

## Recent Changes (This Version)

✅ **Better polling:** Now checks every 2 seconds for up to 10 minutes (was 3 seconds for 5 minutes)

✅ **Better logging:** More detailed console output to track what's happening

✅ **Case-insensitive email:** Email is now converted to lowercase in API calls

✅ **Fallback to local cache:** Even if Stripe verification fails, uses local cache (marked immediately after payment)

✅ **No redirect to paywall:** Payment success now always leads to main-navigation

✅ **Extended verification window:** Gives Stripe more time to process webhooks

## Success Criteria

After the fix, here's what should happen:

1. ✅ Click "Start Now" → Redirects to Stripe
2. ✅ Complete payment → Returns to app with `?payment=success` URL
3. ✅ Shows "Verifying subscription with Stripe..."
4. ✅ Within 10 minutes (usually <10 seconds), shows "Subscription active!"
5. ✅ **Navigates to main-navigation** (not paywall)
6. ✅ Can now use AI Essay Writer features

## Production Monitoring

Once working, monitor:
- **Stripe Dashboard → Customers:** All payment emails should have active subscriptions
- **Vercel Logs:** Check `/api/check-subscription` response times (should be <1s)
- **Browser Console:** No ❌ errors when checking subscription

---

**Need help?** All responses are logged to Vercel. Check function logs in Vercel Dashboard.
