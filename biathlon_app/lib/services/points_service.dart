import 'package:biathlon_app/models/race_points_result.dart';

import '../models/career.dart';
import '../models/athlete.dart';

/// Service responsible for calculating and processing points data
class PointsService {
  /// Calculate points data from career results
  PointsCalculationResult calculatePoints(Career career) {
    // Only include results from the current season
    final races = career.currentSeason.races;
    final raceIds = races.map((r) => r.id).toSet();
    final allResults = career.allRacesResults.expand((x) => x).where((result) => raceIds.contains(result.race.id)).toList();
    if (allResults.isEmpty) {
      return PointsCalculationResult(
        athletes: [],
        raceKeys: [],
      );
    }

    // Group results by race
    final raceGroups = <String, List<RacePointsResult>>{};
    for (final r in allResults) {
      final key = '${r.race.id}';
      raceGroups.putIfAbsent(key, () => []).add(r);
    }

    // Get unique race keys sorted by race name
    final raceKeys = raceGroups.keys.toList()..sort();

    // Get all unique athletes
    final athletes = <int, Map<String, dynamic>>{};
    for (final r in allResults) {
      final key = r.athlete.id;
      if (!athletes.containsKey(key)) {
        athletes[key] = {
          'athlete': r.athlete,
          'points': 0,
          'results': <RacePointsResult>[],
        };
      }
      athletes[key]!['points'] += r.points;
      athletes[key]!['results'].add(r);
    }

    // Convert to AthletePointsData objects
    final athleteDataList = athletes.values.map((athlete) {
      final athleteObj = athlete['athlete'] as Athlete;
      final points = athlete['points'] as int;
      final resultsList = athlete['results'] as List<RacePointsResult>;
      final resultsByRace = {for (var r in resultsList) '${r.race.id}': r};

      return AthletePointsData(
        athlete: athleteObj,
        totalPoints: points,
        resultsByRace: resultsByRace,
      );
    }).toList();

    // Sort athletes by total points
    athleteDataList.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return PointsCalculationResult(
      athletes: athleteDataList,
      raceKeys: raceKeys,
    );
  }

  /// Get athlete ranking position
  int getAthleteRanking(List<AthletePointsData> athletes, int athleteId) {
    final index = athletes.indexWhere((a) => a.athlete.id == athleteId);
    return index >= 0 ? index + 1 : -1;
  }

  /// Get top athletes
  List<AthletePointsData> getTopAthletes(List<AthletePointsData> athletes, int count) {
    return athletes.take(count).toList();
  }

  /// Calculate total points for an athlete
  int calculateTotalPoints(List<RacePointsResult> results) {
    return results.fold(0, (sum, result) => sum + result.points);
  }
}

/// Result of points calculation
class PointsCalculationResult {
  final List<AthletePointsData> athletes;
  final List<String> raceKeys;

  const PointsCalculationResult({
    required this.athletes,
    required this.raceKeys,
  });
}

/// Data class for athlete points information
class AthletePointsData {
  final Athlete athlete;
  final int totalPoints;
  final Map<String, RacePointsResult> resultsByRace;

  AthletePointsData({
    required this.athlete,
    required this.totalPoints,
    required this.resultsByRace,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthletePointsData &&
          runtimeType == other.runtimeType &&
          athlete.id == other.athlete.id;

  @override
  int get hashCode => athlete.id.hashCode;
} 