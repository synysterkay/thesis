// Modern Landing Page - Clean Design
class LandingPage {
  constructor() {
    this.init();
  }

  init() {
    this.setupNavigation();
    this.setupScrollEffects();
    this.setupFAQ();
    this.setupStats();
    this.setupAnimations();
    this.setupCookieConsent();
    this.setupFormHandling();
    this.setupVisibilityFixes();
  }

  setupNavigation() {
    // Mobile menu toggle
    const navToggle = document.getElementById('nav-toggle');
    const navMenu = document.getElementById('nav-menu');
    
    if (navToggle && navMenu) {
      navToggle.addEventListener('click', () => {
        navMenu.classList.toggle('active');
        navToggle.classList.toggle('active');
        document.body.classList.toggle('nav-open');
      });

      // Close menu when clicking outside
      document.addEventListener('click', (e) => {
        if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
          navMenu.classList.remove('active');
          navToggle.classList.remove('active');
          document.body.classList.remove('nav-open');
        }
      });
    }

    // Smooth scrolling for nav links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          // Close mobile menu if open
          if (navMenu && navToggle) {
            navMenu.classList.remove('active');
            navToggle.classList.remove('active');
            document.body.classList.remove('nav-open');
          }
          
          // Smooth scroll to target
          target.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      });
    });
  }

  setupScrollEffects() {
    // Scroll progress bar
    const progressBar = document.querySelector('.scroll-progress');
    if (progressBar) {
      window.addEventListener('scroll', () => {
        const scrolled = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
        progressBar.style.width = Math.min(scrolled, 100) + '%';
      });
    }

    // Back to top button
    const backToTop = document.getElementById('back-to-top');
    if (backToTop) {
      window.addEventListener('scroll', () => {
        if (window.scrollY > 300) {
          backToTop.style.display = 'flex';
        } else {
          backToTop.style.display = 'none';
        }
      });

      backToTop.addEventListener('click', () => {
        window.scrollTo({ 
          top: 0, 
          behavior: 'smooth' 
        });
      });
    }

    // Navbar background on scroll
    const navbar = document.getElementById('navbar');
    if (navbar) {
      window.addEventListener('scroll', () => {
        if (window.scrollY > 20) {
          navbar.classList.add('scrolled');
        } else {
          navbar.classList.remove('scrolled');
        }
      });
    }
  }

  setupFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
      const question = item.querySelector('.faq-question');
      const answer = item.querySelector('.faq-answer');
      const icon = item.querySelector('.faq-icon');

      if (question && answer && icon) {
        question.addEventListener('click', () => {
          const isOpen = question.getAttribute('aria-expanded') === 'true';
          
          // Close all other FAQ items
          faqItems.forEach(otherItem => {
            if (otherItem !== item) {
              const otherQuestion = otherItem.querySelector('.faq-question');
              const otherAnswer = otherItem.querySelector('.faq-answer');
              const otherIcon = otherItem.querySelector('.faq-icon');
              
              if (otherQuestion && otherAnswer && otherIcon) {
                otherQuestion.setAttribute('aria-expanded', 'false');
                otherAnswer.style.maxHeight = '0';
                otherIcon.className = 'fas fa-plus faq-icon';
              }
            }
          });

          // Toggle current item
          if (isOpen) {
            question.setAttribute('aria-expanded', 'false');
            answer.style.maxHeight = '0';
            icon.className = 'fas fa-plus faq-icon';
          } else {
            question.setAttribute('aria-expanded', 'true');
            answer.style.maxHeight = answer.scrollHeight + 'px';
            icon.className = 'fas fa-minus faq-icon';
          }
        });
      }
    });
  }

  setupStats() {
    // Animated counters with Intersection Observer
    const observerOptions = {
      threshold: 0.5,
      rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const target = entry.target;
          const finalNumber = parseInt(target.dataset.target);
          this.animateCounter(target, finalNumber);
          observer.unobserve(target);
        }
      });
    }, observerOptions);

    document.querySelectorAll('.stat-number').forEach(stat => {
      observer.observe(stat);
    });
  }

  animateCounter(element, target) {
    let current = 0;
    const increment = target / 60; // Smoother animation
    const duration = 2000; // 2 seconds
    const stepTime = duration / 60;

    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        element.textContent = target;
        clearInterval(timer);
      } else {
        element.textContent = Math.floor(current);
      }
    }, stepTime);
  }

  setupAnimations() {
    // First ensure all content is visible immediately
    const animatedElements = document.querySelectorAll(
      '.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card'
    );
    
    // Make content visible immediately to prevent blank sections
    animatedElements.forEach(el => {
      el.style.opacity = '1';
      el.style.visibility = 'visible';
      el.style.transform = 'translateY(0)';
      el.classList.add('animate-in');
    });

    // Only add intersection observer animations if user doesn't prefer reduced motion
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
      };

      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
            // Add a subtle animation effect
            entry.target.style.transform = 'translateY(0)';
            entry.target.style.opacity = '1';
          }
        });
      }, observerOptions);

      // Re-observe elements for enhanced animation
      animatedElements.forEach(el => {
        // Reset for animation
        el.style.transform = 'translateY(20px)';
        el.style.opacity = '0.8';
        observer.observe(el);
      });
    }
  }

  setupVisibilityFixes() {
    // Emergency visibility fix for all content sections
    const contentSections = [
      '.benefits-grid',
      '.steps',
      '.pricing-grid', 
      '.features-list',
      '.testimonials-grid'
    ];

    contentSections.forEach(selector => {
      const section = document.querySelector(selector);
      if (section) {
        section.style.opacity = '1';
        section.style.visibility = 'visible';
        section.style.display = section.classList.contains('steps') ? 'flex' : 
                                section.classList.contains('features-list') ? 'block' : 'grid';
      }
    });

    // Ensure all cards are visible
    const allCards = document.querySelectorAll(
      '.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card'
    );
    
    allCards.forEach(card => {
      card.style.opacity = '1';
      card.style.visibility = 'visible';
      card.style.display = 'block';
      card.style.transform = 'none';
    });

    // Fix specific layout issues
    this.fixLayoutIssues();
  }

  fixLayoutIssues() {
    // Fix steps layout
    const stepsContainer = document.querySelector('.steps');
    if (stepsContainer) {
      stepsContainer.style.display = 'flex';
      stepsContainer.style.flexWrap = 'wrap';
      stepsContainer.style.justifyContent = 'center';
      stepsContainer.style.alignItems = 'flex-start';
      stepsContainer.style.gap = '2rem';
    }

    // Fix features list
    const featuresList = document.querySelector('.features-list');
    if (featuresList) {
      featuresList.style.display = 'block';
      featuresList.style.maxWidth = '800px';
      featuresList.style.margin = '0 auto';
    }

    // Fix pricing grid
    const pricingGrid = document.querySelector('.pricing-grid');
    if (pricingGrid) {
      pricingGrid.style.display = 'grid';
      pricingGrid.style.gridTemplateColumns = 'repeat(auto-fit, minmax(350px, 1fr))';
      pricingGrid.style.gap = '2rem';
    }

    // Fix benefits grid
    const benefitsGrid = document.querySelector('.benefits-grid');
    if (benefitsGrid) {
      benefitsGrid.style.display = 'grid';
      benefitsGrid.style.gridTemplateColumns = 'repeat(auto-fit, minmax(350px, 1fr))';
      benefitsGrid.style.gap = '2rem';
    }

    // Fix testimonials grid
    const testimonialsGrid = document.querySelector('.testimonials-grid');
    if (testimonialsGrid) {
      testimonialsGrid.style.display = 'grid';
      testimonialsGrid.style.gridTemplateColumns = 'repeat(auto-fit, minmax(350px, 1fr))';
      testimonialsGrid.style.gap = '2rem';
    }
  }

  setupCookieConsent() {
    // Cookie consent is optional - only run if elements exist
    const cookieBanner = document.getElementById('cookie-banner');
    const acceptBtn = document.getElementById('accept-cookies');
    const declineBtn = document.getElementById('decline-cookies');

    // Check if user has already made a choice
    const cookieChoice = localStorage.getItem('cookieConsent');
    
    if (!cookieChoice && cookieBanner) {
      setTimeout(() => {
        cookieBanner.style.display = 'block';
      }, 3000); // Show after 3 seconds
    }

    if (acceptBtn) {
      acceptBtn.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'accepted');
        if (cookieBanner) {
          cookieBanner.style.display = 'none';
        }
        
        // Enable analytics
        if (typeof gtag !== 'undefined') {
          gtag('consent', 'update', {
            'analytics_storage': 'granted'
          });
        }
        
        this.showNotification('Cookie preferences saved', 'success');
      });
    }

    if (declineBtn) {
      declineBtn.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'declined');
        if (cookieBanner) {
          cookieBanner.style.display = 'none';
        }
        
        this.showNotification('Cookie preferences saved', 'info');
      });
    }
  }

  setupFormHandling() {
    // Handle any forms on the page
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        this.handleFormSubmit(form);
      });
    });
  }

  handleFormSubmit(form) {
    const formData = new FormData(form);
    const data = Object.fromEntries(formData);
    
    // Show loading state
    this.showLoading();
    
    // Simulate form submission
    setTimeout(() => {
      this.hideLoading();
      this.showNotification('Thank you! We\'ll be in touch soon.', 'success');
      form.reset();
    }, 2000);
  }

  showLoading() {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
      overlay.style.display = 'flex';
      document.body.style.overflow = 'hidden';
    }
  }

  hideLoading() {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
      overlay.style.display = 'none';
      document.body.style.overflow = '';
    }
  }

  showNotification(message, type = 'info') {
    const toast = document.getElementById('notification-toast');
    if (!toast) return;

    const icon = toast.querySelector('.toast-icon');
    const messageEl = toast.querySelector('.toast-message');
    
    // Set icon based on type
    const icons = {
      success: 'fas fa-check-circle',
      error: 'fas fa-exclamation-circle',
      warning: 'fas fa-exclamation-triangle',
      info: 'fas fa-info-circle'
    };
    
    if (icon) icon.className = icons[type] || icons.info;
    if (messageEl) messageEl.textContent = message;
    
    // Set colors based on type
    const colors = {
      success: '#10b981',
      error: '#ef4444',
      warning: '#f59e0b',
      info: '#2563eb'
    };
    
    toast.style.background = colors[type] || colors.info;
    toast.style.display = 'flex';
    toast.classList.add('show');
    
    // Auto hide after 5 seconds
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => {
        toast.style.display = 'none';
      }, 300);
    }, 5000);
  }

  // Utility method to handle responsive behavior
  handleResize() {
    const navMenu = document.getElementById('nav-menu');
    const navToggle = document.getElementById('nav-toggle');
    
    if (window.innerWidth > 768) {
      if (navMenu) navMenu.classList.remove('active');
      if (navToggle) navToggle.classList.remove('active');
      document.body.classList.remove('nav-open');
    }

    // Re-fix layouts on resize
    this.fixLayoutIssues();
  }

  // Debug method to check visibility
  debugVisibility() {
    const sections = [
      '.benefits',
      '.how-it-works', 
      '.pricing',
      '.features-showcase',
      '.testimonials'
    ];

    sections.forEach(selector => {
      const section = document.querySelector(selector);
      if (section) {
               console.log(`${selector}:`, {
          display: getComputedStyle(section).display,
          visibility: getComputedStyle(section).visibility,
          opacity: getComputedStyle(section).opacity,
          height: section.offsetHeight
        });
      }
    });

    const cards = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card');
    console.log(`Found ${cards.length} content cards`);
    
    cards.forEach((card, index) => {
      const styles = getComputedStyle(card);
      console.log(`Card ${index}:`, {
        display: styles.display,
        visibility: styles.visibility,
        opacity: styles.opacity,
        transform: styles.transform
      });
    });
  }

  // Force visibility method as last resort
  forceVisibility() {
    const style = document.createElement('style');
    style.textContent = `
      .benefit-card, .testimonial-card, .step, .feature-row, .pricing-card {
        opacity: 1 !important;
        visibility: visible !important;
        display: block !important;
        transform: none !important;
      }
      
      .benefits-grid, .testimonials-grid, .pricing-grid {
        display: grid !important;
        opacity: 1 !important;
        visibility: visible !important;
      }
      
      .steps {
        display: flex !important;
        opacity: 1 !important;
        visibility: visible !important;
      }
      
      .features-list {
        display: block !important;
        opacity: 1 !important;
        visibility: visible !important;
      }
    `;
    document.head.appendChild(style);
    
    console.log('🔧 Force visibility styles applied');
  }

  // Initialize content visibility immediately
  initializeContentVisibility() {
    // Run multiple times to ensure content shows
    this.setupVisibilityFixes();
    
    setTimeout(() => {
      this.setupVisibilityFixes();
    }, 100);
    
    setTimeout(() => {
      this.setupVisibilityFixes();
      this.debugVisibility();
    }, 500);
    
    // Force visibility as backup
    setTimeout(() => {
      const hiddenElements = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card');
      let hasHiddenContent = false;
      
      hiddenElements.forEach(el => {
        const styles = getComputedStyle(el);
        if (styles.opacity === '0' || styles.visibility === 'hidden' || styles.display === 'none') {
          hasHiddenContent = true;
        }
      });
      
      if (hasHiddenContent) {
        console.warn('⚠️ Hidden content detected, applying force visibility');
        this.forceVisibility();
      }
    }, 1000);
  }
}

