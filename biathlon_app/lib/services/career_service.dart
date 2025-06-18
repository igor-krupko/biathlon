import '../models/career.dart';
import '../models/athlete.dart';
import '../models/track.dart';

/// Service responsible for career-related business logic
class CareerService {
  /// Check if career is completed
  bool isCareerCompleted(Career career) {
    return !career.hasNextTrack();
  }

  /// Get next track information
  NextTrackInfo? getNextTrackInfo(Career career) {
    if (career.currentTrack == null) return null;
    
    return NextTrackInfo(
      track: career.currentTrack!,
      isLastTrack: !career.hasNextTrack(),
    );
  }

  /// Get career progress information
  CareerProgress getCareerProgress(Career career) {
    final totalTracks = career.tracks.length;
    final completedTracks = career.allRacesResults.length; // Use completed races instead
    final currentTrackIndex = career.currentTrackIndex;
    
    return CareerProgress(
      totalTracks: totalTracks,
      completedTracks: completedTracks,
      currentTrackIndex: currentTrackIndex,
      progressPercentage: totalTracks > 0 ? (completedTracks / totalTracks) * 100.0 : 0.0,
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

    final playerResults = allResults.where((r) => 
      r.athleteName == career.player.name && 
      r.athleteSurname == career.player.surname
    ).toList();

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

/// Information about the next track
class NextTrackInfo {
  final Track track;
  final bool isLastTrack;

  const NextTrackInfo({
    required this.track,
    required this.isLastTrack,
  });
}

/// Career progress information
class CareerProgress {
  final int totalTracks;
  final int completedTracks;
  final int currentTrackIndex;
  final double progressPercentage;

  const CareerProgress({
    required this.totalTracks,
    required this.completedTracks,
    required this.currentTrackIndex,
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