import 'dart:convert';
import 'dart:typed_data';

import '../models/destination.dart';
import 'offline_store.dart';

/// High-level helpers for everything the website keeps available offline.
///
/// Records are stored in IndexedDB on the web: the destination catalogue,
/// destination photos, downloaded OpenStreetMap tiles, and download timestamps.
class OfflineCache {
  static const String _catalogueKey = 'catalogue_v1';
  static const String _catalogueSavedAtKey = 'catalogue_saved_at';
  static const String _mapDownloadedAtKey = 'map_downloaded_at';

  static Future<void> saveCatalogue(
    List<Destination> destinations, {
    DateTime? savedAt,
  }) async {
    final payload = jsonEncode(destinations.map((item) => item.toJson()).toList());
    await OfflineStore.instance.writeValue(_catalogueKey, payload);
    await OfflineStore.instance.writeValue(
      _catalogueSavedAtKey,
      (savedAt ?? DateTime.now()).toIso8601String(),
    );
  }

  static Future<List<Destination>> readCatalogue() async {
    final raw = await OfflineStore.instance.readValue(_catalogueKey);
    if (raw == null || raw.isEmpty) return <Destination>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Destination>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Destination.fromJson)
          .toList();
    } catch (_) {
      return <Destination>[];
    }
  }

  static Future<DateTime?> readCatalogueSavedAt() async {
    final raw = await OfflineStore.instance.readValue(_catalogueSavedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> saveMapDownloadedAt(DateTime value) =>
      OfflineStore.instance.writeValue(_mapDownloadedAtKey, value.toIso8601String());

  static Future<DateTime?> readMapDownloadedAt() async {
    final raw = await OfflineStore.instance.readValue(_mapDownloadedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<Uint8List?> readTile(String url) =>
      OfflineStore.instance.readTile(url);

  static Future<void> saveTile(String url, Uint8List bytes) =>
      OfflineStore.instance.writeTile(url, bytes);

  static Future<bool> hasTile(String url) => OfflineStore.instance.hasTile(url);

  static Future<int> tileCount() => OfflineStore.instance.tileCount();

  static Future<int> tileBytes() => OfflineStore.instance.tileBytes();

  static Future<void> clearTiles() => OfflineStore.instance.clearTiles();

  static Future<Uint8List?> readImage(String url) =>
      OfflineStore.instance.readImage(url);

  static Future<void> saveImage(String url, Uint8List bytes) =>
      OfflineStore.instance.writeImage(url, bytes);

  static Future<void> clearImages() => OfflineStore.instance.clearImages();

  /// Clears cached map tiles and photos while keeping the destination text
  /// catalogue and the signed-in session.
  static Future<void> clearMapAndImages() async {
    await clearTiles();
    await clearImages();
    await OfflineStore.instance.deleteValue(_mapDownloadedAtKey);
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
