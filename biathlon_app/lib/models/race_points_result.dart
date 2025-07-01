import 'race.dart';
import 'athlete.dart';

class RacePointsResult {
  final Race race;
  final int place;
  final int points;
  final String type;
  final Athlete athlete;
  final double time;

  RacePointsResult({
    required this.race,
    required this.place,
    required this.points,
    required this.type,
    required this.athlete,
    required this.time,
  });

  factory RacePointsResult.fromJson(Map<String, dynamic> json) {
    return RacePointsResult(
      race: Race.fromJson(json['race'] as Map<String, dynamic>),
      place: json['place'] as int,
      points: json['points'] as int,
      type: json['type'] as String,
      athlete: Athlete.fromJson(json['athlete'] as Map<String, dynamic>),
      time: (json['time'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'race': race.toJson(),
        'place': place,
        'points': points,
        'type': type,
        'athlete': athlete.toJson(),
        'time': time,
      };
} 