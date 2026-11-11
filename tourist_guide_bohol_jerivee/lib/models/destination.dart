class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.municipality,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.entranceFee = 'Check with the destination',
    this.operatingHours = 'Check before visiting',
    this.tips = 'Confirm current visitor information before travelling.',
    this.contactInfo = '',
    this.activities = '',
    this.accommodations = '',
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String municipality;
  final String category;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String entranceFee;
  final String operatingHours;
  final String tips;
  final String contactInfo;
  final String activities;
  final String accommodations;
  final bool isCustom;

  Destination copyWith({
    String? name,
    String? municipality,
    String? category,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? entranceFee,
    String? operatingHours,
    String? tips,
    String? contactInfo,
    String? activities,
    String? accommodations,
  }) {
    return Destination(
      id: id,
      name: name ?? this.name,
      municipality: municipality ?? this.municipality,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      entranceFee: entranceFee ?? this.entranceFee,
      operatingHours: operatingHours ?? this.operatingHours,
      tips: tips ?? this.tips,
      contactInfo: contactInfo ?? this.contactInfo,
      activities: activities ?? this.activities,
      accommodations: accommodations ?? this.accommodations,
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'municipality': municipality,
        'category': category,
        'description': description,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'entranceFee': entranceFee,
        'operatingHours': operatingHours,
        'tips': tips,
        'contactInfo': contactInfo,
        'activities': activities,
        'accommodations': accommodations,
      };

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        id: json['id'] as String,
        name: json['name'] as String,
        municipality: json['municipality'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        entranceFee: json['entranceFee'] as String? ?? 'Check with the destination',
        operatingHours: json['operatingHours'] as String? ?? 'Check before visiting',
        tips: json['tips'] as String? ?? '',
        contactInfo: json['contactInfo'] as String? ?? '',
        activities: json['activities'] as String? ?? '',
        accommodations: json['accommodations'] as String? ?? '',
        isCustom: json['isCustom'] as bool? ?? true,
      );
}
