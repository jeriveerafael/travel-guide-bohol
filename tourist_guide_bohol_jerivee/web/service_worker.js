// Offline app shell for Bohol Explorer.
// Caches the Flutter bootsrap and compiled assets after the first visit so the
// website can open without a network connection. Map tiles and tourism records
// are cached separately by the app in IndexedDB.
const CACHE_NAME = 'bohol-explorer-shell-v2';
const CORE_ASSETS = ['./', './manifest.json', './icons/Icon-192.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(CORE_ASSETS))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))),
      )
      .then(() => self.clients.claim()),
  );
});

// After the first successful load the page reports the same-origin files it
// used, so the compiled app, fonts and CanvasKit are ready for offline startup.
self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'CACHE_URLS' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      Promise.all(
        data.urls.map((url) =>
          fetch(url)
            .then((response) => {
              if (response && response.ok) return cache.put(url, response);
            })
            .catch(() => {}),
        ),
      ),
    ),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Cross-origin requests (PHP API on XAMPP, Wikimedia photos) are managed by
  // the app's own offline caches and should not be shadowed here.
  if (url.origin !== self.location.origin) return;
  // Never cache live API responses; the app stores tourism records itself.
  if (url.searchParams.has('resource')) return;

  // Navigation and app bundles: try the network so updates appear, fall back
  // to the cached app shell when offline.
  const isAppBundle = /\/(main\.dart\.js|flutter_bootstrap\.js)$/.test(url.pathname);
  if (request.mode === 'navigate' || isAppBundle) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(async () => (await caches.match(request)) || (await caches.match('./'))),
    );
    return;
  }

  // Static assets: serve from cache immediately, refresh in the background.
  event.respondWith(
    caches.match(request).then((cached) => {
      const network = fetch(request)
        .then((response) => {
          if (response && response.status === 200) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(() => cached);
      return cached || network;
    }),
  );
});
