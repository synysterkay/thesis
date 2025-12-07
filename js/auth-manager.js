import { auth, db } from './firebase-config.js';
import {
  onAuthStateChanged,
  signInWithPopup,
  GoogleAuthProvider,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  updateProfile,
  sendPasswordResetEmail
} from 'firebase/auth';
import { doc, setDoc, getDoc, updateDoc, collection, query, where, getDocs, orderBy, limit } from 'firebase/firestore';

class AuthManager {
  constructor() {
    this.user = null;
    this.authStateCallbacks = [];
    this.subscriptionStatus = null;
    this.subscriptionData = null;
    this.init();
  }

  init() {
    console.log('🔐 Initializing Auth Manager...');
    // Listen for auth state changes
    onAuthStateChanged(auth, (user) => {
      this.user = user;
      this.handleAuthStateChange(user);
    });
  }

  // Handle authentication state changes
  async handleAuthStateChange(user) {
    console.log('🔄 Auth state changed:', user ? user.email : 'Not authenticated');
    
    if (user) {
      await this.updateLastLogin(user);
      // Check subscription status from both Firebase and Stripe
      await this.checkSubscriptionStatus(user);
    } else {
      this.subscriptionStatus = null;
      this.subscriptionData = null;
    }

    // Notify all callbacks
    this.authStateCallbacks.forEach(callback => {
      try {
        callback(user);
      } catch (error) {
        console.error('Error in auth state callback:', error);
      }
    });
  }

  // Check user's subscription status from Firebase and validate with Stripe
  async checkSubscriptionStatus(user) {
    try {
      console.log('💳 Checking subscription status for:', user.email);
      
      // Get user profile from Firebase
      const userProfile = await this.getUserProfile(user.uid);
      
      // Get subscription data from Firebase
      const subscriptionData = await this.getSubscriptionData(user.uid);
      
      if (subscriptionData && subscriptionData.status === 'active') {
        // Check if subscription is still valid (not expired)
        const isValid = await this.validateSubscription(subscriptionData);
        
        if (isValid) {
          this.subscriptionStatus = 'active';
          this.subscriptionData = subscriptionData;
          console.log('✅ Active subscription found:', subscriptionData.plan);
        } else {
          // Subscription expired, update status
          await this.updateSubscriptionStatus('inactive');
          this.subscriptionStatus = 'inactive';
          this.subscriptionData = null;
          console.log('⏰ Subscription expired');
        }
      } else {
        this.subscriptionStatus = 'inactive';
        this.subscriptionData = null;
        console.log('❌ No active subscription found');
      }
      
      return this.subscriptionStatus;
    } catch (error) {
      console.error('Error checking subscription status:', error);
      this.subscriptionStatus = 'inactive';
      this.subscriptionData = null;
      return 'inactive';
    }
  }

  // Get subscription data from Firebase
  async getSubscriptionData(userId) {
    try {
      // Check subscriptions collection
      const subscriptionsRef = collection(db, 'subscriptions');
      const q = query(
        subscriptionsRef,
        where('userId', '==', userId),
        where('status', '==', 'active'),
        orderBy('createdAt', 'desc'),
        limit(1)
      );
      
      const querySnapshot = await getDocs(q);
      
      if (!querySnapshot.empty) {
        const subscriptionDoc = querySnapshot.docs[0];
        return {
          id: subscriptionDoc.id,
          ...subscriptionDoc.data()
        };
      }
      
      return null;
    } catch (error) {
      console.error('Error getting subscription data:', error);
      return null;
    }
  }

  // Validate subscription (check if not expired)
  async validateSubscription(subscriptionData) {
    try {
      if (!subscriptionData.endDate) {
        // If no end date, check with Stripe or assume active
        return true;
      }
      
      const endDate = subscriptionData.endDate.toDate ? 
        subscriptionData.endDate.toDate() : 
        new Date(subscriptionData.endDate);
      
      const now = new Date();
      const isValid = endDate > now;
      
      console.log('📅 Subscription validation:', {
        endDate: endDate.toISOString(),
        now: now.toISOString(),
        isValid
      });
      
      return isValid;
    } catch (error) {
      console.error('Error validating subscription:', error);
      return false;
    }
  }

