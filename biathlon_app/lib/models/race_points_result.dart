import 'race.dart';
import 'athlete.dart';

class RacePointsResult {
  final Race race;
  final int place;
  final int points;
  final String type;
  final Athlete athlete;

  RacePointsResult({
    required this.race,
    required this.place,
    required this.points,
    required this.type,
    required this.athlete,
  });
} 