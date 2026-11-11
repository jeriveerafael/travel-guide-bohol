import 'package:flutter/material.dart';

import '../models/destination.dart';
import 'offline_image.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.compact = false,
  });

  final Destination destination;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? 132.0 : 174.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: OfflineImage(
                    url: destination.imageUrl,
                    fallback: const _ImageFallback(),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        destination.category,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                if (onFavorite != null)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : const Color(0xFF30454A),
                          size: 19,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF087E8B)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destination.municipality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 17, color: Color(0xFF087E8B)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFDDEBE8),
        alignment: Alignment.center,
        child: const Icon(Icons.landscape_rounded, size: 42, color: Color(0xFF087E8B)),
      );
}
