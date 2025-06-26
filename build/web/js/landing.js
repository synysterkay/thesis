// ==============================================
// THESIS GENERATOR LANDING PAGE JAVASCRIPT
// ==============================================

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎓 Thesis Generator landing page loaded');
    
    // Initialize all functionality
    initializeNavigation();
    initializeFAQ();
    initializeAnimations();
    initializeScrollEffects();
    initializeCookieConsent();
    initializeAuthModals();
    initializeStripePayments();
    initializeAuthIntegration();
    
    console.log('✅ All landing page features initialized');
});

// ==============================================
// STRIPE PAYMENT INTEGRATION (SIMPLIFIED)
// ==============================================

// Keep your Stripe key for potential future use, but we won't need it for Payment Links
const STRIPE_PUBLISHABLE_KEY = 'pk_live_51IwsyLEHyyRHgrPiQTfkXDJVqQbdIS1RGqOEyRdsMFBbxnx8G8Qoid4iGZxpLv5lX43YA0X2qzdYoWJRZHGexYaB00Xan2xYkh';

// Replace the old price IDs with direct Payment Links
const STRIPE_PAYMENT_LINKS = {
    weekly: 'https://buy.stripe.com/8x214n4zH5lr4kTaOHfrW01',
    monthly: 'https://buy.stripe.com/cNiaEXgip017eZxg91frW02'
};

let stripe;

function initializeStripePayments() {
    // Optional: Still initialize Stripe for potential future features
    if (typeof Stripe !== 'undefined') {
        stripe = Stripe(STRIPE_PUBLISHABLE_KEY);
        console.log('✅ Stripe initialized');
    } else {
        console.log('ℹ️ Using Stripe Payment Links - no client initialization needed');
    }
}

// ==============================================
// SIMPLIFIED PLAN SELECTION
// ==============================================

function selectPlan(planType) {
    console.log('🎯 Plan selected:', planType);
    
    // Direct payment links - no domain authorization needed!
    const paymentLinks = {
        weekly: 'https://buy.stripe.com/8x214n4zH5lr4kTaOHfrW01',
        monthly: 'https://buy.stripe.com/cNiaEXgip017eZxg91frW02'
    };
    
    // Get the button that was clicked
    const button = event.target;
    const originalText = button.textContent;
    
    // Show loading state
    button.textContent = 'Redirecting to payment...';
    button.disabled = true;
    
    // Track plan selection
    trackEvent('plan_selected', {
        'plan_type': planType,
        'user_id': window.firebaseAuth?.currentUser?.uid || 'anonymous'
    });
    
    // ✅ DIRECT REDIRECT - No auth check, no popups
    if (paymentLinks[planType]) {
        console.log('💳 Redirecting to Stripe Payment Link...');
        
        // Add a small delay for better UX
        setTimeout(() => {
            window.location.href = paymentLinks[planType];
        }, 1000);
        
    } else {
        console.error('❌ Payment link not found for plan:', planType);
        // Only log error, don't show popup to user
        console.log('Available plans:', Object.keys(paymentLinks));
        
        // Restore button
        button.textContent = originalText;
        button.disabled = false;
    }
}


// ==============================================
// AUTH MODAL INITIALIZATION
// ==============================================

function initializeAuthModals() {
    // Auth modal elements
    const authModal = document.getElementById('auth-modal');
    const closeAuthModal = document.getElementById('close-auth-modal');
    const authTabs = document.querySelectorAll('.auth-tab');
    const authForm = document.getElementById('auth-form');
    const googleSigninBtn = document.getElementById('google-signin');

    // Subscription modal elements
    const subscriptionModal = document.getElementById('subscription-modal');
    const closeSubscriptionModal = document.getElementById('close-subscription-modal');

    // Close modal handlers
    closeAuthModal?.addEventListener('click', () => {
        closeModal('auth-modal');
    });

    closeSubscriptionModal?.addEventListener('click', () => {
        closeModal('subscription-modal');
    });

    // Close modal when clicking outside
    authModal?.addEventListener('click', (e) => {
        if (e.target === authModal) {
            closeModal('auth-modal');
        }
    });

    subscriptionModal?.addEventListener('click', (e) => {
        if (e.target === subscriptionModal) {
            closeModal('subscription-modal');
        }
    });

    // Auth tab switching
    authTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabType = tab.dataset.tab;

            // Update active tab
            authTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');

            // Update form
            const title = document.getElementById('auth-title');
            const submitBtn = document.querySelector('.auth-submit-btn');
            const confirmPasswordGroup = document.getElementById('confirm-password-group');

            if (tabType === 'signup') {
                title.textContent = 'Sign Up';
                submitBtn.textContent = 'Sign Up';
                confirmPasswordGroup.style.display = 'block';
                document.getElementById('confirm-password').required = true;
            } else {
                title.textContent = 'Sign In';
                submitBtn.textContent = 'Sign In';
                confirmPasswordGroup.style.display = 'none';
                document.getElementById('confirm-password').required = false;
            }
        });
    });

    // Auth form submission
    authForm?.addEventListener('submit', handleAuthSubmit);

    // Google signin
    googleSigninBtn?.addEventListener('click', handleGoogleSignin);

    // Forgot password
    document.getElementById('forgot-password')?.addEventListener('click', (e) => {
        e.preventDefault();
        handleForgotPassword();
    });
}

// ==============================================
// AUTH INTEGRATION WITH EXISTING AUTH-MANAGER
// ==============================================

function initializeAuthIntegration() {
    // Wait for Firebase to be available
    const checkFirebase = setInterval(() => {
        if (typeof window.firebaseAuth !== 'undefined') {
            clearInterval(checkFirebase);
            setupAuthIntegration();
        }
    }, 100);
}

function setupAuthIntegration() {
    console.log('🔐 Setting up auth integration...');

    // Listen for auth state changes
    if (window.firebaseAuth) {
        window.firebaseAuth.onAuthStateChanged((user) => {
            updateUIBasedOnAuthState(user);
        });
    }
}

function updateUIBasedOnAuthState(user) {
    // Update UI elements based on authentication state
    const navElements = {
        loginBtn: document.getElementById('nav-login-btn'),
        // ❌ REMOVED: Dashboard button
        // appBtn: document.getElementById('nav-app-btn'),
        userStatus: document.getElementById('user-status-bar')
    };

    if (user) {
        // User is authenticated
        if (navElements.loginBtn) navElements.loginBtn.style.display = 'none';
        // ❌ REMOVED: Dashboard button logic
        // if (navElements.appBtn) navElements.appBtn.style.display = 'inline-block';
        if (navElements.userStatus) navElements.userStatus.style.display = 'block';

        // Update user info if elements exist
        const userName = document.getElementById('user-name');
        const subscriptionStatus = document.getElementById('subscription-status');

        if (userName) {
            userName.textContent = user.displayName || user.email.split('@')[0];
        }

        if (subscriptionStatus) {
            subscriptionStatus.textContent = 'No Active Subscription';
            subscriptionStatus.className = 'subscription-status inactive';
        }
    } else {
        // User is not authenticated
        if (navElements.loginBtn) navElements.loginBtn.style.display = 'inline-block';
        // ❌ REMOVED: Dashboard button logic
        // if (navElements.appBtn) navElements.appBtn.style.display = 'none';
        if (navElements.userStatus) navElements.userStatus.style.display = 'none';
    }
}


// ==============================================
// UPDATED AUTH HANDLERS (with payment link support)
// ==============================================

async function handleAuthSubmit(e) {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const confirmPassword = document.getElementById('confirm-password').value;
    const isSignUp = document.querySelector('.auth-tab.active').dataset.tab === 'signup';
    const submitBtn = document.querySelector('.auth-submit-btn');

    // Validation
    if (!validateEmail(email)) {
        showMessage('Please enter a valid email address.', 'error');
        return;
    }

    if (password.length < 6) {
        showMessage('Password must be at least 6 characters long.', 'error');
        return;
    }

    if (isSignUp && password !== confirmPassword) {
        showMessage('Passwords do not match.', 'error');
        return;
    }

    // Show loading state
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'Processing...';
    submitBtn.disabled = true;

    try {
        if (window.firebaseAuth) {
            let result;
            if (isSignUp) {
                result = await window.firebaseAuth.createUserWithEmailAndPassword(email, password);
                await createOrUpdateUserProfile(result.user);
                showMessage('Account created successfully!', 'success');
            } else {
                result = await window.firebaseAuth.signInWithEmailAndPassword(email, password);
                showMessage('Signed in successfully!', 'success');
            }

            // Handle pending payment after successful auth
            handleAuthSuccess(result.user);

        } else {
            throw new Error('Firebase Auth not available');
        }
    } catch (error) {
        console.error('Auth error:', error);
        showMessage(error.message || 'Authentication failed. Please try again.', 'error');
    } finally {
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
    }
}

async function handleGoogleSignin() {
    try {
        console.log('🔍 Attempting Google sign-in...');

        if (!window.firebaseAuth || !window.googleProvider) {
            throw new Error('Firebase not properly initialized');
        }

        const result = await window.firebaseAuth.signInWithPopup(window.googleProvider);
        const user = result.user;

        console.log('✅ Google sign-in successful:', user.email);

        // Create or update user profile with retry logic
        await createOrUpdateUserProfileWithRetry(user);

        // Handle pending payment after successful auth
        handleAuthSuccess(user);

    } catch (error) {
        console.error('Google sign-in error:', error);
        showAuthError(error.message || 'Google sign-in failed. Please try again.');
    }
}

// ==============================================
// NEW: HANDLE AUTH SUCCESS WITH PENDING PAYMENTS
// ==============================================

function handleAuthSuccess(user) {
    console.log('✅ User authenticated:', user.email);
    
    // Close auth modal
    closeModal('auth-modal');
    
    // Check if user was trying to select a plan
    const selectedPlan = sessionStorage.getItem('selectedPlan');
    
    if (selectedPlan) {
        console.log('🎯 Redirecting to payment for plan:', selectedPlan);
        
        // Clear stored plan
        sessionStorage.removeItem('selectedPlan');
        
        // Redirect to payment
        const paymentLinks = {
            weekly: 'https://buy.stripe.com/8x214n4zH5lr4kTaOHfrW01',
            monthly: 'https://buy.stripe.com/cNiaEXgip017eZxg91frW02'
        };
        
        if (paymentLinks[selectedPlan]) {
            // Small delay to ensure modal closes
            setTimeout(() => {
                window.location.href = paymentLinks[selectedPlan];
            }, 500);
        }
    } else {
        // Just show subscription modal if no specific plan was selected
        showSubscriptionModal();
    }
}


async function createOrUpdateUserProfile(user) {
    try {
        if (!window.firebaseDb) {
            throw new Error('Firestore not available');
        }

        const userRef = window.firebaseDb.collection('users').doc(user.uid);
        const userDoc = await userRef.get();

        const userData = {
            uid: user.uid,
            email: user.email,
            displayName: user.displayName || '',
            photoURL: user.photoURL || '',
            lastLogin: window.firebase.firestore.FieldValue.serverTimestamp(),
            lastUpdated: window.firebase.firestore.FieldValue.serverTimestamp()
        };

        if (userDoc.exists) {
            await userRef.update(userData);
            console.log('✅ User profile updated');
        } else {
            userData.createdAt = window.firebase.firestore.FieldValue.serverTimestamp();
            userData.subscriptionStatus = 'inactive';
            userData.subscriptionPlan = null;
            await userRef.set(userData);
            console.log('✅ User profile created');
        }
    } catch (error) {
        console.error('Error creating/updating user profile:', error);
        throw error;
    }
}


async function createOrUpdateUserProfileWithRetry(user, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            await createOrUpdateUserProfile(user);
            return;
        } catch (error) {
            console.warn(`Attempt ${i + 1} failed:`, error.message);
            if (i === maxRetries - 1) {
                // Last attempt failed, but don't block the user
                console.error('Failed to create user profile after all retries');
                showMessage('Profile creation delayed, but you can continue.', 'warning');
                return;
            }
            // Wait before retry
            await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
        }
    }
}

