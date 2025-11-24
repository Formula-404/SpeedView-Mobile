// To parse this JSON data, do
//
//     final team = teamFromJson(jsonString);

import 'dart:convert';

Team teamFromJson(String str) => Team.fromJson(json.decode(str));

String teamToJson(Team data) => json.encode(data.toJson());

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
    DateTime createdAt;
    DateTime updatedAt;
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

    factory Team.fromJson(Map<String, dynamic> json) => Team(
        teamName: json["team_name"],
        shortCode: json["short_code"],
        teamLogoUrl: json["team_logo_url"],
        website: json["website"],
        wikiUrl: json["wiki_url"],
        teamColour: json["team_colour"],
        teamColourHex: json["team_colour_hex"],
        teamColourSecondary: json["team_colour_secondary"],
        teamColourSecondaryHex: json["team_colour_secondary_hex"],
        country: json["country"],
        base: json["base"],
        foundedYear: json["founded_year"],
        isActive: json["is_active"],
        teamDescription: json["team_description"],
        engines: json["engines"],
        constructorsChampionships: json["constructors_championships"],
        driversChampionships: json["drivers_championships"],
        racesEntered: json["races_entered"],
        raceVictories: json["race_victories"],
        podiums: json["podiums"],
        points: json["points"],
        avgLapTimeMs: json["avg_lap_time_ms"],
        bestLapTimeMs: json["best_lap_time_ms"],
        avgPitDurationMs: json["avg_pit_duration_ms"],
        topSpeedKph: json["top_speed_kph"],
        lapsCompleted: json["laps_completed"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        detailUrl: json["detail_url"],
    );

    Map<String, dynamic> toJson() => {
        "team_name": teamName,
        "short_code": shortCode,
        "team_logo_url": teamLogoUrl,
        "website": website,
        "wiki_url": wikiUrl,
        "team_colour": teamColour,
        "team_colour_hex": teamColourHex,
        "team_colour_secondary": teamColourSecondary,
        "team_colour_secondary_hex": teamColourSecondaryHex,
        "country": country,
        "base": base,
        "founded_year": foundedYear,
        "is_active": isActive,
        "team_description": teamDescription,
        "engines": engines,
        "constructors_championships": constructorsChampionships,
        "drivers_championships": driversChampionships,
        "races_entered": racesEntered,
        "race_victories": raceVictories,
        "podiums": podiums,
        "points": points,
        "avg_lap_time_ms": avgLapTimeMs,
        "best_lap_time_ms": bestLapTimeMs,
        "avg_pit_duration_ms": avgPitDurationMs,
        "top_speed_kph": topSpeedKph,
        "laps_completed": lapsCompleted,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "detail_url": detailUrl,
    };
}
