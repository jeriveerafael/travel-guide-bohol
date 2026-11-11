import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'offline_cache.dart';

/// Loads destination photos through IndexedDB first, then the network.
///
/// A photo viewed once is stored locally, so previously seen destinations can
/// display their images when the visitor is offline.
class ImageCacheService {
  static final Map<String, Uint8List> _memory = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _inFlight = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> load(String url) {
    if (url.isEmpty) return Future<Uint8List?>.value(null);
    final memory = _memory[url];
    if (memory != null) return Future<Uint8List?>.value(memory);
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _load(url).whenComplete(() => _inFlight.remove(url));
    _inFlight[url] = future;
    return future;
  }

  static Future<Uint8List?> _load(String url) async {
    final cached = await OfflineCache.readImage(url);
    if (cached != null && cached.isNotEmpty) {
      _memory[url] = cached;
      return cached;
    }

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _memory[url] = response.bodyBytes;
        unawaited(OfflineCache.saveImage(url, response.bodyBytes));
        return response.bodyBytes;
      }
    } catch (_) {
      // Offline or blocked image: the widgets fall back to an icon.
    }
    return null;
  }
}
