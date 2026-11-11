class TravelItinerary {
  const TravelItinerary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.destinationIds,
    required this.budgetNote,
    required this.tag,
  });

  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final List<String> destinationIds;
  final String budgetNote;
  final String tag;
}
