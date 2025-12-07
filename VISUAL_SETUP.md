# 🎯 VISUAL SETUP GUIDE

## Your 3 Environment Variables

Copy these exact values to Vercel:

### Variable 1: STRIPE_SECRET_KEY
```
Name: STRIPE_SECRET_KEY

Value: 
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
```

### Variable 2: STRIPE_WEBHOOK_SECRET
```
Name: STRIPE_WEBHOOK_SECRET

Value:
whsec_FM0x9dDp56q7CkDMhMzilUX97Uk41f9T
```

### Variable 3: ADMIN_API_KEY
```
Name: ADMIN_API_KEY

Value:
cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a
```

---

## Step-by-Step in Vercel

### 1️⃣ Open Vercel Dashboard
```
https://vercel.com/dashboard
│
├─ Select Project: thesis-web
├─ Click: Settings (top)
└─ Click: Environment Variables (left)
```

### 2️⃣ Add First Variable
```
Page: Environment Variables

Click "Add New" 
│
├─ Name: STRIPE_SECRET_KEY
├─ Value: sk_live_51IwsyLEHyyRHgrPi...
├─ Production: ✓ Yes
└─ Click: Save
```

### 3️⃣ Add Second Variable
```
Click "Add New" again
│
├─ Name: STRIPE_WEBHOOK_SECRET
├─ Value: whsec_FM0x9dDp56q7CkD...
├─ Production: ✓ Yes
└─ Click: Save
```

### 4️⃣ Add Third Variable
```
Click "Add New" again
│
├─ Name: ADMIN_API_KEY
├─ Value: cc396fbad7fb8dde9ce...
├─ Production: ✓ Yes
└─ Click: Save
```

### 5️⃣ Redeploy
```
Tab: Deployments

Find Latest Deployment → Click ⋯ (three dots)
│
└─ Click: Redeploy
   
Wait for deployment to complete (usually <1 minute)
```

---

## Quick Copy-Paste Commands

### Test 1: Verify Setup
```bash
curl "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/subscriptions?limit=1" \
  -H "x-admin-key: cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a"
```

Should return JSON with no errors ✅

### Test 2: Create Checkout
```bash
curl -X POST "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/create-checkout-session" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

Should return checkout URL ✅

---

## Visual Payment Flow

```
┌─────────────┐
│  User Pays  │
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────┐
│ Stripe Checkout (4242 4242...)  │
└──────┬──────────────────────────┘
       │
       ↓
┌─────────────────────────────────┐
│ Payment Processed               │
│ • Subscription Created          │
│ • Webhook Fired                 │
└──────┬──────────────────────────┘
       │
       ↓
┌─────────────────────────────────┐
│ User Redirected Back to App     │
│ • App marks as subscribed       │
│ • App polls Stripe (every 3s)   │
└──────┬──────────────────────────┘
       │
       ↓
┌─────────────────────────────────┐
│ Webhook Confirms (real-time)    │
│ • Updates logs                  │
│ • Finalizes subscription        │
└──────┬──────────────────────────┘
       │
       ↓
┌─────────────────────────────────┐
│ ✅ USER UNLOCKED                │
│ Can now use app!                │
└─────────────────────────────────┘
```

**Time:** ~2-5 seconds total ⚡

---

## Admin Dashboard Commands

### View All Subscriptions
```bash
curl "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/subscriptions?limit=20" \
  -H "x-admin-key: cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a"
```

### View One Customer
```bash
curl "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/customer?email=user@example.com" \
  -H "x-admin-key: cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a"
```

### Cancel Subscription
```bash
curl -X DELETE "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/subscription" \
  -H "x-admin-key: cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a" \
  -H "Content-Type: application/json" \
  -d '{"subscriptionId":"sub_xxxxx"}'
```

### Issue Refund
```bash
curl -X POST "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/refund" \
  -H "x-admin-key: cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a" \
  -H "Content-Type: application/json" \
  -d '{"chargeId":"ch_xxxxx","amount":19.99}'
```

---

## Where to Find Things in Stripe Dashboard

### View Payments
```
https://dashboard.stripe.com/payments
```

### View Webhooks
```
https://dashboard.stripe.com/developers/webhooks
│
└─ Click your endpoint
   └─ Events tab (to see all webhook attempts)
```

### View Customers
```
https://dashboard.stripe.com/customers
```

### View Subscriptions
```
https://dashboard.stripe.com/subscriptions
```

---

## Saved Keys For Your Records

**SAVE THESE SOMEWHERE SAFE:**

```
Production App URL:
https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app

Stripe Secret Key:
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

Webhook Secret:
whsec_FM0x9dDp56q7CkDMhMzilUX97Uk41f9T

Admin API Key:
cc396fbad7fb8dde9ce613c15aeb25dfd4e93fabfeacd39ef39a5e5396f0025a

Webhook Endpoint:
https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/webhook
```

---

## ✅ You're All Set!

Just add those 3 variables to Vercel and you're live! 🚀

Questions? See:
- START_HERE.md (this process explained)
- QUICK_REFERENCE.md (common commands)
- PRODUCTION_GUIDE.md (detailed guide)