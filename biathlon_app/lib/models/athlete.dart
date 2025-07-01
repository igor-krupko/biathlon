import 'athlete_season_stats.dart';

class Athlete {
  final int id;
  final String name;
  final String surname;
  final String country;
  final int speed; // 1-100
  final int shootingDown; // 1-100 (prone)
  final int shootingStanding; // 1-100 (standing)
  final int money; // Player's money (default 0 for player)
  final Map<int, AthleteSeasonStats>? seasonStats;

  const Athlete({
    required this.id,
    required this.name,
    required this.surname,
    required this.country,
    required this.speed,
    required this.shootingDown,
    required this.shootingStanding,
    this.money = 0,
    required this.seasonStats,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      country: json['country'] as String,
      speed: json['speed'] as int,
      shootingDown: json['shootingDown'] as int,
      shootingStanding: json['shootingStanding'] as int,
      money: json['money'] as int? ?? 0,
      seasonStats: json['seasonStats'] != null
          ? (json['seasonStats'] as Map<String, dynamic>).map((key, value) =>
              MapEntry(int.parse(key), AthleteSeasonStats.fromJson(value)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        'country': country,
        'speed': speed,
        'shootingDown': shootingDown,
        'shootingStanding': shootingStanding,
        'money': money,
        'seasonStats': seasonStats?.map((key, value) => MapEntry(key.toString(), value.toJson())),
      };
} 