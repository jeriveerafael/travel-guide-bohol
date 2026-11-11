import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import '../services/location_service.dart';
import '../services/offline_map_downloader.dart';
import '../services/offline_tile_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.destinations,
    required this.onOpenDestination,
    this.isOnline = true,
  });

  final List<Destination> destinations;
  final ValueChanged<Destination> onOpenDestination;
  final bool isOnline;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng? _userLocation;
  double _accuracyMeters = 0;
  bool _locating = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _showMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final location = await _locationService.currentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    if (location == null) {
      _showMessage('Location is unavailable. Allow location access in the browser to see your position on the map.');
      return;
    }

    final point = LatLng(location.latitude, location.longitude);
    setState(() {
      _userLocation = point;
      _accuracyMeters = location.accuracyMeters;
    });
    _mapController.move(point, 14);
    _showMessage('Showing your approximate location. Map pins are reference points, not turn-by-turn directions.');
  }

  Future<void> _downloadOfflineMap() async {
    if (!widget.isOnline) {
      _showMessage('Connect to the internet to download map tiles for offline use.');
      return;
    }
    final downloader = OfflineMapDownloader.instance;
    if (downloader.isRunning) return;
    await downloader.start(widget.destinations);
    if (!mounted) return;
    if (downloader.isCancelled) {
      _showMessage('Offline map download cancelled.');
    } else if (downloader.error != null) {
      _showMessage(downloader.error!);
    } else {
      _showMessage('Offline map ready. Cached tiles open without an internet connection.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        const Text('Bohol map guide', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          'Select a marker to view destination information. Downloaded tiles stay available offline.',
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
        if (!widget.isOnline) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFFF2DF), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.cloud_off, size: 17, color: Color(0xFFB66A12)),
              SizedBox(width: 8),
              Expanded(child: Text('Offline mode: showing map tiles saved on this device.', style: TextStyle(fontSize: 11.5, color: Color(0xFF7A4B0F)))),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 440,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(9.72, 124.12),
                    initialZoom: 8.1,
                    minZoom: 7,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: OfflineMapTileProvider.urlTemplate,
                      userAgentPackageName: 'com.example.tourist_guide_bohol',
                      tileProvider: OfflineMapTileProvider.instance,
                    ),
                    if (_userLocation != null && _accuracyMeters > 0)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: _userLocation!,
                          radius: _accuracyMeters,
                          useRadiusInMeter: true,
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
                          borderColor: const Color(0xFF2F80ED).withValues(alpha: 0.45),
                          borderStrokeWidth: 1,
                        ),
                      ]),
                    MarkerLayer(
                      markers: [
                        ...widget.destinations.map((destination) => Marker(
                              point: LatLng(destination.latitude, destination.longitude),
                              width: 42,
                              height: 48,
                              child: GestureDetector(
                                onTap: () => widget.onOpenDestination(destination),
                                child: const Icon(Icons.location_on, size: 39, color: Color(0xFFE45B4F)),
                              ),
                            )),
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F80ED),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'my-location',
                    tooltip: 'Show my location',
                    onPressed: _locating ? null : _showMyLocation,
                    child: _locating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(8)),
                    child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _OfflineMapCard(
          isOnline: widget.isOnline,
          onDownload: _downloadOfflineMap,
        ),
        const SizedBox(height: 18),
        const Text('Mapped destinations', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 10),
        ...widget.destinations.map((destination) => Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE7F3F0), child: Icon(Icons.place_outlined, color: Color(0xFF087E8B))),
                title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: Text('${destination.municipality} · ${destination.latitude.toStringAsFixed(5)}, ${destination.longitude.toStringAsFixed(5)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpenDestination(destination),
              ),
            )),
        const SizedBox(height: 8),
        const Text(
          'Map data © OpenStreetMap contributors (ODbL). Downloading stores a limited set of tiles in this browser for offline viewing; it is not a complete navigation dataset. '
          'Pins mark visitor areas, not property boundaries. Verify routes, fees, and opening hours with the destination or a local operator before travelling.',
          style: TextStyle(fontSize: 11, color: Colors.blueGrey, height: 1.5),
        ),
      ],
    );
  }
}

class _OfflineMapCard extends StatelessWidget {
  const _OfflineMapCard({required this.isOnline, required this.onDownload});

  final bool isOnline;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: AnimatedBuilder(
          animation: OfflineMapDownloader.instance,
          builder: (context, _) {
            final downloader = OfflineMapDownloader.instance;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.cloud_download_outlined, color: Color(0xFF087E8B)),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Save this map for offline use',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
                if (downloader.isRunning)
                  Text('${(downloader.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))
                else
                  FilledButton.tonalIcon(
                    onPressed: isOnline ? onDownload : null,
                    icon: const Icon(Icons.download, size: 17),
                    label: Text(isOnline ? 'Download' : 'Offline'),
                  ),
              ]),
              if (downloader.isRunning) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: downloader.progress, minHeight: 7, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('${downloader.completed} / ${downloader.total} tiles', style: TextStyle(fontSize: 10.5, color: Colors.blueGrey.shade600)),
                  const Spacer(),
                  TextButton(onPressed: downloader.cancel, child: const Text('Cancel')),
                ]),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Stores an overview of Bohol and a closer map around each destination in this browser.',
                    style: TextStyle(fontSize: 11, height: 1.45, color: Colors.blueGrey.shade600),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
