import './race.dart';

class Season {
  final int id;
  final int year;
  final String name;
  final List<Race> races;

  Season({
    required this.id,
    required this.year,
    required this.name,
    required this.races,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int,
      year: json['year'] as int,
      name: json['name'] as String,
      races: (json['races'] as List<dynamic>)
          .map((e) => Race.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'name': name,
        'races': races.map((e) => e.toJson()).toList(),
      };
} 