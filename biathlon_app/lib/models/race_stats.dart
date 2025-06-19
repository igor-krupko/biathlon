import 'dart:math';
import 'athlete.dart';
import 'track.dart';

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

  static double calculateSegmentTime(double progress) {
    if (progress <= 0.75) {
      // If stopped at or before 75%, calculate speed based on progress
      final speed = 0.5 + (progress / 0.75) * 0.5; // Speed from 50% to 100%
      return 16 / speed; // Base time (16s) divided by speed
    } else {
      // If stopped after 75%, apply 3x penalty for the portion after 75%
      final penaltyProgress = progress - 0.75;
      final speed = 1.0 - (penaltyProgress * 4); // Speed decreases by 3x
      return 16 / speed;
    }
  }

  static double calculateShootingPenalty(int misses) {
    return misses * 24.0; // 24 seconds per miss
  }
}

class AthleteRaceResult {
  final Athlete athlete;
  final List<double> segmentTimes;
  final List<int> shootingMisses;
  final List<double> cumulativeTimes; // after each segment
  final double totalTime;

  AthleteRaceResult({
    required this.athlete,
    required this.segmentTimes,
    required this.shootingMisses,
    required this.cumulativeTimes,
    required this.totalTime,
  });
}

class RaceSimulator {
  static AthleteRaceResult simulate({
    required Athlete athlete,
    required Track track,
    required Random random,
  }) {
    final List<double> segmentTimes = [];
    final List<int> shootingMisses = [];
    final List<double> cumulativeTimes = [];
    double totalTime = 0;
    int shootingIndex = 0;
    int segmentCount = (track.lapDistance / 100).ceil() * track.laps;
    int segmentsPerLap = (track.lapDistance / 100).ceil();

    for (int lap = 0; lap < track.laps; lap++) {
      for (int seg = 0; seg < segmentsPerLap; seg++) {
        // Simulate speed: base 16s, scale by athlete speed (80-100 -> 0.8-1.0x), add randomness
        double base = 8.0;
        double speedFactor = (athlete.speed + random.nextInt(21) - 12) / 100.0; // ±3 randomness
        speedFactor = sqrt(speedFactor.clamp(0.5, 1.1));
        double time = base + 8.0 / speedFactor;
        // Add a little more randomness
        time += random.nextDouble() * 2 - 1; // ±1s
        time = time.clamp(12.0, 32.0);
        segmentTimes.add(time);
        totalTime += time;
        cumulativeTimes.add(totalTime);
      }
      // Shooting after each lap except last
      if (shootingIndex < track.shootingPositions.length) {
        final pos = track.shootingPositions[shootingIndex];
        int shootingSkill = pos == ShootingPosition.down ? athlete.shootingDown : athlete.shootingStanding;
        int misses = 0;
        for (int shot = 0; shot < 5; shot++) {
          // Each shot: chance to hit = shootingSkill% ± randomness
          int skill = shootingSkill + random.nextInt(13) - 7; // ±5 randomness
          skill = skill.clamp(50, 100);
          if (random.nextInt(100) >= skill) {
            misses++;
          }
        }
        shootingMisses.add(misses);
        double penalty = RaceStats.calculateShootingPenalty(misses);
        totalTime += penalty;
        cumulativeTimes.add(totalTime); // after shooting
        shootingIndex++;
      }
    }
    return AthleteRaceResult(
      athlete: athlete,
      segmentTimes: segmentTimes,
      shootingMisses: shootingMisses,
      cumulativeTimes: cumulativeTimes,
      totalTime: totalTime,
    );
  }
} 