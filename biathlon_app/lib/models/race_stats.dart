import 'dart:math';
import 'athlete.dart';
import 'track.dart';
import 'athlete_race_result.dart';
import 'race_simulator.dart';
import 'track_type.dart';

class RaceStats {
  final List<double> segmentTimes; // Time for each 100m segment
  final List<int> shootingMisses; // Number of misses at each shooting
  final double totalTime; // Total race time in seconds

  RaceStats({
    required this.segmentTimes,
    required this.shootingMisses,
    required this.totalTime,
  });

  String get formattedTotalTime {
    final minutes = (totalTime / 60).floor();
    final seconds = totalTime % 60;
    return '$minutes:${seconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  static double calculateSegmentTime(double progress, double playerBaseSpeed) {
    if (progress <= 0.75) {
      final speed = 0.5 + (progress / 0.75) * 0.5; // Speed from 50% to 100%
      final result = 8 + 8 / speed / sqrt(playerBaseSpeed);
      return result;
    } else {
      final penaltyProgress = progress - 0.75;
      final speed = 1.0 - (penaltyProgress * 3); // Speed decreases by 3x
      final result = 8 + 8 / speed / sqrt(playerBaseSpeed);
      return result;
    }
  }

  static double calculateShootingPenalty(int misses, TrackType type) {
    if (type == TrackType.individual) {
      return misses * 60.0;
    }
    return misses * 24.0;
  }
} 