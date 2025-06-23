import 'dart:math';
import 'athlete.dart';
import 'track.dart';
import 'athlete_race_result.dart';
import 'race_simulator.dart';

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
      // If stopped at or before 75%, calculate speed based on progress
      final speed = 0.5 + (progress / 0.75) * 0.5; // Speed from 50% to 100%
      return 8 + 8 / speed / sqrt(playerBaseSpeed); // Base time (16s) divided by speed
    } else {
      // If stopped after 75%, apply 3x penalty for the portion after 75%
      final penaltyProgress = progress - 0.75;
      final speed = 1.0 - (penaltyProgress * 4); // Speed decreases by 3x
      return 8 + 8 / speed / sqrt(playerBaseSpeed);
    }
  }

  static double calculateShootingPenalty(int misses) {
    return misses * 24.0; // 24 seconds per miss
  }
} 