async function handleForgotPassword() {
    const email = document.getElementById('email').value;
    
    if (!email) {
        showMessage('Please enter your email address first.', 'warning');
        return;
    }
    
    if (!validateEmail(email)) {
        showMessage('Please enter a valid email address.', 'error');
        return;
    }
    
    try {
        if (window.firebaseAuth) {
            await window.firebaseAuth.sendPasswordResetEmail(email);
            showMessage('Password reset email sent! Check your inbox.', 'success');
        } else {
            throw new Error('Firebase Auth not available');
        }
    } catch (error) {
        console.error('Password reset error:', error);
        showMessage(error.message || 'Failed to send reset email. Please try again.', 'error');
    }
}

// ==============================================
// MAIN CTA BUTTON HANDLERS
// ==============================================

// Main CTA buttons
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('start-generating')?.addEventListener('click', handleGenerateThesisClick);
    document.getElementById('start-generating-bottom')?.addEventListener('click', handleGenerateThesisClick);
});

function handleGenerateThesisClick(e) {
    e.preventDefault();
    
    const button = e.target.closest('button');
    console.log('🎯 Generate thesis button clicked');
    
    // Track CTA click
    trackEvent('generate_thesis_clicked', {
        'button_location': button.id,
        'user_authenticated': !!window.firebaseAuth?.currentUser
    });
    
    // Check authentication status
    if (!window.firebaseAuth?.currentUser) {
        console.log('🔐 User not authenticated, showing auth modal...');
        sessionStorage.setItem('pendingAction', 'generate_thesis');
        showAuthModal();
        return;
    }
    
    // User is authenticated - redirect to app
    console.log('✅ User authenticated, redirecting to app...');
    showLoadingAndRedirect(button, 'Launching your thesis generator...', 'app.html');
}

// ==============================================
// MODAL FUNCTIONS
// ==============================================

function showAuthModal() {
    const authModal = document.getElementById('auth-modal');
    if (authModal) {
        authModal.style.display = 'flex';
        authModal.classList.add('show');
        document.body.classList.add('no-scroll');
        
        // Focus management
        const firstInput = authModal.querySelector('input');
        if (firstInput) {
            setTimeout(() => firstInput.focus(), 100);
        }
        
        trackEvent('auth_modal_shown');
    }
}

function showSubscriptionModal() {
    const subscriptionModal = document.getElementById('subscription-modal');
    if (subscriptionModal) {
        subscriptionModal.style.display = 'flex';
        subscriptionModal.classList.add('show');
        document.body.classList.add('no-scroll');
        
        trackEvent('subscription_modal_shown');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        modal.classList.remove('show');
        document.body.classList.remove('no-scroll');
    }
}

function closeAllModals() {
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
        modal.style.display = 'none';
        modal.classList.remove('show');
    });
    document.body.classList.remove('no-scroll');
}

// ==============================================
// PLAN SELECTION FUNCTION
// ==============================================

function selectPlan(planType) {
    console.log('🎯 Plan selected:', planType);
    
    // Payment links
    const paymentLinks = {
        weekly: 'https://buy.stripe.com/8x214n4zH5lr4kTaOHfrW01',
        monthly: 'https://buy.stripe.com/cNiaEXgip017eZxg91frW02'
    };
    
    // Check if user is authenticated
    const currentUser = window.firebaseAuth?.currentUser;
    
    if (currentUser) {
        // User is authenticated - direct redirect to payment
        console.log('✅ User authenticated, redirecting to payment...');
        
        // Track plan selection
        trackEvent('plan_selected', {
            'plan_type': planType,
            'user_id': currentUser.uid,
            'user_email': currentUser.email
        });
        
        // Direct redirect to Stripe
        if (paymentLinks[planType]) {
            window.location.href = paymentLinks[planType];
        } else {
            console.error('❌ Payment link not found for plan:', planType);
        }
    } else {
        // User not authenticated - show auth modal first
        console.log('❌ User not authenticated, showing auth modal...');
        
        // Store selected plan for after authentication
        sessionStorage.setItem('selectedPlan', planType);
        
        // Show auth modal
        showAuthModal();
    }
}








