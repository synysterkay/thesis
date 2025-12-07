const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({
  origin: [
    'https://thesisgenerator.tech',
    'https://www.thesisgenerator.tech',
    'https://thesis-generator-web.web.app',
    'https://thesis-generator-web.firebaseapp.com',
    'http://localhost:3000',
    'http://localhost:5000'
  ],
  credentials: true
});

// Initialize Firebase Admin
admin.initializeApp();

// Your domain configuration
const DOMAIN = 'https://thesisgenerator.tech';
const APP_DOMAIN = 'https://thesis-generator-web.web.app';

// Stripe Payment Links (from your provided links)
const PAYMENT_LINKS = {
  pro: 'https://buy.stripe.com/28EbJ12rz8xD3gPaOHfrW06'
};

// Price IDs (you'll need to get these from your Stripe dashboard)
const PRICE_IDS = {
  pro: 'price_1SPWU1EHyyRHgrPieMZNbjTL' // Replace with actual price ID from Stripe
};

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

// 🔍 API Endpoint: Check Subscription Status
exports.checkSubscription = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('🔍 Checking subscription status...');
      
      // Verify authentication
      const decodedToken = await verifyAuthToken(req);
      const userId = decodedToken.uid;
      
      console.log(`👤 User ID: ${userId}`);

      // Get user's active subscriptions from Firestore
      const subscriptionsSnapshot = await admin.firestore()
        .collection('customers')
        .doc(userId)
        .collection('subscriptions')
        .where('status', 'in', ['active', 'trialing'])
        .orderBy('created', 'desc')
        .limit(1)
        .get();

      if (subscriptionsSnapshot.empty) {
        console.log('📭 No active subscriptions found');
        return res.status(200).json({
          isActive: false,
          status: 'no_active_subscription',
          userId: userId,
          message: 'No active subscription found'
        });
      }

      const subscriptionDoc = subscriptionsSnapshot.docs[0];
      const subscription = subscriptionDoc.data();
      
      console.log(`📋 Found subscription: ${subscription.status}`);

      // Extract plan type from price ID
      let planType = 'unknown';
      if (subscription.items && subscription.items.length > 0) {
        const priceId = subscription.items[0].price.id;
        planType = getPlanTypeFromPriceId(priceId);
      }

      // Check if subscription is actually active
      const isActive = subscription.status === 'active' || subscription.status === 'trialing';
      const currentTime = Math.floor(Date.now() / 1000);
      const isNotExpired = !subscription.current_period_end || subscription.current_period_end > currentTime;

      const response = {
        isActive: isActive && isNotExpired,
        status: subscription.status,
        planType: planType,
        userId: userId,
        subscriptionId: subscriptionDoc.id,
        currentPeriodEnd: subscription.current_period_end,
        currentPeriodStart: subscription.current_period_start,
        cancelAtPeriodEnd: subscription.cancel_at_period_end || false,
        customerId: subscription.customer,
        created: subscription.created
      };

      console.log('✅ Subscription status response:', {
        isActive: response.isActive,
        status: response.status,
        planType: response.planType
      });

      return res.status(200).json(response);

    } catch (error) {
      console.error('❌ Error checking subscription:', error);
      return res.status(500).json({
        error: 'Failed to check subscription status',
        details: error.message,
        isActive: false
      });
    }
  });
});

// 🔗 API Endpoint: Get Payment Links
exports.getPaymentLinks = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('🔗 Getting payment links...');
      
      // Optionally verify authentication
      try {
        await verifyAuthToken(req);
      } catch (e) {
        console.log('⚠️ No auth token provided, returning public payment links');
      }

      const response = {
        success: true,
        paymentLinks: PAYMENT_LINKS,
        domain: DOMAIN,
        appDomain: APP_DOMAIN,
        plans: {
          pro: {
            priceId: PRICE_IDS.pro,
            paymentLink: PAYMENT_LINKS.pro,
            price: '$19.99',
            interval: 'month'
          }
        }
      };

      console.log('✅ Payment links response sent');
      return res.status(200).json(response);

    } catch (error) {
      console.error('❌ Error getting payment links:', error);
      return res.status(500).json({
        error: 'Failed to get payment links',
        details: error.message
      });
    }
  });
});

