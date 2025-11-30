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

}
