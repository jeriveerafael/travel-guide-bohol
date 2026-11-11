import 'package:flutter/material.dart';

/// Top banner shown throughout the website when the browser is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.onOpenOffline,
    required this.onRetry,
  });

  final VoidCallback onOpenOffline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF2DF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
          child: Row(children: [
            const Icon(Icons.cloud_off, size: 18, color: Color(0xFFB66A12)),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Offline mode — showing guides and maps saved on this device.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7A4B0F), height: 1.35),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7A4B0F), visualDensity: VisualDensity.compact),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: onOpenOffline,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7A4B0F), visualDensity: VisualDensity.compact),
              child: const Text('Offline guide'),
            ),
          ]),
        ),
      ),
    );
  }
}