// 🛒 API Endpoint: Create Stripe Checkout Session
exports.createCheckoutSession = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('🛒 Creating Stripe checkout session...');
      console.log('Request method:', req.method);
      console.log('Request body:', req.body);

      // Only allow POST requests
      if (req.method !== 'POST') {
        console.error('❌ Invalid method:', req.method);
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { email, firebase_uid } = req.body;

      if (!email) {
        console.error('❌ Email missing from request');
        return res.status(400).json({ error: 'Email is required' });
      }

      console.log('📧 Processing checkout for email:', email);

      // Initialize Stripe with better error handling
      let stripeSecretKey;
      try {
        stripeSecretKey = functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY;
        if (!stripeSecretKey) {
          throw new Error('Stripe secret key not configured');
        }
      } catch (configError) {
        console.error('❌ Stripe configuration error:', configError);
        return res.status(500).json({ 
          error: 'Stripe configuration error',
          details: 'Please ensure Stripe keys are properly configured'
        });
      }

      const stripe = require('stripe')(stripeSecretKey);
      
      // Create or retrieve customer
      let customer;
      try {
        const existingCustomers = await stripe.customers.list({
          email: email,
          limit: 1
        });

        if (existingCustomers.data.length > 0) {
          customer = existingCustomers.data[0];
          console.log('✅ Found existing customer:', customer.id);
        } else {
          customer = await stripe.customers.create({
            email: email,
            metadata: {
              firebase_uid: firebase_uid || '',
              created_via: 'thesis_generator_web'
            }
          });
          console.log('✅ Created new customer:', customer.id);
        }
      } catch (customerError) {
        console.error('❌ Customer creation error:', customerError);
        return res.status(500).json({ 
          error: 'Failed to create/retrieve customer',
          details: customerError.message 
        });
      }

      // Get price ID from environment or use fallback
      const defaultPriceId = functions.config().stripe?.price_id || 
                            process.env.STRIPE_PRICE_ID || 
                            'price_1SPWU1EHyyRHgrPieMZNbjTL';
      console.log(`💰 Using price ID: ${defaultPriceId}`);

      // Determine base URL with better fallback
      const baseUrl = req.headers.origin || 
                     req.headers.referer?.replace(/\/$/, '') || 
                     'https://thesis-k2nn5oh9k-kaynelapps-projects.vercel.app';
      console.log('🌐 Base URL:', baseUrl);

      // Create checkout session with better error handling
      try {
        const session = await stripe.checkout.sessions.create({
          customer: customer.id,
          payment_method_types: ['card'],
          mode: 'subscription',
          line_items: [
            {
              price: defaultPriceId,
              quantity: 1,
            },
          ],
          success_url: `${baseUrl}/payment-success.html?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${baseUrl}/?payment=cancelled`,
          metadata: {
            firebase_email: email,
            firebase_uid: firebase_uid || '',
            created_via: 'thesis_generator_web'
          },
          subscription_data: {
            metadata: {
              firebase_email: email,
              firebase_uid: firebase_uid || '',
              created_via: 'thesis_generator_web'
            }
          },
          allow_promotion_codes: true,
          billing_address_collection: 'auto',
        });

        console.log('✅ Checkout session created:', session.id);
        console.log('🔗 Checkout URL:', session.url);
        
        return res.status(200).json({ 
          sessionId: session.id,
          url: session.url,
          customerId: customer.id,
          success: true
        });
      } catch (sessionError) {
        console.error('❌ Session creation error:', sessionError);
        return res.status(500).json({ 
          error: 'Failed to create checkout session',
          details: sessionError.message,
          type: sessionError.type || 'unknown'
        });
      }

    } catch (error) {
      console.error('❌ Unexpected error:', error);
      return res.status(500).json({ 
        error: 'Internal server error',
        details: error.message,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      });
    }
  });
});

