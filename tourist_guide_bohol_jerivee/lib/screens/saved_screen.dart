import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../widgets/destination_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.destinations,
    required this.favorites,
    required this.savedOffline,
    required this.visited,
    required this.onOpenDestination,
    required this.onFavorite,
    required this.onSaveOffline,
    required this.onOpenOfflineCenter,
  });

  final List<Destination> destinations;
  final Set<String> favorites;
  final Set<String> savedOffline;
  final Set<String> visited;
  final ValueChanged<Destination> onOpenDestination;
  final ValueChanged<String> onFavorite;
  final ValueChanged<String> onSaveOffline;
  final VoidCallback onOpenOfflineCenter;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('My travel library', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Keep your favorite and downloaded Bohol guides together.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenOfflineCenter,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Open offline guide center'),
              ),
            ]),
          ),
          const TabBar(
            tabs: [Tab(text: 'Favorites'), Tab(text: 'Offline'), Tab(text: 'Visited')],
            labelColor: Color(0xFF087E8B),
            indicatorColor: Color(0xFF087E8B),
          ),
          Expanded(
            child: TabBarView(children: [
              _DestinationList(
                destinations: destinations.where((d) => favorites.contains(d.id)).toList(),
                emptyTitle: 'No favorites yet',
                emptyText: 'Tap the heart on a destination to save it here.',
                onOpen: onOpenDestination,
                favorites: favorites,
                onFavorite: onFavorite,
              ),
              _DestinationList(
                destinations: destinations.where((d) => savedOffline.contains(d.id)).toList(),
                emptyTitle: 'No offline guides saved',
                emptyText: 'Open a destination and select Save offline to keep its guide in this list.',
                onOpen: onOpenDestination,
                favorites: favorites,
                onFavorite: onFavorite,
              ),
              _DestinationList(
                destinations: destinations.where((d) => visited.contains(d.id)).toList(),
                emptyTitle: 'No visited places yet',
                emptyText: 'Mark a destination as visited after your trip.',
                onOpen: onOpenDestination,
                favorites: favorites,
                onFavorite: onFavorite,
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Text(
              'Saved destination guides and any downloaded map tiles are stored in this browser with IndexedDB. After the first visit, the written guides stay available without an internet connection.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({
    required this.destinations,
    required this.emptyTitle,
    required this.emptyText,
    required this.onOpen,
    required this.favorites,
    required this.onFavorite,
  });

  final List<Destination> destinations;
  final String emptyTitle;
  final String emptyText;
  final ValueChanged<Destination> onOpen;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 5),
            Text(emptyText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, height: 1.5)),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return DestinationCard(
          destination: destination,
          compact: true,
          isFavorite: favorites.contains(destination.id),
          onFavorite: () => onFavorite(destination.id),
          onTap: () => onOpen(destination),
        );
      },
    );
  }
}
