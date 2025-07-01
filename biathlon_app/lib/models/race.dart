import 'track.dart';

enum Tournament {
  worldCup,
  wc,
  olympics;

  static Tournament fromString(String value) {
    switch (value) {
      case 'worldCup':
        return Tournament.worldCup;
      case 'wc':
        return Tournament.wc;
      case 'olympics':
        return Tournament.olympics;
      default:
        throw Exception('Unknown Tournament: $value');
    }
  }

  String toJson() => toString().split('.').last;
}

class Race {
  final int id;
  final DateTime date;
  final Track track;
  final Tournament tournament;
  final int? stage; // Only for WorldCup, null for WC and Olympics

  Race({
    required this.id,
    required this.date,
    required this.track,
    required this.tournament,
    this.stage,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      tournament: Tournament.fromString(json['tournament'] as String),
      stage: json['stage'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'track': track.toJson(),
        'tournament': tournament.toJson(),
        'stage': stage,
      };
} 