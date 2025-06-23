import '../models/career.dart';
import '../models/athlete.dart';
import '../models/track.dart';
import '../models/season.dart';
import '../models/race.dart';

/// Service responsible for career-related business logic
class CareerService {
  /// Check if career is completed
  bool isCareerCompleted(Career career) {
    return !career.hasNextSeason() && !career.hasNextRace();
  }

  /// Get next race information
  NextRaceInfo? getNextRaceInfo(Career career) {
    if (career.currentSeason.races.isEmpty || career.currentRace == null) return null;
    return NextRaceInfo(
      race: career.currentRace!,
      isLastRace: !career.hasNextRace(),
      season: career.currentSeason,
      isLastSeason: !career.hasNextSeason(),
    );
  }

  /// Get career progress information
  CareerProgress getCareerProgress(Career career) {
    final totalSeasons = career.seasons.length;
    final currentSeasonIndex = career.currentSeasonIndex;
    final totalRaces = career.currentSeason.races.length;
    final completedRaces = career.currentRaceIndex;
    return CareerProgress(
      totalSeasons: totalSeasons,
      currentSeasonIndex: currentSeasonIndex,
      totalRaces: totalRaces,
      completedRaces: completedRaces,
      progressPercentage: totalRaces > 0 ? (completedRaces / totalRaces) * 100.0 : 0.0,
    );
  }

  /// Get career statistics
  CareerStats getCareerStats(Career career) {
    final allResults = career.allRacesResults.expand((x) => x).toList();
    
    if (allResults.isEmpty) {
      return CareerStats(
        totalRaces: 0,
        totalPoints: 0,
        averagePlace: 0.0,
        bestPlace: 0,
        worstPlace: 0,
      );
    }

    final playerResults = allResults.where((r) => r.athlete.id == career.player.id).toList();

    final totalRaces = playerResults.length;
    final totalPoints = playerResults.fold(0, (sum, r) => sum + r.points);
    final averagePlace = totalRaces > 0 ? 
      playerResults.fold(0.0, (sum, r) => sum + r.place) / totalRaces : 0.0;
    final bestPlace = playerResults.isNotEmpty ? 
      playerResults.map((r) => r.place).reduce((a, b) => a < b ? a : b) : 0;
    final worstPlace = playerResults.isNotEmpty ? 
      playerResults.map((r) => r.place).reduce((a, b) => a > b ? a : b) : 0;

    return CareerStats(
      totalRaces: totalRaces,
      totalPoints: totalPoints,
      averagePlace: averagePlace,
      bestPlace: bestPlace,
      worstPlace: worstPlace,
    );
  }

  /// Validate if career can be started
  bool canStartCareer(Athlete player) {
    return player.name.isNotEmpty && 
           player.surname.isNotEmpty && 
           player.country.isNotEmpty;
  }

  /// Get career completion message
  String getCareerCompletionMessage(Career career) {
    final stats = getCareerStats(career);
    
    if (stats.totalRaces == 0) {
      return 'No races completed yet.';
    }
    
    return 'Career completed! You finished ${stats.totalRaces} races with ${stats.totalPoints} total points.';
  }
}

/// Information about the next race
class NextRaceInfo {
  final Race race;
  final bool isLastRace;
  final Season season;
  final bool isLastSeason;

  const NextRaceInfo({
    required this.race,
    required this.isLastRace,
    required this.season,
    required this.isLastSeason,
  });
}

/// Career progress information
class CareerProgress {
  final int totalSeasons;
  final int currentSeasonIndex;
  final int totalRaces;
  final int completedRaces;
  final double progressPercentage;

  const CareerProgress({
    required this.totalSeasons,
    required this.currentSeasonIndex,
    required this.totalRaces,
    required this.completedRaces,
    required this.progressPercentage,
  });
}

/// Career statistics
class CareerStats {
  final int totalRaces;
  final int totalPoints;
  final double averagePlace;
  final int bestPlace;
  final int worstPlace;

  const CareerStats({
    required this.totalRaces,
    required this.totalPoints,
    required this.averagePlace,
    required this.bestPlace,
    required this.worstPlace,
  });
} 