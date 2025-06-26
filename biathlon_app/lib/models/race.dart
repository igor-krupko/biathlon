import 'track.dart';

enum Tournament {
  worldCup,
  wc,
  olympics,
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
} 