// Enhanced initialization with multiple fallbacks
document.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 Initializing landing page...');
  
  const landingPage = new LandingPage();
  
  // Initialize content visibility immediately
  landingPage.initializeContentVisibility();
  
  // Handle window resize
  window.addEventListener('resize', () => {
    landingPage.handleResize();
  });
  
  // Make methods globally available for debugging
  window.landingPage = landingPage;
  window.showNotification = (message, type) => {
    landingPage.showNotification(message, type);
  };
  window.debugVisibility = () => {
    landingPage.debugVisibility();
  };
  window.forceVisibility = () => {
    landingPage.forceVisibility();
  };
  
  console.log('✅ Landing page initialized successfully');
});

// Backup initialization if DOMContentLoaded already fired
if (document.readyState === 'loading') {
  // DOMContentLoaded has not fired yet
} else {
  // DOMContentLoaded has already fired
  console.log('🔄 DOM already loaded, initializing immediately...');
  const landingPage = new LandingPage();
  landingPage.initializeContentVisibility();
  
  window.landingPage = landingPage;
  window.showNotification = (message, type) => {
    landingPage.showNotification(message, type);
  };
}

// Performance monitoring
window.addEventListener('load', () => {
  console.log('🚀 Landing page fully loaded');
  
  // Final visibility check
  setTimeout(() => {
    const allSections = document.querySelectorAll('.benefits, .how-it-works, .pricing, .features-showcase, .testimonials');
    const allCards = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card');
    
    console.log(`📊 Page stats: ${allSections.length} sections, ${allCards.length} content cards`);
    
    // Check if any content is still hidden
    let hiddenCount = 0;
    allCards.forEach(card => {
      const styles = getComputedStyle(card);
      if (styles.opacity === '0' || styles.visibility === 'hidden') {
        hiddenCount++;
      }
    });
    
    if (hiddenCount > 0) {
      console.warn(`⚠️ ${hiddenCount} cards still hidden, applying emergency fix`);
      if (window.landingPage) {
        window.landingPage.forceVisibility();
      }
    } else {
      console.log('✅ All content is visible');
    }
  }, 2000);
  
  // Log performance metrics
  if ('performance' in window) {
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
    console.log(`⚡ Page load time: ${loadTime}ms`);
    
    // Track performance with analytics if available
    if (typeof gtag !== 'undefined') {
      gtag('event', 'timing_complete', {
        'name': 'load',
        'value': loadTime
      });
    }
  }
});

