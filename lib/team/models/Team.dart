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
        foundedYear: json['founded_year'] ?? 0,
        isActive: json['is_active'] ?? false,
        teamDescription: json['team_description'] ?? '',
        engines: json['engines'] ?? '',
        constructorsChampionships: json['constructors_championships'] ?? 0,
        driversChampionships: json['drivers_championships'] ?? 0,
        racesEntered: json['races_entered'] ?? 0,
        raceVictories: json['race_victories'] ?? 0,
        podiums: json['podiums'] ?? 0,
        points: json['points'] ?? 0,
        avgLapTimeMs: json['avg_lap_time_ms'] ?? 0,
        bestLapTimeMs: json['best_lap_time_ms'] ?? 0,
        avgPitDurationMs: json['avg_pit_duration_ms'] ?? 0,
        topSpeedKph: json['top_speed_kph'] ?? 0,
        lapsCompleted: json['laps_completed'] ?? 0,
        createdAt: json['created_at'] != null && json['created_at'] != ''
            ? DateTime.tryParse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null && json['updated_at'] != ''
            ? DateTime.tryParse(json['updated_at'])
            : null,
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
