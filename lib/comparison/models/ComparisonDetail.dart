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
      foundedYear: json['founded_year'] as int?,
      engines: json['engines'] as String? ?? '',
      website: json['website'] as String? ?? '',
      wikiUrl: json['wiki_url'] as String? ?? '',
      racesEntered: json['races_entered'] as int?,
      raceVictories: json['race_victories'] as int?,
      podiums: json['podiums'] as int?,
      points: json['points'] as double?,
      avgLapTimeMs: json['avg_lap_time_ms'] as double?,
      bestLapTimeMs: json['best_lap_time_ms'] as double?,
      avgPitDurationMs: json['avg_pit_duration_ms'] as double?,
      topSpeedKph: json['top_speed_kph'] as double?,
      lapsCompleted: json['laps_completed'] as int?,
      detailUrl: json['detail_url'] as String? ?? '',
    );
  }
}
