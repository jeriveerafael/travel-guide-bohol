import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/offline_cache.dart';
import '../services/offline_map_downloader.dart';
import '../widgets/offline_image.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({
    super.key,
    required this.destinations,
    required this.savedOffline,
    required this.isOnline,
    required this.onOpenDestination,
    required this.onRefresh,
  });

  final List<Destination> destinations;
  final Set<String> savedOffline;
  final bool isOnline;
  final ValueChanged<Destination> onOpenDestination;
  final Future<bool> Function() onRefresh;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  _CacheStats _stats = const _CacheStats.empty();
  bool _loading = true;
  bool _refreshing = false;
  bool _wasDownloading = false;

  @override
  void initState() {
    super.initState();
    OfflineMapDownloader.instance.addListener(_handleDownloaderChange);
    _loadStats();
  }

  @override
  void dispose() {
    OfflineMapDownloader.instance.removeListener(_handleDownloaderChange);
    super.dispose();
  }

  void _handleDownloaderChange() {
    final downloading = OfflineMapDownloader.instance.isRunning;
    if (_wasDownloading && !downloading) _loadStats();
    _wasDownloading = downloading;
  }

  Future<void> _loadStats() async {
    final catalogueCount = (await OfflineCache.readCatalogue()).length;
    final tiles = await OfflineCache.tileCount();
    final bytes = await OfflineCache.tileBytes();
    final mapAt = await OfflineCache.readMapDownloadedAt();
    final catalogueAt = await OfflineCache.readCatalogueSavedAt();
    if (!mounted) return;
    setState(() {
      _stats = _CacheStats(
        cachedDestinations: catalogueCount,
        tiles: tiles,
        bytes: bytes,
        mapDownloadedAt: mapAt,
        catalogueSavedAt: catalogueAt,
      );
      _loading = false;
    });
  }

  Future<void> _refreshContent() async {
    setState(() => _refreshing = true);
    final success = await widget.onRefresh();
    if (!mounted) return;
    setState(() => _refreshing = false);
    await _loadStats();
    if (!mounted) return;
    _showMessage(success
        ? 'Cached tourism information is up to date.'
        : 'The tourism database could not be reached. Cached information is still available.');
  }

  Future<void> _downloadMap() async {
    if (!widget.isOnline) {
      _showMessage('Connect to the internet to download the offline map.');
      return;
    }
    if (OfflineMapDownloader.instance.isRunning) return;
    _showMessage('Downloading Bohol map tiles for offline use...');
    await OfflineMapDownloader.instance.start(widget.destinations);
    await _loadStats();
    if (!mounted) return;
    final downloader = OfflineMapDownloader.instance;
    if (downloader.isCancelled) {
      _showMessage('Offline map download cancelled.');
    } else if (downloader.error != null) {
      _showMessage(downloader.error!);
    } else {
      _showMessage('Offline map saved. You can now open the map without the internet.');
    }
  }

  Future<void> _clearMapCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove offline map?'),
        content: const Text(
          'This deletes downloaded map tiles and cached destination photos from this browser. '
          'Your saved destinations and the written travel guides stay available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep map'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await OfflineCache.clearMapAndImages();
    await _loadStats();
    if (!mounted) return;
    _showMessage('Offline map tiles and cached photos were removed.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.destinations
        .where((destination) => widget.savedOffline.contains(destination.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 36),
      children: [
        const Text('Offline guide center', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          'Download the parts of Bohol you need before you travel, then browse them without a connection.',
          style: TextStyle(color: Colors.blueGrey.shade600, height: 1.5),
        ),
        const SizedBox(height: 18),
        _ConnectionCard(
          isOnline: widget.isOnline,
          lastSync: _stats.catalogueSavedAt,
          cachedDestinations: _stats.cachedDestinations,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 760 ? 4 : 2;
          final width = (constraints.maxWidth - (12 * (columns - 1))) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: width, child: _StatCard(icon: Icons.place_outlined, label: 'Cached places', value: '${_stats.cachedDestinations}')),
              SizedBox(width: width, child: _StatCard(icon: Icons.map_outlined, label: 'Map tiles', value: '${_stats.tiles}')),
              SizedBox(width: width, child: _StatCard(icon: Icons.storage_outlined, label: 'Storage used', value: OfflineCache.formatBytes(_stats.bytes))),
              SizedBox(width: width, child: _StatCard(icon: Icons.download_done_outlined, label: 'Map saved', value: _shortDate(_stats.mapDownloadedAt))),
            ],
          );
        }),
        const SizedBox(height: 26),
        const _SectionTitle(title: 'Bohol offline map', subtitle: 'OpenStreetMap tiles stored in this browser'),
        const SizedBox(height: 10),
        _MapDownloadCard(
          stats: _stats,
          isOnline: widget.isOnline,
          onDownload: _downloadMap,
          onClear: _clearMapCache,
        ),
        const SizedBox(height: 26),
        const _SectionTitle(title: 'Tourism information', subtitle: 'Destination details, guides, and travel tips'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFFE7F3F0), child: Icon(Icons.article_outlined, color: Color(0xFF087E8B))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Cached destination catalogue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      _stats.catalogueSavedAt == null
                          ? 'Not cached yet'
                          : 'Last updated ${_longDateTime(_stats.catalogueSavedAt)}',
                      style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade600),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                'Destination names, municipalities, categories, descriptions, fees, hours, tips, coordinates, and itineraries are stored in IndexedDB. '
                'Photos you have viewed are cached as well, so saved guides stay readable without a connection.',
                style: TextStyle(fontSize: 12, height: 1.55, color: Colors.blueGrey.shade700),
              ),
              const SizedBox(height: 13),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _refreshing ? null : _refreshContent,
                  icon: _refreshing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: Text(_refreshing ? 'Updating...' : 'Update cached information'),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 26),
        const _SectionTitle(title: 'Saved for offline reading', subtitle: 'Destinations you marked with Save offline'),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (saved.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Icon(Icons.download_for_offline_outlined, size: 42, color: Colors.blueGrey),
                const SizedBox(height: 10),
                const Text('No saved destinations yet', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Open any destination and select Save offline to keep it in this list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12, height: 1.5),
                ),
              ]),
            ),
          )
        else
          ...saved.map((destination) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: OfflineImage(url: destination.imageUrl),
                    ),
                  ),
                  title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: Text('${destination.municipality} · ${destination.category}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onOpenDestination(destination),
                ),
              )),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFEAF4F1), borderRadius: BorderRadius.circular(16)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Color(0xFF087E8B), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Map data © OpenStreetMap contributors, available under the Open Database License. '
                'The offline download is limited to Bohol at overview zoom levels and a small detailed area around each destination; it is not turn-by-turn navigation. '
                'Entrance fees, opening hours, and transport schedules still need to be confirmed with the destination or operator, because they can change after the offline copy is saved.',
                style: TextStyle(fontSize: 11, height: 1.55, color: Color(0xFF2D5457)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  String _shortDate(DateTime? value) {
    if (value == null) return 'Not yet';
    return '${_months[value.month - 1]} ${value.day}';
  }

  String _longDateTime(DateTime? value) {
    if (value == null) return 'not yet';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${_months[value.month - 1]} ${value.day}, ${value.year} · $hour:$minute $period';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _CacheStats {
  const _CacheStats({
    required this.cachedDestinations,
    required this.tiles,
    required this.bytes,
    required this.mapDownloadedAt,
    required this.catalogueSavedAt,
  });

  const _CacheStats.empty()
      : cachedDestinations = 0,
        tiles = 0,
        bytes = 0,
        mapDownloadedAt = null,
        catalogueSavedAt = null;

  final int cachedDestinations;
  final int tiles;
  final int bytes;
  final DateTime? mapDownloadedAt;
  final DateTime? catalogueSavedAt;
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.isOnline,
    required this.lastSync,
    required this.cachedDestinations,
  });

  final bool isOnline;
  final DateTime? lastSync;
  final int cachedDestinations;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? const Color(0xFF0E7C66) : const Color(0xFFB66A12);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE8F5EF) : const Color(0xFFFFF2DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(isOnline ? Icons.wifi : Icons.cloud_off, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isOnline ? 'Online — offline content is ready' : 'Offline mode',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              isOnline
                  ? '$cachedDestinations destination guides are stored on this device.'
                  : 'Showing $cachedDestinations cached destination guides and any downloaded map tiles.',
              style: TextStyle(fontSize: 12, height: 1.45, color: Colors.blueGrey.shade800),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 19, color: const Color(0xFF087E8B)),
            const SizedBox(height: 9),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.blueGrey.shade600)),
          ]),
        ),
      );
}

