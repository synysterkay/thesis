// Payment Manager for handling Stripe payments and subscriptions
class PaymentManager {
  constructor() {
    this.stripe = null;
    this.selectedPlan = null;
    this.isProcessing = false;
    this.currentUser = null;
    this.plans = {
      weekly: {
        priceId: 'price_1RbhGMEHyyRHgrPiSXQFnnrT',
        price: 9.99,
        interval: 'week',
        name: 'Weekly Plan',
        description: 'Perfect for short-term projects',
        features: [
          'AI-powered thesis generation',
          'All citation formats (APA, MLA, Chicago)',
          'Unlimited revisions',
          'Export to PDF/Word',
          '7 days of access'
        ]
      },
      monthly: {
        priceId: 'price_1RbhH1EHyyRHgrPiijEs1rTB',
        price: 26.99,
        interval: 'month',
        name: 'Monthly Plan',
        description: 'Best value for ongoing work',
        features: [
          'AI-powered thesis generation',
          'All citation formats (APA, MLA, Chicago)',
          'Unlimited revisions',
          'Export to PDF/Word',
          'Priority support',
          '30 days of access',
          'Advanced AI models'
        ]
      }
    };
    this.init();
  }

  async init() {
    try {
      // Initialize Stripe with your publishable key
      this.stripe = Stripe('pk_live_51IwsyLEHyyRHgrPiQTfkXDJVqQbdIS1RGqOEyRdsMFBbxnx8G8Qoid4iGZxpLv5lX43YA0X2qzdYoWJRZHGexYaB00Xan2xYkh');
      console.log('💳 Stripe initialized successfully');
      
      // Listen for auth state changes
      if (window.auth) {
        window.auth.onAuthStateChanged((user) => {
          this.currentUser = user;
          if (user) {
            console.log('👤 User authenticated for payments:', user.email);
          }
        });
      }
      
      // Initialize event listeners
      this.initializeEventListeners();
      
    } catch (error) {
      console.error('❌ Error initializing Stripe:', error);
      this.showError('Failed to initialize payment system. Please refresh the page.');
    }
  }