function loadStripeScript() {
    return new Promise((resolve, reject) => {
        if (typeof Stripe !== 'undefined') {
            resolve();
            return;
        }
        
        const script = document.createElement('script');
        script.src = 'https://js.stripe.com/v3/';
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

// ==============================================
// UTILITY FUNCTIONS
// ==============================================

function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showMessage(message, type = 'info') {
    // Remove existing messages
    const existingMessages = document.querySelectorAll('.message-toast');
    existingMessages.forEach(msg => msg.remove());
    
    // Create new message
    const messageEl = document.createElement('div');
    messageEl.className = `message-toast ${type}`;
    messageEl.innerHTML = `
        <div class="message-content">
            <span class="message-icon">${getMessageIcon(type)}</span>
            <span class="message-text">${message}</span>
            <button class="message-close" onclick="this.parentElement.parentElement.remove()">×</button>
        </div>
    `;
    
    // Add styles
    messageEl.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getMessageColor(type)};
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        z-index: 10000;
        max-width: 400px;
        animation: slideInRight 0.3s ease;
    `;
    
    document.body.appendChild(messageEl);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (messageEl.parentNode) {
            messageEl.style.animation = 'slideOutRight 0.3s ease';
            setTimeout(() => messageEl.remove(), 300);
        }
    }, 5000);
}

function showAuthError(message) {
    showMessage(message, 'error');
}

function getMessageIcon(type) {
    const icons = {
        success: '✅',
        error: '❌',
        warning: '⚠️',
        info: 'ℹ️'
    };
    return icons[type] || icons.info;
}

function getMessageColor(type) {
    const colors = {
        success: '#28a745',
        error: '#dc3545',
        warning: '#ffc107',
        info: '#17a2b8'
    };
    return colors[type] || colors.info;
}

function showLoadingAndRedirect(button, message, url) {
    const originalText = button.textContent;
    button.textContent = message;
    button.disabled = true;
    
    // Show loading overlay
    const loadingOverlay = document.getElementById('loading-overlay');
    const loadingText = document.querySelector('.loading-text');
    
    if (loadingOverlay && loadingText) {
        loadingText.textContent = message;
        loadingOverlay.style.display = 'flex';
    }
    
    // Redirect after delay
    setTimeout(() => {
        window.location.href = url;
    }, 1500);
}

// ==============================================
// NAVIGATION FUNCTIONALITY
// ==============================================

function initializeNavigation() {
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // Mobile menu toggle (if exists)
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    const mobileMenu = document.querySelector('.mobile-menu');
    
    if (mobileMenuToggle && mobileMenu) {
        mobileMenuToggle.addEventListener('click', () => {
            mobileMenu.classList.toggle('active');
        });
    }
}

// ==============================================
// FAQ FUNCTIONALITY
// ==============================================

function initializeFAQ() {
    const faqQuestions = document.querySelectorAll('.faq-question');
    
    faqQuestions.forEach(question => {
        question.addEventListener('click', () => {
            const isExpanded = question.getAttribute('aria-expanded') === 'true';
            
            // Close all other FAQ items
            faqQuestions.forEach(q => {
                q.setAttribute('aria-expanded', 'false');
                const answer = q.nextElementSibling;
                if (answer) {
                    answer.style.display = 'none';
                }
            });
            
            // Toggle current item
            if (!isExpanded) {
                question.setAttribute('aria-expanded', 'true');
                const answer = question.nextElementSibling;
                if (answer) {
                    answer.style.display = 'block';
                }
            }
        });
    });
}

// ==============================================
// SCROLL EFFECTS
// ==============================================

function initializeScrollEffects() {
    // Scroll progress bar
    const scrollProgress = document.querySelector('.scroll-progress');
    
    if (scrollProgress) {
        window.addEventListener('scroll', () => {
            const scrolled = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
            scrollProgress.style.setProperty('--scroll-progress', `${Math.min(scrolled, 100)}%`);
        });
    }
    
    // Back to top button
    const backToTopBtn = document.getElementById('back-to-top');
    
    if (backToTopBtn) {
        window.addEventListener('scroll', () => {
            if (window.scrollY > 300) {
                backToTopBtn.style.display = 'flex';
            } else {
                backToTopBtn.style.display = 'none';
            }
        });
        
        backToTopBtn.addEventListener('click', () => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }
    
    // Stats counter animation
    initializeStatsCounter();
}

function initializeStatsCounter() {
    const statNumbers = document.querySelectorAll('.stat-number');
    const observerOptions = {
        threshold: 0.5,
        rootMargin: '0px 0px -100px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = parseInt(entry.target.dataset.target);
                animateCounter(entry.target, target);
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    statNumbers.forEach(stat => {
        observer.observe(stat);
    });
}

function animateCounter(element, target) {
    let current = 0;
    const increment = target / 50;
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 40);
}

// ==============================================
// ANIMATIONS
// ==============================================

function initializeAnimations() {
    // Intersection Observer for fade-in animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    // Observe elements for animation
    const animatedElements = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row');
    animatedElements.forEach(el => {
        observer.observe(el);
    });
}

// ==============================================
// COOKIE CONSENT
// ==============================================

function initializeCookieConsent() {
    const cookieBanner = document.getElementById('cookie-banner');
    const acceptCookies = document.getElementById('accept-cookies');
    const declineCookies = document.getElementById('decline-cookies');
    
    // Check if user has already made a choice
    const cookieChoice = localStorage.getItem('cookieConsent');
    
    if (!cookieChoice && cookieBanner) {
        // Show banner after 2 seconds
        setTimeout(() => {
            cookieBanner.style.display = 'block';
        }, 2000);
    }
    
    acceptCookies?.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'accepted');
        cookieBanner.style.display = 'none';
        trackEvent('cookies_accepted');
    });
    
    declineCookies?.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'declined');
        cookieBanner.style.display = 'none';
        trackEvent('cookies_declined');
    });
}

// ==============================================
// ANALYTICS & TRACKING
// ==============================================

function trackEvent(eventName, parameters = {}) {
    try {
        // Google Analytics 4
        if (typeof gtag !== 'undefined') {
            gtag('event', eventName, parameters);
        }
        
        // Firebase Analytics
        if (window.firebaseAnalytics) {
            window.firebaseAnalytics.logEvent(eventName, parameters);
        }
        
        console.log('📊 Event tracked:', eventName, parameters);
    } catch (error) {
        console.warn('Analytics tracking failed:', error);
    }
}

// ==============================================
// URL PARAMETER HANDLING
// ==============================================

function handleURLParameters() {
    const urlParams = new URLSearchParams(window.location.search);
    
    // Handle payment success
    if (urlParams.get('success') === 'true') {
        const sessionId = urlParams.get('session_id');
        showMessage('Payment successful! Welcome to Thesis Generator Pro!', 'success');
        trackEvent('payment_success', { session_id: sessionId });
        
        // Clean URL
        window.history.replaceState({}, document.title, window.location.pathname);
        
        // Redirect to app after showing success message
        setTimeout(() => {
            window.location.href = 'app.html';
        }, 3000);
    }
    
    // Handle payment cancellation
    if (urlParams.get('canceled') === 'true') {
        showMessage('Payment was canceled. You can try again anytime.', 'warning');
        trackEvent('payment_canceled');
        
        // Clean URL
        window.history.replaceState({}, document.title, window.location.pathname);
    }
}

// ==============================================
// ERROR HANDLING
// ==============================================

// Global error handler
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    trackEvent('javascript_error', {
        'error_message': event.error?.message || 'Unknown error',
        'error_filename': event.filename,
        'error_lineno': event.lineno
    });
});

// Unhandled promise rejection handler
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection:', event.reason);
    trackEvent('unhandled_promise_rejection', {
        'error_message': event.reason?.message || 'Unknown promise rejection'
    });
});

// ==============================================
// KEYBOARD SHORTCUTS
// ==============================================

document.addEventListener('keydown', (e) => {
    // Escape key closes modals
    if (e.key === 'Escape') {
        closeAllModals();
    }
    
    // Ctrl/Cmd + K opens auth modal
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        if (!window.firebaseAuth?.currentUser) {
            showAuthModal();
        }
    }
});

// ==============================================
// PERFORMANCE MONITORING
// ==============================================

// Page load performance
window.addEventListener('load', () => {
    if ('performance' in window) {
        const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
        trackEvent('page_load_time', {
            'load_time_ms': loadTime,
            'page': 'landing'
        });
    }
});

// ==============================================
// INITIALIZATION ON DOM READY
// ==============================================

// Handle URL parameters when page loads
document.addEventListener('DOMContentLoaded', () => {
    handleURLParameters();
});

// ==============================================
// EXPORT FUNCTIONS FOR GLOBAL ACCESS
// ==============================================

// Make functions available globally for HTML onclick handlers
window.selectPlan = selectPlan;
window.showAuthModal = showAuthModal;
window.closeModal = closeModal;
window.closeAllModals = closeAllModals;
window.trackEvent = trackEvent;

console.log('🎓 Landing page JavaScript fully loaded and initialized');

// ==============================================
// ADDITIONAL FEATURES & ENHANCEMENTS
// ==============================================

// ==============================================
// TESTIMONIALS CAROUSEL (if needed)
// ==============================================

function initializeTestimonialsCarousel() {
    const testimonialContainer = document.querySelector('.testimonials-grid');
    const testimonials = document.querySelectorAll('.testimonial-card');
    
    if (testimonials.length > 3) {
        let currentIndex = 0;
        const totalTestimonials = testimonials.length;
        
        // Create navigation dots
        const dotsContainer = document.createElement('div');
        dotsContainer.className = 'testimonial-dots';
        dotsContainer.style.cssText = `
            display: flex;
            justify-content: center;
            gap: 0.5rem;
            margin-top: 2rem;
        `;
        
        for (let i = 0; i < Math.ceil(totalTestimonials / 3); i++) {
            const dot = document.createElement('button');
            dot.className = 'testimonial-dot';
            dot.style.cssText = `
                width: 12px;
                height: 12px;
                border-radius: 50%;
                border: none;
                background: ${i === 0 ? '#9D4EDD' : '#ddd'};
                cursor: pointer;
                transition: background 0.3s ease;
            `;
            dot.addEventListener('click', () => goToTestimonialSlide(i));
            dotsContainer.appendChild(dot);
        }
        
        testimonialContainer.parentNode.appendChild(dotsContainer);
        
        // Auto-rotate testimonials
        setInterval(() => {
            currentIndex = (currentIndex + 1) % Math.ceil(totalTestimonials / 3);
            goToTestimonialSlide(currentIndex);
        }, 8000);
        
        function goToTestimonialSlide(index) {
            currentIndex = index;
            const offset = -index * 100;
            testimonialContainer.style.transform = `translateX(${offset}%)`;
            
            // Update dots
            document.querySelectorAll('.testimonial-dot').forEach((dot, i) => {
                dot.style.background = i === index ? '#9D4EDD' : '#ddd';
            });
        }
    }
}

// ==============================================
// ADVANCED FORM VALIDATION
// ==============================================

function initializeAdvancedFormValidation() {
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const confirmPasswordInput = document.getElementById('confirm-password');
    
    // Real-time email validation
    emailInput?.addEventListener('input', (e) => {
        const email = e.target.value;
        const isValid = validateEmail(email);
        
        if (email.length > 0) {
            if (isValid) {
                showFieldValidation(emailInput, true, '✅ Valid email');
            } else {
                showFieldValidation(emailInput, false, '❌ Invalid email format');
            }
        } else {
            clearFieldValidation(emailInput);
        }
    });
    
    // Real-time password validation
    passwordInput?.addEventListener('input', (e) => {
        const password = e.target.value;
        const strength = getPasswordStrength(password);
        
        if (password.length > 0) {
            showPasswordStrength(passwordInput, strength);
        } else {
            clearFieldValidation(passwordInput);
        }
    });
    
    // Real-time password confirmation
    confirmPasswordInput?.addEventListener('input', (e) => {
        const password = passwordInput?.value || '';
        const confirmPassword = e.target.value;
        
        if (confirmPassword.length > 0) {
            if (password === confirmPassword) {
                showFieldValidation(confirmPasswordInput, true, '✅ Passwords match');
            } else {
                showFieldValidation(confirmPasswordInput, false, '❌ Passwords do not match');
            }
        } else {
            clearFieldValidation(confirmPasswordInput);
        }
    });
}

function showFieldValidation(field, isValid, message) {
    clearFieldValidation(field);
    
    const validationEl = document.createElement('div');
    validationEl.className = `field-validation ${isValid ? 'valid' : 'invalid'}`;
    validationEl.textContent = message;
    validationEl.style.cssText = `
        font-size: 0.8rem;
        margin-top: 0.25rem;
        color: ${isValid ? '#28a745' : '#dc3545'};
        transition: opacity 0.3s ease;
    `;
    
    field.parentNode.appendChild(validationEl);
    field.style.borderColor = isValid ? '#28a745' : '#dc3545';
}

function clearFieldValidation(field) {
    const existingValidation = field.parentNode.querySelector('.field-validation');
    if (existingValidation) {
        existingValidation.remove();
    }
    field.style.borderColor = '';
}

function getPasswordStrength(password) {
    let strength = 0;
    const checks = {
        length: password.length >= 8,
        lowercase: /[a-z]/.test(password),
        uppercase: /[A-Z]/.test(password),
        numbers: /\d/.test(password),
        symbols: /[!@#$%^&*(),.?":{}|<>]/.test(password)
    };
    
    strength = Object.values(checks).filter(Boolean).length;
    
    return {
        score: strength,
        level: strength < 2 ? 'weak' : strength < 4 ? 'medium' : 'strong',
        checks: checks
    };
}

function showPasswordStrength(field, strength) {
    clearFieldValidation(field);
    
    const strengthEl = document.createElement('div');
    strengthEl.className = 'password-strength';
    
    const colors = { weak: '#dc3545', medium: '#ffc107', strong: '#28a745' };
    const labels = { weak: 'Weak', medium: 'Medium', strong: 'Strong' };
    
    strengthEl.innerHTML = `
        <div style="display: flex; align-items: center; gap: 0.5rem; margin-top: 0.25rem;">
            <div style="flex: 1; height: 4px; background: #eee; border-radius: 2px; overflow: hidden;">
                <div style="height: 100%; width: ${(strength.score / 5) * 100}%; background: ${colors[strength.level]}; transition: all 0.3s ease;"></div>
            </div>
            <span style="font-size: 0.8rem; color: ${colors[strength.level]}; font-weight: 500;">
                ${labels[strength.level]}
            </span>
        </div>
    `;
    
    field.parentNode.appendChild(strengthEl);
    field.style.borderColor = colors[strength.level];
}

// ==============================================
// SOCIAL PROOF & TRUST INDICATORS
// ==============================================

function initializeSocialProof() {
    // Simulate recent user activity
    const activities = [
        "Sarah from New York just created her thesis",
        "Michael from London upgraded to Pro",
        "Emma from Toronto generated 5 chapters",
        "David from Sydney completed his research paper",
        "Lisa from Berlin exported her thesis to PDF"
    ];
    
    let activityIndex = 0;
    
    function showActivity() {
        const notification = document.createElement('div');
        notification.className = 'social-proof-notification';
        notification.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: white;
            padding: 1rem 1.5rem;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
            border-left: 4px solid #28a745;
            z-index: 1000;
            max-width: 300px;
            transform: translateX(-100%);
            transition: transform 0.3s ease;
        `;
        
        notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 0.5rem;">
                <span style="color: #28a745; font-size: 1.2rem;">✅</span>
                <span style="font-size: 0.9rem; color: #333;">${activities[activityIndex]}</span>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Animate out
        setTimeout(() => {
            notification.style.transform = 'translateX(-100%)';
            setTimeout(() => notification.remove(), 300);
        }, 4000);
        
        activityIndex = (activityIndex + 1) % activities.length;
    }
    
    // Show first activity after 5 seconds, then every 15 seconds
    setTimeout(() => {
        showActivity();
        setInterval(showActivity, 15000);
    }, 5000);
}

// ==============================================
// ADVANCED ANALYTICS & HEATMAP
// ==============================================

function initializeAdvancedAnalytics() {
    // Track scroll depth
    let maxScrollDepth = 0;
    const scrollDepthThresholds = [25, 50, 75, 90, 100];
    const trackedDepths = new Set();
    
    window.addEventListener('scroll', () => {
        const scrollDepth = Math.round((window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100);
        
        if (scrollDepth > maxScrollDepth) {
            maxScrollDepth = scrollDepth;
        }
        
        scrollDepthThresholds.forEach(threshold => {
            if (scrollDepth >= threshold && !trackedDepths.has(threshold)) {
                trackedDepths.add(threshold);
                trackEvent('scroll_depth', {
                    'depth_percentage': threshold,
                    'page': 'landing'
                });
            }
        });
    });
    
    // Track time on page
    const startTime = Date.now();
    const timeThresholds = [30, 60, 120, 300]; // seconds
    const trackedTimes = new Set();
    
    setInterval(() => {
        const timeOnPage = Math.round((Date.now() - startTime) / 1000);
        
        timeThresholds.forEach(threshold => {
            if (timeOnPage >= threshold && !trackedTimes.has(threshold)) {
                trackedTimes.add(threshold);
                trackEvent('time_on_page', {
                    'time_seconds': threshold,
                    'page': 'landing'
                });
            }
        });
    }, 5000);
    
    // Track element interactions
    const interactiveElements = document.querySelectorAll('button, a, .cta-primary, .benefit-card, .testimonial-card');
    
    interactiveElements.forEach(element => {
        element.addEventListener('click', (e) => {
            trackEvent('element_interaction', {
                'element_type': e.target.tagName.toLowerCase(),
                'element_class': e.target.className,
                'element_text': e.target.textContent.substring(0, 50),
                'page': 'landing'
            });
        });
    });
}

// ==============================================
// ACCESSIBILITY ENHANCEMENTS
// ==============================================

function initializeAccessibilityEnhancements() {
    // Skip link functionality
    const skipLink = document.querySelector('.skip-link');
    if (skipLink) {
        skipLink.addEventListener('click', (e) => {
            e.preventDefault();
            const target = document.querySelector(skipLink.getAttribute('href'));
            if (target) {
                target.focus();
                target.scrollIntoView({ behavior: 'smooth' });
            }
        });
    }
    
    // Keyboard navigation for modals
    document.addEventListener('keydown', (e) => {
        const activeModal = document.querySelector('.modal[style*="flex"]');
        
        if (activeModal && e.key === 'Tab') {
            const focusableElements = activeModal.querySelectorAll(
                'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
            );
            
            const firstElement = focusableElements[0];
            const lastElement = focusableElements[focusableElements.length - 1];
            
            if (e.shiftKey) {
                if (document.activeElement === firstElement) {
                    e.preventDefault();
                    lastElement.focus();
                }
            } else {
                if (document.activeElement === lastElement) {
                    e.preventDefault();
                    firstElement.focus();
                }
            }
        }
    });
    
    // Announce dynamic content changes to screen readers
    const announcer = document.createElement('div');
    announcer.setAttribute('aria-live', 'polite');
    announcer.setAttribute('aria-atomic', 'true');
    announcer.style.cssText = `
        position: absolute;
        left: -10000px;
        width: 1px;
        height: 1px;
        overflow: hidden;
    `;
    document.body.appendChild(announcer);
    
    window.announceToScreenReader = function(message) {
        announcer.textContent = message;
        setTimeout(() => {
            announcer.textContent = '';
        }, 1000);
    };
}

// ==============================================
// PROGRESSIVE WEB APP FEATURES
// ==============================================

function initializePWAFeatures() {
    // Service Worker registration
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
            navigator.serviceWorker.register('/sw.js')
                .then(registration => {
                    console.log('✅ SW registered:', registration);
                })
                .catch(registrationError => {
                    console.log('❌ SW registration failed:', registrationError);
                });
        });
    }
    
    // Install prompt
    let deferredPrompt;
    
    window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;
        
        // Show install button
        const installBtn = document.createElement('button');
        installBtn.textContent = '📱 Install App';
        installBtn.className = 'install-app-btn';
        installBtn.style.cssText = `
            position: fixed;
            bottom: 80px;
            right: 20px;
            background: #9D4EDD;
            color: white;
            border: none;
            padding: 0.8rem 1.2rem;
            border-radius: 25px;
            cursor: pointer;
            font-weight: 600;
            box-shadow: 0 4px 15px rgba(157, 78, 221, 0.3);
            z-index: 1000;
            transition: all 0.3s ease;
        `;
        
        installBtn.addEventListener('click', async () => {
            if (deferredPrompt) {
                deferredPrompt.prompt();
                const { outcome } = await deferredPrompt.userChoice;
                
                trackEvent('pwa_install_prompt', { outcome });
                
                if (outcome === 'accepted') {
                    installBtn.remove();
                }
                
                deferredPrompt = null;
            }
        });
        
           document.body.appendChild(installBtn);
        
        // Hide after 10 seconds if not clicked
        setTimeout(() => {
            if (installBtn.parentNode) {
                installBtn.style.opacity = '0';
                setTimeout(() => installBtn.remove(), 300);
            }
        }, 10000);
    });
    
    // Track app installation
    window.addEventListener('appinstalled', () => {
        trackEvent('pwa_installed');
        console.log('✅ PWA installed successfully');
    });
}

