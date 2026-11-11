import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import '../widgets/offline_image.dart';

class DestinationDetailSheet extends StatelessWidget {
  const DestinationDetailSheet({
    super.key,
    required this.destination,
    required this.isFavorite,
    required this.isSavedOffline,
    required this.onFavorite,
    required this.onSaveOffline,
    required this.onVisited,
    required this.onShowMap,
  });

  final Destination destination;
  final bool isFavorite;
  final bool isSavedOffline;
  final VoidCallback onFavorite;
  final VoidCallback onSaveOffline;
  final VoidCallback onVisited;
  final VoidCallback onShowMap;

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _photoCredit() {
    switch (destination.id) {
      case 'chocolate-hills': return 'Photo: ChiyukiRen · CC BY-SA 4.0';
      case 'tarsier-sanctuary': return 'Photo: OfficialMetro · CC BY-SA 4.0';
      case 'loboc-river': return 'Photo: Kris Fulgencio · CC BY-SA 4.0';
      case 'panglao-island': return 'Photo: Francisco M. Pajares, Jr. · CC BY-SA 4.0';
      case 'hinagdanan-cave': return 'Photo: Qaalvin · CC BY-SA 3.0';
      case 'baclayon-church': return 'Photo: Bengoeswhere · CC BY-SA 4.0';
      case 'alona-beach': return 'Photo: Marife.altabano · CC BY-SA 4.0';
      case 'blood-compact-shrine': return 'Photo: AroundBohol · CC BY 4.0';
      case 'anda-beach': return 'Photo: pinay06 · CC BY-SA 3.0 / CC BY 2.5';
      default: return 'Photo supplied by the website administrator';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 225,
                  width: double.infinity,
                  child: OfflineImage(
                    url: destination.imageUrl,
                    fallback: Container(
                      color: const Color(0xFFDDEBE8),
                      child: const Icon(Icons.landscape, size: 58),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 7, 22, 0),
              child: Text(
                _photoCredit(),
                style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(destination.category, style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  Text(destination.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 17, color: colors.primary),
                    const SizedBox(width: 4),
                    Text('${destination.municipality}, Bohol', style: TextStyle(color: Colors.blueGrey.shade600)),
                  ]),
                  const SizedBox(height: 16),
                  Text(destination.description, style: const TextStyle(fontSize: 14, height: 1.65)),
                  const SizedBox(height: 20),
                  _InfoRow(icon: Icons.payments_outlined, title: 'Entrance fee', value: destination.entranceFee),
                  _InfoRow(icon: Icons.schedule_outlined, title: 'Operating hours', value: destination.operatingHours),
                  _InfoRow(icon: Icons.lightbulb_outline, title: 'Travel tip', value: destination.tips),
                  if (destination.activities.trim().isNotEmpty)
                    _InfoRow(icon: Icons.hiking_outlined, title: 'Things to do', value: destination.activities),
                  if (destination.accommodations.trim().isNotEmpty)
                    _InfoRow(icon: Icons.hotel_outlined, title: 'Where to stay', value: destination.accommodations),
                  if (destination.contactInfo.trim().isNotEmpty)
                    _InfoRow(icon: Icons.contact_phone_outlined, title: 'Contact information', value: destination.contactInfo),
                  _InfoRow(
                    icon: Icons.my_location_outlined,
                    title: 'Map coordinates',
                    value: '${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onFavorite,
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        label: Text(isFavorite ? 'Favorited' : 'Favorite'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onSaveOffline,
                        icon: Icon(isSavedOffline ? Icons.download_done : Icons.download),
                        label: Text(isSavedOffline ? 'Saved offline' : 'Save offline'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onVisited,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark visited'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Get directions'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onShowMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View on Bohol map'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF087E8B), size: 19),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13, height: 1.4)),
          ])),
        ]),
      );
}
