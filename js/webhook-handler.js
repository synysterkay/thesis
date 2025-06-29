const express = require('express');
const stripe = require('stripe')('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'); // Replace with your secret key
const admin = require('firebase-admin');
const app = express();

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert({
    // Your Firebase service account credentials
    projectId: "thesis-generator-web",
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});

const db = admin.firestore();

// Webhook endpoint
app.post('/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = 'whsec_v2twl7cYtuBujKWlAHbmQnB6Y2eMYuwb'; // Replace with your webhook secret
  
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.log(`❌ Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('📨 Webhook received:', event.type);

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutCompleted(event.data.object);
      break;
    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(event.data.object);
      break;
    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object);
      break;
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionCanceled(event.data.object);
      break;
    default:
      console.log(`🤷‍♂️ Unhandled event type ${event.type}`);
  }

  res.json({received: true});
});

// Handle successful checkout
async function handleCheckoutCompleted(session) {
  try {
    console.log('✅ Checkout completed:', session.id);
    
    const customerId = session.customer;
    const clientReferenceId = session.client_reference_id; // This should be the user UID
    
    if (!clientReferenceId) {
      console.error('❌ No client_reference_id found in session');
      return;
    }

    // Get subscription details
    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
      status: 'active',
      limit: 1
    });

    if (subscriptions.data.length === 0) {
      console.error('❌ No active subscription found for customer');
      return;
    }

    const subscription = subscriptions.data[0];
    const priceId = subscription.items.data[0].price.id;
    
    // Determine plan type based on price ID
    let planType = 'monthly';
    let planDuration = 30;
    
    if (priceId === 'price_1RbhGMEHyyRHgrPiSXQFnnrT') { // Weekly price ID
      planType = 'weekly';
      planDuration = 7;
    }

    // Calculate subscription end date
    const startDate = new Date(subscription.current_period_start * 1000);
    const endDate = new Date(subscription.current_period_end * 1000);

    // Update user in Firebase
    await db.collection('users').doc(clientReferenceId).update({
      subscriptionStatus: 'active',
      subscriptionPlan: planType,
      subscriptionId: subscription.id,
      customerId: customerId,
      subscriptionStartDate: admin.firestore.Timestamp.fromDate(startDate),
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
      lastUpdated: admin.firestore.Timestamp.now()
    });

    // Create subscription record
    await db.collection('subscriptions').doc(subscription.id).set({
      userId: clientReferenceId,
      subscriptionId: subscription.id,
      customerId: customerId,
      status: 'active',
      plan: planType,
      priceId: priceId,
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      createdAt: admin.firestore.Timestamp.now(),
      lastUpdated: admin.firestore.Timestamp.now()
    });

    console.log(`✅ Subscription activated for user ${clientReferenceId}: ${planType} plan`);

  } catch (error) {
    console.error('❌ Error handling checkout completed:', error);
  }
}

// Handle successful payment (renewals)
async function handlePaymentSucceeded(invoice) {
  try {
    console.log('💰 Payment succeeded:', invoice.id);
    
    const subscriptionId = invoice.subscription;
    const customerId = invoice.customer;

    // Get subscription details
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    
    // Find user by customer ID
    const userQuery = await db.collection('users').where('customerId', '==', customerId).limit(1).get();
    
    if (userQuery.empty) {
      console.error('❌ No user found for customer:', customerId);
      return;
    }

    const userDoc = userQuery.docs[0];
    const userId = userDoc.id;

    // Update subscription end date
    const endDate = new Date(subscription.current_period_end * 1000);

    await db.collection('users').doc(userId).update({
      subscriptionStatus: 'active',
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
      lastUpdated: admin.firestore.Timestamp.now()
    });

    // Update subscription record
    await db.collection('subscriptions').doc(subscriptionId).update({
      status: 'active',
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      lastPaymentDate: admin.firestore.Timestamp.now(),
      lastUpdated: admin.firestore.Timestamp.now()
    });

    console.log(`✅ Subscription renewed for user ${userId} until ${endDate}`);

  } catch (error) {
    console.error('❌ Error handling payment succeeded:', error);
  }
}

// Handle failed payment
async function handlePaymentFailed(invoice) {
  try {
    console.log('❌ Payment failed:', invoice.id);
    
    const subscriptionId = invoice.subscription;
    const customerId = invoice.customer;

    // Find user by customer ID
    const userQuery = await db.collection('users').where('customerId', '==', customerId).limit(1).get();
    
    if (userQuery.empty) {
      console.error('❌ No user found for customer:', customerId);
      return;
    }

    const userDoc = userQuery.docs[0];
    const userId = userDoc.id;

    // Mark subscription as past_due (Stripe will retry)
    await db.collection('users').doc(userId).update({
      subscriptionStatus: 'past_due',
      lastUpdated: admin.firestore.Timestamp.now()
    });

    await db.collection('subscriptions').doc(subscriptionId).update({
      status: 'past_due',
      lastUpdated: admin.firestore.Timestamp.now()
    });

    console.log(`⚠️ Subscription marked as past_due for user ${userId}`);

  } catch (error) {
    console.error('❌ Error handling payment failed:', error);
  }
}

// Handle subscription cancellation
async function handleSubscriptionCanceled(subscription) {
  try {
    console.log('🚫 Subscription canceled:', subscription.id);
    
    const customerId = subscription.customer;

    // Find user by customer ID
    const userQuery = await db.collection('users').where('customerId', '==', customerId).limit(1).get();
    
    if (userQuery.empty) {
      console.error('❌ No user found for customer:', customerId);
      return;
    }

    const userDoc = userQuery.docs[0];
    const userId = userDoc.id;

    // Deactivate subscription
    await db.collection('users').doc(userId).update({
      subscriptionStatus: 'canceled',
      lastUpdated: admin.firestore.Timestamp.now()
    });

    await db.collection('subscriptions').doc(subscription.id).update({
      status: 'canceled',
      canceledAt: admin.firestore.Timestamp.now(),
      lastUpdated: admin.firestore.Timestamp.now()
    });

    console.log(`🚫 Subscription deactivated for user ${userId}`);

  } catch (error) {
    console.error('❌ Error handling subscription canceled:', error);
  }
}

app.listen(3000, () => {
  console.log('🎧 Webhook server listening on port 3000');
});
