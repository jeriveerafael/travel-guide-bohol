import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'offline_cache.dart';

/// Cache-first map tile provider for Flutter Web.
///
/// Every successfully loaded tile is written to IndexedDB immediately, and
/// cached tiles are preferred over the network. This is deliberately
/// independent of flutter_map's caching layer, whose HTTP-metadata parsing
/// skips tiles when the tile server omits a `Date` header.
class OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return OfflineTileImage(getTileUrl(coordinates, options));
  }

  @override
  bool get supportsCancelLoading => false;
}

@immutable
class OfflineTileImage extends ImageProvider<OfflineTileImage> {
  const OfflineTileImage(this.url);

  final String url;

  static final http.Client _client = http.Client();
  static final Map<String, Future<Uint8List?>> _inFlight = <String, Future<Uint8List?>>{};

  @override
  Future<OfflineTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<OfflineTileImage>(this);

  @override
  ImageStreamCompleter loadImage(OfflineTileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key.url, decode),
      scale: 1,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _load(String tileUrl, ImageDecoderCallback decode) async {
    final bytes = await _bytes(tileUrl);
    if (bytes == null || bytes.isEmpty) {
      throw NetworkImageLoadException(
        statusCode: 404,
        uri: Uri.parse(tileUrl),
      );
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  static Future<Uint8List?> _bytes(String tileUrl) {
    final existing = _inFlight[tileUrl];
    if (existing != null) return existing;
    final future = _loadBytes(tileUrl).whenComplete(() => _inFlight.remove(tileUrl));
    _inFlight[tileUrl] = future;
    return future;
  }

  static Future<Uint8List?> _loadBytes(String tileUrl) async {
    final cached = await OfflineCache.readTile(tileUrl);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _client
          .get(Uri.parse(tileUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await OfflineCache.saveTile(tileUrl, response.bodyBytes);
        return response.bodyBytes;
      }
    } catch (_) {
      // Offline or request failed: the tile is simply unavailable.
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfflineTileImage && other.url == url);

  @override
  int get hashCode => url.hashCode;
}

/// Shared map tile configuration and provider used by the map screen and the
/// offline downloader.
class OfflineMapTileProvider {
  OfflineMapTileProvider._();

  static const String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static final OfflineTileProvider instance = OfflineTileProvider();
}
