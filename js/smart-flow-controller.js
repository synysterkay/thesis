import { auth, db, functions } from './firebase-config.js';
import { 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  GoogleAuthProvider,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
  httpsCallable
} from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// User states
const USER_STATES = {
  ANONYMOUS: 'anonymous',
  AUTHENTICATED_NO_SUB: 'authenticated_no_subscription',
  AUTHENTICATED_SUBSCRIBED: 'authenticated_subscribed'
};

// Actions that require authentication only
const AUTH_REQUIRED = ['save_thesis', 'view_history', 'account_settings', 'dashboard'];

// Actions that require subscription
const SUBSCRIPTION_REQUIRED = ['generate_thesis', 'export_pdf', 'advanced_features', 'access_app'];

class SmartFlowController {
  constructor() {
    this.user = null;
    this.userState = USER_STATES.ANONYMOUS;
    this.subscriptionStatus = 'inactive';
    this.subscriptionPlan = null;
    this.unsubscribeAuth = null;
    this.unsubscribeUser = null;
    
    this.init();
  }

  async init() {
    console.log('🎯 Initializing Smart Flow Controller...');
    
    // Initialize UI components
    this.initTopBar();
    this.initAuthModal();
    this.initMenuDropdown();
    this.bindEvents();
    
    // Listen for auth state changes
    this.unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      this.handleAuthStateChange(user);
    });
    
    console.log('✅ Smart Flow Controller initialized');
  }

  // Handle authentication state changes
  async handleAuthStateChange(user) {
    console.log('🔄 Auth state changed:', user ? 'Logged in' : 'Logged out');
    
    this.user = user;
    
    if (user) {
      // User is authenticated, get subscription status
      await this.loadUserSubscription();
      this.listenToUserChanges();
    } else {
      // User is not authenticated
      this.userState = USER_STATES.ANONYMOUS;
      this.subscriptionStatus = 'inactive';
      this.subscriptionPlan = null;
      
      if (this.unsubscribeUser) {
        this.unsubscribeUser();
        this.unsubscribeUser = null;
      }
    }
    
    this.updateUI();
  }

  // Load user subscription status from Firestore
  async loadUserSubscription() {
    try {
      const userDoc = await getDoc(doc(db, 'users', this.user.uid));
      
      if (userDoc.exists()) {
        const userData = userDoc.data();
        this.subscriptionStatus = userData.subscriptionStatus || 'inactive';
        this.subscriptionPlan = userData.subscriptionPlan || null;
        
        // Update user state
        this.userState = this.subscriptionStatus === 'active' 
          ? USER_STATES.AUTHENTICATED_SUBSCRIBED 
          : USER_STATES.AUTHENTICATED_NO_SUB;
      } else {
        // Create user document if it doesn't exist
        await this.createUserDocument();
      }
    } catch (error) {
      console.error('Error loading user subscription:', error);
      this.userState = USER_STATES.AUTHENTICATED_NO_SUB;
    }
  }

  // Listen to real-time user document changes
  listenToUserChanges() {
    if (!this.user) return;
    
    this.unsubscribeUser = onSnapshot(doc(db, 'users', this.user.uid), (doc) => {
      if (doc.exists()) {
        const userData = doc.data();
        const newStatus = userData.subscriptionStatus || 'inactive';
        const newPlan = userData.subscriptionPlan || null;
        
        // Check if subscription status changed
        if (newStatus !== this.subscriptionStatus) {
          console.log('🔄 Subscription status changed:', this.subscriptionStatus, '→', newStatus);
          this.subscriptionStatus = newStatus;
          this.subscriptionPlan = newPlan;
          
          // Update user state
          this.userState = this.subscriptionStatus === 'active' 
            ? USER_STATES.AUTHENTICATED_SUBSCRIBED 
            : USER_STATES.AUTHENTICATED_NO_SUB;
          
          this.updateUI();
          
          // Show success message if user just subscribed
          if (newStatus === 'active') {
            this.showSuccessMessage('🎉 Subscription activated! You now have full access.');
          }
        }
      }
    });
  }

  // Create user document in Firestore
  async createUserDocument() {
    try {
      await setDoc(doc(db, 'users', this.user.uid), {
        uid: this.user.uid,
        email: this.user.email,
        displayName: this.user.displayName || '',
        photoURL: this.user.photoURL || '',
        subscriptionStatus: 'inactive',
        subscriptionPlan: null,
        createdAt: new Date(),
        lastLogin: new Date()
      });
      
      this.userState = USER_STATES.AUTHENTICATED_NO_SUB;
      this.subscriptionStatus = 'inactive';
    } catch (error) {
      console.error('Error creating user document:', error);
    }
  }

  // Universal action handler with smart flow control
  async handleAction(action, element = null) {
    console.log('🎯 Handling action:', action, 'User state:', this.userState);
    
    // Show loading state
    if (element) {
      element.classList.add('loading');
    }
    
    try {
      // Check if action requires authentication
      if (AUTH_REQUIRED.includes(action) || SUBSCRIPTION_REQUIRED.includes(action)) {
        if (this.userState === USER_STATES.ANONYMOUS) {
          this.showAuthModal();
          return false;
        }
      }
      
      // Check if action requires subscription
      if (SUBSCRIPTION_REQUIRED.includes(action)) {
        if (this.userState === USER_STATES.AUTHENTICATED_NO_SUB) {
          await this.triggerSuperwall(action);
          return false;
        }
      }
      
      // Execute the action
      return await this.executeAction(action);
      
    } finally {
      // Remove loading state
      if (element) {
        element.classList.remove('loading');
      }
    }
  }

  // Execute specific actions
  async executeAction(action) {
    console.log('✅ Executing action:', action);
    
    switch (action) {
      case 'access_app':
        this.loadFlutterApp();
        break;
        
      case 'generate_thesis':
        this.loadFlutterApp();
        break;
        
      case 'dashboard':
        this.scrollToSection('hero');
        break;
        
      case 'account_settings':
        this.showAccountModal();
        break;
        
      case 'save_thesis':
        this.showMessage('💾 Thesis saved successfully!', 'success');
        break;
        
      default:
        console.log('Unknown action:', action);
        return false;
    }
    
    return true;
  }

  // Load Flutter app for subscribed users
  async loadFlutterApp() {
    try {
      console.log('🚀 Loading Flutter app...');
      
      // Show loading overlay
      this.showLoadingOverlay('Loading Thesis Generator...');
      
      // Verify subscription status one more time
      await this.loadUserSubscription();
      
      if (this.subscriptionStatus !== 'active') {
        this.hideLoadingOverlay();
        await this.triggerSuperwall('access_app');
        return;
      }
      
      // Load app.html content via AJAX
      const response = await fetch('app.html');
      const appContent = await response.text();
      
      // Create app container
      const appContainer = document.createElement('div');
      appContainer.id = 'flutter-app-container';
      appContainer.innerHTML = appContent;
      
      // Hide main content and show app
      document.querySelector('main').style.display = 'none';
      document.body.appendChild(appContainer);
      
      // Update top bar for app mode
      this.updateTopBarForApp();
      
      this.hideLoadingOverlay();
      
      // Track app access
      this.trackEvent('app_accessed', { user_id: this.user.uid });
      
    } catch (error) {
      console.error('Error loading Flutter app:', error);
      this.hideLoadingOverlay();
      this.showMessage('❌ Failed to load app. Please try again.', 'error');
    }
  }

  // Trigger Superwall paywall
  async triggerSuperwall(action) {
    console.log('💳 Triggering Superwall for action:', action);
    
    try {
      // Show subscription required message
      this.showSubscriptionModal(action);
      
      // Track paywall trigger
      this.trackEvent('paywall_triggered', { 
        action: action,
        user_id: this.user?.uid || 'anonymous'
      });
      
    } catch (error) {
      console.error('Error triggering Superwall:', error);
      this.showMessage('❌ Unable to load subscription options. Please try again.', 'error');
    }
  }

  // Initialize top bar
  initTopBar() {
    const topBar = document.createElement('div');
    topBar.id = 'topbar';
    topBar.className = 'topbar';
    topBar.innerHTML = `
      <div class="topbar-left">
        <div class="logo" onclick="smartFlow.scrollToSection('hero')">
          🎓 Thesis Generator
        </div>
      </div>
      <div class="topbar-center">
        <nav class="main-nav">
          <a href="#home" onclick="smartFlow.scrollToSection('hero')">Home</a>
          <a href="#features" onclick="smartFlow.scrollToSection('features')">Features</a>
          <a href="#pricing" onclick="smartFlow.scrollToSection('pricing')">Pricing</a>
        </nav>
      </div>
      <div class="topbar-right">
        <div class="menu-dropdown" onclick="smartFlow.toggleMenu()">
          <span>☰</span>
          <div class="dropdown-menu" id="dropdown-menu">
            <a href="#home" onclick="smartFlow.scrollToSection('hero')">Home</a>
            <a href="#features" onclick="smartFlow.scrollToSection('features')">Features</a>
            <a href="#pricing" onclick="smartFlow.scrollToSection('pricing')">Pricing</a>
            <a href="#how-it-works" onclick="smartFlow.scrollToSection('how-it-works')">How It Works</a>
            <a href="#faq" onclick="smartFlow.scrollToSection('faq')">FAQ</a>
            <div class="dropdown-divider"></div>
            <div class="auth-section">
              <!-- Dynamic content -->
            </div>
          </div>
        </div>
        <div class="user-status" id="user-status">
          <!-- Dynamic content -->
        </div>
      </div>
    `;
    
    // Insert at the beginning of body
    document.body.insertBefore(topBar, document.body.firstChild);
    
    // Add padding to main content
    document.querySelector('main').style.paddingTop = '80px';
  }

  // Update UI based on user state
  updateUI() {
    this.updateUserStatus();
    this.updateAuthSection();
    this.updateActionButtons();
  }

  // Update user status indicator
  updateUserStatus() {
    const userStatus = document.getElementById('user-status');
    if (!userStatus) return;
    
    let statusHTML = '';
    let statusClass = '';
    let tooltipText = '';
    
    switch (this.userState) {
      case USER_STATES.ANONYMOUS:
        statusHTML = `
          <button class="auth-btn" onclick="smartFlow.showAuthModal()">
            Sign In
          </button>
        `;
        statusClass = 'anonymous';
        break;
        
      case USER_STATES.AUTHENTICATED_NO_SUB:
        statusHTML = `
          <div class="user-info">
            <img src="${this.user.photoURL || '/icons/Icon-192.png'}" alt="Profile" class="user-avatar">
            <span class="user-email">${this.user.email}</span>
            <span class="status-dot orange" title="Connected - No Subscription"></span>
          </div>
        `;
        statusClass = 'authenticated-no-sub';
        tooltipText = 'Connected - No Subscription';
        break;
        
      case USER_STATES.AUTHENTICATED_SUBSCRIBED:
        statusHTML = `
          <div class="user-info">
            <img src="${this.user.photoURL || '/icons/Icon-192.png'}" alt="Profile" class="user-avatar">
            <span class="user-email">${this.user.email}</span>
            <span class="status-dot green" title="Connected & Subscribed"></span>
          </div>
        `;
        statusClass = 'authenticated-subscribed';
        tooltipText = 'Connected & Subscribed';
        break;
    }
    
    userStatus.innerHTML = statusHTML;
    userStatus.className = `user-status ${statusClass}`;
    
    // Add tooltip
    if (tooltipText) {
      userStatus.setAttribute('title', tooltipText);
    }
  }

  // Update auth section in dropdown menu
  updateAuthSection() {
    const authSection = document.querySelector('.auth-section');
    if (!authSection) return;
    
    let authHTML = '';
    
    switch (this.userState) {
      case USER_STATES.ANONYMOUS:
        authHTML = `
          <a href="#" onclick="smartFlow.showAuthModal()">Sign In</a>
          <a href="#" onclick="smartFlow.showAuthModal('signup')">Sign Up</a>
        `;
        break;
        
      case USER_STATES.AUTHENTICATED_NO_SUB:
        authHTML = `
          <a href="#" onclick="smartFlow.handleAction('account_settings')">Account Settings</a>
          <a href="#" onclick="smartFlow.handleAction('dashboard')">Dashboard</a>
          <a href="#" onclick="smartFlow.signOut()">Sign Out</a>
        `;
        break;
        
      case USER_STATES.AUTHENTICATED_SUBSCRIBED:
        authHTML = `
          <a href="#" onclick="smartFlow.handleAction('dashboard')">Dashboard</a>
          <a href="#" onclick="smartFlow.handleAction('account_settings')">Account Settings</a>
          <a href="#" onclick="smartFlow.signOut()">Sign Out</a>
        `;
        break;
    }
    
    authSection.innerHTML = authHTML;
  }

  // Update all action buttons on the page
  updateActionButtons() {
    // Update CTA buttons
    const ctaButtons = document.querySelectorAll('[data-action]');
    ctaButtons.forEach(button => {
      const action = button.getAttribute('data-action');
      const originalText = button.getAttribute('data-original-text') || button.textContent;
      
      // Store original text if not already stored
      if (!button.getAttribute('data-original-text')) {
        button.setAttribute('data-original-text', originalText);
      }
      
      // Update button text and behavior based on user state
      switch (this.userState) {
        case USER_STATES.ANONYMOUS:
          if (SUBSCRIPTION_REQUIRED.includes(action) || AUTH_REQUIRED.includes(action)) {
            button.textContent = 'Sign In to Continue';
            button.className = button.className.replace(/btn-\w+/, 'btn-auth');
          }
          break;
          
        case USER_STATES.AUTHENTICATED_NO_SUB:
          if (SUBSCRIPTION_REQUIRED.includes(action)) {
            button.textContent = 'Subscribe to Access';
            button.className = button.className.replace(/btn-\w+/, 'btn-subscribe');
          } else {
            button.textContent = originalText;
            button.className = button.className.replace(/btn-(auth|subscribe)/, 'btn-primary');
          }
          break;
          
        case USER_STATES.AUTHENTICATED_SUBSCRIBED:
          button.textContent = originalText;
          button.className = button.className.replace(/btn-(auth|subscribe)/, 'btn-primary');
          break;
      }
    });
  }

  // Show authentication modal
  showAuthModal(mode = 'signin') {
    console.log('🔐 Showing auth modal:', mode);
    
    const modal = document.getElementById('auth-modal');
    if (modal) {
      modal.style.display = 'flex';
      modal.classList.add('show');
    } else {
      this.createAuthModal(mode);
    }
    
    // Update modal content based on mode
    this.updateAuthModalContent(mode);
    
    // Track modal open
    this.trackEvent('auth_modal_opened', { mode: mode });
  }

  // Create authentication modal
  createAuthModal(mode = 'signin') {
    const modal = document.createElement('div');
    modal.id = 'auth-modal';
    modal.className = 'modal';
    modal.innerHTML = `
      <div class="modal-backdrop" onclick="smartFlow.hideAuthModal()"></div>
      <div class="modal-content">
        <div class="modal-header">
          <h2 id="auth-modal-title">Sign In to Continue</h2>
          <button class="modal-close" onclick="smartFlow.hideAuthModal()">×</button>
        </div>
        <div class="modal-body">
          <div class="auth-methods">
            <button class="google-signin-btn" onclick="smartFlow.signInWithGoogle()">
              <img src="https://developers.google.com/identity/images/g-logo.png" alt="Google">
              Continue with Google
            </button>
            
            <div class="divider">
              <span>or</span>
            </div>
            
            <form class="email-auth-form" id="email-auth-form">
              <div class="form-group">
                <input type="email" id="auth-email" placeholder="Email address" required>
              </div>
              <div class="form-group">
                <input type="password" id="auth-password" placeholder="Password" required>
              </div>
              <button type="submit" class="email-auth-btn" id="email-auth-btn">
                Sign In
              </button>
            </form>
            
            <div class="auth-switch">
              <p id="auth-switch-text">
                Don't have an account? 
                <a href="#" onclick="smartFlow.switchAuthMode('signup')">Sign up</a>
              </p>
            </div>
          </div>
          
          <div class="auth-benefits">
            <h3>Why create an account?</h3>
            <ul>
              <li>💾 Save your thesis progress</li>
              <li>📚 Access your thesis history</li>
              <li>⚡ Faster generation with saved preferences</li>
              <li>🔒 Secure cloud storage</li>
            </ul>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    
    // Bind form submission
    document.getElementById('email-auth-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.handleEmailAuth();
    });
    
    this.updateAuthModalContent(mode);
  }

  // Update auth modal content based on mode
  updateAuthModalContent(mode) {
    const title = document.getElementById('auth-modal-title');
    const submitBtn = document.getElementById('email-auth-btn');
    const switchText = document.getElementById('auth-switch-text');
    
    if (mode === 'signup') {
      title.textContent = 'Create Your Account';
      submitBtn.textContent = 'Create Account';
      switchText.innerHTML = 'Already have an account? <a href="#" onclick="smartFlow.switchAuthMode(\'signin\')">Sign in</a>';
    } else {
      title.textContent = 'Sign In to Continue';
      submitBtn.textContent = 'Sign In';
      switchText.innerHTML = 'Don\'t have an account? <a href="#" onclick="smartFlow.switchAuthMode(\'signup\')">Sign up</a>';
    }
    
    // Store current mode
    document.getElementById('auth-modal').setAttribute('data-mode', mode);
  }

  // Switch between signin and signup modes
  switchAuthMode(mode) {
    this.updateAuthModalContent(mode);
    
    // Clear form
    document.getElementById('auth-email').value = '';
    document.getElementById('auth-password').value = '';
  }

  // Hide authentication modal
  hideAuthModal() {
    const modal = document.getElementById('auth-modal');
    if (modal) {
      modal.classList.remove('show');
      setTimeout(() => {
        modal.style.display = 'none';
      }, 300);
    }
  }

  // Sign in with Google
  async signInWithGoogle() {
    try {
      console.log('🔐 Signing in with Google...');
      
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      
      console.log('✅ Google sign-in successful:', result.user.email);
      
      this.hideAuthModal();
      this.showMessage('✅ Successfully signed in with Google!', 'success');
      
      // Track sign-in
      this.trackEvent('user_signed_in', { 
        method: 'google',
        user_id: result.user.uid 
      });
      
    } catch (error) {
      console.error('Google sign-in error:', error);
      this.showMessage('❌ Failed to sign in with Google. Please try again.', 'error');
      
      // Track error
      this.trackEvent('auth_error', { 
        method: 'google',
        error: error.code 
      });
    }
  }

  // Handle email authentication (signin/signup)
  async handleEmailAuth() {
    const email = document.getElementById('auth-email').value;
    const password = document.getElementById('auth-password').value;
    const mode = document.getElementById('auth-modal').getAttribute('data-mode');
    
    if (!email || !password) {
      this.showMessage('❌ Please fill in all fields.', 'error');
      return;
    }
    
    try {
      console.log('🔐 Email auth:', mode, email);
      
      let result;
      if (mode === 'signup') {
        result = await createUserWithEmailAndPassword(auth, email, password);
        this.showMessage('✅ Account created successfully!', 'success');
      } else {
        result = await signInWithEmailAndPassword(auth, email, password);
        this.showMessage('✅ Successfully signed in!', 'success');
      }
      
      console.log('✅ Email auth successful:', result.user.email);
      
      this.hideAuthModal();
      
      // Track auth
      this.trackEvent('user_signed_in', { 
        method: 'email',
        mode: mode,
        user_id: result.user.uid 
      });
      
    } catch (error) {
      console.error('Email auth error:', error);
      
      let errorMessage = '❌ Authentication failed. Please try again.';
      
      switch (error.code) {
        case 'auth/user-not-found':
          errorMessage = '❌ No account found with this email.';
          break;
        case 'auth/wrong-password':
          errorMessage = '❌ Incorrect password.';
          break;
        case 'auth/email-already-in-use':
          errorMessage = '❌ An account with this email already exists.';
          break;
        case 'auth/weak-password':
          errorMessage = '❌ Password should be at least 6 characters.';
          break;
        case 'auth/invalid-email':
          errorMessage = '❌ Please enter a valid email address.';
          break;
      }
      
      this.showMessage(errorMessage, 'error');
      
      // Track error
      this.trackEvent('auth_error', { 
        method: 'email',
        mode: mode,
        error: error.code 
      });
    }
  }

  // Sign out
  async signOut() {
    try {
      console.log('🔐 Signing out...');
      
      await signOut(auth);
      
      // Hide Flutter app if loaded
      const appContainer = document.getElementById('flutter-app-container');
      if (appContainer) {
        appContainer.remove();
        document.querySelector('main').style.display = 'block';
        this.updateTopBarForMain();
      }
      
      this.showMessage('✅ Successfully signed out.', 'success');
      
      // Track sign-out
      this.trackEvent('user_signed_out');
      
    } catch (error) {
      console.error('Sign-out error:', error);
      this.showMessage('❌ Failed to sign out. Please try again.', 'error');
    }
  }

  // Show subscription modal
  showSubscriptionModal(action) {
    const modal = document.createElement('div');
    modal.id = 'subscription-modal';
    modal.className = 'modal';
    modal.innerHTML = `
      <div class="modal-backdrop" onclick="smartFlow.hideSubscriptionModal()"></div>
      <div class="modal-content subscription-modal-content">
        <div class="modal-header">
          <h2>Subscription Required</h2>
          <button class="modal-close" onclick="smartFlow.hideSubscriptionModal()">×</button>
        </div>
        <div class="modal-body">
          <div class="subscription-message">
            <div class="subscription-icon">🔒</div>
            <h3>Unlock Full Access</h3>
            <p>Subscribe to access thesis generation and all premium features.</p>
          </div>
          
          <div class="pricing-options">
            <div class="pricing-card">
              <h4>Weekly Plan</h4>
              <div class="price">$9.99<span>/week</span></div>
              <ul>
                <li>✅ Unlimited thesis generation</li>
                <li>✅ All citation formats</li>
                <li>✅ PDF export</li>
                <li>✅ Priority support</li>
              </ul>
              <button class="subscribe-btn" onclick="smartFlow.subscribe('weekly')">
                Choose Weekly
              </button>
            </div>
            
            <div class="pricing-card featured">
              <div class="popular-badge">Most Popular</div>
              <h4>Monthly Plan</h4>
              <div class="price">$26.99<span>/month</span></div>
              <div class="savings">Save 30%</div>
              <ul>
                <li>✅ Unlimited thesis generation</li>
                <li>✅ All citation formats</li>
                <li>✅ PDF export</li>
                <li>✅ Priority support</li>
                <li>✅ Advanced AI features</li>
              </ul>
              <button class="subscribe-btn primary" onclick="smartFlow.subscribe('monthly')">
                Choose Monthly
              </button>
            </div>
          </div>
          
          <div class="subscription-footer">
            <p>💳 Secure payment • 📱 Cancel anytime • 🔒 Privacy protected</p>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    modal.style.display = 'flex';
    modal.classList.add('show');
  }

  // Hide subscription modal
  hideSubscriptionModal() {
    const modal = document.getElementById('subscription-modal');
    if (modal) {
      modal.classList.remove('show');
      setTimeout(() => {
        modal.remove();
      }, 300);
    }
  }

  // Subscribe (integrate with Superwall)
  async subscribe(plan) {
    console.log('💳 Subscribing to plan:', plan);
    
    try {
      // Here you would integrate with Superwall SDK
      // For now, we'll simulate the subscription process
      
      this.showMessage('🔄 Processing subscription...', 'info');
      
      // Track subscription attempt
      this.trackEvent('subscription_attempted', { 
        plan: plan,
        user_id: this.user?.uid || 'anonymous'
      });
      
      // TODO: Replace with actual Superwall integration
      // Example: Superwall.present('subscription_required', { plan: plan });
      
      // For demo purposes, simulate successful subscription after 2 seconds
      setTimeout(() => {
        this.simulateSuccessfulSubscription(plan);
      }, 2000);
      
    } catch (error) {
      console.error('Subscription error:', error);
      this.showMessage('❌ Subscription failed. Please try again.', 'error');
    }
  }

  // Simulate successful subscription (remove when Superwall is integrated)
  async simulateSuccessfulSubscription(plan) {
    try {
      // Update user document in Firestore
      await updateDoc(doc(db, 'users', this.user.uid), {
        subscriptionStatus: 'active',
        subscriptionPlan: plan,
        lastUpdated: new Date()
      });
      
      this.hideSubscriptionModal();
      this.showMessage('🎉 Subscription successful! Welcome to premium!', 'success');
      
      // Track successful subscription
      this.trackEvent('subscription_successful', { 
        plan: plan,
        user_id: this.user.uid
      });
      
    } catch (error) {
      console.error('Error updating subscription:', error);
    }
  }

  // Utility methods
  scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
      section.scrollIntoView({ behavior: 'smooth' });
    }
  }

  toggleMenu() {
    const menu = document.getElementById('dropdown-menu');
    if (menu) {
      menu.classList.toggle('show');
    }
  }

  showMessage(message, type = 'info') {
    // Remove existing messages
    const existingMessages = document.querySelectorAll('.toast-message');
    existingMessages.forEach(msg => msg.remove());
    
       const toast = document.createElement('div');
    toast.className = `toast-message toast-${type}`;
    toast.innerHTML = `
      <div class="toast-content">
        <span class="toast-text">${message}</span>
        <button class="toast-close" onclick="this.parentElement.parentElement.remove()">×</button>
      </div>
    `;
    
    document.body.appendChild(toast);
    
    // Show toast
    setTimeout(() => toast.classList.add('show'), 100);
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }, 5000);
  }

  showSuccessMessage(message) {
    this.showMessage(message, 'success');
  }

  showLoadingOverlay(message = 'Loading...') {
    let overlay = document.getElementById('loading-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'loading-overlay';
      overlay.className = 'loading-overlay';
      overlay.innerHTML = `
        <div class="loading-content">
          <div class="loading-spinner"></div>
          <p class="loading-text">${message}</p>
        </div>
      `;
      document.body.appendChild(overlay);
    }
    
    overlay.style.display = 'flex';
    overlay.classList.add('show');
  }

  hideLoadingOverlay() {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
      overlay.classList.remove('show');
      setTimeout(() => {
        overlay.style.display = 'none';
      }, 300);
    }
  }

  updateTopBarForApp() {
    const topBar = document.getElementById('topbar');
    if (topBar) {
      topBar.classList.add('app-mode');
      
      // Add back button
      const backBtn = document.createElement('button');
      backBtn.className = 'back-btn';
      backBtn.innerHTML = '← Back to Home';
      backBtn.onclick = () => this.returnToMain();
      
      const topBarLeft = topBar.querySelector('.topbar-left');
      topBarLeft.appendChild(backBtn);
    }
  }

  updateTopBarForMain() {
    const topBar = document.getElementById('topbar');
    if (topBar) {
      topBar.classList.remove('app-mode');
      
      // Remove back button
      const backBtn = topBar.querySelector('.back-btn');
      if (backBtn) {
        backBtn.remove();
      }
    }
  }

  returnToMain() {
    const appContainer = document.getElementById('flutter-app-container');
    if (appContainer) {
      appContainer.remove();
    }
    
    document.querySelector('main').style.display = 'block';
    this.updateTopBarForMain();
    this.scrollToSection('hero');
  }

  bindEvents() {
    // Bind all action buttons
    document.addEventListener('click', (e) => {
      const actionElement = e.target.closest('[data-action]');
      if (actionElement) {
        e.preventDefault();
        const action = actionElement.getAttribute('data-action');
        this.handleAction(action, actionElement);
      }
    });

    // Close dropdowns when clicking outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.menu-dropdown')) {
        const menu = document.getElementById('dropdown-menu');
        if (menu) {
          menu.classList.remove('show');
        }
      }
    });

    // Handle escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        // Close modals
        this.hideAuthModal();
        this.hideSubscriptionModal();
        
        // Close dropdown menu
        const menu = document.getElementById('dropdown-menu');
        if (menu) {
          menu.classList.remove('show');
        }
      }
    });

    // Handle scroll for top bar
    let lastScrollTop = 0;
    window.addEventListener('scroll', () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      const topBar = document.getElementById('topbar');
      
      if (topBar) {
        if (scrollTop > lastScrollTop && scrollTop > 100) {
          // Scrolling down
          topBar.classList.add('hidden');
        } else {
          // Scrolling up
          topBar.classList.remove('hidden');
        }
      }
      
      lastScrollTop = scrollTop;
    });
  }

  initMenuDropdown() {
    // Menu dropdown is initialized in initTopBar
    // This method can be used for additional dropdown functionality
  }

  trackEvent(eventName, parameters = {}) {
    try {
      // Google Analytics 4
      if (typeof gtag !== 'undefined') {
        gtag('event', eventName, parameters);
      }
      
      // Console log for debugging
      console.log('📊 Event tracked:', eventName, parameters);
      
      // Firebase Analytics (if available)
      if (window.fbAnalytics) {
        // logEvent(analytics, eventName, parameters);
      }
    } catch (error) {
      console.error('Error tracking event:', error);
    }
  }

  // Cleanup method
  destroy() {
    if (this.unsubscribeAuth) {
      this.unsubscribeAuth();
    }
    if (this.unsubscribeUser) {
      this.unsubscribeUser();
    }
  }
}

// Initialize Smart Flow Controller
const smartFlow = new SmartFlowController();

// Make it globally available
window.smartFlow = smartFlow;

// Export for module usage
export default SmartFlowController;


