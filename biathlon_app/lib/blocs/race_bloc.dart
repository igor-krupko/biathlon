import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/track.dart';
import '../models/athlete.dart';
import '../models/race_stats.dart';
import '../models/career.dart';
import '../models/athlete_race_result.dart';
import '../models/race_points_result.dart';
import '../services/race_simulation_service.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../models/race.dart';
import '../services/points_service.dart';
import 'package:collection/collection.dart';

// Events
abstract class RaceEvent extends Equatable {
  const RaceEvent();

  @override
  List<Object?> get props => [];
}

class StartRace extends RaceEvent {
  final Race race;
  final Athlete player;
  final List<List<RacePointsResult>>? seasonResults;

  const StartRace(this.race, this.player, this.seasonResults);

  @override
  List<Object?> get props => [race, player, seasonResults];
}

class CompleteSegment extends RaceEvent {
  final double progress;

  const CompleteSegment(this.progress);

  @override
  List<Object?> get props => [progress];
}

class StartShooting extends RaceEvent {
  final int shootingRound;

  const StartShooting(this.shootingRound);

  @override
  List<Object?> get props => [shootingRound];
}

class CompleteShooting extends RaceEvent {
  final int shootingRound;
  final int hits;
  final int totalShots;

  const CompleteShooting(this.shootingRound, this.hits, this.totalShots);

  @override
  List<Object?> get props => [shootingRound, hits, totalShots];
}

class FinishRace extends RaceEvent {}

class ResetRace extends RaceEvent {}

// States
abstract class RaceState extends Equatable {
  const RaceState();

  @override
  List<Object?> get props => [];
}

class RaceInitial extends RaceState {}

class RaceLoading extends RaceState {}

class RaceInProgress extends RaceState {
  final Race race;
  final Athlete player;
  final int? playerStartNumber;
  final int currentLap;
  final int totalLaps;
  final int currentShooting;
  final bool isShooting;
  final List<double> segmentTimes;
  final List<int> shootingMisses;
  final double totalTime;
  final List<AthleteRaceResult> allSimulatedResults;
  final List<AthleteRaceResult> liveLeaderboard;
  final int livePlayerIndex;
  final List<AthleteRaceResult> partialResults;
  final bool showIntermediateTime;
  final double lastIntermediateTime;

  const RaceInProgress({
    required this.race,
    required this.player,
    required this.playerStartNumber,
    required this.currentLap,
    required this.totalLaps,
    required this.currentShooting,
    required this.isShooting,
    required this.segmentTimes,
    required this.shootingMisses,
    required this.totalTime,
    required this.allSimulatedResults,
    required this.liveLeaderboard,
    required this.livePlayerIndex,
    required this.partialResults,
    required this.showIntermediateTime,
    required this.lastIntermediateTime,
  });

  @override
  List<Object?> get props => [
        race,
        player,
        currentLap,
        totalLaps,
        currentShooting,
        isShooting,
        segmentTimes,
        shootingMisses,
        totalTime,
        allSimulatedResults,
        liveLeaderboard,
        livePlayerIndex,
        partialResults,
        showIntermediateTime,
        lastIntermediateTime,
      ];

  RaceInProgress copyWith({
    Race? race,
    Athlete? player,
    int? playerStartNumber,
    int? currentLap,
    int? totalLaps,
    int? currentShooting,
    bool? isShooting,
    List<double>? segmentTimes,
    List<int>? shootingMisses,
    double? totalTime,
    List<AthleteRaceResult>? allSimulatedResults,
    List<AthleteRaceResult>? liveLeaderboard,
    int? livePlayerIndex,
    List<AthleteRaceResult>? partialResults,
    bool? showIntermediateTime,
    double? lastIntermediateTime,
  }) {
    return RaceInProgress(
      race: race ?? this.race,
      player: player ?? this.player,
      playerStartNumber: playerStartNumber ?? this.playerStartNumber,
      currentLap: currentLap ?? this.currentLap,
      totalLaps: totalLaps ?? this.totalLaps,
      currentShooting: currentShooting ?? this.currentShooting,
      isShooting: isShooting ?? this.isShooting,
      segmentTimes: segmentTimes ?? this.segmentTimes,
      shootingMisses: shootingMisses ?? this.shootingMisses,
      totalTime: totalTime ?? this.totalTime,
      allSimulatedResults: allSimulatedResults ?? this.allSimulatedResults,
      liveLeaderboard: liveLeaderboard ?? this.liveLeaderboard,
      livePlayerIndex: livePlayerIndex ?? this.livePlayerIndex,
      partialResults: partialResults ?? this.partialResults,
      showIntermediateTime: showIntermediateTime ?? this.showIntermediateTime,
      lastIntermediateTime: lastIntermediateTime ?? this.lastIntermediateTime,
    );
  }
}

