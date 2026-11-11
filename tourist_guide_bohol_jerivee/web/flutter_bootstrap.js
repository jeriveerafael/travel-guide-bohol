// Custom Flutter bootstrap: start the app without Flutter's self-unregistering
// service worker. Offline app-shell caching is handled by service_worker.js.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const loader = document.getElementById('loading');
    if (loader) loader.remove();
  },
});
