# Production Deployment Guide

## Overview
This guide covers deploying the Thesis Generator with production-ready Stripe integration on Vercel, without requiring Firebase Blaze plan.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Web App                          │
│              (https://thesisgenerator.tech)                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Firebase Auth  │
                    │  (Free tier)    │
                    └─────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Vercel API (Serverless)                    │
├─────────────────────────────────────────────────────────────┤
│ • /api/create-checkout-session.js                           │
│ • /api/check-subscription.js                                │
│ • /api/subscription-status.js                               │
│ • /api/webhook.js                                           │
│ • /api/admin.js                                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Stripe API     │
                    │  (Production)   │
                    └─────────────────┘
```

## Environment Variables

Add these to your Vercel project settings (Dashboard → Settings → Environment Variables):

### Required (Already configured)
```
STRIPE_SECRET_KEY=sk_live_xxxxx
STRIPE_PRICE_ID=price_1SPWU1EHyyRHgrPieMZNbjTL
```

### Optional but Recommended
```
STRIPE_WEBHOOK_SECRET=whsec_xxxxx    # Get from Stripe Dashboard
ADMIN_API_KEY=your_secure_random_key # Generate a strong random key
```

## Step 1: Configure Stripe Webhook

### 1.1 Get Webhook Endpoint Secret
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/developers/webhooks)
2. Click "Add endpoint"
3. Enter endpoint URL: `https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/webhook`
4. Select events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `charge.refunded`
5. Click "Add endpoint"
6. Click on the new endpoint and copy "Signing secret"

### 1.2 Add to Vercel
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project
3. Settings → Environment Variables
4. Add:
   - Name: `STRIPE_WEBHOOK_SECRET`
   - Value: (paste the signing secret from step 1.1.6)
5. Click "Save"

### 1.3 Redeploy
```bash
cd build/web
vercel deploy --prod
```

## Step 2: Configure Admin API Key

### 2.1 Generate Admin Key
Generate a secure random key (use any of these methods):

**Option A - Terminal:**
```bash
openssl rand -hex 32
# Output: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Option B - Node.js:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 2.2 Add to Vercel
1. Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add:
   - Name: `ADMIN_API_KEY`
   - Value: (paste your generated key)
3. Redeploy

## Step 3: Test Production Setup

### Test Subscription Creation
```bash
curl -X POST https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/create-checkout-session \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "firebase_uid": "test_user_123"
  }'
```

### Test Subscription Check
```bash
curl -X POST https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/check-subscription \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### View All Subscriptions (Admin)
```bash
curl https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/admin/subscriptions?limit=20 \
  -H "x-admin-key: YOUR_ADMIN_KEY"
```

### View Customer Subscriptions (Admin)
```bash
curl https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/admin/customer?email=user@example.com \
  -H "x-admin-key: YOUR_ADMIN_KEY"
```

### Cancel Subscription (Admin)
```bash
curl -X DELETE https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/admin/subscription \
  -H "Content-Type: application/json" \
  -H "x-admin-key: YOUR_ADMIN_KEY" \
  -d '{"subscriptionId": "sub_xxxxx"}'
```

### Process Refund (Admin)
```bash
curl -X POST https://thesis-nzav79qs5-kaynelapps-projects.vercel.app/api/admin/refund \
  -H "Content-Type: application/json" \
  -H "x-admin-key: YOUR_ADMIN_KEY" \
  -d '{"chargeId": "ch_xxxxx", "amount": 19.99}'
```

## Step 4: Production Checklist

- [ ] STRIPE_SECRET_KEY set in Vercel (production key)
- [ ] STRIPE_PRICE_ID configured correctly
- [ ] STRIPE_WEBHOOK_SECRET configured in Vercel
- [ ] ADMIN_API_KEY generated and stored securely
- [ ] Webhook endpoint created in Stripe Dashboard
- [ ] Test payment flow end-to-end
- [ ] Verify webhooks are being received (Stripe Dashboard → Webhooks → view logs)
- [ ] Test admin endpoints with correct API key
- [ ] Set up monitoring/alerts for failed payments
- [ ] Document your subscription plan details for support team

## Step 5: Monitoring & Logging

### View API Logs in Vercel
1. Vercel Dashboard → Select Project → Functions
2. Click on any function to see real-time logs

### View Webhook Events in Stripe
1. Stripe Dashboard → Developers → Webhooks
2. Click your endpoint
3. View "Events" tab to see all webhook deliveries
4. Each event shows request/response details

### Key Metrics to Monitor
- Failed payments: `invoice.payment_failed` events
- Subscription cancellations: `customer.subscription.deleted` events
- Payment success rate: Compare `checkout.session.completed` vs `invoice.payment_failed`

## Step 6: Scaling Considerations

### Current Limits
- Vercel serverless functions: **100 requests/second** (easily upgradable)
- Stripe API: **100 requests/second** per API key
- Free tier should handle ~10,000 users/month comfortably

### When to Upgrade

**Upgrade Vercel Plan when:**
- You have >100k monthly API calls
- You need guaranteed uptime SLA
- You need advanced monitoring

**Consider Database when:**
- You have >10k active subscribers
- You need subscription history/analytics
- You want faster customer lookups

Recommended options:
- **Supabase**: Free tier with PostgreSQL (up to 500MB)
- **Neon**: Free tier PostgreSQL
- **Vercel KV**: Redis alternative ($0.2 per 10GB)

## Step 7: Security Best Practices

1. ✅ **API Key Management**
   - Never commit `.env` files
   - Rotate admin keys quarterly
   - Use environment variables in Vercel

2. ✅ **Webhook Security**
   - Always verify signatures (already implemented)
   - Log all webhook events
   - Handle retries gracefully

3. ✅ **Rate Limiting** (TODO - add in future)
   ```javascript
   // Example rate limiter for future implementation
   const rateLimit = 100; // requests per minute
   ```

4. ✅ **Input Validation** (TODO - add in future)
   - Validate email format
   - Sanitize all inputs
   - Prevent SQL injection

## Troubleshooting

### Webhook Not Receiving Events
1. Check endpoint URL in Stripe Dashboard
2. Verify `STRIPE_WEBHOOK_SECRET` is correct
3. Check Vercel function logs for errors
4. Verify Stripe key has webhook permissions

### Subscription Not Creating
1. Verify `STRIPE_PRICE_ID` is valid
2. Check Stripe account is in live mode (not test mode)
3. Verify customer email is valid
4. Check API logs for detailed error messages

### High Latency
1. Check Vercel region settings
2. Monitor Stripe API response times
3. Consider adding caching layer

## Next Steps

1. **Analytics Dashboard**: Create admin panel to view metrics
2. **Email Notifications**: Send receipt emails on successful payment
3. **Subscription Management**: Allow users to manage/cancel subscriptions
4. **Automated Reports**: Generate daily/weekly subscription reports
5. **Database Migration**: Move to Supabase/Neon for advanced features

## Support

For issues, check:
1. Vercel function logs
2. Stripe webhook logs
3. Browser console errors
4. Network tab in DevTools

---

**Last Updated:** November 4, 2025
**Status:** Production Ready ✅