class RaceFinished extends RaceState {
  final Race race;
  final Athlete player;
  final double totalTime;
  final List<double> segmentTimes;
  final List<int> shootingMisses;
  final List<AthleteRaceResult> allResults;
  final int playerPlace;
  final List<RacePointsResult> raceResults;

  const RaceFinished({
    required this.race,
    required this.player,
    required this.totalTime,
    required this.segmentTimes,
    required this.shootingMisses,
    required this.allResults,
    required this.playerPlace,
    required this.raceResults,
  });

  @override
  List<Object?> get props => [
        race,
        player,
        totalTime,
        segmentTimes,
        shootingMisses,
        allResults,
        playerPlace,
        raceResults,
      ];
}

// BLoC
class RaceBloc extends Bloc<RaceEvent, RaceState> {
  final RaceSimulationService _simulationService;
  final AudioService _audioService;
  final SettingsService _settingsService;

  RaceBloc({
    RaceSimulationService? simulationService,
    AudioService? audioService,
    SettingsService? settingsService,
  }) : _simulationService = simulationService ?? RaceSimulationService(),
       _audioService = audioService ?? AudioService(),
       _settingsService = settingsService ?? SettingsService(),
       super(RaceInitial()) {
    on<StartRace>(_onStartRace);
    on<CompleteSegment>(_onCompleteSegment);
    on<StartShooting>(_onStartShooting);
    on<CompleteShooting>(_onCompleteShooting);
    on<FinishRace>(_onFinishRace);
    on<ResetRace>(_onResetRace);
  }

  void _onStartRace(StartRace event, Emitter<RaceState> emit) async {
    emit(RaceLoading());
    
    // Initialize services
    await _settingsService.initialize();
    await _audioService.initialize();
    
    // Build athleteIdToStartNumber map
    Map<int, int>? athleteIdToStartNumber;
    final competitors = _simulationService.generateCompetitors(event.race.date.year);
    final allAthletes = List<Athlete>.from(competitors);
    if (!allAthletes.any((a) => a.id == event.player.id)) {
      allAthletes.add(event.player);
    }
    // Use event.seasonResults to aggregate points for the current year
    if (event.seasonResults != null && event.seasonResults!.isNotEmpty) {
      // Flatten all results into a single list
      final allResults = event.seasonResults!.expand((x) => x).toList();
      // Only include results from the current year
      final year = event.race.date.year;
      final yearResults = allResults.where((r) => r.race.date.year == year).toList();
      // Aggregate points by athlete id
      final Map<int, int> athletePoints = {};
      for (final r in yearResults) {
        athletePoints[r.athlete.id] = (athletePoints[r.athlete.id] ?? 0) + r.points;
      }
      // Sort allAthletes by points descending, then by name as fallback
      allAthletes.sort((a, b) {
        final pB = athletePoints[b.id] ?? 0;
        final pA = athletePoints[a.id] ?? 0;
        if (pB != pA) return pB.compareTo(pA);
        return (a.surname + a.name).compareTo(b.surname + b.name);
      });
      athleteIdToStartNumber = { for (int i = 0; i < allAthletes.length; i++) allAthletes[i].id: i + 1 };
      print('athleteIdToStartNumber (by points):');
      athleteIdToStartNumber.forEach((id, num) {
        print('  id=\x1B[32m$id\x1B[0m => startNumber=$num');
      });
    } else {
      // Assign randomly
      allAthletes.shuffle();
      athleteIdToStartNumber = { for (int i = 0; i < allAthletes.length; i++) allAthletes[i].id: i + 1 };
      print('athleteIdToStartNumber (random):');
      athleteIdToStartNumber.forEach((id, num) {
        print('  id=\x1B[32m$id\x1B[0m => startNumber=$num');
      });
    }
    // Simulate competitors using the service
    final allSimulatedResults = await _simulationService.simulateCompetitors(event.race.track, event.race.date.year, athleteIdToStartNumber);

    emit(RaceInProgress(
      race: event.race,
      player: event.player,
      playerStartNumber: athleteIdToStartNumber?[event.player.id],
      currentLap: 0,
      totalLaps: event.race.track.laps,
      currentShooting: 0,
      isShooting: false,
      segmentTimes: [],
      shootingMisses: [],
      totalTime: 0.0,
      allSimulatedResults: allSimulatedResults,
      liveLeaderboard: [],
      livePlayerIndex: 0,
      partialResults: [],
      showIntermediateTime: false,
      lastIntermediateTime: 0.0,
    ));
  }

