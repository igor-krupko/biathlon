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
} 