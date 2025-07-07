import 'track.dart';
import '../data/predefined_tracks.dart';
import 'dart:math';
import 'athlete.dart';
import 'race_points_result.dart';
import 'season.dart';
import 'race.dart';
import '../data/races_by_season/races_1999.dart' as races_1999;
import '../data/races_by_season/races_2000.dart' as races_2000;
import '../data/races_by_season/races_2001.dart' as races_2001;
import '../data/races_by_season/races_2002.dart' as races_2002;
import '../data/races_by_season/races_2003.dart' as races_2003;
import '../data/races_by_season/races_2004.dart' as races_2004;
import '../data/races_by_season/races_2005.dart' as races_2005;
import '../data/races_by_season/races_2006.dart' as races_2006;
import '../data/races_by_season/races_2007.dart' as races_2007;
import '../data/races_by_season/races_2008.dart' as races_2008;
import '../data/races_by_season/races_2009.dart' as races_2009;
import '../data/races_by_season/races_2010.dart' as races_2010;
import '../data/races_by_season/races_2011.dart' as races_2011;
import '../data/races_by_season/races_2012.dart' as races_2012;
import '../data/races_by_season/races_2013.dart' as races_2013;
import '../data/races_by_season/races_2014.dart' as races_2014;
import '../data/races_by_season/races_2015.dart' as races_2015;
import '../data/races_by_season/races_2016.dart' as races_2016;
import '../data/races_by_season/races_2017.dart' as races_2017;
import '../data/races_by_season/races_2018.dart' as races_2018;
import '../data/races_by_season/races_2019.dart' as races_2019;
import '../data/races_by_season/races_2020.dart' as races_2020;
import '../data/races_by_season/races_2021.dart' as races_2021;
import '../data/races_by_season/races_2022.dart' as races_2022;
import '../data/races_by_season/races_2023.dart' as races_2023;
import '../data/races_by_season/races_2024.dart' as races_2024;

class Career {
  final DateTime startDate;
  bool isActive;
  final List<Season> seasons;
  int currentSeasonIndex;
  int currentRaceIndex;
  final List<RacePointsResult> racePointsHistory = [];
  final List<List<RacePointsResult>> allRacesResults = [];
  Athlete player;
  int? seasonRating;

  Career({
    required this.startDate,
    required this.player,
    this.isActive = true,
    List<Season>? seasons,
    this.currentSeasonIndex = 0,
    this.currentRaceIndex = 0,
  }) : seasons = seasons ?? _generateSeasons();

  factory Career.fromJson(Map<String, dynamic> json) {
    Career career = Career(
      startDate: DateTime.parse(json['startDate'] as String),
      player: Athlete.fromJson(json['player'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool,
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentSeasonIndex: json['currentSeasonIndex'] as int,
      currentRaceIndex: json['currentRaceIndex'] as int,
    );
    if (json['racePointsHistory'] != null) {
      (json['racePointsHistory'] as List<dynamic>)
          .map((e) => RacePointsResult.fromJson(e as Map<String, dynamic>))
          .forEach(career.racePointsHistory.add);
    }
    if (json['allRacesResults'] != null) {
      (json['allRacesResults'] as List<dynamic>)
          .map((list) => (list as List<dynamic>)
              .map((e) => RacePointsResult.fromJson(e as Map<String, dynamic>))
              .toList())
          .forEach(career.allRacesResults.add);
    }
    career.seasonRating = json['seasonRating'] as int?;
    return career;
  }

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'isActive': isActive,
        'seasons': seasons.map((e) => e.toJson()).toList(),
        'currentSeasonIndex': currentSeasonIndex,
        'currentRaceIndex': currentRaceIndex,
        'player': player.toJson(),
        'racePointsHistory': racePointsHistory.map((e) => e.toJson()).toList(),
        'allRacesResults': allRacesResults.map((list) => list.map((e) => e.toJson()).toList()).toList(),
        'seasonRating': seasonRating,
      };

  static List<Race> _loadRacesForYear(int year) {
    switch (year) {
      case 1999:
        return races_1999.races1999;
      case 2000:
        return races_2000.races2000;
      case 2001:
        return races_2001.races2001;
      case 2002:
        return races_2002.races2002;
      case 2003:
        return races_2003.races2003;
      case 2004:
        return races_2004.races2004;
      case 2005:
        return races_2005.races2005;
      case 2006:
        return races_2006.races2006;
      case 2007:
        return races_2007.races2007;
      case 2008:
        return races_2008.races2008;
      case 2009:
        return races_2009.races2009;
      case 2010:
        return races_2010.races2010;
      case 2011:
        return races_2011.races2011;
      case 2012:
        return races_2012.races2012;
      case 2013:
        return races_2013.races2013;
      case 2014:
        return races_2014.races2014;
      case 2015:
        return races_2015.races2015;
      case 2016:
        return races_2016.races2016;
      case 2017:
        return races_2017.races2017;
      case 2018:
        return races_2018.races2018;
      case 2019:
        return races_2019.races2019;
      case 2020:
        return races_2020.races2020;
      case 2021:
        return races_2021.races2021;
      case 2022:
        return races_2022.races2022;
      case 2023:
        return races_2023.races2023;
      case 2024:
        return races_2024.races2024;
      default:
        throw Exception('No race data for year: $year');
    }
  }

  static List<Season> _generateSeasons() {
    final List<Season> generatedSeasons = [];
    final List<int> years = List.generate(25, (i) => 1999 + i);
    for (int i = 0; i < years.length; i++) {
      final year = years[i];
      final races = _loadRacesForYear(year);
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
    updateSeasonRating();
  }

  void moveToNextSeason() {
    if (hasNextSeason()) {
      currentSeasonIndex++;
      currentRaceIndex = 0;
      seasonRating = null;
      // Update player stats for the new season if available
      final newYear = currentSeason.year;
      final stats = player.seasonStats != null ? player.seasonStats![newYear] : null;
      if (stats != null && stats.isActive) {
        player = Athlete(
          id: player.id,
          name: player.name,
          surname: player.surname,
          country: player.country,
          speed: stats.speed,
          shootingDown: stats.shootingDown,
          shootingStanding: stats.shootingStanding,
          money: player.money,
          seasonStats: player.seasonStats,
        );
      }
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

  void updateSeasonRating() {
    // Aggregate points for all athletes in the current season using date range
    final seasonStart = DateTime(currentSeason.year, 6, 1);
    final seasonEnd = DateTime(currentSeason.year + 1, 6, 1);
    final List<RacePointsResult> seasonResults = allRacesResults.expand((x) => x)
      .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
      .toList();
    final Map<String, int> athletePoints = {};
    for (final result in seasonResults) {
      final key = '${result.athlete.name}|${result.athlete.surname}|${result.athlete.country}';
      athletePoints[key] = (athletePoints[key] ?? 0) + result.points;
    }
    // Sort athletes by points descending
    final sorted = athletePoints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final playerKey = '${player.name}|${player.surname}|${player.country}';
    final place = sorted.indexWhere((e) => e.key == playerKey);
    seasonRating = place >= 0 ? place + 1 : null;
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