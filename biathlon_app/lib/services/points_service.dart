import '../models/career.dart';

/// Service responsible for calculating and processing points data
class PointsService {
  /// Calculate points data from career results
  PointsCalculationResult calculatePoints(Career career) {
    final races = career.allRacesResults.expand((x) => x).toList();
    
    if (races.isEmpty) {
      return PointsCalculationResult(
        athletes: [],
        raceKeys: [],
      );
    }

    // Group results by race
    final raceGroups = <String, List<RacePointsResult>>{};
    for (final r in races) {
      final key = '${r.track.name}|${r.type}';
      raceGroups.putIfAbsent(key, () => []).add(r);
    }

    // Get unique race keys sorted by track name
    final raceKeys = raceGroups.keys.toList()..sort();

    // Get all unique athletes
    final athletes = <String, Map<String, dynamic>>{};
    for (final r in races) {
      final key = '${r.athleteName}|${r.athleteSurname}|${r.athleteCountry}';
      if (!athletes.containsKey(key)) {
        athletes[key] = {
          'name': r.athleteName,
          'surname': r.athleteSurname,
          'country': r.athleteCountry,
          'points': 0,
          'results': <RacePointsResult>[],
        };
      }
      athletes[key]!['points'] += r.points;
      athletes[key]!['results'].add(r);
    }

    // Convert to AthletePointsData objects
    final athleteDataList = athletes.values.map((athlete) {
      final name = athlete['name'] as String;
      final surname = athlete['surname'] as String;
      final country = athlete['country'] as String;
      final points = athlete['points'] as int;
      final resultsList = athlete['results'] as List<RacePointsResult>;
      final resultsByRace = {for (var r in resultsList) '${r.track.name}|${r.type}': r};

      return AthletePointsData(
        name: name,
        surname: surname,
        country: country,
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
  int getAthleteRanking(List<AthletePointsData> athletes, String athleteName, String athleteSurname) {
    final index = athletes.indexWhere((a) => 
      a.name == athleteName && a.surname == athleteSurname
    );
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
  final String name;
  final String surname;
  final String country;
  final int totalPoints;
  final Map<String, RacePointsResult> resultsByRace;

  AthletePointsData({
    required this.name,
    required this.surname,
    required this.country,
    required this.totalPoints,
    required this.resultsByRace,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthletePointsData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          surname == other.surname &&
          country == other.country;

  @override
  int get hashCode => name.hashCode ^ surname.hashCode ^ country.hashCode;
} 