// ==============================================
// THESIS GENERATOR SERVICE WORKER
// Advanced PWA functionality with caching strategies
// ==============================================

const CACHE_NAME = 'thesis-generator-v2.1';
const STATIC_CACHE = 'thesis-static-v2.1';
const DYNAMIC_CACHE = 'thesis-dynamic-v2.1';
const API_CACHE = 'thesis-api-v2.1';

// Static assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/app.html',
  '/success.html',
  '/cancel.html',
  '/css/landing.css',
  '/js/landing.js',
  '/js/payment-manager.js',
  '/js/auth-manager.js',
  '/js/firebase-config.js',
  '/favicon.png',
  '/favicon.ico',
  '/manifest.json',
  '/offline.html'
];

// API endpoints to cache
const API_ENDPOINTS = [
  '/api/subscription',
  '/api/user',
  '/api/thesis'
];

// Cache strategies
const CACHE_STRATEGIES = {
  CACHE_FIRST: 'cache-first',
  NETWORK_FIRST: 'network-first',
  STALE_WHILE_REVALIDATE: 'stale-while-revalidate',
  NETWORK_ONLY: 'network-only',
  CACHE_ONLY: 'cache-only'
};

// ==============================================
// INSTALL EVENT - Cache static assets
// ==============================================
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker: Installing...');
  
  event.waitUntil(
    Promise.all([
      // Cache static assets
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('📦 Service Worker: Caching static assets');
        return cache.addAll(STATIC_ASSETS.map(url => new Request(url, {
          cache: 'reload'
        })));
      }),
      
      // Cache shell for offline functionality
      caches.open(DYNAMIC_CACHE).then((cache) => {
        console.log('🏠 Service Worker: Caching app shell');
        return cache.add('/offline.html');
      })
    ]).then(() => {
      console.log('✅ Service Worker: Installation complete');
      // Force activation of new service worker
      return self.skipWaiting();
    }).catch((error) => {
      console.error('❌ Service Worker: Installation failed', error);
    })
  );
});

// ==============================================
// ACTIVATE EVENT - Clean up old caches
// ==============================================
self.addEventListener('activate', (event) => {
  console.log('🚀 Service Worker: Activating...');
  
  event.waitUntil(
    Promise.all([
      // Clean up old caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE && 
                cacheName !== DYNAMIC_CACHE && 
                cacheName !== API_CACHE &&
                cacheName !== CACHE_NAME) {
              console.log('🗑️ Service Worker: Deleting old cache', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      
      // Take control of all clients
      self.clients.claim()
    ]).then(() => {
      console.log('✅ Service Worker: Activation complete');
    }).catch((error) => {
      console.error('❌ Service Worker: Activation failed', error);
    })
  );
});

// ==============================================
// FETCH EVENT - Handle network requests
// ==============================================
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip chrome-extension and other non-http requests
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // Handle different types of requests
  if (isStaticAsset(request)) {
    event.respondWith(handleStaticAsset(request));
  } else if (isAPIRequest(request)) {
    event.respondWith(handleAPIRequest(request));
  } else if (isNavigationRequest(request)) {
    event.respondWith(handleNavigationRequest(request));
  } else {
    event.respondWith(handleDynamicRequest(request));
  }
});

// ==============================================
// REQUEST HANDLERS
// ==============================================

// Handle static assets (CSS, JS, images)
async function handleStaticAsset(request) {
  try {
    // Cache first strategy for static assets
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // If not in cache, fetch from network and cache
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('❌ Static asset fetch failed:', error);
    
    // Return cached version if available
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Return offline fallback for images
    if (request.destination === 'image') {
      return new Response(
        '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"><rect width="200" height="200" fill="#f0f0f0"/><text x="100" y="100" text-anchor="middle" dy=".3em" fill="#999">Image Offline</text></svg>',
        { headers: { 'Content-Type': 'image/svg+xml' } }
      );
    }
    
    throw error;
  }
}

