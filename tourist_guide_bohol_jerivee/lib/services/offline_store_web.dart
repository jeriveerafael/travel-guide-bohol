import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Persistent offline storage for the Flutter Web build.
///
/// Uses IndexedDB so tourism records, saved map tiles, and destination images
/// survive browser restarts and remain available without a network connection.
class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();

  static const String _databaseName = 'bohol_explorer_offline';
  static const int _databaseVersion = 1;
  static const String _kvStore = 'kv';
  static const String _tileStore = 'tiles';
  static const String _imageStore = 'images';

  Future<web.IDBDatabase>? _databaseFuture;

  Future<web.IDBDatabase> _database() => _databaseFuture ??= _open();

  Future<web.IDBDatabase> _open() {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_databaseName, _databaseVersion);

    request.onupgradeneeded = ((web.Event event) {
      final database = request.result as web.IDBDatabase;
      if (!database.objectStoreNames.contains(_kvStore)) {
        database.createObjectStore(_kvStore);
      }
      if (!database.objectStoreNames.contains(_tileStore)) {
        database.createObjectStore(_tileStore);
      }
      if (!database.objectStoreNames.contains(_imageStore)) {
        database.createObjectStore(_imageStore);
      }
    }).toJS;

    request.onsuccess = ((web.Event event) {
      final result = request.result;
      if (result == null) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('IndexedDB did not return a database.'));
        }
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(result as web.IDBDatabase);
      }
    }).toJS;

    request.onerror = ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('IndexedDB could not be opened.'));
      }
    }).toJS;

    return completer.future;
  }

  Future<JSAny?> _request(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.onsuccess = ((web.Event event) {
      if (!completer.isCompleted) completer.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('An IndexedDB request failed.'));
      }
    }).toJS;
    return completer.future;
  }

  Future<void> _awaitTransaction(web.IDBTransaction transaction) {
    final completer = Completer<void>();
    transaction.oncomplete = ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    transaction.onabort = ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('An IndexedDB transaction was aborted.'));
      }
    }).toJS;
    transaction.onerror = ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('An IndexedDB transaction failed.'));
      }
    }).toJS;
    return completer.future;
  }

  Future<void> _write(String storeName, JSAny? value, JSAny? key) async {
    final database = await _database();
    final transaction = database.transaction(storeName.toJS, 'readwrite');
    final store = transaction.objectStore(storeName);
    store.put(value, key);
    await _awaitTransaction(transaction);
  }

  Future<JSAny?> _read(String storeName, String key) async {
    final database = await _database();
    final transaction = database.transaction(storeName.toJS, 'readonly');
    final request = transaction.objectStore(storeName).get(key.toJS);
    return _request(request);
  }

  Future<String?> readValue(String key) async {
    try {
      final result = await _read(_kvStore, key);
      return result == null ? null : (result as JSString).toDart;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeValue(String key, String value) async {
    try {
      await _write(_kvStore, value.toJS, key.toJS);
    } catch (_) {
      // Storage failures must not break the tourism guide.
    }
  }

  Future<void> deleteValue(String key) async {
    try {
      final database = await _database();
      final transaction = database.transaction(_kvStore.toJS, 'readwrite');
      transaction.objectStore(_kvStore).delete(key.toJS);
      await _awaitTransaction(transaction);
    } catch (_) {
      // Ignore missing values.
    }
  }

  Future<Uint8List?> _readBytes(String storeName, String key) async {
    try {
      final result = await _read(storeName, key);
      if (result == null) return null;
      return (result as JSUint8Array).toDart;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> readTile(String url) => _readBytes(_tileStore, url);

  Future<void> writeTile(String url, Uint8List bytes) async {
    try {
      await _write(_tileStore, bytes.toJS, url.toJS);
    } catch (_) {
      // A failed tile write only affects later offline map viewing.
    }
  }

  Future<bool> hasTile(String url) async => await readTile(url) != null;

  Future<int> _count(String storeName) async {
    try {
      final database = await _database();
      final transaction = database.transaction(storeName.toJS, 'readonly');
      final result = await _request(transaction.objectStore(storeName).count());
      return (result as JSNumber?)?.toDartInt ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _totalBytes(String storeName) async {
    try {
      final database = await _database();
      final transaction = database.transaction(storeName.toJS, 'readonly');
      final result = await _request(transaction.objectStore(storeName).getAll());
      if (result == null) return 0;
      var total = 0;
      for (final item in (result as JSArray<JSAny?>).toDart) {
        if (item != null && item.isA<JSUint8Array>()) {
          total += (item as JSUint8Array).toDart.length;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> tileCount() => _count(_tileStore);

  Future<int> tileBytes() => _totalBytes(_tileStore);

  Future<Uint8List?> readImage(String url) => _readBytes(_imageStore, url);

  Future<void> writeImage(String url, Uint8List bytes) async {
    try {
      await _write(_imageStore, bytes.toJS, url.toJS);
    } catch (_) {
      // Images are a convenience; text guidance still works offline.
    }
  }

  Future<void> _clear(String storeName) async {
    try {
      final database = await _database();
      final transaction = database.transaction(storeName.toJS, 'readwrite');
      transaction.objectStore(storeName).clear();
      await _awaitTransaction(transaction);
    } catch (_) {
      // Nothing to clear or storage unavailable.
    }
  }

  Future<void> clearTiles() => _clear(_tileStore);

  Future<void> clearImages() => _clear(_imageStore);

  Future<void> clearAll() async {
    await _clear(_kvStore);
    await _clear(_tileStore);
    await _clear(_imageStore);
  }
}
