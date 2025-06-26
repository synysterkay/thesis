const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const cors = require('cors')({
  origin: true,
  credentials: true
});

admin.initializeApp();

// Wrap your functions with CORS
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { priceId, userId, userEmail, planType } = data;
    
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price: priceId,
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: 'https://thesis-generator-web.web.app/?success=true&session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'https://thesis-generator-web.web.app/?canceled=true',
      customer_email: userEmail,
      metadata: {
        userId: userId,
        planType: planType
      },
      allow_promotion_codes: true,
      billing_address_collection: 'required',
    });

    return { sessionId: session.id };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Add CORS to webhook
exports.stripeWebhook = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    const sig = req.headers['stripe-signature'];
    const endpointSecret = functions.config().stripe.webhook_secret;

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    } catch (err) {
      console.log(`Webhook signature verification failed.`, err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      switch (event.type) {
        case 'checkout.session.completed':
          const session = event.data.object;
          await handleSuccessfulPayment(session);
          break;
        case 'customer.subscription.updated':
          const subscription = event.data.object;
          await updateUserSubscription(subscription);
          break;
        case 'customer.subscription.deleted':
          const deletedSubscription = event.data.object;
          await cancelUserSubscription(deletedSubscription);
          break;
        case 'invoice.payment_failed':
          const failedInvoice = event.data.object;
          await handleFailedPayment(failedInvoice);
          break;
        default:
          console.log(`Unhandled event type ${event.type}`);
      }
    } catch (error) {
      console.error('Error handling webhook:', error);
      return res.status(500).send('Webhook handler failed');
    }

    res.json({received: true});
  });
});

// Superwall webhook handler with CORS
exports.superwallWebhook = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log('Superwall webhook received:', req.body);

      const { event_type, user_id, subscription_status, product_id } = req.body;

      if (!user_id) {
        console.error('No user_id in webhook');
        return res.status(400).send('Missing user_id');
      }

      const db = admin.firestore();
      const userRef = db.collection('users').doc(user_id);
      const subscriptionRef = db.collection('subscriptions').doc(user_id);

      switch (event_type) {
        case 'subscription_start':
          await Promise.all([
            userRef.update({
              subscriptionStatus: 'active',
              subscriptionPlan: product_id,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }),
            subscriptionRef.set({
              userId: user_id,
              status: 'active',
              plan: product_id,
              startDate: admin.firestore.FieldValue.serverTimestamp(),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true })
          ]);
          break;

        case 'subscription_cancel':
        case 'subscription_expire':
          await Promise.all([
            userRef.update({
              subscriptionStatus: 'inactive',
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            }),
            subscriptionRef.update({
              status: 'inactive',
              endDate: admin.firestore.FieldValue.serverTimestamp(),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            })
          ]);
          break;

        default:
          console.log('Unhandled event type:', event_type);
      }

      res.status(200).send('Webhook processed successfully');
    } catch (error) {
      console.error('Webhook processing error:', error);
      res.status(500).send('Internal server error');
    }
  });
});

// Create user profile on authentication
exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  try {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(user.uid);

    await userRef.set({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || '',
      photoURL: user.photoURL || '',
      subscriptionStatus: 'inactive',
      subscriptionPlan: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('User profile created for:', user.uid);
  } catch (error) {
    console.error('Error creating user profile:', error);
  }
});

// Get user subscription status
exports.getUserSubscription = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User profile not found');
    }

    const userData = userDoc.data();
    return {
      subscriptionStatus: userData.subscriptionStatus || 'inactive',
      subscriptionPlan: userData.subscriptionPlan || null,
      lastUpdated: userData.lastUpdated
    };

  } catch (error) {
    console.error('Error getting user subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Update user subscription manually (admin function)
exports.updateUserSubscription = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, subscriptionStatus, subscriptionPlan } = data;
    
    // For now, allow any authenticated user to update subscriptions
    // In production, you'd want to check if the user is an admin
    
    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);
    
    await userRef.update({
      subscriptionStatus: subscriptionStatus,
      subscriptionPlan: subscriptionPlan,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Subscription updated for user ${userId}: ${subscriptionStatus}`);
    return { success: true };

  } catch (error) {
    console.error('Error updating user subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Helper functions
async function handleSuccessfulPayment(session) {
  const userId = session.metadata.userId;
  const planType = session.metadata.planType;
  
  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);
  
  await userRef.update({
    subscriptionStatus: 'active',
    subscriptionPlan: planType,
    stripeCustomerId: session.customer,
    subscriptionId: session.subscription,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Also create/update subscription record
  const subscriptionRef = db.collection('subscriptions').doc(userId);
  await subscriptionRef.set({
    userId: userId,
    status: 'active',
    plan: planType,
    stripeCustomerId: session.customer,
    subscriptionId: session.subscription,
    startDate: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  
  console.log(`Subscription activated for user ${userId}`);
}

async function updateUserSubscription(subscription) {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const query = usersRef.where('stripeCustomerId', '==', subscription.customer);
  const snapshot = await query.get();
  
  if (!snapshot.empty) {
    const userDoc = snapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: subscription.status,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update subscription record
    const subscriptionRef = db.collection('subscriptions').doc(userDoc.id);
    await subscriptionRef.update({
      status: subscription.status,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Subscription updated for customer ${subscription.customer}`);
  }
}

async function cancelUserSubscription(subscription) {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const query = usersRef.where('stripeCustomerId', '==', subscription.customer);
  const snapshot = await query.get();
  
  if (!snapshot.empty) {
    const userDoc = snapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: 'canceled',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update subscription record
    const subscriptionRef = db.collection('subscriptions').doc(userDoc.id);
    await subscriptionRef.update({
      status: 'canceled',
      endDate: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Subscription canceled for customer ${subscription.customer}`);
  }
}

async function handleFailedPayment(invoice) {
  const customerId = invoice.customer;
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const query = usersRef.where('stripeCustomerId', '==', customerId);
  const snapshot = await query.get();
  
  if (!snapshot.empty) {
    const userDoc = snapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: 'past_due',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update subscription record
    const subscriptionRef = db.collection('subscriptions').doc(userDoc.id);
    await subscriptionRef.update({
      status: 'past_due',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Payment failed for customer ${customerId}`);
  }
}
