class Driver {
  final int driverNumber;
  final String fullName;
  final String broadcastName;
  final String headshotUrl;
  final String countryCode;
  final List<String> teams;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Driver({
    required this.driverNumber,
    required this.fullName,
    required this.broadcastName,
    required this.headshotUrl,
    required this.countryCode,
    required this.teams,
    this.createdAt,
    this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverNumber: json['driver_number'] is int
          ? json['driver_number']
          : int.tryParse(json['driver_number'].toString()) ?? 0,
      fullName: (json['full_name'] ?? '') as String,
      broadcastName: (json['broadcast_name'] ?? '') as String,
      headshotUrl: (json['headshot_url'] ?? '') as String,
      countryCode: (json['country_code'] ?? '') as String,
      teams: (json['teams'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Data yang dikirim waktu create / update ke Django.
  Map<String, String> toJsonForCreateUpdate() {
    return {
      'driver_number': driverNumber.toString(),
      'full_name': fullName,
      'broadcast_name': broadcastName,
      'country_code': countryCode,
      'headshot_url': headshotUrl,
      // teams dikosongkan → ManyToMany boleh kosong (opsional)
    };
  }

  String get displayName =>
      fullName.isNotEmpty ? fullName : (broadcastName.isNotEmpty ? broadcastName : '#$driverNumber');

  String get displayTeams =>
      teams.isEmpty ? '—' : teams.join(', ');

  bool get hasHeadshot => headshotUrl.trim().isNotEmpty;
}
