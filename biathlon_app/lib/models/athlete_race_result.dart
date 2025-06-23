import 'athlete.dart';

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