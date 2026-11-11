// Cross-platform entry point for the offline store.
//
// On the web this resolves to the IndexedDB implementation; other platforms
// use the in-memory fallback.
export 'offline_store_stub.dart'
    if (dart.library.js_interop) 'offline_store_web.dart';
