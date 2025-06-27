import 'dart:math';
import '../models/track.dart';
import '../models/athlete.dart';
import '../models/race_stats.dart';
import '../models/career.dart';
import '../data/predefined_athletes.dart';
import '../data/biathlon_points.dart';
import '../blocs/race_bloc.dart';
import '../models/athlete_race_result.dart';
import '../models/race_simulator.dart';
import '../models/race_points_result.dart';
import '../models/race.dart';

class RaceSimulationService {
  final Random _random = Random();

  /// Simulates all competitors for a given track and year
  Future<List<AthleteRaceResult>> simulateCompetitors(Track track, int year, Map<int, int>? athleteIdToStartNumber) async {
    final competitors = generateCompetitors(year);
    return competitors.map((a) {
      final result = RaceSimulator.simulate(
        athlete: a,
        year: year,
        track: track,
        random: Random(_random.nextInt(100000)),
      );
      final startNumber = athleteIdToStartNumber != null ? athleteIdToStartNumber[a.id] : null;
      return AthleteRaceResult(
        athlete: result.athlete,
        segmentTimes: result.segmentTimes,
        shootingMisses: result.shootingMisses,
        cumulativeTimes: result.cumulativeTimes,
        totalTime: result.totalTime,
        startNumber: startNumber,
      );
    }).toList();
  }

  /// Updates the live leaderboard based on current race progress
  RaceInProgress updateLiveLeaderboard(RaceInProgress currentState) {
    final playerAthlete = currentState.player;
    final currentSegment = currentState.segmentTimes.length;
    
    // Build partial results for all athletes
    final partialResults = currentState.allSimulatedResults.map((full) {
      final segTimes = full.segmentTimes.take(currentSegment).toList();
      final cumTimes = <double>[];
      double sum = 0;
      for (final t in segTimes) {
        sum += t;
        cumTimes.add(sum);
      }
      
      // Add shooting penalties
      final shootingMisses = <int>[];
      int segsPerLap = (currentState.race.track.lapDistance / 100).ceil();
      int segDone = 0;
      int shootingIdx = 0;
      for (int lap = 0; lap < currentState.race.track.laps; lap++) {
        for (int s = 0; s < segsPerLap; s++) {
          if (++segDone >= currentSegment) break;
        }
        if (segDone >= currentSegment) break;
        if (shootingIdx < full.shootingMisses.length) {
          shootingMisses.add(full.shootingMisses[shootingIdx++]);
          sum += RaceStats.calculateShootingPenalty(shootingMisses.last);
          cumTimes.add(sum);
        }
      }
      // If the player has just finished shooting but hasn't started the next segment,
      // add the next penalty for the simulated athlete as well.
      if (currentState.shootingMisses.length > shootingMisses.length &&
          shootingIdx < full.shootingMisses.length) {
        shootingMisses.add(full.shootingMisses[shootingIdx++]);
        sum += RaceStats.calculateShootingPenalty(shootingMisses.last);
        cumTimes.add(sum);
      }
      
      return AthleteRaceResult(
        athlete: full.athlete,
        segmentTimes: segTimes,
        shootingMisses: shootingMisses,
        cumulativeTimes: cumTimes,
        startNumber: full.startNumber,
        totalTime: cumTimes.isNotEmpty ? cumTimes.last : 0,
      );
    }).toList();
    
    final playerResult = AthleteRaceResult(
      athlete: playerAthlete,
      segmentTimes: List<double>.from(currentState.segmentTimes),
      shootingMisses: List<int>.from(currentState.shootingMisses),
      cumulativeTimes: _buildPlayerCumulativeTimes(currentState),
      totalTime: currentState.totalTime,
      startNumber: currentState.playerStartNumber,
    );
    partialResults.add(playerResult);
    partialResults.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    
    final playerIndex = partialResults.indexWhere((r) => r.athlete.name == playerAthlete.name);
    
    return currentState.copyWith(
      partialResults: partialResults,
      liveLeaderboard: partialResults.take(10).toList(),
      livePlayerIndex: playerIndex,
    );
  }

  /// Calculates final race results
  FinalRaceResults calculateFinalResults(RaceInProgress currentState, Race race) {
    // Add player result to all results
    final playerResult = AthleteRaceResult(
      athlete: currentState.player,
      segmentTimes: List<double>.from(currentState.segmentTimes),
      shootingMisses: List<int>.from(currentState.shootingMisses),
      cumulativeTimes: _buildPlayerCumulativeTimes(currentState),
      totalTime: currentState.totalTime,
    );
    
    final allResults = List<AthleteRaceResult>.from(currentState.allSimulatedResults)..add(playerResult);
    allResults.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    
    final playerIndex = allResults.indexWhere((r) => r.athlete.name == currentState.player.name);
    final playerPlace = playerIndex + 1;
    
    // Calculate race results
    final pointsResults = _calculateRaceResults(race, allResults);
    
    return FinalRaceResults(
      allResults: allResults,
      playerPlace: playerPlace,
      pointsResults: pointsResults,
    );
  }

  List<Athlete> generateCompetitors(int year) {
    final competitors = predefinedAthletes.where((athlete) {
      final stats = athlete.seasonStats;
      if (stats == null) return false;
      final season = stats[year];
      return season != null && season.isActive;
    }).toList();
    competitors.shuffle(_random);
    return competitors;
  }

  List<double> _buildPlayerCumulativeTimes(RaceInProgress state) {
    List<double> result = [];
    double sum = 0;
    int seg = 0;
    int shoot = 0;
    final segmentsInLap = (state.race.track.lapDistance / 100).ceil();
    
    for (int lap = 0; lap < state.race.track.laps; lap++) {
      for (int s = 0; s < segmentsInLap; s++) {
        if (seg < state.segmentTimes.length) {
          sum += state.segmentTimes[seg++];
          result.add(sum);
        }
      }
      if (shoot < state.shootingMisses.length) {
        sum += RaceStats.calculateShootingPenalty(state.shootingMisses[shoot++]);
        result.add(sum);
      }
    }
    return result;
  }

  List<RacePointsResult> _calculateRaceResults(Race race, List<AthleteRaceResult> allResults) {
    final isMass = race.track.type.toString().contains('mass');
    final pointsTable = isMass ? massStartPoints : usualRacePoints;
    
    return allResults.asMap().entries.map((entry) {
      final athlete = entry.value.athlete;
      final place = entry.key + 1;
      final points = entry.key < pointsTable.length ? pointsTable[entry.key] : 0;
      
      return RacePointsResult(
        race: race,
        place: place,
        points: points,
        type: race.track.type.toString().split('.').last,
        athlete: athlete,
      );
    }).toList();
  }
}

/// Data class for final race results
class FinalRaceResults {
  final List<AthleteRaceResult> allResults;
  final int playerPlace;
  final List<RacePointsResult> pointsResults;

  FinalRaceResults({
    required this.allResults,
    required this.playerPlace,
    required this.pointsResults,
  });
} 