// Handle API requests
async function handleAPIRequest(request) {
  try {
    // Network first strategy for API requests
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Cache successful API responses
      const cache = await caches.open(API_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('❌ API request failed:', error);
    
    // Return cached version if available
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      console.log('📦 Serving cached API response');
      return cachedResponse;
    }
    
    // Return offline API response
    return new Response(
      JSON.stringify({
        error: 'Offline',
        message: 'This feature is not available offline'
      }),
      {
        status: 503,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// Handle navigation requests (HTML pages)
async function handleNavigationRequest(request) {
  try {
    // Network first for navigation
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Cache successful navigation responses
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('❌ Navigation request failed:', error);
    
    // Try to serve from cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Serve offline page
    const offlinePage = await caches.match('/offline.html');
    if (offlinePage) {
      return offlinePage;
    }
    
    // Fallback offline HTML
    return new Response(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Thesis Generator - Offline</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
              text-align: center;
            }
            .offline-content {
              max-width: 400px;
              padding: 2rem;
            }
            .offline-icon {
              font-size: 4rem;
              margin-bottom: 1rem;
            }
            h1 {
              font-size: 2rem;
              margin-bottom: 1rem;
            }
            p {
              font-size: 1.1rem;
              line-height: 1.6;
              margin-bottom: 2rem;
            }
            .retry-btn {
              background: rgba(255, 255, 255, 0.2);
              color: white;
              border: 2px solid rgba(255, 255, 255, 0.3);
              padding: 1rem 2rem;
              border-radius: 8px;
              cursor: pointer;
              font-size: 1rem;
              transition: all 0.3s ease;
            }
            .retry-btn:hover {
              background: rgba(255, 255, 255, 0.3);
            }
          </style>
        </head>
        <body>
          <div class="offline-content">
            <div class="offline-icon">📡</div>
            <h1>You're Offline</h1>
            <p>Thesis Generator needs an internet connection to work. Please check your connection and try again.</p>
            <button class="retry-btn" onclick="window.location.reload()">Try Again</button>
          </div>
        </body>
      </html>
    `, {
      headers: { 'Content-Type': 'text/html' }
    });
  }
}

// Handle other dynamic requests
async function handleDynamicRequest(request) {
  try {
    // Stale while revalidate strategy
    const cachedResponse = await caches.match(request);
    const networkResponsePromise = fetch(request);
    
    // Return cached response immediately if available
    if (cachedResponse) {
      // Update cache in background
      networkResponsePromise.then((networkResponse) => {
        if (networkResponse.ok) {
          const cache = caches.open(DYNAMIC_CACHE);
          cache.then(c => c.put(request, networkResponse));
        }
      }).catch(() => {
        // Ignore network errors for background updates
      });
      
      return cachedResponse;
    }
    
    // If no cache, wait for network
    const networkResponse = await networkResponsePromise;
    
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('❌ Dynamic request failed:', error);
    
    // Try cache as last resort
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    throw error;
  }
}

// ==============================================
// UTILITY FUNCTIONS
// ==============================================

function isStaticAsset(request) {
  const url = new URL(request.url);
  return url.pathname.match(/\.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/);
}

function isAPIRequest(request) {
  const url = new URL(request.url);
  return API_ENDPOINTS.some(endpoint => url.pathname.startsWith(endpoint)) ||
         url.pathname.startsWith('/api/') ||
         url.hostname.includes('firestore.googleapis.com') ||
         url.hostname.includes('firebase.googleapis.com');
}

function isNavigationRequest(request) {
  return request.mode === 'navigate' || 
         (request.method === 'GET' && request.headers.get('accept').includes('text/html'));
}

// ==============================================
// BACKGROUND SYNC
// ==============================================
self.addEventListener('sync', (event) => {
  console.log('🔄 Background sync:', event.tag);
  
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

async function doBackgroundSync() {
  try {
    // Sync any pending data when connection is restored
    console.log('🔄 Performing background sync...');
    
    // Check if there are any pending operations in IndexedDB
    const pendingOperations = await getPendingOperations();
    
    for (const operation of pendingOperations) {
      try {
        await syncOperation(operation);
        await removePendingOperation(operation.id);
        console.log('✅ Synced operation:', operation.type);
      } catch (error) {
        console.error('❌ Failed to sync operation:', operation.type, error);
      }
    }
    
    // Notify clients about sync completion
    const clients = await self.clients.matchAll();
    clients.forEach(client => {
      client.postMessage({
        type: 'BACKGROUND_SYNC_COMPLETE',
        synced: pendingOperations.length
      });
    });
    
  } catch (error) {
    console.error('❌ Background sync failed:', error);
  }
}

async function getPendingOperations() {
  // This would typically read from IndexedDB
  // For now, return empty array
  return [];
}

async function syncOperation(operation) {
  // Implement actual sync logic based on operation type
  switch (operation.type) {
    case 'thesis_save':
      return await syncThesisSave(operation.data);
    case 'user_profile_update':
      return await syncUserProfileUpdate(operation.data);
    default:
      console.warn('Unknown operation type:', operation.type);
  }
}

async function removePendingOperation(operationId) {
  // Remove from IndexedDB
  console.log('🗑️ Removing synced operation:', operationId);
}

async function syncThesisSave(data) {
  // Sync thesis data to server
  const response = await fetch('/api/thesis/sync', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    throw new Error('Failed to sync thesis data');
  }
  
  return response.json();
}

async function syncUserProfileUpdate(data) {
  // Sync user profile updates
  const response = await fetch('/api/user/sync', {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    throw new Error('Failed to sync user profile');
  }
  
  return response.json();
}

// ==============================================
// PUSH NOTIFICATIONS
// ==============================================
self.addEventListener('push', (event) => {
  console.log('📱 Push notification received');
  
  let notificationData = {
    title: 'Thesis Generator',
    body: 'You have a new notification',
    icon: '/favicon.png',
    badge: '/favicon.png',
    tag: 'thesis-notification',
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: 'Open App',
        icon: '/favicon.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ]
  };
  
  if (event.data) {
    try {
      const data = event.data.json();
      notificationData = { ...notificationData, ...data };
    } catch (error) {
      console.error('❌ Error parsing push data:', error);
    }
  }
  
  event.waitUntil(
    self.registration.showNotification(notificationData.title, notificationData)
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Notification clicked:', event.action);
  
  event.notification.close();
  
  if (event.action === 'dismiss') {
    return;
  }
  
  // Open the app
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      
      // Otherwise open new window
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// ==============================================
// MESSAGE HANDLING
// ==============================================
self.addEventListener('message', (event) => {
  console.log('💬 Message received:', event.data);
  
  const { type, payload } = event.data;
  
  switch (type) {
    case 'SKIP_WAITING':
      self.skipWaiting();
      break;
      
    case 'GET_VERSION':
      event.ports[0].postMessage({ version: CACHE_NAME });
      break;
      
    case 'CLEAR_CACHE':
      clearAllCaches().then(() => {
        event.ports[0].postMessage({ success: true });
      });
      break;
      
    case 'CACHE_URLS':
      cacheUrls(payload.urls).then(() => {
        event.ports[0].postMessage({ success: true });
      });
      break;
      
    case 'GET_CACHE_STATUS':
      getCacheStatus().then((status) => {
        event.ports[0].postMessage(status);
      });
      break;
      
    default:
      console.warn('Unknown message type:', type);
  }
});

async function clearAllCaches() {
  const cacheNames = await caches.keys();
  await Promise.all(
    cacheNames.map(cacheName => caches.delete(cacheName))
  );
  console.log('🗑️ All caches cleared');
}

async function cacheUrls(urls) {
  const cache = await caches.open(DYNAMIC_CACHE);
  await cache.addAll(urls);
  console.log('📦 URLs cached:', urls.length);
}

async function getCacheStatus() {
  const cacheNames = await caches.keys();
  const status = {};
  
  for (const cacheName of cacheNames) {
    const cache = await caches.open(cacheName);
    const keys = await cache.keys();
    status[cacheName] = keys.length;
  }
  
  return status;
}

// ==============================================
// PERIODIC BACKGROUND SYNC
// ==============================================
self.addEventListener('periodicsync', (event) => {
  console.log('⏰ Periodic sync:', event.tag);
  
  if (event.tag === 'content-sync') {
    event.waitUntil(performPeriodicSync());
  }
});

async function performPeriodicSync() {
  try {
    console.log('⏰ Performing periodic sync...');
    
    // Update cache with fresh content
    const importantUrls = [
      '/',
      '/index.html',
      '/app.html'
    ];
    
    const cache = await caches.open(DYNAMIC_CACHE);
    
    for (const url of importantUrls) {
      try {
        const response = await fetch(url);
        if (response.ok) {
          await cache.put(url, response);
          console.log('✅ Updated cache for:', url);
        }
      } catch (error) {
        console.error('❌ Failed to update cache for:', url, error);
      }
    }
    
    // Notify clients
    const clients = await self.clients.matchAll();
    clients.forEach(client => {
      client.postMessage({
        type: 'PERIODIC_SYNC_COMPLETE',
        timestamp: Date.now()
      });
    });
    
  } catch (error) {
    console.error('❌ Periodic sync failed:', error);
  }
}

// ==============================================
// ERROR HANDLING
// ==============================================
self.addEventListener('error', (event) => {
  console.error('❌ Service Worker error:', event.error);
  
  // Report error to analytics if available
  if (self.gtag) {
    self.gtag('event', 'exception', {
      description: event.error.toString(),
      fatal: false,
      custom_map: {
        service_worker: true
      }
    });
  }
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('❌ Service Worker unhandled rejection:', event.reason);
  
  // Report error to analytics if available
  if (self.gtag) {
    self.gtag('event', 'exception', {
      description: event.reason.toString(),
      fatal: false,
      custom_map: {
        service_worker: true,
        type: 'unhandled_rejection'
      }
    });
  }
});

// ==============================================
// CACHE MANAGEMENT
// ==============================================

// Clean up old caches periodically
async function cleanupOldCaches() {
  const cacheNames = await caches.keys();
  const currentCaches = [STATIC_CACHE, DYNAMIC_CACHE, API_CACHE, CACHE_NAME];
  
  const oldCaches = cacheNames.filter(name => !currentCaches.includes(name));
  
  await Promise.all(
    oldCaches.map(cacheName => {
      console.log('🗑️ Deleting old cache:', cacheName);
      return caches.delete(cacheName);
    })
  );
}

// Limit cache size
async function limitCacheSize(cacheName, maxItems) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  
  if (keys.length > maxItems) {
    const keysToDelete = keys.slice(0, keys.length - maxItems);
    await Promise.all(
      keysToDelete.map(key => {
        console.log('🗑️ Removing old cache entry:', key.url);
        return cache.delete(key);
      })
    );
  }
}

// Run cache cleanup every hour
setInterval(() => {
  cleanupOldCaches();
  limitCacheSize(DYNAMIC_CACHE, 50);
  limitCacheSize(API_CACHE, 30);
}, 60 * 60 * 1000);

// ==============================================
// ANALYTICS
// ==============================================

// Track service worker performance
function trackSWEvent(eventName, data = {}) {
  try {
    // Send to analytics if available
    if (self.gtag) {
      self.gtag('event', eventName, {
        event_category: 'Service Worker',
        ...data
      });
    }
    
    // Also log for debugging
    console.log('📊 SW Event:', eventName, data);
  } catch (error) {
    console.error('❌ Error tracking SW event:', error);
  }
}

// Track cache hit rates
let cacheHits = 0;
let cacheMisses = 0;

function trackCacheHit() {
  cacheHits++;
  if ((cacheHits + cacheMisses) % 10 === 0) {
    trackSWEvent('cache_performance', {
      hit_rate: (cacheHits / (cacheHits + cacheMisses) * 100).toFixed(2),
      total_requests: cacheHits + cacheMisses
    });
  }
}

function trackCacheMiss() {
  cacheMisses++;
}

// ==============================================
// INITIALIZATION
// ==============================================

console.log('🎓 Thesis Generator Service Worker v2.1 loaded');
console.log('📦 Cache Strategy: Advanced with background sync');
console.log('🔄 Features: Offline support, push notifications, background sync');

// Track service worker load
trackSWEvent('service_worker_loaded', {
  version: CACHE_NAME,
  timestamp: Date.now()
});

// ==============================================
// EXPORT FOR TESTING
// ==============================================

// Make functions available for testing
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    CACHE_NAME,
    STATIC_CACHE,
    DYNAMIC_CACHE,
    API_CACHE,
    handleStaticAsset,
    handleAPIRequest,
    handleNavigationRequest,
    isStaticAsset,
    isAPIRequest,
    isNavigationRequest
  };
}