// ==============================================
// PERFORMANCE OPTIMIZATIONS
// ==============================================

function initializePerformanceOptimizations() {
    // Lazy load images
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                imageObserver.unobserve(img);
            }
        });
    });
    
    images.forEach(img => imageObserver.observe(img));
    
    // Preload critical resources
    const criticalResources = [
        'app.html',
        'css/app.css',
        'js/app.js'
    ];
    
    criticalResources.forEach(resource => {
        const link = document.createElement('link');
        link.rel = 'prefetch';
        link.href = resource;
        document.head.appendChild(link);
    });
    
    // Memory usage monitoring
    if ('memory' in performance) {
        setInterval(() => {
            const memory = performance.memory;
            if (memory.usedJSHeapSize > memory.jsHeapSizeLimit * 0.9) {
                console.warn('⚠️ High memory usage detected');
                trackEvent('high_memory_usage', {
                    'used_heap': memory.usedJSHeapSize,
                    'heap_limit': memory.jsHeapSizeLimit
                });
            }
        }, 30000);
    }
}

// ==============================================
// ADVANCED USER EXPERIENCE FEATURES
// ==============================================

function initializeAdvancedUXFeatures() {
    // Smart form autofill detection
    const emailInput = document.getElementById('email');
    if (emailInput) {
        emailInput.addEventListener('input', (e) => {
            const email = e.target.value;
            if (email.includes('@') && !email.endsWith('@')) {
                // Suggest common email domains
                const commonDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
                const [username, domain] = email.split('@');
                
                if (domain && domain.length > 0) {
                    const suggestions = commonDomains
                        .filter(d => d.startsWith(domain.toLowerCase()))
                        .slice(0, 3);
                    
                    if (suggestions.length > 0) {
                        showEmailSuggestions(emailInput, username, suggestions);
                    }
                }
            }
        });
    }
    
    // Smart loading states
    const buttons = document.querySelectorAll('button[type="submit"], .cta-primary');
    buttons.forEach(button => {
        button.addEventListener('click', () => {
            if (!button.disabled) {
                addSmartLoadingState(button);
            }
        });
    });
    
    // Context-aware help tooltips
    initializeContextualHelp();
    
    // Smart error recovery
    initializeErrorRecovery();
}

function showEmailSuggestions(input, username, suggestions) {
    // Remove existing suggestions
    const existingSuggestions = document.querySelector('.email-suggestions');
    if (existingSuggestions) {
        existingSuggestions.remove();
    }
    
    const suggestionsEl = document.createElement('div');
    suggestionsEl.className = 'email-suggestions';
    suggestionsEl.style.cssText = `
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: white;
        border: 1px solid #ddd;
        border-top: none;
        border-radius: 0 0 8px 8px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        z-index: 1000;
        max-height: 150px;
        overflow-y: auto;
    `;
    
    suggestions.forEach(domain => {
        const suggestion = document.createElement('div');
        suggestion.className = 'email-suggestion';
        suggestion.textContent = `${username}@${domain}`;
        suggestion.style.cssText = `
            padding: 0.8rem 1rem;
            cursor: pointer;
            border-bottom: 1px solid #eee;
            transition: background 0.2s ease;
        `;
        
        suggestion.addEventListener('click', () => {
            input.value = `${username}@${domain}`;
            suggestionsEl.remove();
            input.focus();
        });
        
        suggestion.addEventListener('mouseenter', () => {
            suggestion.style.background = '#f8f9ff';
        });
        
        suggestion.addEventListener('mouseleave', () => {
            suggestion.style.background = 'white';
        });
        
        suggestionsEl.appendChild(suggestion);
    });
    
    input.parentNode.style.position = 'relative';
    input.parentNode.appendChild(suggestionsEl);
    
    // Remove suggestions when clicking outside
    setTimeout(() => {
        document.addEventListener('click', function removeSuggestions(e) {
            if (!suggestionsEl.contains(e.target) && e.target !== input) {
                suggestionsEl.remove();
                document.removeEventListener('click', removeSuggestions);
            }
        });
    }, 100);
}

function addSmartLoadingState(button) {
    const originalText = button.textContent;
    const loadingTexts = [
        'Processing...',
        'Almost there...',
        'Just a moment...',
        'Setting things up...'
    ];
    
    let textIndex = 0;
    button.textContent = loadingTexts[textIndex];
    
    const interval = setInterval(() => {
        textIndex = (textIndex + 1) % loadingTexts.length;
        if (button.textContent !== originalText) {
            button.textContent = loadingTexts[textIndex];
        } else {
            clearInterval(interval);
        }
    }, 1500);
}

function initializeContextualHelp() {
    const helpTriggers = document.querySelectorAll('[data-help]');
    
    helpTriggers.forEach(trigger => {
        const helpText = trigger.dataset.help;
        
        trigger.addEventListener('mouseenter', () => {
            showTooltip(trigger, helpText);
        });
        
        trigger.addEventListener('mouseleave', () => {
            hideTooltip();
        });
        
        trigger.addEventListener('focus', () => {
            showTooltip(trigger, helpText);
        });
        
        trigger.addEventListener('blur', () => {
            hideTooltip();
        });
    });
}

function showTooltip(element, text) {
    hideTooltip(); // Remove any existing tooltip
    
    const tooltip = document.createElement('div');
    tooltip.className = 'contextual-tooltip';
    tooltip.textContent = text;
    tooltip.style.cssText = `
        position: absolute;
        background: #333;
        color: white;
        padding: 0.5rem 0.8rem;
        border-radius: 6px;
        font-size: 0.8rem;
        white-space: nowrap;
        z-index: 10000;
        pointer-events: none;
        opacity: 0;
        transition: opacity 0.2s ease;
    `;
    
    document.body.appendChild(tooltip);
    
    // Position tooltip
    const rect = element.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();
    
    let top = rect.top - tooltipRect.height - 8;
    let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
    
    // Adjust if tooltip goes off screen
    if (top < 0) {
        top = rect.bottom + 8;
    }
    if (left < 0) {
        left = 8;
    }
    if (left + tooltipRect.width > window.innerWidth) {
        left = window.innerWidth - tooltipRect.width - 8;
    }
    
    tooltip.style.top = `${top + window.scrollY}px`;
    tooltip.style.left = `${left}px`;
    tooltip.style.opacity = '1';
}

function hideTooltip() {
    const tooltip = document.querySelector('.contextual-tooltip');
    if (tooltip) {
        tooltip.remove();
    }
}

function initializeErrorRecovery() {
    // Network error recovery
    window.addEventListener('online', () => {
        showMessage('Connection restored! You can continue using the app.', 'success');
        
        // Retry failed operations
        retryFailedOperations();
    });
    
    window.addEventListener('offline', () => {
        showMessage('You are currently offline. Some features may not work properly.', 'warning');
    });
    
    // Form error recovery
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', (e) => {
            // Save form data before submission
            saveFormData(form);
        });
    });
}

function saveFormData(form) {
    const formData = new FormData(form);
    const data = {};
    
    for (let [key, value] of formData.entries()) {
        data[key] = value;
    }
    
    sessionStorage.setItem(`form_backup_${form.id}`, JSON.stringify(data));
}

function restoreFormData(form) {
    const savedData = sessionStorage.getItem(`form_backup_${form.id}`);
    
    if (savedData) {
        const data = JSON.parse(savedData);
        
        Object.entries(data).forEach(([key, value]) => {
            const field = form.querySelector(`[name="${key}"]`);
            if (field) {
                field.value = value;
            }
        });
        
        showMessage('Form data restored from previous session.', 'info');
    }
}

function retryFailedOperations() {
    // Retry any failed Firebase operations
    const failedOperations = JSON.parse(sessionStorage.getItem('failed_operations') || '[]');
    
    failedOperations.forEach(async (operation) => {
        try {
            switch (operation.type) {
                case 'user_profile_update':
                    await createOrUpdateUserProfile(operation.data);
                    break;
                case 'analytics_event':
                    trackEvent(operation.eventName, operation.parameters);
                    break;
            }
        } catch (error) {
            console.warn('Failed to retry operation:', operation, error);
        }
    });
    
    // Clear failed operations
    sessionStorage.removeItem('failed_operations');
}

// ==============================================
// FINAL INITIALIZATION
// ==============================================

// Initialize all advanced features when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Initialize advanced form validation
    initializeAdvancedFormValidation();
    
    // Initialize social proof
    initializeSocialProof();
    
    // Initialize advanced analytics
    initializeAdvancedAnalytics();
    
    // Initialize accessibility enhancements
    initializeAccessibilityEnhancements();
    
    // Initialize PWA features
    initializePWAFeatures();
    
    // Initialize performance optimizations
    initializePerformanceOptimizations();
    
    // Initialize advanced UX features
    initializeAdvancedUXFeatures();
    
    // Initialize testimonials carousel if needed
    initializeTestimonialsCarousel();
    
    console.log('🚀 All advanced features initialized successfully');
});

// ==============================================
// CLEANUP AND MEMORY MANAGEMENT
// ==============================================

// Clean up when page is about to unload
window.addEventListener('beforeunload', () => {
    // Clear any intervals
    const intervals = window.intervals || [];
    intervals.forEach(interval => clearInterval(interval));
    
    // Clear any timeouts
    const timeouts = window.timeouts || [];
    timeouts.forEach(timeout => clearTimeout(timeout));
    
    // Send final analytics
    trackEvent('page_unload', {
        'time_on_page': Math.round((Date.now() - window.pageLoadTime) / 1000),
        'max_scroll_depth': window.maxScrollDepth || 0
    });
});

// Store page load time for analytics
window.pageLoadTime = Date.now();

// ==============================================
// DEBUG MODE (for development)
// ==============================================

if (window.location.hostname === 'localhost' || window.location.search.includes('debug=true')) {
    window.debugMode = true;
    
    // Add debug panel
    const debugPanel = document.createElement('div');
    debugPanel.id = 'debug-panel';
    debugPanel.style.cssText = `
        position: fixed;
        top: 10px;
        left: 10px;
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 1rem;
        border-radius: 8px;
        font-family: monospace;
        font-size: 0.8rem;
        z-index: 10000;
        max-width: 300px;
        display: none;
    `;
    
    debugPanel.innerHTML = `
        <h4>Debug Panel</h4>
        <div id="debug-info"></div>
        <button onclick="this.parentNode.style.display='none'" style="margin-top: 0.5rem; padding: 0.25rem 0.5rem;">Close</button>
    `;
    
    document.body.appendChild(debugPanel);
    
    // Toggle debug panel with Ctrl+Shift+D
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.shiftKey && e.key === 'D') {
            e.preventDefault();
            debugPanel.style.display = debugPanel.style.display === 'none' ? 'block' : 'none';
            
            if (debugPanel.style.display === 'block') {
                updateDebugInfo();
            }
        }
    });
    
    function updateDebugInfo() {
        const debugInfo = document.getElementById('debug-info');
        if (debugInfo) {
            debugInfo.innerHTML = `
                <div>Firebase Auth: ${window.firebaseAuth ? '✅' : '❌'}</div>
                <div>Firebase DB: ${window.firebaseDb ? '✅' : '❌'}</div>
                <div>Stripe: ${stripe ? '✅' : '❌'}</div>
                <div>User: ${window.firebaseAuth?.currentUser?.email || 'Not signed in'}</div>
                <div>Page Load: ${window.pageLoadTime ? 'OK' : 'Error'}</div>
                <div>Memory: ${performance.memory ? Math.round(performance.memory.usedJSHeapSize / 1024 / 1024) + 'MB' : 'N/A'}</div>
            `;
        }
    }
    
       console.log('🐛 Debug mode enabled');
}

