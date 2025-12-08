int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String && v.trim().isNotEmpty) {
    return int.tryParse(v.trim());
  }
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String && v.trim().isNotEmpty) {
    return double.tryParse(v.trim());
  }
  return null;
}

class ComparisonTeamItem {
  final String teamName;
  final String shortCode;
  final String teamLogoUrl;
  final String teamColourHex;
  final String country;
  final String base;
  final int? foundedYear;
  final String engines;
  final String website;
  final String wikiUrl;
  final int? racesEntered;
  final int? raceVictories;
  final int? podiums;
  final int? lapsCompleted;
  final double? points;
  final double? avgLapTimeMs;
  final double? bestLapTimeMs;
  final double? avgPitDurationMs;
  final double? topSpeedKph;
  final String detailUrl;

  ComparisonTeamItem({
    required this.teamName,
    required this.shortCode,
    required this.teamLogoUrl,
    required this.teamColourHex,
    required this.country,
    required this.base,
    required this.foundedYear,
    required this.engines,
    required this.website,
    required this.wikiUrl,
    required this.racesEntered,
    required this.raceVictories,
    required this.podiums,
    required this.points,
    required this.avgLapTimeMs,
    required this.bestLapTimeMs,
    required this.avgPitDurationMs,
    required this.topSpeedKph,
    required this.lapsCompleted,
    required this.detailUrl,
  });

  factory ComparisonTeamItem.fromJson(Map<String, dynamic> json) {
    return ComparisonTeamItem(
      teamName: json['team_name'] as String? ?? '',
      shortCode: json['short_code'] as String? ?? '',
      teamLogoUrl: json['team_logo_url'] as String? ?? '',
      teamColourHex: json['team_colour_hex'] as String? ?? '#000000',
      country: json['country'] as String? ?? '',
      base: json['base'] as String? ?? '',
      foundedYear: _asInt(json['founded_year']),
      engines: json['engines'] as String? ?? '',
      website: json['website'] as String? ?? '',
      wikiUrl: json['wiki_url'] as String? ?? '',
      racesEntered: _asInt(json['races_entered']),
      raceVictories: _asInt(json['race_victories']),
      podiums: _asInt(json['podiums']),
      points: _asDouble(json['points']),
      avgLapTimeMs: _asDouble(json['avg_lap_time_ms']),
      bestLapTimeMs: _asDouble(json['best_lap_time_ms']),
      avgPitDurationMs: _asDouble(json['avg_pit_duration_ms']),
      topSpeedKph: _asDouble(json['top_speed_kph']),
      lapsCompleted: _asInt(json['laps_completed']),
      detailUrl: json['detail_url'] as String? ?? '',
    );
  }
}

class ComparisonCircuitItem {
  final String label;
  final String location;
  final String country;
  final String mapImageUrl;
  final String circuitTypeLabel;
  final String directionLabel;
  final double? lengthKm;
  final int? turns;
  final int? grandsPrixHeld;
  final String lastUsed;
  final String detailUrl;

  ComparisonCircuitItem({
    required this.label,
    required this.location,
    required this.country,
    required this.mapImageUrl,
    required this.circuitTypeLabel,
    required this.directionLabel,
    required this.lengthKm,
    required this.turns,
    required this.grandsPrixHeld,
    required this.lastUsed,
    required this.detailUrl,
  });

  factory ComparisonCircuitItem.fromJson(Map<String, dynamic> json) {
    return ComparisonCircuitItem(
      label: json['label'] as String? ?? '',
      location: json['location'] as String? ?? '',
      country: json['country'] as String? ?? '',
      mapImageUrl: json['map_image_url'] as String? ?? '',
      circuitTypeLabel: json['circuit_type_label'] as String? ?? '',
      directionLabel: json['direction_label'] as String? ?? '',
      lengthKm: _asDouble(json['length_km']),
      turns: _asInt(json['turns']),
      grandsPrixHeld: _asInt(json['grands_prix_held']),
      lastUsed: json['last_used'] as String? ?? '',
      detailUrl: json['detail_url'] as String? ?? '',
    );
  }

  String get lastUsedDisplay => lastUsed.isEmpty ? '—' : lastUsed;
}

class ComparisonDriverItem {
  final String label;
  final int? number;
  final String detailUrl;

  ComparisonDriverItem({
    required this.label,
    required this.number,
    required this.detailUrl,
  });

  factory ComparisonDriverItem.fromJson(Map<String, dynamic> json) {
    return ComparisonDriverItem(
      label: json['label'] as String? ?? '',
      number: _asInt(json['number']),
      detailUrl: json['detail_url'] as String? ?? '',
    );
  }

  String get displayNumber => number != null ? '#$number' : '—';
}

class ComparisonCarItem {
  final String label;
  final int? driverNumber;
  final int? meetingKey;
  final int? sessionKey;
  final String detailUrl;

  ComparisonCarItem({
    required this.label,
    required this.driverNumber,
    required this.meetingKey,
    required this.sessionKey,
    required this.detailUrl,
  });

  factory ComparisonCarItem.fromJson(Map<String, dynamic> json) {
    return ComparisonCarItem(
      label: json['label'] as String? ?? '',
      driverNumber: _asInt(json['driver_number']),
      meetingKey: _asInt(json['meeting_key']),
      sessionKey: _asInt(json['session_key']),
      detailUrl: json['detail_url'] as String? ?? '',
    );
  }

  String get displayDriverNumber =>
      driverNumber != null ? '#$driverNumber' : '—';
}