  initializeEventListeners() {
    // Plan selection buttons
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-plan]')) {
        const planType = e.target.getAttribute('data-plan');
        this.selectPlan(planType);
      }
      
      // Payment form submission
      if (e.target.matches('#submit-payment')) {
        e.preventDefault();
        this.processPayment();
      }
      
      // Modal close buttons
      if (e.target.matches('.close-modal, .modal-backdrop')) {
        this.closeModal('payment-modal');
      }
    });

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.closeModal('payment-modal');
      }
    });
  }

  selectPlan(planType) {
    if (!this.plans[planType]) {
      console.error('❌ Invalid plan type:', planType);
      return;
    }

    this.selectedPlan = planType;
    console.log('📋 Plan selected:', planType);
    
    // Track plan selection
    this.trackEvent('plan_selected', {
      plan_type: planType,
      plan_name: this.plans[planType].name,
      price: this.plans[planType].price
    });
    
    // Update UI
    this.updatePlanSelection(planType);
    
    // Show payment modal
    this.showPaymentModal();
  }

  updatePlanSelection(selectedPlan) {
    const planCards = document.querySelectorAll('.plan-option, [data-plan]');
    planCards.forEach(card => {
      card.classList.remove('selected', 'active');
      if (card.dataset.plan === selectedPlan || card.getAttribute('data-plan') === selectedPlan) {
        card.classList.add('selected', 'active');
      }
    });
  }

  showPaymentModal() {
    const modal = document.getElementById('payment-modal');
    const plan = this.plans[this.selectedPlan];
    
    if (!modal || !plan) {
      console.error('❌ Payment modal or plan not found');
      return;
    }

    try {
      // Update modal content
      this.updateModalContent(plan);
      
      // Show modal with animation
      modal.style.display = 'flex';
      modal.classList.add('show');
      document.body.classList.add('no-scroll');
      
      // Focus management for accessibility
      const firstFocusable = modal.querySelector('button, input, select, textarea, [tabindex]:not([tabindex="-1"])');
      if (firstFocusable) {
        firstFocusable.focus();
      }
      
      // Track modal shown
      this.trackEvent('payment_modal_shown', {
        plan_type: this.selectedPlan,
        plan_name: plan.name
      });
      
    } catch (error) {
      console.error('❌ Error showing payment modal:', error);
      this.showError('Failed to open payment modal. Please try again.');
    }
  }

  updateModalContent(plan) {
    // Update plan details
    const elements = {
      'selected-plan-title': plan.name,
      'selected-plan-price': `$${plan.price}/${plan.interval}`,
      'selected-plan-description': plan.description
    };

    Object.entries(elements).forEach(([id, content]) => {
      const element = document.getElementById(id);
      if (element) {
        element.textContent = content;
      }
    });

    // Update features list
    const featuresList = document.getElementById('plan-features-list');
    if (featuresList && plan.features) {
      featuresList.innerHTML = plan.features
        .map(feature => `<li><span class="feature-check">✓</span> ${feature}</li>`)
        .join('');
    }

    // Update pricing display
    const pricingElement = document.getElementById('plan-pricing');
    if (pricingElement) {
      pricingElement.innerHTML = `
        <div class="price-display">
          <span class="currency">$</span>
          <span class="amount">${plan.price}</span>
          <span class="period">/${plan.interval}</span>
        </div>
      `;
    }
  }

  async processPayment() {
    if (!this.selectedPlan || this.isProcessing) {
      return;
    }

    // Check if user is authenticated
    if (!this.currentUser) {
      this.showError('Please sign in to continue with payment.');
      return;
    }

    this.isProcessing = true;
    const submitButton = document.getElementById('submit-payment');
    
    try {
      // Update UI to loading state
      this.setLoadingState(submitButton, true);
      
      const plan = this.plans[this.selectedPlan];
      
      // Track payment attempt
      this.trackEvent('payment_attempt', {
        plan_type: this.selectedPlan,
        plan_name: plan.name,
        price: plan.price,
        user_id: this.currentUser.uid
      });

      // Initialize Stripe Checkout
      await this.initializeStripeCheckout(plan.priceId, plan.name);
      
    } catch (error) {
      console.error('❌ Payment error:', error);
      this.handlePaymentError(error);
      
      // Track payment error
      this.trackEvent('payment_error', {
        plan_type: this.selectedPlan,
        error_message: error.message,
        user_id: this.currentUser?.uid
      });
      
    } finally {
      this.isProcessing = false;
      this.setLoadingState(submitButton, false);
    }
  }

  async initializeStripeCheckout(priceId, planName) {
    try {
      const checkoutOptions = {
        mode: 'subscription',
        lineItems: [{
          price: priceId,
          quantity: 1,
        }],
        successUrl: `${window.location.origin}/success.html?session_id={CHECKOUT_SESSION_ID}`,
        cancelUrl: `${window.location.origin}/cancel.html`,
        clientReferenceId: this.currentUser.uid,
        customerEmail: this.currentUser.email,
        allowPromotionCodes: true,
        billingAddressCollection: 'required',
        subscriptionData: {
          description: `${planName} - Thesis Generator Subscription`
        }
      };

      console.log('🚀 Redirecting to Stripe Checkout...');
      
      const { error } = await this.stripe.redirectToCheckout(checkoutOptions);

      if (error) {
        throw error;
      }
      
    } catch (error) {
      console.error('❌ Stripe checkout error:', error);
      throw error;
    }
  }

  handlePaymentError(error) {
    let errorMessage = 'Payment failed. Please try again.';
    
    // Handle specific error types
    if (error.type === 'card_error') {
      errorMessage = error.message;
    } else if (error.type === 'validation_error') {
      errorMessage = 'Please check your payment information and try again.';
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    this.showError(errorMessage);
  }

  setLoadingState(button, isLoading) {
    if (!button) return;
    
    if (isLoading) {
      button.classList.add('loading');
      button.disabled = true;
      button.innerHTML = `
        <span class="loading-spinner"></span>
        Processing...
      `;
    } else {
      button.classList.remove('loading');
      button.disabled = false;
      button.innerHTML = `
        <span>Complete Payment</span>
        <span class="button-arrow">→</span>
      `;
    }
  }

  showError(message) {
    // Show error in modal if open
    const errorEl = document.getElementById('payment-error');
    if (errorEl) {
      errorEl.textContent = message;
      errorEl.classList.add('show');
      
      setTimeout(() => {
        errorEl.classList.remove('show');
      }, 5000);
    }
    
    // Also show toast notification
    this.showToast(message, 'error');
  }

  showSuccess(message) {
    this.showToast(message, 'success');
  }

  showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
      <div class="toast-content">
        <span class="toast-icon">${type === 'error' ? '❌' : type === 'success' ? '✅' : 'ℹ️'}</span>
        <span class="toast-message">${message}</span>
      </div>
    `;
    
    // Add styles
    toast.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: ${type === 'error' ? '#ff4757' : type === 'success' ? '#2ed573' : '#5352ed'};
      color: white;
      padding: 1rem 1.5rem;
      border-radius: 8px;
      font-weight: 600;
      z-index: 10001;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      animation: slideInRight 0.3s ease;
      max-width: 400px;
      word-wrap: break-word;
    `;
    
    document.body.appendChild(toast);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
      toast.style.animation = 'slideOutRight 0.3s ease';
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast);
        }
      }, 300);
    }, 5000);
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('show');
      setTimeout(() => {
        modal.style.display = 'none';
      }, 300);
      document.body.classList.remove('no-scroll');
      
      // Return focus to trigger element
      const planButtons = document.querySelectorAll('[data-plan]');
      if (planButtons.length > 0) {
        planButtons[0].focus();
      }
    }
  }

  // Utility methods
  getPlan(planType) {
    return this.plans[planType] || null;
  }

  getAllPlans() {
    return this.plans;
  }

  getCurrentPlan() {
    return this.selectedPlan ? this.plans[this.selectedPlan] : null;
  }

  isValidPlan(planType) {
    return planType && this.plans.hasOwnProperty(planType);
  }

  // Analytics tracking
  trackEvent(eventName, properties = {}) {
    try {
      // Google Analytics
      if (typeof gtag !== 'undefined') {
        gtag('event', eventName, {
          event_category: 'Payment',
          ...properties
        });
      }
      
      // Console logging for development
      console.log('📊 Payment Event:', eventName, properties);
      
    } catch (error) {
      console.error('❌ Error tracking event:', error);
    }
  }

  // Subscription management
  async checkSubscriptionStatus() {
    if (!this.currentUser) {
      return null;
    }

    try {
      // This would typically call your backend API
      // For now, we'll check localStorage or make a Firestore query
      const response = await fetch(`/api/subscription/${this.currentUser.uid}`, {
        headers: {
          'Authorization': `Bearer ${await this.currentUser.getIdToken()}`
        }
      });
      
      if (response.ok) {
        const subscription = await response.json();
        return subscription;
      }
      
    } catch (error) {
      console.error('❌ Error checking subscription:', error);
    }
    
    return null;
  }

  // Price formatting
  formatPrice(price, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency
    }).format(price);
  }

  // Validation
  validatePaymentForm() {
    // Add any form validation logic here
    return true;
  }

  // Cleanup
  destroy() {
    this.stripe = null;
    this.selectedPlan = null;
    this.currentUser = null;
    this.isProcessing = false;
  }
}

// Create global instance
window.paymentManager = new PaymentManager();

// Global functions for backward compatibility
window.selectPlan = function(planType) {
  window.paymentManager.selectPlan(planType);
};

window.processPayment = function() {
  window.paymentManager.processPayment();
};

window.closePaymentModal = function() {
  window.paymentManager.closeModal('payment-modal');
};

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = PaymentManager;
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('💳 Payment Manager initialized');
  });
} else {
  console.log('💳 Payment Manager initialized');
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
  @keyframes slideInRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
  
  @keyframes slideOutRight {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(100%);
      opacity: 0;
    }
  }
  
  .loading-spinner {
    display: inline-block;
    width: 16px;
    height: 16px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top: 2px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-right: 8px;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  .toast-content {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .payment-error {
    background: #fee;
    color: #c33;
    padding: 1rem;
    border-radius: 8px;
    margin: 1rem 0;
    border-left: 4px solid #c33;
    display: none;
  }
  
  .payment-error.show {
    display: block;
    animation: fadeInUp 0.3s ease;
  }
  
  @keyframes fadeInUp {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
`;

document.head.appendChild(style);

console.log('💳 Payment Manager loaded successfully');