// 🏪 API Endpoint: Create Customer Portal Session
exports.createPortalSession = functions.https.onCall(async (data, context) => {
  try {
    console.log('🏪 Creating customer portal session...');
    
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    const returnUrl = data.returnUrl || `${DOMAIN}/paywall`;

    console.log(`👤 User ID: ${userId}`);
    console.log(`🔗 Return URL: ${returnUrl}`);

    // Create portal session document in Firestore
    // The Firebase Stripe Extension will automatically process this
    const portalSessionRef = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('portal_sessions')
      .add({
        returnUrl: returnUrl,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });

    console.log(`📄 Portal session document created: ${portalSessionRef.id}`);

    // Wait for the Firebase Extension to process and add the URL
    let attempts = 0;
    const maxAttempts = 30;
    
    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const doc = await portalSessionRef.get();
      const docData = doc.data();
      
      if (docData && docData.url) {
        console.log('✅ Portal URL created successfully');
        return { 
          success: true,
          url: docData.url, 
          sessionId: portalSessionRef.id 
        };
      }
      
      if (docData && docData.error) {
        console.error('❌ Portal session error:', docData.error);
        throw new functions.https.HttpsError('internal', `Portal session error: ${docData.error}`);
      }
      
      attempts++;
      console.log(`⏳ Waiting for portal URL... (${attempts}/${maxAttempts})`);
    }

    throw new functions.https.HttpsError('deadline-exceeded', 'Timeout waiting for portal session URL');

  } catch (error) {
    console.error('❌ Error creating portal session:', error);
    throw new functions.https.HttpsError('internal', `Failed to create portal session: ${error.message}`);
  }
});

// 📊 API Endpoint: Get Customer Data
exports.getCustomerData = functions.https.onCall(async (data, context) => {
  try {
    console.log('📊 Getting customer data...');
    
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    console.log(`👤 User ID: ${userId}`);

    // Get customer document
    const customerDoc = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .get();

    if (!customerDoc.exists) {
      console.log('👤 Customer document does not exist');
      return { 
        success: true,
        exists: false,
        userId: userId
      };
    }

    const customerData = customerDoc.data();
    
    // Get subscription data
    const subscriptionsSnapshot = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('subscriptions')
      .orderBy('created', 'desc')
      .limit(5)
      .get();

    const subscriptions = subscriptionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log('✅ Customer data retrieved');

    return {
      success: true,
      exists: true,
      customer: customerData,
      subscriptions: subscriptions,
      subscriptionCount: subscriptions.length
    };

  } catch (error) {
    console.error('❌ Error getting customer data:', error);
    throw new functions.https.HttpsError('internal', `Failed to get customer data: ${error.message}`);
  }
});

// 🎯 Trigger: Handle new user creation
exports.createCustomerOnSignup = functions.auth.user().onCreate(async (user) => {
  try {
    console.log(`👤 New user created: ${user.uid}`);
    
    // Create customer document for Stripe Extension
    await admin.firestore()
      .collection('customers')
      .doc(user.uid)
      .set({
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          firebaseUID: user.uid,
          source: 'thesisgenerator.tech'
        }
      });

    console.log(`✅ Customer document created for user: ${user.uid}`);
  } catch (error) {
    console.error('❌ Error creating customer document:', error);
  }
});

// 🗑️ Trigger: Handle user deletion
exports.deleteCustomerOnDelete = functions.auth.user().onDelete(async (user) => {
  try {
    console.log(`🗑️ User deleted: ${user.uid}`);
    
    // Delete customer document and subcollections
    const customerRef = admin.firestore().collection('customers').doc(user.uid);
    
    // Delete subcollections
    const subcollections = ['checkout_sessions', 'portal_sessions', 'subscriptions'];
    
    for (const subcollection of subcollections) {
      const snapshot = await customerRef.collection(subcollection).get();
      const batch = admin.firestore().batch();
      
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      if (!snapshot.empty) {
        await batch.commit();
      }
    }
    
    // Delete customer document
    await customerRef.delete();
    
    console.log(`✅ Customer data deleted for user: ${user.uid}`);
  } catch (error) {
    console.error('❌ Error deleting customer data:', error);
  }
});

