import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/destination.dart';
import '../models/itinerary.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({
    super.key,
    required this.destinations,
    required this.savedItineraries,
    required this.onToggleSaved,
    required this.onOpenDestination,
  });

  final List<Destination> destinations;
  final Set<String> savedItineraries;
  final ValueChanged<String> onToggleSaved;
  final ValueChanged<Destination> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        const Text('Recommended itineraries', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('Sample travel plans to help you organize your visit.', style: TextStyle(color: Colors.blueGrey.shade600)),
        const SizedBox(height: 18),
        ...sampleItineraries.map((itinerary) => _ItineraryCard(
          itinerary: itinerary,
          destinations: destinations,
          isSaved: savedItineraries.contains(itinerary.id),
          onToggleSaved: () => onToggleSaved(itinerary.id),
          onOpenDestination: onOpenDestination,
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF5DE), borderRadius: BorderRadius.circular(16)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Color(0xFF9A6B17)),
            SizedBox(width: 10),
            Expanded(child: Text('These are example routes, not confirmed tour packages. Travel times, transport, fees, weather, and site access should be checked before departure.', style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF684B18)))),
          ]),
        ),
      ],
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.itinerary,
    required this.destinations,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onOpenDestination,
  });

  final TravelItinerary itinerary;
  final List<Destination> destinations;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final ValueChanged<Destination> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    final routeDestinations = itinerary.destinationIds
        .map((id) {
          for (final destination in destinations) {
            if (destination.id == id) return destination;
          }
          return null;
        })
        .whereType<Destination>()
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(itinerary.tag.toUpperCase(), style: const TextStyle(color: Color(0xFF087E8B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 5),
              Text(itinerary.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(itinerary.subtitle, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12, height: 1.4)),
            ])),
            IconButton.filledTonal(
              onPressed: onToggleSaved,
              tooltip: isSaved ? 'Remove saved itinerary' : 'Save itinerary',
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            ),
          ]),
          const SizedBox(height: 13),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Tag(icon: Icons.schedule, label: itinerary.duration),
            _Tag(icon: Icons.place_outlined, label: '${routeDestinations.length} stops'),
          ]),
          const SizedBox(height: 14),
          const Text('Suggested stops', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 7),
          ...routeDestinations.map((destination) => InkWell(
            onTap: () => onOpenDestination(destination),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF087E8B), size: 17),
                const SizedBox(width: 7),
                Expanded(child: Text('${destination.name} · ${destination.municipality}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right, size: 17),
              ]),
            ),
          )),
          const SizedBox(height: 8),
          Text(itinerary.budgetNote, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, height: 1.45)),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFFEAF4F1), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: const Color(0xFF087E8B)), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
  );
}
