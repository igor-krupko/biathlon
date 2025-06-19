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
              Text(
                'Your Place: ${state.playerPlace}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Total Time: ${RaceUtils.formatTime(state.totalTime)}'),
              const SizedBox(height: 8),
              Text('Total Misses: ${state.shootingMisses.fold(0, (sum, misses) => sum + misses)}'),
              const SizedBox(height: 16),
              PodiumWidget(results: state.allResults),
              const SizedBox(height: 24),
              _buildResultsTable(dialogContext, state.allResults),
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
      final showTime = RaceUtils.formatTime(entry.value.totalTime);
      final showDiff = entry.key == 0 ? '' : '+${RaceUtils.formatTimeDiff(diff)}';
      final totalMisses = entry.value.shootingMisses.fold(0, (a, b) => a + b);
      final flag = RaceUtils.countryToFlag(entry.value.athlete.country);
      // Get points based on place (example logic, adjust as needed)
      final points = entry.key < 40 
          ? (entry.key < 30 ? usualRacePoints[entry.key] : 0)
          : 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Text('${entry.key + 1}. ', style: const TextStyle(fontSize: 14)),
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${entry.value.athlete.name} ${entry.value.athlete.surname}',
                style: TextStyle(
                  fontWeight: entry.key == playerIndex ? FontWeight.bold : FontWeight.normal,
                  color: entry.key == playerIndex ? Colors.blue : DefaultTextStyle.of(context).style.color,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(showTime, style: const TextStyle(fontSize: 13)),
            if (showDiff.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(showDiff, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(width: 8),
            Text('Misses: $totalMisses', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            Text('$points pts', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ],
        ),
      );
    }).toList();
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

class PodiumWidget extends StatelessWidget {
  final List<AthleteRaceResult> results;
  const PodiumWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final sorted = [...results];
    sorted.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final podium = sorted.take(3).toList();
    final leaderTime = podium.isNotEmpty ? podium.first.totalTime : 0.0;
    // If less than 3, fill with dummy placeholders
    while (podium.length < 3) {
      podium.add(_dummyAthleteRaceResult());
    }
    // 2nd, 1st, 3rd (stairs effect)
    return SizedBox(
      height: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumStep(
            place: 2,
            result: podium[1],
            height: 60,
            color: Colors.grey[400]!,
            isPlaceholder: results.length < 2,
            leaderTime: leaderTime,
            points: 1 < 40 ? (1 < 30 ? usualRacePoints[1] : 0) : 0,
          ),
          _PodiumStep(
            place: 1,
            result: podium[0],
            height: 90,
            color: Colors.amber[400]!,
            isPlaceholder: results.isEmpty,
            leaderTime: leaderTime,
            points: 0 < 40 ? (0 < 30 ? usualRacePoints[0] : 0) : 0,
          ),
          _PodiumStep(
            place: 3,
            result: podium[2],
            height: 40,
            color: Colors.brown[300]!,
            isPlaceholder: results.length < 3,
            leaderTime: leaderTime,
            points: 2 < 40 ? (2 < 30 ? usualRacePoints[2] : 0) : 0,
          ),
        ],
      ),
    );
  }

  // Returns a dummy AthleteRaceResult for placeholder
  AthleteRaceResult _dummyAthleteRaceResult() {
    return AthleteRaceResult(
      athlete: const Athlete(
        name: '-',
        surname: '',
        country: '',
        speed: 0,
        shootingDown: 0,
        shootingStanding: 0,
      ),
      segmentTimes: const [],
      shootingMisses: const [],
      cumulativeTimes: const [],
      totalTime: 0,
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final int place;
  final AthleteRaceResult result;
  final double height;
  final Color color;
  final bool isPlaceholder;
  final double leaderTime;
  final int points;
  const _PodiumStep({required this.place, required this.result, required this.height, required this.color, this.isPlaceholder = false, required this.leaderTime, required this.points});

  @override
  Widget build(BuildContext context) {
    final showTime = RaceUtils.formatTime(result.totalTime);
    final diff = result.totalTime - leaderTime;
    final showDiff = place == 1 ? '' : '+${RaceUtils.formatTimeDiff(diff)}';
    final totalMisses = result.shootingMisses.fold(0, (a, b) => a + b);
    return SizedBox(
      width: 110,
      height: 250, // Fixed height for the whole podium step
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Step box at the bottom
          Positioned(
            bottom: 0,
            child: Container(
              width: 100,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                '$place',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          // Flag, name, and stats above the step
          Positioned(
            bottom: height + 4, // 4px gap above the step
            left: 0,
            right: 0,
            child: (!isPlaceholder && result.athlete.name != '-')
                ? SizedBox(
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          RaceUtils.countryToFlag(result.athlete.country),
                          style: const TextStyle(fontSize: 22),
                        ),
                        Text(
                          '${result.athlete.name} ${result.athlete.surname}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 2),
                        Text(showTime, style: const TextStyle(fontSize: 13)),
                        if (showDiff.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(showDiff, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                        const SizedBox(height: 2),
                        Text('Misses: ${totalMisses.toString()}', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('$points pts', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ],
                    ),
                  )
                : Column(
                    children: const [
                      SizedBox(height: 24),
                      Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _buildResultsTable(BuildContext context, List<AthleteRaceResult> allResults) {
  final sorted = [...allResults];
  sorted.sort((a, b) => a.totalTime.compareTo(b.totalTime));
  final rest = sorted.length > 3 ? sorted.sublist(3) : [];
  final leaderTime = sorted.isNotEmpty ? sorted.first.totalTime : 0.0;
  if (rest.isEmpty) {
    return const Text('No other results.');
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: rest.asMap().entries.map((entry) {
      final idx = entry.key + 4;
      final r = entry.value;
      final flag = RaceUtils.countryToFlag(r.athlete.country);
      final totalMisses = r.shootingMisses.fold(0, (a, b) => a + b);
      final showTime = RaceUtils.formatTime(r.totalTime);
      final diff = r.totalTime - leaderTime;
      final showDiff = idx == 1 ? '' : '+${RaceUtils.formatTimeDiff(diff)}';
      final points = (idx - 1) < 40 ? ((idx - 1) < 30 ? usualRacePoints[idx - 1] : 0) : 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Text('$idx. ', style: const TextStyle(fontSize: 14)),
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${r.athlete.name} ${r.athlete.surname}',
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDiff.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(showDiff, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(width: 8),
            Text('Misses: $totalMisses', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            Text('$points pts', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ],
        ),
      );
    }).toList(),
  );
}