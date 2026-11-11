import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/image_cache_service.dart';

/// Destination image that renders from the offline IndexedDB cache when the
/// network is unavailable.
class OfflineImage extends StatefulWidget {
  const OfflineImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  State<OfflineImage> createState() => _OfflineImageState();
}

class _OfflineImageState extends State<OfflineImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = ImageCacheService.load(widget.url);
  }

  @override
  void didUpdateWidget(covariant OfflineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = ImageCacheService.load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          if (snapshot.connectionState != ConnectionState.done) {
            return widget.fallback ?? const _ImageFallback(loading: true);
          }
          return widget.fallback ?? const _ImageFallback();
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) =>
              widget.fallback ?? const _ImageFallback(),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFDDEBE8),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.landscape_rounded, size: 42, color: Color(0xFF087E8B)),
      );
}
