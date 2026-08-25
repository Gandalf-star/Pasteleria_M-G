self.addEventListener('install', function(e) {
  // Instalar inmediatamente e ignorar espera
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          // Eliminar absolutamente TODOS los cachés guardados
          return caches.delete(cacheName);
        })
      );
    }).then(function() {
      // Y luego autodestruirse
      return self.registration.unregister();
    })
  );
});

// Interceptar fetch para no romper la navegación mientras se destruye
self.addEventListener('fetch', function(e) {
  e.respondWith(fetch(e.request));
});
