import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/track.dart';
import '../models/career.dart';
import '../models/race_stats.dart';
import '../models/athlete.dart';
import '../widgets/shooting_targets.dart';
import '../widgets/lap_progress.dart';
import '../blocs/career_bloc.dart';
import '../blocs/race_bloc.dart';
import '../blocs/shooting_bloc.dart' as shooting;
import '../blocs/lap_progress_bloc.dart' as lap_progress;
import '../blocs/audio_bloc.dart';
import '../utils/race_utils.dart';
import '../data/biathlon_points.dart';

class RaceScreen extends StatefulWidget {
  final Track track;
  final Career career;

  const RaceScreen({
    super.key,
    required this.track,
    required this.career,
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    // Start background ambience if enabled
    context.read<AudioBloc>().add(PlayBackgroundAmbience());
  }

  @override
  void dispose() {
    context.read<AudioBloc>().add(StopBackgroundAmbience());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RaceBloc()..add(StartRace(widget.track, widget.career.player)),
      child: BlocListener<RaceBloc, RaceState>(
        listener: (context, state) {
          if (state is RaceFinished) {
            _handleRaceFinished(context, state);
          }
        },
        child: BlocBuilder<RaceBloc, RaceState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Text("${widget.track.name} (${widget.track.country}), ${widget.track.type.toString()} - ${widget.track.totalDistance / 1000} km"),
              ),
              body: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RaceState state) {
    if (state is RaceInitial || state is RaceLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is RaceInProgress) {
      return _buildRaceInProgress(context, state);
    } else if (state is RaceFinished) {
      return _buildRaceFinished(context, state);
    } else {
      return const Center(child: Text('Unknown state'));
    }
  }

  Widget _buildRaceInProgress(BuildContext context, RaceInProgress state) {
    return Stack(
      children: [
        Center(
          child: state.isShooting
              ? ShootingView(
                  position: state.track.shootingPositions[state.currentShooting],
                  onComplete: (hits) {
                    context.read<RaceBloc>().add(
                      CompleteShooting(
                        state.currentShooting,
                        hits.where((hit) => hit).length,
                        hits.length,
                      ),
                    );
                  },
                )
              : LapView(
                  lapNumber: state.currentLap + 1,
                  totalLaps: state.totalLaps,
                  lapDistance: state.track.lapDistance,
                  onSegmentComplete: (progress) {
                    context.read<RaceBloc>().add(CompleteSegment(progress));
                  },
                ),
        ),
        // Cumulative time display
        Positioned(
          top: 16,
          right: 16,
          child: _buildTimeDisplay(state),
        ),
        // Live leaderboard overlay
        if (state.segmentTimes.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: _buildLiveLeaderboard(context, state),
          ),
      ],
    );
  }

  Widget _buildTimeDisplay(RaceInProgress state) {
    final playerIdx = state.partialResults.indexWhere((r) => r.athlete.name == state.player.name);
    final player = playerIdx != -1 ? state.partialResults[playerIdx] : null;
    final leaderTime = state.partialResults.isNotEmpty ? state.partialResults.first.totalTime : 0.0;
    final playerTime = player?.totalTime ?? 0.0;
    final diff = playerTime - leaderTime;
    final place = playerIdx != -1 ? playerIdx + 1 : '-';
    final diffStr = diff <= 0 
        ? (player != null ? RaceUtils.formatTime(player.totalTime) : '0:00') 
        : RaceUtils.formatTimeDiff(diff);
    final playerName = player != null 
        ? '${player.athlete.name}${player.athlete.surname.isNotEmpty ? ' ${player.athlete.surname}' : ''}' 
        : '';
    final flag = player != null ? RaceUtils.countryToFlag(player.athlete.country) : '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '№ $place   $flag $playerName   ${diff <= 0 ? diffStr : "+$diffStr"}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLiveLeaderboard(BuildContext context, RaceInProgress state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 10 After This Segment:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...List.generate(state.liveLeaderboard.length, (i) {
            final leaderTime = state.liveLeaderboard.first.totalTime;
            final diff = state.liveLeaderboard[i].totalTime - leaderTime;
            final showTime = i == 0
                ? RaceUtils.formatTime(state.liveLeaderboard[i].totalTime)
                : '+${RaceUtils.formatTimeDiff(diff)}';
            final totalMisses = state.liveLeaderboard[i].shootingMisses.fold(0, (a, b) => a + b);
            final flag = RaceUtils.countryToFlag(state.liveLeaderboard[i].athlete.country);
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${i + 1}. ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
                  RaceUtils.buildFlagNameSpan(flag, state.liveLeaderboard[i].athlete.name, state.liveLeaderboard[i].athlete.surname),
                  TextSpan(text: ' $showTime (${totalMisses} misses)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
                ],
                style: TextStyle(
                  fontWeight: i == state.livePlayerIndex ? FontWeight.bold : FontWeight.normal,
                  color: i == state.livePlayerIndex ? Colors.blue : DefaultTextStyle.of(context).style.color,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRaceFinished(BuildContext context, RaceFinished state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Race Finished!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Place: ${state.playerPlace}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Total Time: ${RaceUtils.formatTime(state.totalTime)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/career-details'),
            child: const Text('Return to Career'),
          ),
        ],
      ),
    );
  }

  void _handleRaceFinished(BuildContext context, RaceFinished state) {
    // Add race results to career
    context.read<CareerBloc>().add(AddRaceResult(state.raceResults.firstWhere(
      (result) => result.athleteName == state.player.name,
    )));
    context.read<CareerBloc>().add(AddFullRaceResults(state.raceResults));
    
    // Move to next track
    context.read<CareerBloc>().add(MoveToNextTrack());
    
    // Show results dialog
    _showResultsDialog(context, state);
  }

  void _showResultsDialog(BuildContext context, RaceFinished state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Race Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Time: ${RaceUtils.formatTime(state.totalTime)}'),
              const SizedBox(height: 8),
              Text('Total Misses: ${state.shootingMisses.fold(0, (sum, misses) => sum + misses)}'),
              const SizedBox(height: 16),
              const Text('Leaderboard:'),
              ..._buildFinalLeaderboard(dialogContext, state.allResults, state.player),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/career-details');
            },
            child: const Text('Return to Career'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFinalLeaderboard(BuildContext context, List<AthleteRaceResult> allResults, Athlete player) {
    final allResultsSorted = [...allResults];
    allResultsSorted.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final leaderTime = allResultsSorted.first.totalTime;
    final playerIndex = allResultsSorted.indexWhere((r) => r.athlete.name == player.name);
    
    return allResultsSorted.asMap().entries.map((entry) {
      final diff = entry.value.totalTime - leaderTime;
      final showTime = entry.key == 0
          ? RaceUtils.formatTime(entry.value.totalTime)
          : '+${RaceUtils.formatTimeDiff(diff)}';
      final totalMisses = entry.value.shootingMisses.fold(0, (a, b) => a + b);
      final flag = RaceUtils.countryToFlag(entry.value.athlete.country);
      
      // Get points based on track type
      final points = entry.key < 40 
          ? (entry.key < 30 ? usualRacePoints[entry.key] : 0)
          : 0;
      
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '${entry.key + 1}. ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
            RaceUtils.buildFlagNameSpan(flag, entry.value.athlete.name, entry.value.athlete.surname),
            TextSpan(text: ' $showTime (${totalMisses} misses)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
            TextSpan(text: '   $points pts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ],
          style: TextStyle(
            fontWeight: entry.key == playerIndex ? FontWeight.bold : FontWeight.normal,
            color: entry.key == playerIndex ? Colors.blue : DefaultTextStyle.of(context).style.color,
            fontSize: 14,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCumulativeTimesTable(BuildContext context, List<AthleteRaceResult> allResults, Athlete player) {
    final shown = [...allResults];
    final maxSplits = shown.map((r) => r.cumulativeTimes.length).fold(0, (a, b) => a > b ? a : b);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Athlete')),
          ...List.generate(maxSplits, (i) => DataColumn(label: Text('S${i + 1}'))),
        ],
        rows: shown.map((r) {
          final flag = RaceUtils.countryToFlag(r.athlete.country);
          return DataRow(
            cells: [
              DataCell(RichText(
                text: RaceUtils.buildFlagNameSpan(flag, r.athlete.name, r.athlete.surname),
              )),
              ...List.generate(maxSplits, (i) => DataCell(
                i < r.cumulativeTimes.length
                    ? Text(RaceUtils.formatTime(r.cumulativeTimes[i]))
                    : const Text('-'),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class LapView extends StatelessWidget {
  final int lapNumber;
  final int totalLaps;
  final double lapDistance;
  final Function(double) onSegmentComplete;

  const LapView({
    super.key,
    required this.lapNumber,
    required this.totalLaps,
    required this.lapDistance,
    required this.onSegmentComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lap $lapNumber of $totalLaps',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        LapProgress(
          lapDistance: lapDistance,
          onSegmentComplete: onSegmentComplete,
        ),
      ],
    );
  }
}

class ShootingView extends StatelessWidget {
  final ShootingPosition position;
  final void Function(List<bool>) onComplete;

  const ShootingView({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Shooting ${position.name}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ShootingTargets(
            position: position,
            onComplete: onComplete,
          ),
        ),
      ],
    );
  }
} 