// 📈 Analytics: Track subscription events
exports.trackSubscriptionEvent = functions.firestore
  .document('customers/{customerId}/subscriptions/{subscriptionId}')
  .onWrite(async (change, context) => {
    try {
      const customerId = context.params.customerId;
      const subscriptionId = context.params.subscriptionId;
      
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      
      let eventType = 'unknown';
      
      if (!before && after) {
        eventType = 'subscription_created';
      } else if (before && !after) {
        eventType = 'subscription_deleted';
      } else if (before && after) {
        if (before.status !== after.status) {
          eventType = `subscription_${after.status}`;
        }
      }
      
      console.log(`📊 Subscription event: ${eventType} for customer ${customerId}`);
      
      // Log to analytics collection
      await admin.firestore()
        .collection('analytics')
        .collection('subscription_events')
        .add({
          customerId: customerId,
          subscriptionId: subscriptionId,
          eventType: eventType,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          beforeStatus: before?.status || null,
          afterStatus: after?.status || null,
          planType: getPlanTypeFromPriceId(after?.items?.[0]?.price?.id),
          domain: DOMAIN
        });
      
    } catch (error) {
      console.error('❌ Error tracking subscription event:', error);
    }
  });

// 🔧 Utility: Health check endpoint
exports.healthCheck = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const timestamp = new Date().toISOString();
      console.log(`🏥 Health check at ${timestamp}`);
      
      // Test Firestore connection
      await admin.firestore().collection('_health').doc('check').set({
        timestamp: timestamp,
        status: 'healthy',
        domain: DOMAIN
      });
      
      res.status(200).json({
        status: 'healthy',
        timestamp: timestamp,
        domain: DOMAIN,
        appDomain: APP_DOMAIN,
        paymentLinks: PAYMENT_LINKS,
        message: 'Thesis Generator API is operational'
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

// 🐛 Debug: Get subscription debug info
exports.debugSubscription = functions.https.onCall(async (data, context) => {
  try {
    console.log('🐛 Debug subscription data...');
    
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    console.log(`👤 Debug for User ID: ${userId}`);

    // Get all customer data
    const customerDoc = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .get();

    const customerData = customerDoc.exists ? customerDoc.data() : null;

    // Get all subscriptions
    const subscriptionsSnapshot = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('subscriptions')
      .orderBy('created', 'desc')
      .get();

    const subscriptions = subscriptionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Get recent checkout sessions
    const checkoutSessionsSnapshot = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('checkout_sessions')
      .orderBy('created', 'desc')
      .limit(5)
      .get();

    const checkoutSessions = checkoutSessionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Get recent portal sessions
    const portalSessionsSnapshot = await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('portal_sessions')
      .orderBy('created_at', 'desc')
      .limit(3)
      .get();

    const portalSessions = portalSessionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    const debugInfo = {
      userId: userId,
      timestamp: new Date().toISOString(),
      domain: DOMAIN,
      appDomain: APP_DOMAIN,
      customer: {
        exists: customerDoc.exists,
        data: customerData
      },
      subscriptions: {
        count: subscriptions.length,
        data: subscriptions
      },
      checkoutSessions: {
        count: checkoutSessions.length,
        recent: checkoutSessions
      },
      portalSessions: {
        count: portalSessions.length,
        recent: portalSessions
      },
      paymentLinks: PAYMENT_LINKS,
      priceIds: PRICE_IDS
    };

    console.log('🐛 Debug info compiled');
    return debugInfo;

  } catch (error) {
    console.error('❌ Error in debug function:', error);
    throw new functions.https.HttpsError('internal', `Debug failed: ${error.message}`);
  }
});

// 🧹 Scheduled: Clean up old sessions (runs daily at 2 AM)
exports.cleanupOldSessions = functions.pubsub.schedule('0 2 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      console.log('🧹 Starting cleanup of old sessions...');
      
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 7); // 7 days ago
      
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);
      
      // Get all customers
      const customersSnapshot = await admin.firestore().collection('customers').get();
      
      let totalDeleted = 0;
      
      for (const customerDoc of customersSnapshot.docs) {
        const customerId = customerDoc.id;
        
        // Clean checkout sessions
        const oldCheckoutSessions = await customerDoc.ref
          .collection('checkout_sessions')
          .where('created', '<', cutoffTimestamp)
          .get();
        
        // Clean portal sessions
        const oldPortalSessions = await customerDoc.ref
          .collection('portal_sessions')
          .where('created_at', '<', cutoffTimestamp)
          .get();
        
        const batch = admin.firestore().batch();
        
        oldCheckoutSessions.docs.forEach(doc => {
          batch.delete(doc.ref);
          totalDeleted++;
        });
        
        oldPortalSessions.docs.forEach(doc => {
          batch.delete(doc.ref);
          totalDeleted++;
        });
        
        if (oldCheckoutSessions.docs.length > 0 || oldPortalSessions.docs.length > 0) {
          await batch.commit();
          console.log(`🧹 Cleaned ${oldCheckoutSessions.docs.length + oldPortalSessions.docs.length} old sessions for customer ${customerId}`);
        }
      }
      
      console.log(`✅ Cleanup completed. Total sessions deleted: ${totalDeleted}`);
      
      // Log cleanup event
      await admin.firestore()
        .collection('analytics')
        .collection('system_events')
        .add({
          eventType: 'cleanup_completed',
          sessionsDeleted: totalDeleted,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          domain: DOMAIN
        });
      
    } catch (error) {
      console.error('❌ Error during cleanup:', error);
    }
  });