// ==============================================
// FEATURE FLAGS & A/B TESTING
// ==============================================

function initializeFeatureFlags() {
    // Simple feature flag system
    const featureFlags = {
        socialProof: true,
        advancedValidation: true,
        testimonialCarousel: false,
        emailSuggestions: true,
        installPrompt: true,
        contextualHelp: true
    };
    
    // Override with URL parameters for testing
    const urlParams = new URLSearchParams(window.location.search);
    Object.keys(featureFlags).forEach(flag => {
        if (urlParams.has(flag)) {
            featureFlags[flag] = urlParams.get(flag) === 'true';
        }
    });
    
    // Store flags globally
    window.featureFlags = featureFlags;
    
    // A/B test variants
    const userId = window.firebaseAuth?.currentUser?.uid || 'anonymous';
    const userHash = simpleHash(userId);
    const variant = userHash % 2 === 0 ? 'A' : 'B';
    
    window.abTestVariant = variant;
    
    // Track A/B test assignment
    trackEvent('ab_test_assigned', {
        'variant': variant,
        'user_type': window.firebaseAuth?.currentUser ? 'authenticated' : 'anonymous'
    });
    
    // Apply variant-specific changes
    applyABTestVariant(variant);
    
    console.log('🧪 Feature flags initialized:', featureFlags);
    console.log('🔬 A/B test variant:', variant);
}

function simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
}

function applyABTestVariant(variant) {
    if (variant === 'B') {
        // Variant B: Different CTA text
        const ctaButtons = document.querySelectorAll('.cta-primary .button-text');
        ctaButtons.forEach(button => {
            if (button.textContent.includes('Start Writing')) {
                button.textContent = 'Create My Thesis Now';
            }
        });
        
        // Variant B: Different hero subtitle
        const heroSubtitle = document.querySelector('.hero-subtitle');
        if (heroSubtitle) {
            heroSubtitle.textContent = 'Transform your research into a professional thesis in minutes with our AI-powered writing assistant.';
        }
        
        // Track variant B specific interactions
        document.addEventListener('click', (e) => {
            if (e.target.closest('.cta-primary')) {
                trackEvent('cta_clicked_variant_b');
            }
        });
    }
}

// ==============================================
// INTERNATIONALIZATION (i18n) SUPPORT
// ==============================================

function initializeInternationalization() {
    const userLanguage = navigator.language || navigator.userLanguage;
    const supportedLanguages = ['en', 'es', 'fr', 'de', 'pt'];
    const defaultLanguage = 'en';
    
    let currentLanguage = defaultLanguage;
    
    // Check if user's language is supported
    const languageCode = userLanguage.split('-')[0];
    if (supportedLanguages.includes(languageCode)) {
        currentLanguage = languageCode;
    }
    
    // Override with URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('lang') && supportedLanguages.includes(urlParams.get('lang'))) {
        currentLanguage = urlParams.get('lang');
    }
    
    // Store current language
    window.currentLanguage = currentLanguage;
    
    // Load translations if not English
    if (currentLanguage !== 'en') {
        loadTranslations(currentLanguage);
    }
    
    // Add language selector if multiple languages detected
    if (userLanguage !== 'en-US') {
        addLanguageSelector();
    }
}

function loadTranslations(language) {
    // Simple translation system - in production, load from external files
    const translations = {
        es: {
            'Generate Your Thesis with AI': 'Genera tu Tesis con IA',
            'Start Writing My Thesis': 'Comenzar a Escribir mi Tesis',
            'Free to start • No registration required': 'Gratis para empezar • No se requiere registro'
        },
        fr: {
            'Generate Your Thesis with AI': 'Générez votre Thèse avec l\'IA',
            'Start Writing My Thesis': 'Commencer à Écrire ma Thèse',
            'Free to start • No registration required': 'Gratuit pour commencer • Aucune inscription requise'
        }
    };
    
    const langTranslations = translations[language];
    if (langTranslations) {
        Object.entries(langTranslations).forEach(([original, translated]) => {
                       const elements = document.querySelectorAll('*');
            elements.forEach(element => {
                if (element.textContent.trim() === original) {
                    element.textContent = translated;
                }
            });
        });
    }
}

