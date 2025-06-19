import 'track.dart';
import '../data/predefined_tracks.dart';
import 'dart:math';
import 'athlete.dart';

class RacePointsResult {
  final Track track;
  final int place;
  final int points;
  final String type;
  final String athleteName;
  final String athleteSurname;
  final String athleteCountry;
  RacePointsResult({
    required this.track,
    required this.place,
    required this.points,
    required this.type,
    required this.athleteName,
    required this.athleteSurname,
    required this.athleteCountry,
  });
}

class Career {
  final DateTime startDate;
  bool isActive;
  final List<Track> tracks;
  int currentTrackIndex;
  final List<RacePointsResult> racePointsHistory = [];
  final List<List<RacePointsResult>> allRacesResults = [];
  Athlete player;

  Career({
    required this.startDate,
    required this.player,
    this.isActive = true,
    List<Track>? tracks,
    this.currentTrackIndex = 0,
  }) : tracks = tracks ?? _generateTracks();

  static List<Track> _generateTracks() {
    final random = Random();
    final List<Track> selectedTracks = [];
    final List<Track> availableTracks = List.from(predefinedTracks);
    
    // Shuffle the available tracks
    availableTracks.shuffle(random);
    
    // Select 20 tracks
    for (int i = 0; i < 20 && i < availableTracks.length; i++) {
      selectedTracks.add(availableTracks[i]);
    }
    
    return selectedTracks;
  }

  void stopCareer() {
    isActive = false;
  }

  void continueCareer() {
    isActive = true;
  }

  Track? get currentTrack => tracks.isNotEmpty ? tracks[currentTrackIndex] : null;

  bool moveToNextTrack() {
    if (currentTrackIndex < tracks.length - 1) {
      currentTrackIndex++;
      return true;
    }
    return false;
  }

  bool moveToPreviousTrack() {
    if (currentTrackIndex > 0) {
      currentTrackIndex--;
      return true;
    }
    return false;
  }

  bool hasNextTrack() {
    return currentTrackIndex < tracks.length - 1;
  }

  void addRacePointsResult(RacePointsResult result) {
    racePointsHistory.add(result);
  }

  void addFullRaceResults(List<RacePointsResult> results) {
    allRacesResults.add(results);
  }

  int get playerMoney => player.money;

  void addMoneyToPlayer(int amount) {
    // Create a new Athlete with updated money
    final updatedPlayer = Athlete(
      name: player.name,
      surname: player.surname,
      country: player.country,
      speed: player.speed,
      shootingDown: player.shootingDown,
      shootingStanding: player.shootingStanding,
      money: player.money + amount,
    );
    // This is a workaround since player is final; in a real app, refactor to allow updating player
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    // ignore: prefer_final_fields
    player = updatedPlayer;
  }
} 