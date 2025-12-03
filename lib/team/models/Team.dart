class Team {
  String teamName;
  String shortCode;
  String teamLogoUrl;
  String website;
  String wikiUrl;
  String teamColour;
  String teamColourHex;
  String teamColourSecondary;
  String teamColourSecondaryHex;
  String country;
  String base;
  int foundedYear;
  bool isActive;
  String teamDescription;
  String engines;
  int constructorsChampionships;
  int driversChampionships;
  int racesEntered;
  int raceVictories;
  int podiums;
  int points;
  int avgLapTimeMs;
  int bestLapTimeMs;
  int avgPitDurationMs;
  int topSpeedKph;
  int lapsCompleted;
  DateTime? createdAt;
  DateTime? updatedAt;
  String detailUrl;

  Team({
    required this.teamName,
    required this.shortCode,
    required this.teamLogoUrl,
    required this.website,
    required this.wikiUrl,
    required this.teamColour,
    required this.teamColourHex,
    required this.teamColourSecondary,
    required this.teamColourSecondaryHex,
    required this.country,
    required this.base,
    required this.foundedYear,
    required this.isActive,
    required this.teamDescription,
    required this.engines,
    required this.constructorsChampionships,
    required this.driversChampionships,
    required this.racesEntered,
    required this.raceVictories,
    required this.podiums,
    required this.points,
    required this.avgLapTimeMs,
    required this.bestLapTimeMs,
    required this.avgPitDurationMs,
    required this.topSpeedKph,
    required this.lapsCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.detailUrl,
  });

  // ---------- helpers ----------
  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // ---------- fromJson / toJson ----------
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamName: json['team_name'] ?? '',
      shortCode: json['short_code'] ?? '',
      teamLogoUrl: json['team_logo_url'] ?? '',
      website: json['website'] ?? '',
      wikiUrl: json['wiki_url'] ?? '',
      teamColour: json['team_colour'] ?? '',
      teamColourHex: json['team_colour_hex'] ?? '',
      teamColourSecondary: json['team_colour_secondary'] ?? '',
      teamColourSecondaryHex: json['team_colour_secondary_hex'] ?? '',
      country: json['country'] ?? '',
      base: json['base'] ?? '',
      foundedYear: _asInt(json['founded_year']),
      isActive: _asBool(json['is_active']),
      teamDescription: json['team_description'] ?? '',
      engines: json['engines'] ?? '',
      constructorsChampionships: _asInt(json['constructors_championships']),
      driversChampionships: _asInt(json['drivers_championships']),
      racesEntered: _asInt(json['races_entered']),
      raceVictories: _asInt(json['race_victories']),
      podiums: _asInt(json['podiums']),
      points: _asInt(json['points']),
      avgLapTimeMs: _asInt(json['avg_lap_time_ms']),
      bestLapTimeMs: _asInt(json['best_lap_time_ms']),
      avgPitDurationMs: _asInt(json['avg_pit_duration_ms']),
      topSpeedKph: _asInt(json['top_speed_kph']),
      lapsCompleted: _asInt(json['laps_completed']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      detailUrl: json['detail_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_name': teamName,
      'short_code': shortCode,
      'team_logo_url': teamLogoUrl,
      'website': website,
      'wiki_url': wikiUrl,
      'team_colour': teamColour,
      'team_colour_hex': teamColourHex,
      'team_colour_secondary': teamColourSecondary,
      'team_colour_secondary_hex': teamColourSecondaryHex,
      'country': country,
      'base': base,
      'founded_year': foundedYear,
      'is_active': isActive,
      'team_description': teamDescription,
      'engines': engines,
      'constructors_championships': constructorsChampionships,
      'drivers_championships': driversChampionships,
      'races_entered': racesEntered,
      'race_victories': raceVictories,
      'podiums': podiums,
      'points': points,
      'avg_lap_time_ms': avgLapTimeMs,
      'best_lap_time_ms': bestLapTimeMs,
      'avg_pit_duration_ms': avgPitDurationMs,
      'top_speed_kph': topSpeedKph,
      'laps_completed': lapsCompleted,
      'detail_url': detailUrl,
    };
  }
}
