// Service Worker for aggressive cache-busting on mandafesto.com

self.addEventListener('fetch', function(event) {
    const url = new URL(event.request.url);
    
    // For the main page, always fetch fresh
    if (url.pathname === '/' || url.pathname === '/index.html') {
        event.respondWith(
            fetch(event.request.url + '?v=' + Date.now(), {
                cache: 'no-store'
            })
        );
        return;
    }
    
    // For admin pages, always fetch fresh
    if (url.pathname.startsWith('/admin/')) {
        event.respondWith(
            fetch(event.request.url + (url.search ? '&' : '?') + 'v=' + Date.now(), {
                cache: 'no-store'
            })
        );
        return;
    }
    
    // Let other requests pass through normally
    event.respondWith(fetch(event.request));
});

// Install immediately
self.addEventListener('install', function(event) {
    self.skipWaiting();
});

// Activate immediately
self.addEventListener('activate', function(event) {
    event.waitUntil(self.clients.claim());
});