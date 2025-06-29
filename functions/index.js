const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY);
const cors = require('cors')({
  origin: true,
  credentials: true
});

admin.initializeApp();

// Helper function to verify Firebase Auth token
async function verifyAuthToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new functions.https.HttpsError('unauthenticated', 'No valid authorization header');
  }
  
  const token = authHeader.split('Bearer ')[1];
  const decodedToken = await admin.auth().verifyIdToken(token);
  return decodedToken;
}

// 💳 API Endpoint: Create Checkout Session (Direct Stripe)
exports.createCheckoutSession = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('💳 Create checkout session request received');
      
      // Verify authentication
      const decodedToken = await verifyAuthToken(req);
      const userId = decodedToken.uid;
      
      const { priceId, planType, userEmail } = req.body;
      
      console.log('💳 Creating checkout session:', { userId, priceId, planType, userEmail });
      
      // Get user data from Firebase
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      if (!userData) {
        throw new Error('User not found in database');
      }
      
      // Create Stripe checkout session
      const session = await stripe.checkout.sessions.create({
        mode: 'subscription',
        line_items: [{
          price: priceId,
          quantity: 1,
        }],
        success_url: `${req.headers.origin || 'https://thesis-generator-web.web.app'}/app.html?session_id={CHECKOUT_SESSION_ID}&success=true`,
        cancel_url: `${req.headers.origin || 'https://thesis-generator-web.web.app'}/index.html?canceled=true`,
        client_reference_id: userId,
        customer_email: userEmail || userData.email,
        allow_promotion_codes: true,
        billing_address_collection: 'required',
        metadata: {
          firebase_user_id: userId,
          plan_type: planType,
          user_email: userEmail || userData.email
        },
        subscription_data: {
          description: `Thesis Generator ${planType.charAt(0).toUpperCase() + planType.slice(1)} Plan`,
          metadata: {
            firebase_user_id: userId,
            plan_type: planType
          }
        }
      });
      
      // Log checkout session creation
      await admin.firestore().collection('checkout_sessions').doc(session.id).set({
        userId: userId,
        userEmail: userEmail || userData.email,
        planType: planType,
        priceId: priceId,
        status: 'created',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log('✅ Checkout session created:', session.id);
      
      res.json({
        success: true,
        sessionId: session.id,
        checkoutUrl: session.url
      });
      
    } catch (error) {
      console.error('❌ Error creating checkout session:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

// 🔍 API Endpoint: Check Subscription Status (Firebase only)
exports.checkSubscription = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('🔍 Check subscription request received');
      
      // Verify authentication
      const decodedToken = await verifyAuthToken(req);
      const userId = decodedToken.uid;
      
      console.log('👤 Checking subscription for user:', userId);
      
      // Get user data from Firebase
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      if (!userData) {
        return res.json({
          success: true,
          hasActiveSubscription: false,
          subscription: null,
          source: 'firebase'
        });
      }
      
      // Check if subscription is still valid
      const subscriptionStatus = userData.subscriptionStatus || 'inactive';
      const subscriptionEndDate = userData.subscriptionEndDate;
      
      let hasActiveSubscription = false;
      
      if (subscriptionStatus === 'active') {
        if (subscriptionEndDate) {
          const endDate = subscriptionEndDate.toDate ? subscriptionEndDate.toDate() : new Date(subscriptionEndDate);
          hasActiveSubscription = endDate > new Date();
          
          // If expired, update status
          if (!hasActiveSubscription) {
            await admin.firestore().collection('users').doc(userId).update({
              subscriptionStatus: 'expired',
              expiredAt: admin.firestore.FieldValue.serverTimestamp(),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        } else {
          // No end date means active
          hasActiveSubscription = true;
        }
      }
      
      console.log('✅ Subscription check complete:', { userId, hasActiveSubscription });
      
      res.json({
        success: true,
        hasActiveSubscription,
        subscription: hasActiveSubscription ? {
          status: userData.subscriptionStatus,
          plan: userData.subscriptionPlan,
          startDate: userData.subscriptionStartDate,
          endDate: userData.subscriptionEndDate
        } : null,
        source: 'firebase'
      });
      
    } catch (error) {
      console.error('❌ Error checking subscription:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

// 🔗 Webhook: Handle Stripe Events
exports.stripeWebhook = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;
    
    let event;
    
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
    } catch (err) {
      console.error('❌ Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }
    
    console.log('🔗 Stripe webhook received:', event.type);
    
    try {
      switch (event.type) {
        case 'checkout.session.completed':
          await handleCheckoutCompleted(event.data.object);
          break;
          
        case 'customer.subscription.created':
          await handleSubscriptionCreated(event.data.object);
          break;
          
        case 'customer.subscription.updated':
          await handleSubscriptionUpdated(event.data.object);
          break;
          
        case 'customer.subscription.deleted':
          await handleSubscriptionDeleted(event.data.object);
          break;
          
        case 'invoice.payment_succeeded':
          await handlePaymentSucceeded(event.data.object);
          break;
          
        case 'invoice.payment_failed':
          await handlePaymentFailed(event.data.object);
          break;
          
        default:
          console.log(`Unhandled event type: ${event.type}`);
      }
    } catch (error) {
      console.error('❌ Error processing webhook:', error);
      return res.status(500).send('Webhook processing failed');
    }
    
    res.status(200).send('Webhook processed');
  });
});

// Helper function: Handle successful checkout
async function handleCheckoutCompleted(session) {
  try {
    const userId = session.client_reference_id || session.metadata?.firebase_user_id;
    const planType = session.metadata?.plan_type;
    
    if (!userId) {
      console.error('❌ No user ID found in checkout session');
      return;
    }
    
    console.log('✅ Checkout completed for user:', userId);
    
    // Update checkout session status
    await admin.firestore().collection('checkout_sessions').doc(session.id).update({
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      customerId: session.customer,
      subscriptionId: session.subscription
    });
    
    // Calculate subscription end date
    const now = new Date();
    const endDate = new Date();
    
    if (planType === 'weekly') {
      endDate.setDate(now.getDate() + 7);
    } else if (planType === 'monthly') {
      endDate.setMonth(now.getMonth() + 1);
    }
    
    // Update user subscription status
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'active',
      subscriptionPlan: planType,
      stripeCustomerId: session.customer,
      stripeSubscriptionId: session.subscription,
      subscriptionStartDate: admin.firestore.FieldValue.serverTimestamp(),
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ User subscription activated:', userId);
    
  } catch (error) {
    console.error('❌ Error handling checkout completion:', error);
  }
}

// Helper function: Handle subscription creation
async function handleSubscriptionCreated(subscription) {
  try {
    const userId = subscription.metadata?.firebase_user_id;
    
    if (!userId) {
      console.error('❌ No user ID found in subscription metadata');
      return;
    }
    
    console.log('✅ Subscription created for user:', userId);
    
    // Update subscription details in Firebase
    await admin.firestore().collection('users').doc(userId).update({
      stripeSubscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      currentPeriodStart: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_start * 1000)),
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
  } catch (error) {
    console.error('❌ Error handling subscription creation:', error);
  }
}

// Helper function: Handle subscription updates
async function handleSubscriptionUpdated(subscription) {
  try {
    const userId = subscription.metadata?.firebase_user_id;
    
    if (!userId) {
      console.error('❌ No user ID found in subscription metadata');
      return;
    }
    
    console.log('🔄 Subscription updated for user:', userId, 'Status:', subscription.status);
    
    // Update subscription status in Firebase
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: subscription.status,
      currentPeriodStart: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_start * 1000)),
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
  } catch (error) {
    console.error('❌ Error handling subscription update:', error);
  }
}

// Helper function: Handle subscription deletion
async function handleSubscriptionDeleted(subscription) {
  try {
    const userId = subscription.metadata?.firebase_user_id;
    
    if (!userId) {
      console.error('❌ No user ID found in subscription metadata');
      return;
    }
    
    console.log('❌ Subscription deleted for user:', userId);
    
    // Update subscription status to inactive
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'inactive',
      subscriptionEndDate: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
  } catch (error) {
    console.error('❌ Error handling subscription deletion:', error);
  }
}

// Helper function: Handle successful payment
async function handlePaymentSucceeded(invoice) {
  try {
    const subscriptionId = invoice.subscription;
    
    if (!subscriptionId) {
      console.log('ℹ️ Payment succeeded but no subscription ID found');
      return;
    }
    
    // Get subscription details
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const userId = subscription.metadata?.firebase_user_id;
    
    if (!userId) {
      console.error('❌ No user ID found in subscription metadata');
      return;
    }
    
    console.log('✅ Payment succeeded for user:', userId);
    
    // Update payment status and extend subscription
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'active',
      lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
  } catch (error) {
    console.error('❌ Error handling payment success:', error);
  }
}

// Helper function: Handle failed payment
async function handlePaymentFailed(invoice) {
  try {
    const subscriptionId = invoice.subscription;
    
    if (!subscriptionId) {
      console.log('ℹ️ Payment failed but no subscription ID found');
      return;
    }
    
    // Get subscription details
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const userId = subscription.metadata?.firebase_user_id;
    
    if (!userId) {
      console.error('❌ No user ID found in subscription metadata');
      return;
    }
    
    console.log('❌ Payment failed for user:', userId);
    
    // Update payment status
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionStatus: 'past_due',
      lastPaymentFailure: admin.firestore.FieldValue.serverTimestamp(),
      paymentIssue: true,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    } catch (error) {
    console.error('❌ Error handling payment failure:', error);
  }
}

// 🔧 Callable function: Get user subscription status
exports.getUserSubscription = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    
    // Get user data from Firebase
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    return {
      subscriptionStatus: userData.subscriptionStatus || 'inactive',
      subscriptionPlan: userData.subscriptionPlan || null,
      subscriptionEndDate: userData.subscriptionEndDate || null,
      hasActiveSubscription: userData.subscriptionStatus === 'active'
    };
    
  } catch (error) {
    console.error('❌ Error getting user subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// 🔧 Callable function: Cancel subscription
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    
    // Get user data from Firebase
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData || !userData.stripeSubscriptionId) {
      throw new functions.https.HttpsError('not-found', 'No active subscription found');
    }
    
    // Cancel subscription in Stripe
    await stripe.subscriptions.update(userData.stripeSubscriptionId, {
      cancel_at_period_end: true
    });
    
    // Update Firebase
    await admin.firestore().collection('users').doc(userId).update({
      subscriptionCancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      willCancelAtPeriodEnd: true,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Subscription cancelled for user:', userId);
    
    return {
      success: true,
      message: 'Subscription will be cancelled at the end of the current period'
    };
    
  } catch (error) {
    console.error('❌ Error cancelling subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// 🔧 Health check endpoint
exports.healthCheck = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      // Check Firebase connection
      const testDoc = await admin.firestore().collection('health').doc('test').get();
      
      // Check Stripe connection
      let stripeStatus = 'not_configured';
      const stripeKey = functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY;
      
      if (stripeKey) {
        try {
          await stripe.products.list({ limit: 1 });
          stripeStatus = 'connected';
        } catch (error) {
          stripeStatus = 'error';
        }
      }
      
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        services: {
          firebase: 'connected',
          stripe: stripeStatus
        },
        version: '1.0.0'
      });
      
    } catch (error) {
      console.error('❌ Health check failed:', error);
      res.status(500).json({
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });
});

// 🔧 Scheduled function: Check and update expired subscriptions
exports.checkExpiredSubscriptions = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    console.log('🕐 Running scheduled check for expired subscriptions...');
    
    const now = new Date();
    
    // Get all active subscriptions that might be expired
    const expiredSnapshot = await admin.firestore().collection('users')
      .where('subscriptionStatus', '==', 'active')
      .where('subscriptionEndDate', '<=', admin.firestore.Timestamp.fromDate(now))
      .get();
    
    const batch = admin.firestore().batch();
    let expiredCount = 0;
    
    expiredSnapshot.forEach(doc => {
      const userRef = admin.firestore().collection('users').doc(doc.id);
      batch.update(userRef, {
        subscriptionStatus: 'expired',
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      expiredCount++;
    });
    
    if (expiredCount > 0) {
      await batch.commit();
      console.log(`✅ Updated ${expiredCount} expired subscriptions`);
    } else {
      console.log('✅ No expired subscriptions found');
    }
    
    return null;
  } catch (error) {
    console.error('❌ Error checking expired subscriptions:', error);
    return null;
  }
});

console.log('🚀 Firebase Functions loaded successfully');