function addLanguageSelector() {
    const languageSelector = document.createElement('div');
    languageSelector.className = 'language-selector';
    languageSelector.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 1000;
        background: rgba(255, 255, 255, 0.9);
        backdrop-filter: blur(10px);
        border-radius: 8px;
        padding: 0.5rem;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    `;
    
    const languages = [
        { code: 'en', name: '🇺🇸 English' },
        { code: 'es', name: '🇪🇸 Español' },
        { code: 'fr', name: '🇫🇷 Français' },
        { code: 'de', name: '🇩🇪 Deutsch' },
        { code: 'pt', name: '🇧🇷 Português' }
    ];
    
    const select = document.createElement('select');
    select.style.cssText = `
        border: none;
        background: transparent;
        font-size: 0.9rem;
        cursor: pointer;
        outline: none;
    `;
    
    languages.forEach(lang => {
        const option = document.createElement('option');
        option.value = lang.code;
        option.textContent = lang.name;
        option.selected = lang.code === window.currentLanguage;
        select.appendChild(option);
    });
    
    select.addEventListener('change', (e) => {
        const newLang = e.target.value;
        const url = new URL(window.location);
        url.searchParams.set('lang', newLang);
        window.location.href = url.toString();
    });
    
    languageSelector.appendChild(select);
    document.body.appendChild(languageSelector);
}

// ==============================================
// ADVANCED SECURITY MEASURES
// ==============================================

function initializeSecurityMeasures() {
    // Content Security Policy violation reporting
    document.addEventListener('securitypolicyviolation', (e) => {
        console.warn('CSP Violation:', e);
        trackEvent('csp_violation', {
            'blocked_uri': e.blockedURI,
            'violated_directive': e.violatedDirective,
            'original_policy': e.originalPolicy
        });
    });
    
    // Detect and prevent common XSS attempts
    const suspiciousPatterns = [
        /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
        /javascript:/gi,
        /on\w+\s*=/gi
    ];
    
    function sanitizeInput(input) {
        let sanitized = input;
        suspiciousPatterns.forEach(pattern => {
            if (pattern.test(sanitized)) {
                console.warn('Suspicious input detected and sanitized');
                trackEvent('suspicious_input_detected', {
                    'input_length': input.length,
                    'pattern_matched': pattern.toString()
                });
                sanitized = sanitized.replace(pattern, '');
            }
        });
        return sanitized;
    }
    
    // Monitor form inputs for suspicious content
    const inputs = document.querySelectorAll('input[type="text"], input[type="email"], textarea');
    inputs.forEach(input => {
        input.addEventListener('input', (e) => {
            const sanitized = sanitizeInput(e.target.value);
            if (sanitized !== e.target.value) {
                e.target.value = sanitized;
                showMessage('Input has been sanitized for security reasons.', 'warning');
            }
        });
    });
    
    // Rate limiting for API calls
    window.rateLimiter = {
        calls: new Map(),
        isAllowed: function(key, maxCalls = 10, timeWindow = 60000) {
            const now = Date.now();
            const calls = this.calls.get(key) || [];
            
            // Remove old calls outside time window
            const recentCalls = calls.filter(time => now - time < timeWindow);
            
            if (recentCalls.length >= maxCalls) {
                return false;
            }
            
            recentCalls.push(now);
            this.calls.set(key, recentCalls);
            return true;
        }
    };
    
    // Prevent rapid form submissions
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', (e) => {
            const formId = form.id || 'default';
            if (!window.rateLimiter.isAllowed(`form_${formId}`, 3, 30000)) {
                e.preventDefault();
                showMessage('Please wait before submitting again.', 'warning');
                return false;
            }
        });
    });
}

// ==============================================
// ADVANCED ERROR BOUNDARY
// ==============================================

function initializeErrorBoundary() {
    // Create error boundary for critical sections
    const criticalSections = document.querySelectorAll('[data-critical]');
    
    criticalSections.forEach(section => {
        try {
            // Wrap critical functionality
            const originalContent = section.innerHTML;
            
            window.addEventListener('error', (error) => {
                if (section.contains(error.target)) {
                    console.error('Critical section error:', error);
                    
                    // Show fallback UI
                    section.innerHTML = `
                        <div style="
                            padding: 2rem;
                            text-align: center;
                            background: #f8f9fa;
                            border-radius: 8px;
                            border: 1px solid #dee2e6;
                        ">
                            <h3 style="color: #6c757d; margin-bottom: 1rem;">
                                ⚠️ Something went wrong
                            </h3>
                            <p style="color: #6c757d; margin-bottom: 1rem;">
                                This section encountered an error, but the rest of the page is working fine.
                            </p>
                            <button onclick="location.reload()" style="
                                background: #9D4EDD;
                                color: white;
                                border: none;
                                padding: 0.5rem 1rem;
                                border-radius: 4px;
                                cursor: pointer;
                            ">
                                Refresh Page
                            </button>
                        </div>
                    `;
                    
                    trackEvent('critical_section_error', {
                        'section_id': section.id || 'unknown',
                        'error_message': error.message
                    });
                }
            });
        } catch (error) {
            console.error('Error boundary setup failed:', error);
        }
    });
}

// ==============================================
// PERFORMANCE MONITORING & OPTIMIZATION
// ==============================================

function initializePerformanceMonitoring() {
    // Core Web Vitals monitoring
    if ('PerformanceObserver' in window) {
        // Largest Contentful Paint (LCP)
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            const lastEntry = entries[entries.length - 1];
            
            trackEvent('core_web_vital', {
                'metric': 'LCP',
                'value': Math.round(lastEntry.startTime),
                'rating': lastEntry.startTime < 2500 ? 'good' : lastEntry.startTime < 4000 ? 'needs_improvement' : 'poor'
            });
        }).observe({ entryTypes: ['largest-contentful-paint'] });
        
        // First Input Delay (FID)
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            entries.forEach(entry => {
                trackEvent('core_web_vital', {
                    'metric': 'FID',
                    'value': Math.round(entry.processingStart - entry.startTime),
                    'rating': entry.processingStart - entry.startTime < 100 ? 'good' : entry.processingStart - entry.startTime < 300 ? 'needs_improvement' : 'poor'
                });
            });
        }).observe({ entryTypes: ['first-input'] });
        
        // Cumulative Layout Shift (CLS)
        let clsValue = 0;
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            entries.forEach(entry => {
                if (!entry.hadRecentInput) {
                    clsValue += entry.value;
                }
            });
            
            trackEvent('core_web_vital', {
                'metric': 'CLS',
                'value': Math.round(clsValue * 1000) / 1000,
                'rating': clsValue < 0.1 ? 'good' : clsValue < 0.25 ? 'needs_improvement' : 'poor'
            });
        }).observe({ entryTypes: ['layout-shift'] });
    }
    
    // Resource loading performance
    window.addEventListener('load', () => {
        const navigation = performance.getEntriesByType('navigation')[0];
        const resources = performance.getEntriesByType('resource');
        
        // Track navigation timing
        trackEvent('navigation_timing', {
            'dns_lookup': Math.round(navigation.domainLookupEnd - navigation.domainLookupStart),
            'tcp_connect': Math.round(navigation.connectEnd - navigation.connectStart),
            'request_response': Math.round(navigation.responseEnd - navigation.requestStart),
            'dom_processing': Math.round(navigation.domContentLoadedEventEnd - navigation.responseEnd),
            'total_load_time': Math.round(navigation.loadEventEnd - navigation.navigationStart)
        });
        
        // Track slow resources
        resources.forEach(resource => {
            if (resource.duration > 1000) { // Resources taking more than 1 second
                trackEvent('slow_resource', {
                    'resource_name': resource.name.split('/').pop(),
                    'resource_type': resource.initiatorType,
                    'duration': Math.round(resource.duration),
                    'size': resource.transferSize || 0
                });
            }
        });
    });
    
    // Memory usage monitoring
    if ('memory' in performance) {
        setInterval(() => {
            const memory = performance.memory;
            const usagePercent = (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100;
            
            if (usagePercent > 80) {
                console.warn('High memory usage:', usagePercent + '%');
                trackEvent('high_memory_usage', {
                    'usage_percent': Math.round(usagePercent),
                    'used_heap_mb': Math.round(memory.usedJSHeapSize / 1024 / 1024),
                    'heap_limit_mb': Math.round(memory.jsHeapSizeLimit / 1024 / 1024)
                });
                
                // Trigger garbage collection if possible
                if (window.gc) {
                    window.gc();
                }
            }
        }, 30000);
    }
}

// ==============================================
// FINAL INITIALIZATION AND CLEANUP
// ==============================================

// Initialize all systems when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    try {
        // Initialize feature flags first
        initializeFeatureFlags();
        
        // Initialize internationalization
        initializeInternationalization();
        
        // Initialize security measures
        initializeSecurityMeasures();
        
        // Initialize error boundary
        initializeErrorBoundary();
        
        // Initialize performance monitoring
        initializePerformanceMonitoring();
        
        console.log('🎯 All systems initialized successfully');
        
        // Mark page as fully loaded
        document.body.classList.add('page-loaded');
        
        // Track successful initialization
        trackEvent('page_initialized', {
            'timestamp': Date.now(),
            'user_agent': navigator.userAgent,
            'viewport_width': window.innerWidth,
            'viewport_height': window.innerHeight,
            'language': navigator.language,
            'timezone': Intl.DateTimeFormat().resolvedOptions().timeZone
        });
        
    } catch (error) {
        console.error('Initialization error:', error);
        trackEvent('initialization_error', {
            'error_message': error.message,
            'error_stack': error.stack
        });
        
        // Show fallback UI
        showMessage('Some features may not work properly. Please refresh the page.', 'warning');
    }
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    try {
        // Clear all intervals and timeouts
        for (let i = 1; i < 99999; i++) {
            window.clearInterval(i);
            window.clearTimeout(i);
        }
        
        // Send final analytics
        if (window.firebaseAnalytics) {
            trackEvent('session_end', {
                'session_duration': Date.now() - window.pageLoadTime,
                'page_views': 1,
                'interactions': window.interactionCount || 0
            });
        }
        
        // Clear sensitive data from memory
        if (window.firebaseAuth) {
            // Don't actually sign out, just clear references
            window.firebaseAuth = null;
        }
        
        console.log('🧹 Page cleanup completed');
        
    } catch (error) {
        console.error('Cleanup error:', error);
    }
});

// ==============================================
// EXPORT GLOBAL FUNCTIONS
// ==============================================

// Make essential functions available globally
window.ThesisGenerator = {
    // Core functions
    showAuthModal,
    closeModal,
    selectPlan,
    trackEvent,
    showMessage,
    
    // Utility functions
    validateEmail,
    sanitizeInput: (input) => input, // Placeholder for actual sanitization
    
    // State management
    getCurrentUser: () => window.firebaseAuth?.currentUser || null,
    isAuthenticated: () => !!window.firebaseAuth?.currentUser,
    
    // Feature flags
    isFeatureEnabled: (flag) => window.featureFlags?.[flag] || false,
    getABTestVariant: () => window.abTestVariant || 'A',
    
    // Debug functions (only in debug mode)
    ...(window.debugMode && {
        getDebugInfo: () => ({
            firebaseAuth: !!window.firebaseAuth,
            firebaseDb: !!window.firebaseDb,
            stripe: !!stripe,
            currentUser: window.firebaseAuth?.currentUser?.email || null,
            featureFlags: window.featureFlags,
            abTestVariant: window.abTestVariant,
            performanceMetrics: performance.timing
        }),
        clearStorage: () => {
            localStorage.clear();
            sessionStorage.clear();
            console.log('Storage cleared');
        },
        simulateError: () => {
            throw new Error('Simulated error for testing');
        }
    })
};

// Final console message
console.log(`
🎓 Thesis Generator Landing Page
━━━━━━━━━━━━━━━━━━━━━━━━
✅ Core functionality loaded
✅ Firebase integration ready
✅ Authentication system active
✅ Payment processing configured
✅ Analytics tracking enabled
✅ Performance monitoring active
✅ Security measures in place
✅ Accessibility features enabled
✅ PWA capabilities ready
✅ Error handling configured

🚀 Ready to help users create amazing theses!

Debug mode: ${window.debugMode ? 'ON' : 'OFF'}
A/B Test variant: ${window.abTestVariant || 'A'}
Language: ${window.currentLanguage || 'en'}
Feature flags: ${Object.keys(window.featureFlags || {}).length} active

Use window.ThesisGenerator for API access
Press Ctrl+Shift+D for debug panel (localhost only)
`);

// ==============================================
// SERVICE WORKER INTEGRATION
// ==============================================

// Enhanced service worker registration with update handling
if ('serviceWorker' in navigator) {
    window.addEventListener('load', async () => {
        try {
            const registration = await navigator.serviceWorker.register('/sw.js', {
                scope: '/'
            });
            
            console.log('✅ Service Worker registered:', registration.scope);
            
            // Handle service worker updates
            registration.addEventListener('updatefound', () => {
                const newWorker = registration.installing;
                
                newWorker.addEventListener('statechange', () => {
                    if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                        // New version available
                        showUpdateNotification();
                    }
                });
            });
            
            // Listen for messages from service worker
            navigator.serviceWorker.addEventListener('message', (event) => {
                if (event.data && event.data.type === 'CACHE_UPDATED') {
                    console.log('📦 Cache updated:', event.data.payload);
                }
            });
            
            trackEvent('service_worker_registered');
            
        } catch (error) {
            console.warn('⚠️ Service Worker registration failed:', error);
            trackEvent('service_worker_registration_failed', {
                'error_message': error.message
            });
        }
    });
}

function showUpdateNotification() {
    const notification = document.createElement('div');
    notification.className = 'update-notification';
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: #9D4EDD;
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        box-shadow: 0 4px 20px rgba(157, 78, 221, 0.3);
        z-index: 10000;
        display: flex;
        align-items: center;
        gap: 1rem;
        animation: slideInDown 0.3s ease;
    `;
    
    notification.innerHTML = `
        <span>🔄 New version available!</span>
        <button onclick="window.location.reload()" style="
            background: white;
            color: #9D4EDD;
            border: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 600;
        ">Update</button>
        <button onclick="this.parentNode.remove()" style="
            background: transparent;
            color: white;
            border: 1px solid white;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            cursor: pointer;
        ">Later</button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-remove after 30 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 30000);
    
    trackEvent('update_notification_shown');
}

// ==============================================
// ADVANCED CACHING STRATEGY
// ==============================================

function initializeAdvancedCaching() {
    // Cache critical resources in memory
    const resourceCache = new Map();
    
    // Preload and cache critical resources
    const criticalResources = [
        '/app.html',
        '/css/app.css',
        '/js/app.js',
        '/favicon.png'
    ];
    
    criticalResources.forEach(async (resource) => {
        try {
            const response = await fetch(resource);
            if (response.ok) {
                const content = await response.text();
                resourceCache.set(resource, {
                    content,
                    timestamp: Date.now(),
                    contentType: response.headers.get('content-type')
                });
            }
        } catch (error) {
            console.warn('Failed to cache resource:', resource, error);
        }
    });
    
    // Cache API responses
    const apiCache = new Map();
    const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
    
    window.cachedFetch = async function(url, options = {}) {
        const cacheKey = `${url}_${JSON.stringify(options)}`;
        const cached = apiCache.get(cacheKey);
        
        if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
            return cached.response;
        }
        
        try {
            const response = await fetch(url, options);
            const clonedResponse = response.clone();
            
            apiCache.set(cacheKey, {
                response: clonedResponse,
                timestamp: Date.now()
            });
            
            return response;
        } catch (error) {
            // Return cached version if available, even if expired
            if (cached) {
                console.warn('Using expired cache due to network error:', url);
                return cached.response;
            }
            throw error;
        }
    };
    
    // Clean up expired cache entries
    setInterval(() => {
        const now = Date.now();
        
        for (const [key, value] of apiCache.entries()) {
            if (now - value.timestamp > CACHE_DURATION * 2) {
                apiCache.delete(key);
            }
        }
        
        for (const [key, value] of resourceCache.entries()) {
            if (now - value.timestamp > CACHE_DURATION * 10) {
                resourceCache.delete(key);
            }
        }
    }, CACHE_DURATION);
}

// ==============================================
// ADVANCED OFFLINE SUPPORT
// ==============================================

function initializeOfflineSupport() {
    let isOnline = navigator.onLine;
    const offlineQueue = [];
    
    // Update online status
    window.addEventListener('online', () => {
        isOnline = true;
        document.body.classList.remove('offline');
        showMessage('Connection restored! Processing queued actions...', 'success');
        processOfflineQueue();
    });
    
    window.addEventListener('offline', () => {
        isOnline = false;
        document.body.classList.add('offline');
        showMessage('You are offline. Actions will be queued until connection is restored.', 'warning');
    });
    
    // Queue actions when offline
    function queueOfflineAction(action) {
        offlineQueue.push({
            ...action,
            timestamp: Date.now()
        });
        
        // Store in localStorage for persistence
        localStorage.setItem('offline_queue', JSON.stringify(offlineQueue));
    }
    
    // Process queued actions when back online
    async function processOfflineQueue() {
        const queue = [...offlineQueue];
        offlineQueue.length = 0; // Clear queue
        
        for (const action of queue) {
            try {
                switch (action.type) {
                    case 'analytics_event':
                        trackEvent(action.eventName, action.parameters);
                        break;
                    case 'form_submission':
                        await submitForm(action.formData, action.endpoint);
                        break;
                    case 'user_action':
                        await processUserAction(action.actionData);
                        break;
                }
            } catch (error) {
                console.warn('Failed to process offline action:', action, error);
                // Re-queue failed actions
                queueOfflineAction(action);
            }
        }
        
        // Update localStorage
        localStorage.setItem('offline_queue', JSON.stringify(offlineQueue));
        
        if (queue.length > 0) {
            showMessage(`Processed ${queue.length} queued actions.`, 'success');
        }
    }
    
    // Load queued actions from localStorage on page load
    const savedQueue = localStorage.getItem('offline_queue');
    if (savedQueue) {
        try {
            const parsedQueue = JSON.parse(savedQueue);
            offlineQueue.push(...parsedQueue);
            
            if (isOnline && offlineQueue.length > 0) {
                setTimeout(processOfflineQueue, 1000);
            }
        } catch (error) {
            console.warn('Failed to load offline queue:', error);
            localStorage.removeItem('offline_queue');
        }
    }
    
    // Override trackEvent to work offline
    const originalTrackEvent = window.trackEvent;
    window.trackEvent = function(eventName, parameters = {}) {
        if (isOnline) {
            originalTrackEvent(eventName, parameters);
        } else {
            queueOfflineAction({
                type: 'analytics_event',
                eventName,
                parameters
            });
        }
    };
    
    // Add offline indicator to UI
    const offlineIndicator = document.createElement('div');
    offlineIndicator.className = 'offline-indicator';
    offlineIndicator.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        background: #dc3545;
        color: white;
        text-align: center;
        padding: 0.5rem;
        z-index: 10000;
        transform: translateY(-100%);
        transition: transform 0.3s ease;
    `;
    offlineIndicator.textContent = '📡 You are offline. Some features may not work properly.';
    
    document.body.appendChild(offlineIndicator);
    
    // Show/hide offline indicator
    function updateOfflineIndicator() {
        if (isOnline) {
            offlineIndicator.style.transform = 'translateY(-100%)';
        } else {
            offlineIndicator.style.transform = 'translateY(0)';
        }
    }
    
    window.addEventListener('online', updateOfflineIndicator);
    window.addEventListener('offline', updateOfflineIndicator);
    updateOfflineIndicator(); // Initial state
}