// Error handling
window.addEventListener('error', (e) => {
  console.error('❌ JavaScript error:', e.error);
  
  // Try to ensure content is still visible even if there are errors
  setTimeout(() => {
    if (window.landingPage) {
      window.landingPage.forceVisibility();
    }
  }, 100);
  
  // Track errors with analytics if available
  if (typeof gtag !== 'undefined') {
    gtag('event', 'exception', {
      'description': e.error?.toString() || 'Unknown error',
      'fatal': false
    });
  }
});

// Handle unhandled promise rejections
window.addEventListener('unhandledrejection', (e) => {
  console.error('❌ Unhandled promise rejection:', e.reason);
  
  // Track with analytics if available
  if (typeof gtag !== 'undefined') {
    gtag('event', 'exception', {
      'description': 'Promise rejection: ' + (e.reason?.toString() || 'Unknown'),
      'fatal': false
    });
  }
});

// Intersection Observer polyfill check
if (!('IntersectionObserver' in window)) {
  console.warn('⚠️ IntersectionObserver not supported, loading polyfill...');
  
  // Fallback: make all content visible immediately
  document.addEventListener('DOMContentLoaded', () => {
    const allCards = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card');
    allCards.forEach(card => {
      card.style.opacity = '1';
      card.style.visibility = 'visible';
      card.style.transform = 'none';
      card.classList.add('animate-in');
    });
  });
}