// 📊 Analytics: Get subscription analytics
exports.getSubscriptionAnalytics = functions.https.onCall(async (data, context) => {
  try {
    console.log('📈 Getting subscription analytics...');
    
    // Verify authentication (you might want to add admin check)
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));
    const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);
    
    // Get all customers
    const customersSnapshot = await admin.firestore()
      .collection('customers')
      .get();
    
    let totalCustomers = customersSnapshot.size;
    let activeSubscriptions = 0;
    let proSubscriptions = 0;
    let recentSignups = 0;
    let totalRevenue = 0;
    
    for (const customerDoc of customersSnapshot.docs) {
      const customerData = customerDoc.data();
      
      // Count recent signups
      if (customerData.createdAt && customerData.createdAt > thirtyDaysAgoTimestamp) {
        recentSignups++;
      }
      
      // Get active subscriptions
      const subscriptionsSnapshot = await customerDoc.ref
        .collection('subscriptions')
        .where('status', 'in', ['active', 'trialing'])
        .get();
      
      if (!subscriptionsSnapshot.empty) {
        activeSubscriptions++;
        
        // Count plan types and calculate revenue
        const subscription = subscriptionsSnapshot.docs[0].data();
        if (subscription.items && subscription.items.length > 0) {
          const priceId = subscription.items[0].price.id;
          const planType = getPlanTypeFromPriceId(priceId);
          
          // All plans are now "pro" at $19.99/month
          proSubscriptions++;
          totalRevenue += 19.99; // Pro plan price
        }
      }
    }
    
    const analytics = {
      totalCustomers,
      activeSubscriptions,
      proSubscriptions,
      recentSignups,
      totalRevenue: Math.round(totalRevenue * 100) / 100, // Round to 2 decimal places
      conversionRate: totalCustomers > 0 ? Math.round((activeSubscriptions / totalCustomers * 100) * 100) / 100 : 0,
      averageRevenuePerUser: activeSubscriptions > 0 ? Math.round((totalRevenue / activeSubscriptions) * 100) / 100 : 0,
      timestamp: now.toISOString(),
      domain: DOMAIN,
      paymentLinks: PAYMENT_LINKS
    };
    
    console.log('📈 Analytics compiled:', {
      totalCustomers: analytics.totalCustomers,
      activeSubscriptions: analytics.activeSubscriptions,
      conversionRate: analytics.conversionRate
    });
    
    return analytics;
    
  } catch (error) {
    console.error('❌ Error getting analytics:', error);
    throw new functions.https.HttpsError('internal', `Failed to get analytics: ${error.message}`);
  }
});

