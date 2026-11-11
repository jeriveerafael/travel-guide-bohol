import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.destinations,
    required this.favorites,
    required this.initialQuery,
    required this.onOpenDestination,
    required this.onFavorite,
    required this.onQueryChanged,
  });

  final List<Destination> destinations;
  final Set<String> favorites;
  final String initialQuery;
  final ValueChanged<Destination> onOpenDestination;
  final ValueChanged<String> onFavorite;
  final ValueChanged<String> onQueryChanged;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _searchController;
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        widget.initialQuery != _searchController.text) {
      _searchController.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final results = widget.destinations.where((destination) {
      final matchesCategory = _category == 'All' || destination.category == _category;
      final searchable = '${destination.name} ${destination.municipality} ${destination.category} ${destination.description} ${destination.activities} ${destination.accommodations}'.toLowerCase();
      return matchesCategory && (query.isEmpty || searchable.contains(query));
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        const Text('Explore destinations', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('Search and filter tourist attractions around Bohol.', style: TextStyle(color: Colors.blueGrey.shade600)),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {});
            widget.onQueryChanged(value);
          },
          decoration: InputDecoration(
            hintText: 'Search by destination, town, or keyword',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {
                _searchController.clear();
                widget.onQueryChanged('');
                setState(() {});
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: categories.map((category) => ChoiceChip(
            label: Text(category, style: const TextStyle(fontSize: 11)),
            selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
          )).toList(),
        ),
        const SizedBox(height: 19),
        Row(children: [
          Text('${results.length} destinations', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('Bohol, Philippines', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
        ]),
        const SizedBox(height: 13),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(children: [
              Icon(Icons.search_off_rounded, size: 44, color: Colors.blueGrey),
              SizedBox(height: 10),
              Text('No destinations found', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Try another keyword or category.'),
            ]),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 620 ? 2 : 1;
            return GridView.builder(
              itemCount: results.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 1.12 : 0.82,
              ),
              itemBuilder: (context, index) {
                final destination = results[index];
                return DestinationCard(
                  destination: destination,
                  isFavorite: widget.favorites.contains(destination.id),
                  onFavorite: () => widget.onFavorite(destination.id),
                  onTap: () => widget.onOpenDestination(destination),
                );
              },
            );
          }),
      ],
    );
  }
}