  // Subscribe to auth state changes
  onAuthStateChange(callback) {
    this.authStateCallbacks.push(callback);
    // Call immediately with current state
    callback(this.user);
    // Return unsubscribe function
    return () => {
      const index = this.authStateCallbacks.indexOf(callback);
      if (index > -1) {
        this.authStateCallbacks.splice(index, 1);
      }
    };
  }

  // Sign in with Google
  async signInWithGoogle() {
    try {
      const provider = new GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      
      const result = await signInWithPopup(auth, provider);
      const user = result.user;

      // Create or update user profile
      await this.createOrUpdateUserProfile(user);
      
      // Check subscription status
      const subscriptionStatus = await this.checkSubscriptionStatus(user);
      
      console.log('✅ Google sign-in successful:', user.email);
      
      // Handle post-authentication flow
      this.handlePostAuthFlow(user, subscriptionStatus);
      
      return { success: true, user, subscriptionStatus };
    } catch (error) {
      console.error('Google sign-in error:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Sign in with email and password
  async signInWithEmail(email, password) {
    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      const user = result.user;
      
      // Check subscription status
      const subscriptionStatus = await this.checkSubscriptionStatus(user);
      
      console.log('✅ Email sign-in successful:', user.email);
      
      // Handle post-authentication flow
      this.handlePostAuthFlow(user, subscriptionStatus);
      
      return { success: true, user, subscriptionStatus };
    } catch (error) {
      console.error('Email sign-in error:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Create account with email and password
  async createAccountWithEmail(email, password, displayName = '') {
    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      const user = result.user;

      // Update display name if provided
      if (displayName) {
        await updateProfile(user, { displayName });
      }

      // Create user profile
      await this.createOrUpdateUserProfile(user);
      
      // New users always have inactive subscription
      const subscriptionStatus = 'inactive';
      
      console.log('✅ Account created successfully:', user.email);
      
      // Handle post-authentication flow
      this.handlePostAuthFlow(user, subscriptionStatus);
      
      return { success: true, user, subscriptionStatus };
    } catch (error) {
      console.error('Account creation error:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Handle what happens after successful authentication
  handlePostAuthFlow(user, subscriptionStatus) {
    console.log('🔄 Handling post-auth flow for:', user.email, 'Status:', subscriptionStatus);
    
    // If user has active subscription, they can access the app
    if (subscriptionStatus === 'active') {
      console.log('✅ User has active subscription, redirecting to app...');
      this.showSuccessMessage('Welcome back! Redirecting to your thesis generator...');
      
      // Small delay to show success state
      setTimeout(() => {
        window.location.href = '/app.html';
      }, 1500);
    } else {
      console.log('💳 User needs subscription, showing payment options...');
      this.showSubscriptionModal();
    }
  }

  // Show success message
  showSuccessMessage(message) {
    // Create or update success message element
    let messageEl = document.getElementById('auth-success-message');
    if (!messageEl) {
      messageEl = document.createElement('div');
      messageEl.id = 'auth-success-message';
      messageEl.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: linear-gradient(45deg, #28a745, #20c997);
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        font-weight: 600;
        z-index: 10001;
        box-shadow: 0 4px 20px rgba(40, 167, 69, 0.3);
        animation: slideInRight 0.3s ease;
      `;
      document.body.appendChild(messageEl);
    }
    
    messageEl.textContent = message;
    messageEl.style.display = 'block';
    
    // Remove after delay
    setTimeout(() => {
      if (messageEl && messageEl.parentNode) {
        messageEl.style.animation = 'slideOutRight 0.3s ease';
        setTimeout(() => {
          if (messageEl && messageEl.parentNode) {
            messageEl.parentNode.removeChild(messageEl);
          }
        }, 300);
      }
    }, 3000);
  }

  // Show subscription modal
  showSubscriptionModal() {
    // Close any existing modals
    this.closeAllModals();
    
    // Show subscription modal
    const subscriptionModal = document.getElementById('subscription-modal');
    if (subscriptionModal) {
      subscriptionModal.style.display = 'flex';
      document.body.classList.add('no-scroll');
      
      // Focus management for accessibility
      const firstFocusable = subscriptionModal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      if (firstFocusable) {
        setTimeout(() => firstFocusable.focus(), 100);
      }
    } else {
      console.error('Subscription modal not found, creating fallback...');
      this.createSubscriptionModal();
    }
  }

  // Create subscription modal if it doesn't exist
  createSubscriptionModal() {
    const modal = document.createElement('div');
    modal.id = 'subscription-modal';
    modal.className = 'modal';
    modal.innerHTML = `
      <div class="modal-content subscription-modal-content">
        <div class="modal-header">
          <h2>Choose Your Plan</h2>
          <button class="modal-close" onclick="authManager.closeAllModals()">&times;</button>
        </div>
        <div class="modal-body">
          <p>To access the Thesis Generator, please choose a subscription plan:</p>
          <div class="subscription-plans">
            <div class="plan-card" data-plan="weekly">
              <h3>Weekly Plan</h3>
              <div class="plan-price">$9.99</div>
              <p>Perfect for short-term projects</p>
              <button class="plan-button" onclick="subscriptionManager.selectPlan('weekly')">
                Choose Weekly
              </button>
            </div>
            <div class="plan-card popular" data-plan="monthly">
              <h3>Monthly Plan</h3>
              <div class="plan-price">$26.99</div>
              <p>Best value for ongoing work</p>
              <button class="plan-button" onclick="subscriptionManager.selectPlan('monthly')">
                Choose Monthly
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    modal.style.display = 'flex';
    document.body.classList.add('no-scroll');
  }

  // Close all modals
  closeAllModals() {
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
      modal.style.display = 'none';
    });
    document.body.classList.remove('no-scroll');
  }

  // Check if user can access the app
  canAccessApp() {
    return this.isAuthenticated() && this.subscriptionStatus === 'active';
  }

  // Get subscription status
  getSubscriptionStatus() {
    return this.subscriptionStatus;
  }

  // Get subscription data
  getSubscriptionData() {
    return this.subscriptionData;
  }

  // Update subscription status (called after successful payment or webhook)
  async updateSubscriptionStatus(status, plan = null, endDate = null) {
    try {
      if (!this.user) {
        throw new Error('No authenticated user');
      }

      const userRef = doc(db, 'users', this.user.uid);
      const updates = {
        subscriptionStatus: status,
        lastUpdated: new Date()
      };

      if (plan) {
        updates.subscriptionPlan = plan;
      }

      await updateDoc(userRef, updates);
      
      // Also update subscription collection
      if (status === 'active' && plan) {
        const subscriptionRef = doc(db, 'subscriptions', this.user.uid);
        const subscriptionData = {
          userId: this.user.uid,
          status: status,
          plan: plan,
          createdAt: new Date(),
          lastUpdated: new Date()
        };
        
        if (endDate) {
          subscriptionData.endDate = endDate;
        }
        
        await setDoc(subscriptionRef, subscriptionData, { merge: true });
      }
      
      this.subscriptionStatus = status;
      
      console.log('✅ Subscription status updated:', status);
      
      // If subscription is now active, redirect to app
      if (status === 'active') {
        this.showSuccessMessage('Subscription activated! Redirecting to app...');
        setTimeout(() => {
          window.location.href = '/app.html';
        }, 1500);
      }
      
      return { success: true };
    } catch (error) {
      console.error('Error updating subscription status:', error);
      return { success: false, error: error.message };
    }
  }

  // Refresh subscription status (useful for checking after payment)
  async refreshSubscriptionStatus() {
    if (this.user) {
      return await this.checkSubscriptionStatus(this.user);
    }
    return 'inactive';
  }

  // Sign out
  async signOut() {
    try {
      await signOut(auth);
      this.subscriptionStatus = null;
      this.subscriptionData = null;
      console.log('✅ Sign-out successful');
      return { success: true };
       } catch (error) {
      console.error('Sign-out error:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Send password reset email
  async sendPasswordReset(email) {
    try {
      await sendPasswordResetEmail(auth, email);
      console.log('✅ Password reset email sent');
      return { success: true };
    } catch (error) {
      console.error('Password reset error:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Create or update user profile in Firestore
  async createOrUpdateUserProfile(user) {
    try {
      const userRef = doc(db, 'users', user.uid);
      const userDoc = await getDoc(userRef);
      
      const userData = {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || '',
        photoURL: user.photoURL || '',
        lastLogin: new Date(),
        lastUpdated: new Date()
      };

      if (userDoc.exists()) {
        // Update existing user
        await updateDoc(userRef, userData);
        console.log('✅ User profile updated');
      } else {
        // Create new user profile
        userData.createdAt = new Date();
        userData.subscriptionStatus = 'inactive';
        userData.subscriptionPlan = null;
        await setDoc(userRef, userData);
        console.log('✅ User profile created');
      }
    } catch (error) {
      console.error('Error creating/updating user profile:', error);
    }
  }

  // Update last login timestamp
  async updateLastLogin(user) {
    try {
      const userRef = doc(db, 'users', user.uid);
      await updateDoc(userRef, {
        lastLogin: new Date()
      });
    } catch (error) {
      console.error('Error updating last login:', error);
    }
  }

  // Get user profile from Firestore
  async getUserProfile(uid = null) {
    try {
      const userId = uid || this.user?.uid;
      if (!userId) return null;

      const userDoc = await getDoc(doc(db, 'users', userId));
      return userDoc.exists() ? userDoc.data() : null;
    } catch (error) {
      console.error('Error getting user profile:', error);
      return null;
    }
  }

  // Update user profile
  async updateUserProfile(updates) {
    try {
      if (!this.user) {
        throw new Error('No authenticated user');
      }

      // Update Firebase Auth profile if needed
      const authUpdates = {};
      if (updates.displayName !== undefined) {
        authUpdates.displayName = updates.displayName;
      }
      if (updates.photoURL !== undefined) {
        authUpdates.photoURL = updates.photoURL;
      }

      if (Object.keys(authUpdates).length > 0) {
        await updateProfile(this.user, authUpdates);
      }

      // Update Firestore profile
      const userRef = doc(db, 'users', this.user.uid);
      await updateDoc(userRef, {
        ...updates,
        lastUpdated: new Date()
      });

      console.log('✅ User profile updated');
      return { success: true };
    } catch (error) {
      console.error('Error updating user profile:', error);
      return { success: false, error: this.getErrorMessage(error) };
    }
  }

  // Check if user is authenticated
  isAuthenticated() {
    return !!this.user;
  }

  // Get current user
  getCurrentUser() {
    return this.user;
  }

  // Get user email
  getUserEmail() {
    return this.user?.email || null;
  }

  // Get user display name
  getUserDisplayName() {
    return this.user?.displayName || this.user?.email?.split('@')[0] || 'User';
  }

  // Get user photo URL
  getUserPhotoURL() {
    return this.user?.photoURL || null;
  }

  // Convert Firebase error codes to user-friendly messages
  getErrorMessage(error) {
    switch (error.code) {
      case 'auth/user-not-found':
        return 'No account found with this email address.';
      case 'auth/wrong-password':
        return 'Incorrect password. Please try again.';
      case 'auth/email-already-in-use':
        return 'An account with this email already exists.';
      case 'auth/weak-password':
        return 'Password should be at least 6 characters long.';
      case 'auth/invalid-email':
        return 'Please enter a valid email address.';
      case 'auth/user-disabled':
        return 'This account has been disabled.';
      case 'auth/too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'auth/network-request-failed':
        return 'Network error. Please check your connection.';
      case 'auth/popup-closed-by-user':
        return 'Sign-in was cancelled.';
      case 'auth/popup-blocked':
        return 'Pop-up was blocked. Please allow pop-ups and try again.';
      default:
        return error.message || 'An unexpected error occurred.';
    }
  }

  // Validate email format
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  // Validate password strength
  isValidPassword(password) {
    return password.length >= 6;
  }

  // Get password strength
  getPasswordStrength(password) {
    let strength = 0;
    let feedback = [];

    if (password.length >= 8) {
      strength += 1;
    } else {
      feedback.push('At least 8 characters');
    }

    if (/[a-z]/.test(password)) {
      strength += 1;
    } else {
      feedback.push('One lowercase letter');
    }

    if (/[A-Z]/.test(password)) {
      strength += 1;
    } else {
      feedback.push('One uppercase letter');
    }

    if (/[0-9]/.test(password)) {
      strength += 1;
    } else {
      feedback.push('One number');
    }

    if (/[^A-Za-z0-9]/.test(password)) {
      strength += 1;
    } else {
      feedback.push('One special character');
    }

    const levels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    return {
      score: strength,
      level: levels[Math.min(strength, 4)],
      feedback: feedback
    };
  }
}

// Create and export singleton instance
const authManager = new AuthManager();

// Make it globally available for inline event handlers
window.authManager = authManager;

export default authManager;

