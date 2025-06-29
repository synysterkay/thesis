// Landing page interactions and animations
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
  }

  setupNavigation() {
    // Mobile menu toggle
    const navToggle = document.getElementById('nav-toggle');
    const navMenu = document.getElementById('nav-menu');
    
    if (navToggle && navMenu) {
      navToggle.addEventListener('click', () => {
        navMenu.classList.toggle('active');
        navToggle.classList.toggle('active');
      });
    }

    // Smooth scrolling for nav links
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
  }

  setupScrollEffects() {
    // Scroll progress bar
    const progressBar = document.querySelector('.scroll-progress');
    if (progressBar) {
      window.addEventListener('scroll', () => {
        const scrolled = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
        progressBar.style.setProperty('--scroll-progress', scrolled + '%');
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
        window.scrollTo({ top: 0, behavior: 'smooth' });
      });
    }

    // Navbar background on scroll
    const navbar = document.getElementById('navbar');
    if (navbar) {
      window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
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
            const otherQuestion = otherItem.querySelector('.faq-question');
            const otherAnswer = otherItem.querySelector('.faq-answer');
            const otherIcon = otherItem.querySelector('.faq-icon');
            
            if (otherItem !== item) {
              otherQuestion.setAttribute('aria-expanded', 'false');
              otherAnswer.style.display = 'none';
              otherIcon.textContent = '+';
            }
          });

          // Toggle current item
          if (isOpen) {
            question.setAttribute('aria-expanded', 'false');
            answer.style.display = 'none';
            icon.textContent = '+';
          } else {
            question.setAttribute('aria-expanded', 'true');
            answer.style.display = 'block';
            icon.textContent = '−';
          }
        });
      }
    });
  }

  setupStats() {
    // Animated counters
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
    const increment = target / 50;
    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        element.textContent = target;
        clearInterval(timer);
      } else {
        element.textContent = Math.floor(current);
      }
    }, 30);
  }

  setupAnimations() {
    // Intersection Observer for animations
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
    document.querySelectorAll('.benefit-card, .testimonial-card, .step, .feature-row').forEach(el => {
      observer.observe(el);
    });
  }

  setupCookieConsent() {
    const cookieBanner = document.getElementById('cookie-banner');
    const acceptBtn = document.getElementById('accept-cookies');
    const declineBtn = document.getElementById('decline-cookies');

    // Check if user has already made a choice
    const cookieChoice = localStorage.getItem('cookieConsent');
    
    if (!cookieChoice && cookieBanner) {
      setTimeout(() => {
        cookieBanner.style.display = 'block';
      }, 2000);
    }

    if (acceptBtn) {
      acceptBtn.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'accepted');
        if (cookieBanner) cookieBanner.style.display = 'none';
        
        // Enable analytics
        if (typeof gtag !== 'undefined') {
          gtag('consent', 'update', {
            'analytics_storage': 'granted'
          });
        }
      });
    }

    if (declineBtn) {
      declineBtn.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'declined');
        if (cookieBanner) cookieBanner.style.display = 'none';
      });
    }
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new LandingPage();
  });
} else {
  new LandingPage();
}

console.log('📄 Landing page scripts loaded');