// ==============================================
// ADVANCED FORM HANDLING
// ==============================================

function initializeAdvancedFormHandling() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        // Auto-save form data
        const inputs = form.querySelectorAll('input, textarea, select');
        inputs.forEach(input => {
            input.addEventListener('input', debounce(() => {
                saveFormData(form);
            }, 1000));
        });
        
        // Restore form data on page load
        restoreFormData(form);
        
        // Enhanced form validation
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!validateForm(form)) {
                return;
            }
            
            const submitButton = form.querySelector('button[type="submit"]');
            const originalText = submitButton?.textContent;
            
            try {
                if (submitButton) {
                    submitButton.disabled = true;
                    submitButton.textContent = 'Processing...';
                }
                
                await handleFormSubmission(form);
                
                // Clear saved form data on successful submission
                sessionStorage.removeItem(`form_backup_${form.id}`);
                
            } catch (error) {
                console.error('Form submission error:', error);
                showMessage('Form submission failed. Please try again.', 'error');
                
                trackEvent('form_submission_error', {
                    'form_id': form.id,
                    'error_message': error.message
                });
                
            } finally {
                if (submitButton) {
                    submitButton.disabled = false;
                    submitButton.textContent = originalText;
                }
            }
        });
    });
}

function validateForm(form) {
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            showFieldError(field, 'This field is required');
            isValid = false;
        } else {
            clearFieldError(field);
        }
    });
    
    // Email validation
    const emailFields = form.querySelectorAll('input[type="email"]');
    emailFields.forEach(field => {
        if (field.value && !validateEmail(field.value)) {
            showFieldError(field, 'Please enter a valid email address');
            isValid = false;
        }
    });
    
    // Password confirmation
    const passwordField = form.querySelector('input[name="password"]');
    const confirmPasswordField = form.querySelector('input[name="confirm-password"]');
    
    if (passwordField && confirmPasswordField) {
        if (passwordField.value !== confirmPasswordField.value) {
            showFieldError(confirmPasswordField, 'Passwords do not match');
            isValid = false;
        }
    }
    
    return isValid;
}

function showFieldError(field, message) {
    clearFieldError(field);
    
    const errorEl = document.createElement('div');
    errorEl.className = 'field-error';
    errorEl.textContent = message;
    errorEl.style.cssText = `
        color: #dc3545;
        font-size: 0.8rem;
        margin-top: 0.25rem;
    `;
    
    field.parentNode.appendChild(errorEl);
    field.style.borderColor = '#dc3545';
    field.setAttribute('aria-invalid', 'true');
    field.setAttribute('aria-describedby', errorEl.id = `error-${Date.now()}`);
}

function clearFieldError(field) {
    const errorEl = field.parentNode.querySelector('.field-error');
    if (errorEl) {
        errorEl.remove();
    }
    field.style.borderColor = '';
    field.removeAttribute('aria-invalid');
    field.removeAttribute('aria-describedby');
}

async function handleFormSubmission(form) {
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());
    
    // Handle different form types
    if (form.id === 'auth-form') {
        await handleAuthFormSubmission(data);
    } else if (form.id === 'contact-form') {
        await handleContactFormSubmission(data);
    } else if (form.id === 'newsletter-form') {
        await handleNewsletterFormSubmission(data);
    }
}

// ==============================================
// UTILITY FUNCTIONS
// ==============================================

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function() {
          const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

function formatCurrency(amount, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency
    }).format(amount);
}

function formatDate(date, options = {}) {
    const defaultOptions = {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    };
    
    return new Intl.DateTimeFormat('en-US', { ...defaultOptions, ...options }).format(date);
}

function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
        return navigator.clipboard.writeText(text);
    } else {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        return new Promise((resolve, reject) => {
            document.execCommand('copy') ? resolve() : reject();
            textArea.remove();
        });
    }
}

function downloadFile(content, filename, contentType = 'text/plain') {
    const blob = new Blob([content], { type: contentType });
    const url = URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    link.style.display = 'none';
    
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    URL.revokeObjectURL(url);
}

function parseQueryParams() {
    const params = new URLSearchParams(window.location.search);
    const result = {};
    
    for (const [key, value] of params.entries()) {
        result[key] = value;
    }
    
    return result;
}

function updateQueryParams(params, replace = false) {
    const url = new URL(window.location);
    
    Object.entries(params).forEach(([key, value]) => {
        if (value === null || value === undefined) {
            url.searchParams.delete(key);
        } else {
            url.searchParams.set(key, value);
        }
    });
    
    if (replace) {
        window.history.replaceState({}, '', url);
    } else {
        window.history.pushState({}, '', url);
    }
}

// ==============================================
// ADVANCED ANALYTICS HELPERS
// ==============================================

function trackUserJourney(step, data = {}) {
    const journeyData = JSON.parse(sessionStorage.getItem('user_journey') || '[]');
    
    journeyData.push({
        step,
        timestamp: Date.now(),
        url: window.location.href,
        ...data
    });
    
    sessionStorage.setItem('user_journey', JSON.stringify(journeyData));
    
    trackEvent('user_journey_step', {
        'step': step,
        'journey_length': journeyData.length,
        ...data
    });
}

function getSessionData() {
    return {
        sessionId: sessionStorage.getItem('session_id') || generateUUID(),
        startTime: sessionStorage.getItem('session_start') || Date.now(),
        pageViews: parseInt(sessionStorage.getItem('page_views') || '0') + 1,
        referrer: document.referrer,
        userAgent: navigator.userAgent,
        language: navigator.language,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        screenResolution: `${screen.width}x${screen.height}`,
        viewportSize: `${window.innerWidth}x${window.innerHeight}`
    };
}

function initializeSessionTracking() {
    const sessionData = getSessionData();
    
    // Store session data
    sessionStorage.setItem('session_id', sessionData.sessionId);
    sessionStorage.setItem('session_start', sessionData.startTime);
    sessionStorage.setItem('page_views', sessionData.pageViews.toString());
    
    // Track session start
    if (sessionData.pageViews === 1) {
        trackEvent('session_start', sessionData);
    }
    
    // Track page view
    trackEvent('page_view', {
        'page_title': document.title,
        'page_url': window.location.href,
        'page_path': window.location.pathname,
        'session_id': sessionData.sessionId,
        'page_views': sessionData.pageViews
    });
}

// ==============================================
// ADVANCED ERROR HANDLING
// ==============================================

class ErrorHandler {
    constructor() {
        this.errors = [];
        this.maxErrors = 50;
        this.setupGlobalHandlers();
    }

    setupGlobalHandlers() {
        // JavaScript errors
        window.addEventListener('error', (event) => {
            this.handleError({
                type: 'javascript',
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error?.stack,
                timestamp: Date.now()
            });
        });

        // Promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError({
                type: 'promise_rejection',
                message: event.reason?.message || 'Unhandled promise rejection',
                stack: event.reason?.stack,
                timestamp: Date.now()
            });
        });

        // Resource loading errors
        window.addEventListener('error', (event) => {
            if (event.target !== window) {
                this.handleError({
                    type: 'resource',
                    message: `Failed to load ${event.target.tagName}: ${event.target.src || event.target.href}`,
                    element: event.target.tagName,
                    source: event.target.src || event.target.href,
                    timestamp: Date.now()
                });
            }
        }, true);
    }

    handleError(error) {
        // Add to error log
        this.errors.push(error);

        // Keep only recent errors
        if (this.errors.length > this.maxErrors) {
            this.errors = this.errors.slice(-this.maxErrors);
        }

        // Log to console (keep for debugging)
        console.error('Error captured:', error);

        // Track in analytics (keep for monitoring)
        trackEvent('error_occurred', {
            'error_type': error.type,
            'error_message': error.message,
            'error_filename': error.filename,
            'error_line': error.lineno,
            'user_agent': navigator.userAgent,
            'url': window.location.href
        });

        // ❌ REMOVED: No more user-facing error messages
        // The following lines are commented out to prevent error popups:
        /*
        if (this.isCriticalError(error)) {
            this.showErrorMessage(error);
        }
        */

        // Send to error reporting service (keep for monitoring)
        this.reportError(error);
    }

    // Keep this method for potential future use, but don't call it
    isCriticalError(error) {
        const criticalPatterns = [
            /firebase/i,
            /stripe/i,
            /payment/i,
            /authentication/i,
            /network/i
        ];

        return criticalPatterns.some(pattern =>
            pattern.test(error.message) || pattern.test(error.filename || '')
        );
    }

    // ❌ DISABLED: No more user-facing error messages
    showErrorMessage(error) {
        // This method is disabled to prevent error popups
        console.log('Error message suppressed:', error);
        // const message = this.getUserFriendlyMessage(error);
        // showMessage(message, 'error');
    }

    // Keep for potential future use
    getUserFriendlyMessage(error) {
        if (error.message.includes('firebase')) {
            return 'We\'re having trouble connecting to our servers. Please try again in a moment.';
        } else if (error.message.includes('stripe') || error.message.includes('payment')) {
            return 'Payment processing is temporarily unavailable. Please try again later.';
        } else if (error.message.includes('network') || error.message.includes('fetch')) {
            return 'Network connection issue. Please check your internet connection.';
        } else {
            return 'Something went wrong. Please refresh the page and try again.';
        }
    }

    reportError(error) {
        // Send to external error reporting service
        // This would typically be Sentry, LogRocket, or similar
        if (window.Sentry) {
            window.Sentry.captureException(new Error(error.message), {
                extra: error
            });
        }
    }

    getErrorReport() {
        return {
            errors: this.errors,
            userAgent: navigator.userAgent,
            url: window.location.href,
            timestamp: Date.now(),
            sessionId: sessionStorage.getItem('session_id')
        };
    }

    clearErrors() {
        this.errors = [];
    }
}

// Initialize error handler
window.errorHandler = new ErrorHandler();


// ==============================================
// ADVANCED LOADING STATES
// ==============================================

class LoadingManager {
    constructor() {
        this.loadingStates = new Map();
        this.createLoadingOverlay();
    }
    
