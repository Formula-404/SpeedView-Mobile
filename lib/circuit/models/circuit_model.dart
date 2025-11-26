class Circuit {
  final int id;
  final String name;
  final String country;
  final String location;
  final String? mapImageUrl;
  final String circuitType;
  final String direction;
  final double lengthKm;
  final int turns;
  final String grandsPrix;
  final String seasons;
  final int grandsPrixHeld;
  final bool isAdminCreated;
  final bool isAdmin;

  Circuit({
    required this.id,
    required this.name,
    required this.country,
    required this.location,
    this.mapImageUrl,
    required this.circuitType,
    required this.direction,
    required this.lengthKm,
    required this.turns,
    required this.grandsPrix,
    required this.seasons,
    required this.grandsPrixHeld,
    required this.isAdminCreated,
    required this.isAdmin,
  });

  factory Circuit.fromJson(Map<String, dynamic> json) {
    return Circuit(
      id: json['id'],
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      location: json['location'] ?? '',
      mapImageUrl: json['map_image_url'],
      circuitType: json['circuit_type'] ?? 'RACE', 
      direction: json['direction'] ?? 'CW',
      lengthKm: (json['length_km'] ?? 0.0).toDouble(),
      turns: json['turns'] ?? 0,
      grandsPrix: json['grands_prix'] ?? '',
      seasons: json['seasons'] ?? '',
      grandsPrixHeld: json['grands_prix_held'] ?? 0,
      isAdminCreated: json['is_admin_created'] ?? false,
      isAdmin: json['is_admin'] ?? false,
    );
  }
}