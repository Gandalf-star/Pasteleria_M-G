{{flutter_js}}
{{flutter_build_config}}

// Arranque sin caché.
//
// Los despliegues anteriores enviaron `Cache-Control: immutable, max-age=1año`
// sobre los `.js`. Como `main.dart.js` NO lleva hash en el nombre, el navegador
// se queda con la versión antigua aunque Vercel ya sirva una nueva. Aquí
// forzamos que cada arranque descargue código fresco.

(function () {
  var version = Date.now();

  // 1. Eliminar cualquier Service Worker registrado en el dispositivo.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (registros) {
      registros.forEach(function (registro) {
        registro.unregister();
      });
    }).catch(function () {});
  }

  // 2. Vaciar el CacheStorage que dejó el service worker de Flutter.
  if (typeof caches !== 'undefined') {
    caches.keys().then(function (nombres) {
      nombres.forEach(function (nombre) {
        caches.delete(nombre);
      });
    }).catch(function () {});
  }

  // 3. Romper la caché HTTP del bundle principal añadiendo una versión a su
  //    URL. Sin esto, un navegador con el archivo ya guardado ni siquiera
  //    revalida contra el servidor.
  try {
    var config = _flutter.buildConfig;
    if (config && Array.isArray(config.builds)) {
      config.builds.forEach(function (build) {
        if (build.mainJsPath && build.mainJsPath.indexOf('?') === -1) {
          build.mainJsPath += '?v=' + version;
        }
      });
    }
  } catch (e) {
    // Si cambia el formato del build config, seguimos con el arranque normal.
  }

  // 4. Cargar Flutter sin crear un nuevo Service Worker.
  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: null
    }
  });
})();