    createLoadingOverlay() {
        this.overlay = document.createElement('div');
        this.overlay.className = 'global-loading-overlay';
        this.overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.8);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            backdrop-filter: blur(5px);
        `;
        
        this.overlay.innerHTML = `
            <div style="
                background: white;
                padding: 2rem;
                border-radius: 12px;
                text-align: center;
                max-width: 300px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            ">
                <div class="loading-spinner" style="
                    width: 40px;
                    height: 40px;
                    border: 3px solid #f3f3f3;
                    border-top: 3px solid #9D4EDD;
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 1rem;
                "></div>
                <div class="loading-text" style="
                    font-size: 1.1rem;
                    font-weight: 600;
                    color: #333;
                    margin-bottom: 0.5rem;
                ">Loading...</div>
                <div class="loading-subtext" style="
                    font-size: 0.9rem;
                    color: #666;
                ">Please wait</div>
            </div>
        `;
        
        document.body.appendChild(this.overlay);
    }
    
    show(key = 'default', text = 'Loading...', subtext = 'Please wait') {
        this.loadingStates.set(key, true);
        
        const textEl = this.overlay.querySelector('.loading-text');
        const subtextEl = this.overlay.querySelector('.loading-subtext');
        
        if (textEl) textEl.textContent = text;
        if (subtextEl) subtextEl.textContent = subtext;
        
        this.overlay.style.display = 'flex';
        document.body.classList.add('loading');
        
        // Prevent scrolling
        document.body.style.overflow = 'hidden';
    }
    
    hide(key = 'default') {
        this.loadingStates.delete(key);
        
        // Only hide if no other loading states are active
        if (this.loadingStates.size === 0) {
            this.overlay.style.display = 'none';
            document.body.classList.remove('loading');
            document.body.style.overflow = '';
        }
    }
    
    isLoading(key = 'default') {
        return this.loadingStates.has(key);
    }
    
    showProgress(progress, text = 'Loading...') {
        this.show('progress', text, `${Math.round(progress)}% complete`);
        
        // Add progress bar if not exists
        let progressBar = this.overlay.querySelector('.progress-bar');
        if (!progressBar) {
            progressBar = document.createElement('div');
            progressBar.className = 'progress-bar';
            progressBar.style.cssText = `
                width: 100%;
                height: 4px;
                background: #eee;
                border-radius: 2px;
                margin-top: 1rem;
                overflow: hidden;
            `;
            
            const progressFill = document.createElement('div');
            progressFill.className = 'progress-fill';
            progressFill.style.cssText = `
                height: 100%;
                background: linear-gradient(45deg, #9D4EDD, #FF48B0);
                border-radius: 2px;
                transition: width 0.3s ease;
                width: 0%;
            `;
            
            progressBar.appendChild(progressFill);
            this.overlay.querySelector('div').appendChild(progressBar);
        }
        
        const progressFill = progressBar.querySelector('.progress-fill');
        if (progressFill) {
            progressFill.style.width = `${Math.min(100, Math.max(0, progress))}%`;
        }
        
        if (progress >= 100) {
            setTimeout(() => this.hide('progress'), 500);
        }
    }
}

// Initialize loading manager
window.loadingManager = new LoadingManager();

// ==============================================
// FINAL INITIALIZATION SEQUENCE
// ==============================================

// Initialize all advanced systems
document.addEventListener('DOMContentLoaded', () => {
    // Initialize session tracking
    initializeSessionTracking();
    
    // Initialize advanced caching
    initializeAdvancedCaching();
    
    // Initialize offline support
    initializeOfflineSupport();
    
    // Initialize advanced form handling
    initializeAdvancedFormHandling();
    
    // Track initial user journey step
    trackUserJourney('landing_page_loaded', {
        'referrer': document.referrer,
        'utm_source': parseQueryParams().utm_source,
        'utm_medium': parseQueryParams().utm_medium,
        'utm_campaign': parseQueryParams().utm_campaign
    });
    
    console.log('🎯 Advanced systems fully initialized');
});

// Performance mark for initialization complete
performance.mark('landing-js-complete');

// Measure total initialization time
window.addEventListener('load', () => {
    performance.mark('page-load-complete');
    
    try {
                performance.measure('landing-js-duration', 'landing-js-start', 'landing-js-complete');
        performance.measure('total-load-duration', 'navigationStart', 'page-load-complete');
        
        const landingJsDuration = performance.getEntriesByName('landing-js-duration')[0];
        const totalLoadDuration = performance.getEntriesByName('total-load-duration')[0];
        
        trackEvent('performance_metrics', {
            'landing_js_duration': Math.round(landingJsDuration?.duration || 0),
            'total_load_duration': Math.round(totalLoadDuration?.duration || 0),
            'dom_content_loaded': Math.round(performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart),
            'first_paint': Math.round(performance.getEntriesByType('paint').find(entry => entry.name === 'first-paint')?.startTime || 0),
            'first_contentful_paint': Math.round(performance.getEntriesByType('paint').find(entry => entry.name === 'first-contentful-paint')?.startTime || 0)
        });
        
        console.log('📊 Performance metrics captured');
        
    } catch (error) {
        console.warn('Performance measurement failed:', error);
    }
});

// ==============================================
// EXPORT FOR TESTING
// ==============================================

if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        validateEmail,
        formatCurrency,
        formatDate,
        generateUUID,
        debounce,
        throttle,
        ErrorHandler,
        LoadingManager
    };
}

// ==============================================
// DEVELOPMENT HELPERS
// ==============================================

if (window.debugMode) {
    // Add development helpers to window
    window.dev = {
        // Simulate different network conditions
        simulateSlowNetwork: () => {
            const originalFetch = window.fetch;
            window.fetch = function(...args) {
                return new Promise(resolve => {
                    setTimeout(() => resolve(originalFetch.apply(this, args)), 2000);
                });
            };
            console.log('🐌 Slow network simulation enabled');
        },
        
        // Simulate offline mode
        simulateOffline: () => {
            window.dispatchEvent(new Event('offline'));
            console.log('📡 Offline mode simulated');
        },
        
        // Simulate online mode
        simulateOnline: () => {
            window.dispatchEvent(new Event('online'));
            console.log('🌐 Online mode simulated');
        },
        
        // Trigger test error
        triggerError: (message = 'Test error') => {
            throw new Error(message);
        },
        
        // Show all feature flags
        showFeatureFlags: () => {
            console.table(window.featureFlags);
        },
        
        // Toggle feature flag
        toggleFeature: (flag) => {
            if (window.featureFlags.hasOwnProperty(flag)) {
                window.featureFlags[flag] = !window.featureFlags[flag];
                console.log(`🎛️ Feature '${flag}' toggled to:`, window.featureFlags[flag]);
            } else {
                console.warn(`Feature '${flag}' not found`);
            }
        },
        
        // Show performance metrics
        showPerformance: () => {
            const navigation = performance.getEntriesByType('navigation')[0];
            const paint = performance.getEntriesByType('paint');
            
            console.group('📊 Performance Metrics');
            console.log('DNS Lookup:', Math.round(navigation.domainLookupEnd - navigation.domainLookupStart) + 'ms');
            console.log('TCP Connect:', Math.round(navigation.connectEnd - navigation.connectStart) + 'ms');
            console.log('Request/Response:', Math.round(navigation.responseEnd - navigation.requestStart) + 'ms');
            console.log('DOM Processing:', Math.round(navigation.domContentLoadedEventEnd - navigation.responseEnd) + 'ms');
            console.log('Total Load Time:', Math.round(navigation.loadEventEnd - navigation.navigationStart) + 'ms');
            
            paint.forEach(entry => {
                console.log(entry.name + ':', Math.round(entry.startTime) + 'ms');
            });
            
            if (performance.memory) {
                console.log('Memory Usage:', Math.round(performance.memory.usedJSHeapSize / 1024 / 1024) + 'MB');
            }
            console.groupEnd();
        },
        
        // Show error log
        showErrors: () => {
            console.table(window.errorHandler.errors);
        },
        
        // Clear all storage
        clearAllStorage: () => {
            localStorage.clear();
            sessionStorage.clear();
            if ('caches' in window) {
                caches.keys().then(names => {
                    names.forEach(name => caches.delete(name));
                });
            }
            console.log('🧹 All storage cleared');
        },
        
        // Show user journey
        showUserJourney: () => {
            const journey = JSON.parse(sessionStorage.getItem('user_journey') || '[]');
            console.table(journey);
        },
        
        // Simulate different screen sizes
        simulateScreenSize: (width, height) => {
            document.body.style.width = width + 'px';
            document.body.style.height = height + 'px';
            document.body.style.overflow = 'auto';
            window.dispatchEvent(new Event('resize'));
            console.log(`📱 Screen size simulated: ${width}x${height}`);
        },
        
        // Reset screen size
        resetScreenSize: () => {
            document.body.style.width = '';
            document.body.style.height = '';
            document.body.style.overflow = '';
            window.dispatchEvent(new Event('resize'));
            console.log('📱 Screen size reset');
        }
    };
    
    console.log('🛠️ Development helpers available at window.dev');
    console.log('Available commands:', Object.keys(window.dev));
}

// ==============================================
// FINAL CONSOLE MESSAGE
// ==============================================

console.log(`
🎓 Thesis Generator Landing Page - Fully Loaded
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Core Systems:
   • Firebase Authentication & Firestore
   • Stripe Payment Processing
   • Advanced Analytics & Tracking
   • Error Handling & Reporting
   • Performance Monitoring

✅ User Experience:
   • Responsive Design & Accessibility
   • Progressive Web App Features
   • Offline Support & Caching
   • Advanced Form Validation
   • Loading States & Feedback

✅ Developer Features:
   • Feature Flags & A/B Testing
   • Internationalization Support
   • Security Measures
   • Debug Mode & Development Tools
   • Comprehensive Error Boundary

🚀 Ready to convert visitors into thesis writers!

${window.debugMode ? '🐛 Debug Mode: ON - Use window.dev for development tools' : ''}
${window.abTestVariant ? '🧪 A/B Test Variant: ' + window.abTestVariant : ''}
${window.currentLanguage ? '🌍 Language: ' + window.currentLanguage : ''}

Performance: ${performance.now().toFixed(2)}ms initialization time
Memory: ${performance.memory ? (performance.memory.usedJSHeapSize / 1024 / 1024).toFixed(2) + 'MB' : 'N/A'}
`);

// Mark the end of script execution
performance.mark('landing-js-end');

// Set global ready flag
window.landingPageReady = true;

// Dispatch custom event for other scripts
window.dispatchEvent(new CustomEvent('landingPageReady', {
    detail: {
        timestamp: Date.now(),
        performanceMetrics: {
            initializationTime: performance.now(),
            memoryUsage: performance.memory?.usedJSHeapSize || 0
        },
        features: {
            featureFlags: window.featureFlags,
            abTestVariant: window.abTestVariant,
            language: window.currentLanguage,
            debugMode: window.debugMode
        }
    }
})); // End of IIFE

// ==============================================
// POLYFILLS FOR OLDER BROWSERS
// ==============================================

// IntersectionObserver polyfill
if (!window.IntersectionObserver) {
    console.warn('IntersectionObserver not supported, loading polyfill...');
    
    // Simple polyfill for basic functionality
    window.IntersectionObserver = class {
        constructor(callback) {
            this.callback = callback;
            this.elements = new Set();
        }
        
        observe(element) {
            this.elements.add(element);
            // Simple visibility check
            const rect = element.getBoundingClientRect();
            const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
            
            if (isVisible) {
                this.callback([{
                    target: element,
                    isIntersecting: true
                }]);
            }
        }
        
        unobserve(element) {
            this.elements.delete(element);
        }
        
        disconnect() {
            this.elements.clear();
        }
    };
}

// ResizeObserver polyfill
if (!window.ResizeObserver) {
    console.warn('ResizeObserver not supported, using fallback...');
    
    window.ResizeObserver = class {
        constructor(callback) {
            this.callback = callback;
            this.elements = new Set();
            this.lastSizes = new Map();
            
            // Use resize event as fallback
            window.addEventListener('resize', () => {
                this.checkSizes();
            });
        }
        
        observe(element) {
            this.elements.add(element);
            this.lastSizes.set(element, {
                width: element.offsetWidth,
                height: element.offsetHeight
            });
        }
        
        unobserve(element) {
            this.elements.delete(element);
            this.lastSizes.delete(element);
        }
        
        disconnect() {
            this.elements.clear();
            this.lastSizes.clear();
        }
        
        checkSizes() {
            this.elements.forEach(element => {
                const lastSize = this.lastSizes.get(element);
                const currentSize = {
                    width: element.offsetWidth,
                    height: element.offsetHeight
                };
                
                if (lastSize.width !== currentSize.width || lastSize.height !== currentSize.height) {
                    this.callback([{
                        target: element,
                        contentRect: currentSize
                    }]);
                    this.lastSizes.set(element, currentSize);
                }
            });
        }
    };
}

// CustomEvent polyfill for IE
if (!window.CustomEvent) {
    function CustomEvent(event, params) {
        params = params || { bubbles: false, cancelable: false, detail: null };
        const evt = document.createEvent('CustomEvent');
        evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
        return evt;
    }
    window.CustomEvent = CustomEvent;
}

// ==============================================
// END OF LANDING.JS
// ==============================================

console.log('📄 landing.js loaded successfully - ' + new Date().toISOString());


