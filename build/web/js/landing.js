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
    // Intersection Observer for scroll animations
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
        }
      });
    }, observerOptions);

    // Observe elements for animation
    const animatedElements = document.querySelectorAll(
      '.benefit-card, .testimonial-card, .step, .feature-row, .pricing-card'
    );
    
    animatedElements.forEach(el => {
      observer.observe(el);
    });
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
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const landingPage = new LandingPage();
  
  // Handle window resize
  window.addEventListener('resize', () => {
    landingPage.handleResize();
  });
  
  // Make showNotification globally available
  window.showNotification = (message, type) => {
    landingPage.showNotification(message, type);
  };
});

// Performance monitoring
window.addEventListener('load', () => {
  console.log('🚀 Landing page loaded successfully');
  
  // Log performance metrics
  if ('performance' in window) {
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
    console.log(`⚡ Page load time: ${loadTime}ms`);
  }
});

console.log('📄 Modern landing page scripts loaded');
