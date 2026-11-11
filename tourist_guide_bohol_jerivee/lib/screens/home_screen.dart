import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../widgets/destination_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.destinations,
    required this.favorites,
    required this.onOpenDestination,
    required this.onFavorite,
    required this.onSearch,
    required this.onExplore,
    required this.onOpenItineraries,
  });

  final List<Destination> destinations;
  final Set<String> favorites;
  final ValueChanged<Destination> onOpenDestination;
  final ValueChanged<String> onFavorite;
  final ValueChanged<String> onSearch;
  final VoidCallback onExplore;
  final VoidCallback onOpenItineraries;

  @override
  Widget build(BuildContext context) {
    final featured = destinations.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF075B65), Color(0xFF1496A0), Color(0xFF67B9A4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(30)),
              child: const Text('DISCOVER BOHOL, PHILIPPINES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 18),
            const Text('Your next\nBohol adventure\nstarts here.', style: TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900, height: 1.08)),
            const SizedBox(height: 12),
            Text('Explore places, find useful travel information, and plan your journey in one place.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.5, fontSize: 13)),
            const SizedBox(height: 19),
            TextField(
              onSubmitted: onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search destinations in Bohol...',
                hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF087E8B)),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => onSearch('')),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 27),
        _SectionHeading(title: 'Explore Bohol', subtitle: 'Find places that match your travel style', action: 'View all', onAction: onExplore),
        const SizedBox(height: 13),
        const Wrap(spacing: 9, runSpacing: 9, children: [
          _CategoryPill(icon: Icons.terrain, label: 'Nature'),
          _CategoryPill(icon: Icons.beach_access, label: 'Beaches'),
          _CategoryPill(icon: Icons.account_balance, label: 'Culture'),
          _CategoryPill(icon: Icons.water, label: 'Caves'),
        ]),
        const SizedBox(height: 27),
        _SectionHeading(title: 'Popular destinations', subtitle: 'Places to add to your travel list', action: 'Explore all', onAction: onExplore),
        const SizedBox(height: 13),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 640 ? 2 : 1;
          return GridView.builder(
            itemCount: featured.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 1.13 : 0.82,
            ),
            itemBuilder: (context, index) {
              final destination = featured[index];
              return DestinationCard(
                destination: destination,
                isFavorite: favorites.contains(destination.id),
                onFavorite: () => onFavorite(destination.id),
                onTap: () => onOpenDestination(destination),
              );
            },
          );
        }),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFE7F3F0), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.route_rounded, color: Color(0xFF087E8B))),
            const SizedBox(width: 13),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan your Bohol trip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 4),
              Text('Browse sample routes and build your travel plan.', style: TextStyle(fontSize: 12, height: 1.4)),
            ])),
            IconButton.filledTonal(onPressed: onOpenItineraries, icon: const Icon(Icons.arrow_forward)),
          ]),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle, required this.action, required this.onAction});
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
        ])),
        TextButton(onPressed: onAction, child: Text(action)),
      ]);
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 17, color: const Color(0xFF087E8B)),
        label: Text(label),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE4ECEB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      );
}
