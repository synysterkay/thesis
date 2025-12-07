# Quick Reference Card

## 🚀 Production URLs

**Web App:** https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app  
**API Base:** https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api

---

## ⚡ Quick Setup (5 mins)

### 1. Get Stripe Keys
- Go to: https://dashboard.stripe.com/live/dashboard
- Copy LIVE Secret Key (starts with `sk_live_`)

### 2. Create Webhook
- Go to: https://dashboard.stripe.com/developers/webhooks
- Click "Add endpoint"
- URL: `https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/webhook`
- Events: All (checkout, subscription, invoice, charge)
- Copy webhook secret (starts with `whsec_`)

### 3. Add to Vercel
```
STRIPE_SECRET_KEY = sk_live_xxxxx
STRIPE_WEBHOOK_SECRET = whsec_xxxxx
ADMIN_API_KEY = [new secure random key]
```

### 4. Redeploy
```bash
cd build/web && vercel deploy --prod
```

---

## 📡 API Endpoints

### Create Checkout
```bash
curl -X POST https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/create-checkout-session \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com"}'
```

### Check Status
```bash
curl "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/subscription-status?email=user@example.com"
```

### Admin: List Subs
```bash
curl "https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/subscriptions" \
  -H "x-admin-key: YOUR_KEY"
```

### Admin: Cancel Sub
```bash
curl -X DELETE https://thesis-owr5l0w7y-kaynelapps-projects.vercel.app/api/admin/subscription \
  -H "x-admin-key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"subscriptionId":"sub_xxx"}'
```

---

## 🔍 Debugging

### Check Webhook Events
https://dashboard.stripe.com/developers/webhooks → click endpoint → Events

### Check App Logs
https://vercel.com/dashboard → thesis-web → Functions → select function

### Test Payment
- Card: `4242 4242 4242 4242`
- Date: Any future date
- CVC: Any 3 digits

---

## 💰 Pricing
- Vercel: $0 (free tier)
- Firebase Auth: $0 (free tier)
- Stripe: 2.9% + $0.30 per transaction

---

## 🎯 Checklist Before Launch
- [ ] STRIPE_SECRET_KEY in Vercel
- [ ] STRIPE_WEBHOOK_SECRET in Vercel
- [ ] ADMIN_API_KEY generated
- [ ] Webhook endpoint created
- [ ] Test payment works
- [ ] Webhook events showing
- [ ] Users unlock after payment

---

## 👥 Team Access

**Give team members:**
- `ADMIN_API_KEY` for admin endpoints
- Never share STRIPE_SECRET_KEY
- Stripe Dashboard access if needed

---

## 📞 Common Issues

**Q: "No webhook events showing"**  
A: Check endpoint URL and retry a test event in Stripe Dashboard

**Q: "Payment not creating subscription"**  
A: Check price ID is set as recurring in Stripe, not one-time

**Q: "Admin API returning 401"**  
A: Make sure `ADMIN_API_KEY` is in Vercel and header is `x-admin-key`

**Q: "User not getting access"**  
A: Check polling is running (3 sec intervals) and webhook secret is correct

---

## 📚 Full Docs
- **PRODUCTION_GUIDE.md** - Complete setup guide
- **DEPLOYMENT_CHECKLIST.md** - Detailed checklist + API reference
- **README_PRODUCTION.md** - Feature overview

---

**Ready to launch? You're 5 minutes away!**