/* Service worker: permite abrir la app sin conexión.
   - Archivos de la app y fuentes: se sirven desde la caché y se actualizan en segundo plano.
   - Consultas de búsqueda (DuckDuckGo, Wikipedia, etc.): NO se tocan, van directo a la red. */
const CACHE = "calculadora-v1";   // súbele el número si algún día quieres forzar una actualización total
const ARCHIVOS = [
  "./", "./index.html", "./manifest.webmanifest",
  "./icon-192.png", "./icon-512.png", "./icon-maskable-512.png",
  "./apple-touch-icon.png", "./favicon-32.png"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ARCHIVOS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((claves) => Promise.all(claves.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  const propio = url.origin === self.location.origin;
  const fuente = url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com";
  if (!propio && !fuente) return;               // APIs externas: directo a la red

  e.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const guardado = await cache.match(req, { ignoreSearch: propio });
    const red = fetch(req).then((res) => {
      if (res && (res.ok || res.type === "opaque")) cache.put(req, res.clone());
      return res;
    }).catch(() => null);
    if (guardado) { e.waitUntil(red); return guardado; }    // rápido y funciona sin internet
    const res = await red;
    if (res) return res;
    return req.mode === "navigate" ? (await cache.match("./index.html")) || Response.error() : Response.error();
  })());
});
