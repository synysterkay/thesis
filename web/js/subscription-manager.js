// Subscription Manager for Stripe Integration
class SubscriptionManager {
  constructor() {
    this.stripe = null;
    this.selectedPlan = null;
    this.isProcessing = false;
    this.plans = {
      weekly: {
        priceId: 'price_1RbhGMEHyyRHgrPiSXQFnnrT',
        price: 9.99,
        interval: 'week',
        name: 'Weekly Plan'
      },
      monthly: {
        priceId: 'price_1RbhH1EHyyRHgrPiijEs1rTB',
        price: 26.99,
        interval: 'month',
        name: 'Monthly Plan'
      }
    };
    this.init();
  }

  async init() {
    try {
      // Initialize Stripe (replace with your publishable key)
      this.stripe = Stripe('pk_live_51IwsyLEHyyRHgrPiQTfkXDJVqQbdIS1RGqOEyRdsMFBbxnx8G8Qoid4iGZxpLv5lX43YA0X2qzdYoWJRZHGexYaB00Xan2xYkh'); // Replace with your actual key
      console.log('💳 Stripe initialized');
    } catch (error) {
      console.error('Error initializing Stripe:', error);
    }
  }

  // Select a plan
  selectPlan(planType) {
    if (!this.plans[planType]) {
      console.error('Invalid plan type:', planType);
      return;
    }

    this.selectedPlan = planType;
    console.log('📋 Plan selected:', planType);
    
    // Update UI to show selected plan
    this.updatePlanSelection(planType);
    
    // Proceed to checkout
    this.proceedToCheckout();
  }

  // Update plan selection UI
  updatePlanSelection(selectedPlan) {
    const planCards = document.querySelectorAll('.plan-card');
    planCards.forEach(card => {
      card.classList.remove('selected');
      if (card.dataset.plan === selectedPlan) {
        card.classList.add('selected');
      }
    });
  }

  // Proceed to Stripe checkout
  async proceedToCheckout() {
    if (!this.selectedPlan || this.isProcessing) {
      return;
    }

    if (!authManager.isAuthenticated()) {
      console.error('User not authenticated');
      return;
    }

    this.isProcessing = true;
    this.showProcessingState();

    try {
      const plan = this.plans[this.selectedPlan];
      const user = authManager.getCurrentUser();

      console.log('🚀 Creating checkout session for:', plan.name);

      // Create checkout session
      const response = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          priceId: plan.priceId,
          userId: user.uid,
          userEmail: user.email,
          planType: this.selectedPlan
        })
      });

      if (!response.ok) {
        throw new Error('Failed to create checkout session');
      }

      const { sessionId } = await response.json();

      // Redirect to Stripe Checkout
      const { error } = await this.stripe.redirectToCheckout({
        sessionId: sessionId
      });

      if (error) {
        throw error;
      }

    } catch (error) {
      console.error('Checkout error:', error);
      this.showError('Failed to start checkout. Please try again.');
    } finally {
      this.isProcessing = false;
      this.hideProcessingState();
    }
  }

  // Show processing state
  showProcessingState() {
    const buttons = document.querySelectorAll('.plan-button');
    buttons.forEach(button => {
      button.disabled = true;
      button.textContent = 'Processing...';
      button.classList.add('processing');
    });
  }

  // Hide processing state
  hideProcessingState() {
    const buttons = document.querySelectorAll('.plan-button');
    buttons.forEach(button => {
      button.disabled = false;
      button.classList.remove('processing');
      
      // Restore original text
      const planCard = button.closest('.plan-card');
      const planType = planCard?.dataset.plan;
      if (planType === 'weekly') {
        button.textContent = 'Choose Weekly';
      } else if (planType === 'monthly') {
        button.textContent = 'Choose Monthly';
      }
    });
  }

  // Show error message
  showError(message) {
    // Create or update error message element
    let errorEl = document.getElementById('subscription-error');
    if (!errorEl) {
      errorEl = document.createElement('div');
      errorEl.id = 'subscription-error';
      errorEl.className = 'error-message';
      errorEl.style.cssText = `
        background: #fee;
        color: #c33;
        padding: 1rem;
        border-radius: 8px;
        border-left: 4px solid #c33;
        margin: 1rem 0;
        font-weight: 500;
      `;
      
      const modalBody = document.querySelector('.subscription-modal-content .modal-body');
      if (modalBody) {
        modalBody.appendChild(errorEl);
      }
    }
    
    errorEl.textContent = message;
    errorEl.style.display = 'block';
    
    // Hide after 5 seconds
    setTimeout(() => {
      if (errorEl) {
        errorEl.style.display = 'none';
      }
    }, 5000);
  }

  // Handle successful payment (called from success page or webhook)
  async handlePaymentSuccess(sessionId) {
    try {
      console.log('✅ Payment successful, session:', sessionId);
      
      // Refresh subscription status
      await authManager.refreshSubscriptionStatus();
      
      // Close modal
      authManager.closeAllModals();
      
      // Show success message
      this.showSuccessMessage('Payment successful! Welcome to Thesis Generator!');
      
    } catch (error) {
      console.error('Error handling payment success:', error);
    }
  }

  // Show success message
  showSuccessMessage(message) {
    const successEl = document.createElement('div');
    successEl.style.cssText = `
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
    successEl.textContent = message;
    
    document.body.appendChild(successEl);
    
    setTimeout(() => {
      successEl.style.animation = 'slideOutRight 0.3s ease';
      setTimeout(() => {
        if (successEl.parentNode) {
          successEl.parentNode.removeChild(successEl);
        }
      }, 300);
    }, 3000);
  }

  // Get plan details
  getPlan(planType) {
    return this.plans[planType] || null;
  }

  // Get all plans
  getAllPlans() {
    return this.plans;
  }
}

// Create and export singleton instance
const subscriptionManager = new SubscriptionManager();

// Make it globally available
window.subscriptionManager = subscriptionManager;

export default subscriptionManager;
