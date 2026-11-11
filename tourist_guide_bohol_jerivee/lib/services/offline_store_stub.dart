import 'dart:typed_data';

/// In-memory fallback used when the app is not running on the web.
///
/// The website targets Flutter Web, where `offline_store_web.dart` is used
/// instead and records persist in IndexedDB. This implementation keeps the
/// project analysable and testable on non-web platforms.
class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();

  final Map<String, String> _values = <String, String>{};
  final Map<String, Uint8List> _tiles = <String, Uint8List>{};
  final Map<String, Uint8List> _images = <String, Uint8List>{};

  Future<String?> readValue(String key) async => _values[key];

  Future<void> writeValue(String key, String value) async {
    _values[key] = value;
  }

  Future<void> deleteValue(String key) async {
    _values.remove(key);
  }

  Future<Uint8List?> readTile(String url) async => _tiles[url];

  Future<void> writeTile(String url, Uint8List bytes) async {
    _tiles[url] = bytes;
  }

  Future<bool> hasTile(String url) async => _tiles.containsKey(url);

  Future<int> tileCount() async => _tiles.length;

  Future<int> tileBytes() async =>
      _tiles.values.fold<int>(0, (sum, bytes) => sum + bytes.length);

  Future<Uint8List?> readImage(String url) async => _images[url];

  Future<void> writeImage(String url, Uint8List bytes) async {
    _images[url] = bytes;
  }

  Future<void> clearTiles() async {
    _tiles.clear();
  }

  Future<void> clearImages() async {
    _images.clear();
  }

  Future<void> clearAll() async {
    _values.clear();
    _tiles.clear();
    _images.clear();
  }
}