// CSS animation support check
const supportsAnimations = CSS.supports('animation', 'none');
if (!supportsAnimations) {
  console.warn('⚠️ CSS animations not supported');
  
  // Ensure content is visible without animations
  document.addEventListener('DOMContentLoaded', () => {
    const style = document.createElement('style');
    style.textContent = `
      .benefit-card, .testimonial-card, .step, .feature-row, .pricing-card {
        opacity: 1 !important;
        visibility: visible !important;
        transform: none !important;
      }
    `;
    document.head.appendChild(style);
  });
}

// Reduced motion preference handling
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  console.log('🎯 Reduced motion preferred, disabling animations');
  
  document.addEventListener('DOMContentLoaded', () => {
    const style = document.createElement('style');
    style.textContent = `
      *, *::before, *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
      }
      
      .benefit-card, .testimonial-card, .step, .feature-row, .pricing-card {
        opacity: 1 !important;
        visibility: visible !important;
        transform: none !important;
      }
    `;
    document.head.appendChild(style);
  });
}

// Debug mode activation
if (window.location.search.includes('debug=true')) {
  console.log('🐛 Debug mode activated');
  
  window.addEventListener('load', () => {
    setTimeout(() => {
      if (window.debugVisibility) {
        window.debugVisibility();
      }
    }, 1000);
  });
}

// Final safety net - ensure content is visible after everything loads
setTimeout(() => {
  const criticalElements = document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card');
  
  criticalElements.forEach(el => {
    if (getComputedStyle(el).opacity === '0' || getComputedStyle(el).visibility === 'hidden') {
      el.style.opacity = '1';
      el.style.visibility = 'visible';
      el.style.transform = 'none';
      el.style.display = 'block';
    }
  });
  
  console.log('🛡️ Final safety net applied');
}, 3000);

console.log('📄 Modern landing page scripts loaded successfully');
