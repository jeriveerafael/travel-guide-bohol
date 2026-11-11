import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';
import 'offline_cache.dart';
import 'offline_tile_provider.dart';

/// Downloads and caches the Bohol map tiles needed to browse the map offline.
///
/// Tiles come from the OpenStreetMap standard tile service. The download is
/// deliberately limited to a small area and a few zoom levels to respect the
/// tile usage policy. Attribution is shown on the map.
class OfflineMapDownloader extends ChangeNotifier {
  OfflineMapDownloader._();

  static final OfflineMapDownloader instance = OfflineMapDownloader._();

  static const int _maxTiles = 1200;
  static const int _parallelDownloads = 4;

  bool _isRunning = false;
  bool _cancelRequested = false;
  int _completed = 0;
  int _total = 0;
  String? _error;

  bool get isRunning => _isRunning;
  bool get isCancelled => _cancelRequested;
  int get completed => _completed;
  int get total => _total;
  String? get error => _error;
  double get progress => _total == 0 ? 0 : (_completed / _total).clamp(0, 1);

  void cancel() {
    if (!_isRunning) return;
    _cancelRequested = true;
    notifyListeners();
  }

  /// Downloads island-wide tiles at zoom 10-13 plus closer tiles around each
  /// destination at zoom 14. Existing cached tiles are skipped.
  Future<void> start(List<Destination> destinations) async {
    if (_isRunning) return;

    _isRunning = true;
    _cancelRequested = false;
    _completed = 0;
    _error = null;

    final urls = _buildTileUrls(destinations);
    _total = urls.length;
    notifyListeners();

    final client = http.Client();
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (_cancelRequested) return;
        final index = nextIndex++;
        if (index >= urls.length) return;
        final url = urls[index];
        try {
          if (!await OfflineCache.hasTile(url)) {
            final response = await client
                .get(
                  Uri.parse(url),
                  headers: const {'Accept': 'image/png,image/*;q=0.8'},
                )
                .timeout(const Duration(seconds: 25));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              await OfflineCache.saveTile(url, response.bodyBytes);
            }
          }
        } catch (_) {
          // Keep going: one failed tile should not stop the offline download.
        }
        _completed++;
        if (_completed % 4 == 0 || _completed == _total) notifyListeners();
      }
    }

    try {
      await Future.wait(List.generate(_parallelDownloads, (_) => worker()));
      if (!_cancelRequested) {
        await OfflineCache.saveMapDownloadedAt(DateTime.now());
      }
    } catch (error) {
      _error = 'The offline map download stopped unexpectedly.';
    } finally {
      client.close();
      _isRunning = false;
      notifyListeners();
    }
  }

  List<String> _buildTileUrls(List<Destination> destinations) {
    // Bohol island bounding box: south, west, north, east.
    const south = 9.45;
    const west = 123.65;
    const north = 10.12;
    const east = 124.72;

    final urls = <String>{};

    for (var zoom = 10; zoom <= 13; zoom++) {
      final minX = _tileX(west, zoom);
      final maxX = _tileX(east, zoom);
      final minY = _tileY(north, zoom);
      final maxY = _tileY(south, zoom);
      for (var x = minX; x <= maxX; x++) {
        for (var y = minY; y <= maxY; y++) {
          urls.add(_tileUrl(zoom, x, y));
        }
      }
    }

    // A closer 3x3 block at zoom 14 around each destination supports the
    // detailed views visitors use when they arrive at a site.
    for (final destination in destinations) {
      final centerX = _tileX(destination.longitude, 14);
      final centerY = _tileY(destination.latitude, 14);
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          urls.add(_tileUrl(14, centerX + dx, centerY + dy));
        }
      }
    }

    final list = urls.toList()..sort();
    return list.length > _maxTiles ? list.sublist(0, _maxTiles) : list;
  }

  String _tileUrl(int zoom, int x, int y) =>
      OfflineMapTileProvider.urlTemplate
          .replaceFirst('{z}', '$zoom')
          .replaceFirst('{x}', '$x')
          .replaceFirst('{y}', '$y');

  int _tileX(double longitude, int zoom) {
    final max = 1 << zoom;
    final value = ((longitude + 180) / 360 * max).floor();
    return value.clamp(0, max - 1);
  }

  int _tileY(double latitude, int zoom) {
    final max = 1 << zoom;
    final latitudeRadians = latitude * math.pi / 180;
    final value = ((1 -
                math.log(math.tan(latitudeRadians) +
                        1 / math.cos(latitudeRadians)) /
                    math.pi) /
            2 *
            max)
        .floor();
    return value.clamp(0, max - 1);
  }
}
