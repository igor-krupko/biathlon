import 'track.dart';
import '../data/predefined_tracks.dart';
import 'dart:math';
import 'athlete.dart';
import 'race_points_result.dart';
import 'season.dart';
import 'race.dart';

class Career {
  final DateTime startDate;
  bool isActive;
  final List<Season> seasons;
  int currentSeasonIndex;
  int currentRaceIndex;
  final List<RacePointsResult> racePointsHistory = [];
  final List<List<RacePointsResult>> allRacesResults = [];
  Athlete player;

  Career({
    required this.startDate,
    required this.player,
    this.isActive = true,
    List<Season>? seasons,
    this.currentSeasonIndex = 0,
    this.currentRaceIndex = 0,
  }) : seasons = seasons ?? _generateSeasons();

  static List<Season> _generateSeasons() {
    final random = Random();
    final List<Season> generatedSeasons = [];
    final List<int> years = List.generate(25, (i) => 1999 + i);
    int raceId = 1;
    for (int i = 0; i < years.length; i++) {
      final year = years[i];
      final tracks = List<Track>.from(predefinedTracks);
      tracks.shuffle(random);
      final races = List.generate(2, (j) => Race(
        id: raceId++,
        date: DateTime(year, 1, j + 1),
        track: tracks[j],
      ));
      generatedSeasons.add(Season(
        id: i + 1,
        year: year,
        name: 'Season $year',
        races: races,
      ));
    }
    return generatedSeasons;
  }

  Season get currentSeason => seasons[currentSeasonIndex];
  Race? get currentRace =>
    currentRaceIndex < currentSeason.races.length
      ? currentSeason.races[currentRaceIndex]
      : null;

  bool hasNextRace() {
    return currentRaceIndex < currentSeason.races.length - 1;
  }

  bool hasNextSeason() {
    return currentSeasonIndex < seasons.length - 1;
  }

  void moveToNextRace() {
    if (hasNextRace()) {
      currentRaceIndex++;
    } else if (currentRaceIndex == currentSeason.races.length - 1) {
      // After the last race, increment to mark season as ended
      currentRaceIndex++;
    }
  }

  void moveToNextSeason() {
    if (hasNextSeason()) {
      currentSeasonIndex++;
      currentRaceIndex = 0;
    }
  }

  void stopCareer() {
    isActive = false;
  }

  void continueCareer() {
    isActive = true;
  }

  int get playerMoney => player.money;

  void addMoneyToPlayer(int amount) {
    // Create a new Athlete with updated money
    final updatedPlayer = Athlete(
      id: player.id,
      name: player.name,
      surname: player.surname,
      country: player.country,
      speed: player.speed,
      shootingDown: player.shootingDown,
      shootingStanding: player.shootingStanding,
      money: player.money + amount,
      seasonStats: null,
    );
    // This is a workaround since player is final; in a real app, refactor to allow updating player
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    // ignore: prefer_final_fields
    player = updatedPlayer;
  }

  void addRacePointsResult(RacePointsResult result) {
    racePointsHistory.add(result);
  }

  void addFullRaceResults(List<RacePointsResult> results) {
    allRacesResults.add(results);
  }

  bool isSeasonEnded() {
    return currentRaceIndex >= currentSeason.races.length;
  }

  Career copyWith({
    DateTime? startDate,
    Athlete? player,
    bool? isActive,
    List<Season>? seasons,
    int? currentSeasonIndex,
    int? currentRaceIndex,
    List<RacePointsResult>? racePointsHistory,
    List<List<RacePointsResult>>? allRacesResults,
  }) {
    final newCareer = Career(
      startDate: startDate ?? this.startDate,
      player: player ?? this.player,
      isActive: isActive ?? this.isActive,
      seasons: seasons ?? List<Season>.from(this.seasons),
      currentSeasonIndex: currentSeasonIndex ?? this.currentSeasonIndex,
      currentRaceIndex: currentRaceIndex ?? this.currentRaceIndex,
    );
    newCareer.racePointsHistory.addAll(racePointsHistory ?? this.racePointsHistory);
    newCareer.allRacesResults.addAll(allRacesResults ?? this.allRacesResults);
    return newCareer;
  }
} 