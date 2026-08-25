{{flutter_js}}
{{flutter_build_config}}

// 1. Destruir cualquier Service Worker (caché) existente en los dispositivos
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (let registration of registrations) {
      registration.unregister();
    }
  });
}

// 2. Cargar Flutter desactivando la creación de un nuevo Service Worker
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: null
  }
});