  void _onCompleteSegment(CompleteSegment event, Emitter<RaceState> emit) {
    if (state is RaceInProgress) {
      final currentState = state as RaceInProgress;
      final segmentsInLap = (currentState.race.track.lapDistance / 100).ceil();
      final segmentsCompletedInLap = currentState.segmentTimes.length % segmentsInLap;
      
      if (segmentsCompletedInLap < segmentsInLap) {
        final segmentTime = RaceStats.calculateSegmentTime(event.progress, currentState.player.speed / 100.0);
        final newSegmentTimes = List<double>.from(currentState.segmentTimes)..add(segmentTime);
        final newTotalTime = currentState.totalTime + segmentTime;
        
        final updatedState = currentState.copyWith(
          segmentTimes: newSegmentTimes,
          totalTime: newTotalTime,
        );
        
        final updatedStateWithLeaderboard = _simulationService.updateLiveLeaderboard(updatedState);
        emit(updatedStateWithLeaderboard);
        
        // Check if lap is complete
        if ((newSegmentTimes.length % segmentsInLap) == 0) {
          _completeLap(updatedStateWithLeaderboard, emit);
        }
      }
    }
  }

  void _onStartShooting(StartShooting event, Emitter<RaceState> emit) {
    if (state is RaceInProgress) {
      final currentState = state as RaceInProgress;
      emit(currentState.copyWith(
        isShooting: true,
        currentShooting: event.shootingRound,
      ));
    }
  }

  void _onCompleteShooting(CompleteShooting event, Emitter<RaceState> emit) async {
    if (state is RaceInProgress) {
      final currentState = state as RaceInProgress;
      final misses = event.totalShots - event.hits;
      final penalty = RaceStats.calculateShootingPenalty(misses);
      
      final newShootingMisses = List<int>.from(currentState.shootingMisses)..add(misses);
      final newTotalTime = currentState.totalTime + penalty;
      
      final updatedState = currentState.copyWith(
        isShooting: false,
        shootingMisses: newShootingMisses,
        totalTime: newTotalTime,
        showIntermediateTime: true,
        lastIntermediateTime: newTotalTime,
      );
      
      final updatedStateWithLeaderboard = _simulationService.updateLiveLeaderboard(updatedState);
      emit(updatedStateWithLeaderboard);
      
      // Hide intermediate time after delay
      await Future.delayed(const Duration(seconds: 2));
      if (state is RaceInProgress && !emit.isDone) {
        final currentState = state as RaceInProgress;
        emit(currentState.copyWith(showIntermediateTime: false));
      }
    }
  }

  void _onFinishRace(FinishRace event, Emitter<RaceState> emit) {
    if (state is RaceInProgress) {
      final currentState = state as RaceInProgress;
      
      // Calculate final results using the service
      final raceResults = _simulationService.calculateFinalResults(currentState, currentState.race);
      
      emit(RaceFinished(
        race: currentState.race,
        player: currentState.player,
        totalTime: currentState.totalTime,
        segmentTimes: currentState.segmentTimes,
        shootingMisses: currentState.shootingMisses,
        allResults: raceResults.allResults,
        playerPlace: raceResults.playerPlace,
        raceResults: raceResults.pointsResults,
      ));
    }
  }

  void _onResetRace(ResetRace event, Emitter<RaceState> emit) {
    emit(RaceInitial());
  }

  void _completeLap(RaceInProgress currentState, Emitter<RaceState> emit) {
    if (currentState.currentLap < currentState.totalLaps - 1) {
      // Calculate which shooting round this is
      final shootingRound = currentState.currentLap;
      
      emit(currentState.copyWith(
        currentLap: currentState.currentLap + 1,
        isShooting: true,
        currentShooting: shootingRound,
      ));
    } else {
      // Race is complete
      add(FinishRace());
    }
  }
} 