class _MapDownloadCard extends StatelessWidget {
  const _MapDownloadCard({
    required this.stats,
    required this.isOnline,
    required this.onDownload,
    required this.onClear,
  });

  final _CacheStats stats;
  final bool isOnline;
  final VoidCallback onDownload;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: AnimatedBuilder(
          animation: OfflineMapDownloader.instance,
          builder: (context, _) {
            final downloader = OfflineMapDownloader.instance;
            final ready = stats.tiles > 0;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFFE7F3F0), child: Icon(Icons.public, color: Color(0xFF087E8B))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bohol offline map', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      ready
                          ? '${stats.tiles} tiles · ${OfflineCache.formatBytes(stats.bytes)} stored'
                          : 'No map tiles downloaded yet',
                      style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade600),
                    ),
                  ]),
                ),
                if (ready)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('READY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0E7C66), letterSpacing: 0.5)),
                  ),
              ]),
              const SizedBox(height: 12),
              Text(
                'Downloads island overview tiles plus a closer map around every destination. Use it to view markers and read location guides when mobile data is unavailable.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Colors.blueGrey.shade700),
              ),
              if (downloader.isRunning) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: downloader.progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 7),
                Row(children: [
                  Text('${downloader.completed} of ${downloader.total} tiles', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
                  const Spacer(),
                  TextButton(onPressed: downloader.cancel, child: const Text('Cancel')),
                ]),
              ] else if (downloader.error != null) ...[
                const SizedBox(height: 10),
                Text(downloader.error!, style: const TextStyle(fontSize: 11.5, color: Colors.redAccent)),
              ],
              const SizedBox(height: 13),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isOnline ? onDownload : null,
                    icon: Icon(ready ? Icons.cloud_download_outlined : Icons.download),
                    label: Text(
                      !isOnline
                          ? 'Connect to download'
                          : ready
                              ? 'Update offline map'
                              : 'Download offline map',
                    ),
                  ),
                ),
                if (ready) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: onClear,
                    tooltip: 'Remove downloaded map tiles',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ]),
              if (stats.mapDownloadedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last map download: ${_formatDateTime(stats.mapDownloadedAt)}',
                  style: TextStyle(fontSize: 10.5, color: Colors.blueGrey.shade600),
                ),
              ],
            ]);
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'not yet';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '${months[value.month - 1]} ${value.day}, ${value.year} · $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade600)),
      ]);
}