// 🎉 Welcome: Send welcome notification when subscription becomes active
exports.sendWelcomeNotification = functions.firestore
  .document('customers/{customerId}/subscriptions/{subscriptionId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const customerId = context.params.customerId;
      const subscriptionId = context.params.subscriptionId;
      
      // Check if subscription just became active
      if (before.status !== 'active' && after.status === 'active') {
        console.log(`🎉 New active subscription for customer ${customerId}`);
        
        // Get customer data
        const customerDoc = await admin.firestore()
          .collection('customers')
          .doc(customerId)
          .get();
        
        const customerData = customerDoc.data();
        
        if (customerData && customerData.email) {
          console.log(`📧 Welcome notification for ${customerData.email}`);
          
          // Log the welcome event
          await admin.firestore()
            .collection('analytics')
            .collection('welcome_events')
            .add({
              customerId: customerId,
              email: customerData.email,
              subscriptionId: subscriptionId,
              planType: getPlanTypeFromPriceId(after.items?.[0]?.price?.id),
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              domain: DOMAIN
            });
          
          // Here you could integrate with email service like SendGrid
          // await sendWelcomeEmail(customerData.email, customerData.displayName);
        }
      }
      
    } catch (error) {
      console.error('❌ Error sending welcome notification:', error);
    }
  });

// 🔄 Webhook: Handle Stripe webhooks (if needed for additional processing)
exports.stripeWebhook = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('🔄 Stripe webhook received');
      
      const event = req.body;
      console.log(`📨 Event type: ${event.type}`);
      
      // Log webhook events for debugging
      await admin.firestore()
        .collection('analytics')
        .collection('webhook_events')
        .add({
          eventType: event.type,
          eventId: event.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          domain: DOMAIN,
          processed: true
        });
      
      // The Firebase Stripe Extension handles most webhook processing
      // This is just for additional custom logic if needed
      
      res.status(200).json({ received: true });
      
    } catch (error) {
      console.error('❌ Error processing webhook:', error);
      res.status(400).json({ error: error.message });
    }
  });
});

// 🛠️ Utility Functions

function getPlanTypeFromPriceId(priceId) {
  if (!priceId) return 'pro';
  
  switch (priceId) {
    case PRICE_IDS.pro:
      return 'pro';
    default:
      console.log(`⚠️ Unknown price ID: ${priceId}, defaulting to pro`);
      return 'pro'; // Default to pro plan
  }
}

function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function sanitizeUserData(userData) {
  return {
    email: userData.email || null,
    displayName: userData.displayName || null,
    photoURL: userData.photoURL || null,
    createdAt: userData.createdAt || admin.firestore.FieldValue.serverTimestamp()
  };
}

// 📋 Configuration export for testing
exports.config = {
  domain: DOMAIN,
  appDomain: APP_DOMAIN,
  paymentLinks: PAYMENT_LINKS,
  priceIds: PRICE_IDS,
  version: '1.0.0',
  lastUpdated: new Date().toISOString()
};

console.log('🚀 Thesis Generator Firebase Functions loaded successfully');
console.log(`🌐 Domain: ${DOMAIN}`);
console.log(`📱 App Domain: ${APP_DOMAIN}`);
console.log('💳 Payment Links configured:', Object.keys(PAYMENT_LINKS));
