import 'package:flutter/material.dart';
import '../models/track.dart';
import '../models/career.dart';
import '../models/race_stats.dart';
import '../models/athlete.dart';
import '../data/predefined_athletes.dart';
import '../widgets/shooting_targets.dart';
import '../widgets/lap_progress.dart';
import 'dart:math';
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
  int currentLap = 0;
  int currentShooting = 0;
  bool isShooting = false;
  List<List<bool>> shootingResults = [];
  List<double> segmentTimes = [];
  List<int> shootingMisses = [];
  double totalTime = 0;
  int segmentsCompletedInLap = 0;
  List<AthleteRaceResult> allSimulatedResults = [];
  List<AthleteRaceResult> liveLeaderboard = [];
  int livePlayerIndex = 0;
  int lastSimulatedSegment = 0;
  // Store the full partial results for the current segment
  List<AthleteRaceResult> partialResults = [];
  // Intermediate time overlay
  bool showIntermediateTime = false;
  double lastIntermediateTime = 0;

  @override
  void initState() {
    super.initState();
    print('RaceScreen initialized for track: [38;5;2m${widget.track.name}[0m');
    shootingResults = List.generate(
      widget.track.shootingPositions.length,
      (_) => List.filled(5, false),
    );
    _simulateAllAthletesOnce();
  }

  void _simulateAllAthletesOnce() {
    final playerAthlete = widget.career.player;
    final random = Random();
    allSimulatedResults = [
      ...predefinedAthletes.map((a) => RaceSimulator.simulate(
            athlete: a,
            track: widget.track,
            random: Random(random.nextInt(100000)),
          )),
    ];
    // Player is not included here, only real-time
  }

  void _startRace() {
    print('Starting race on track: ${widget.track.name}');
    setState(() {
      currentLap = 0;
      currentShooting = 0;
      isShooting = false;
      shootingResults = List.generate(
        widget.track.shootingPositions.length,
        (_) => List.filled(5, false),
      );
      segmentTimes = [];
      shootingMisses = [];
      totalTime = 0;
      segmentsCompletedInLap = 0;
      liveLeaderboard = [];
      livePlayerIndex = 0;
      lastSimulatedSegment = 0;
      _simulateAllAthletesOnce();
    });
  }

  void _completeLap() {
    print('Completing lap $currentLap');
    if (currentLap < widget.track.laps - 1) {
      setState(() {
        currentLap++;
        isShooting = true;
        segmentsCompletedInLap = 0;
      });
      print('Moving to shooting $currentShooting');
    } else {
      print('Race completed, showing results');
      _showResults();
    }
  }

  void _completeShooting(List<bool> hits) {
    print('Completing shooting $currentShooting');
    final misses = hits.where((hit) => !hit).length;
    setState(() {
      isShooting = false;
      currentShooting++;
      shootingResults[currentShooting - 1] = hits;
      shootingMisses.add(misses);
      totalTime += RaceStats.calculateShootingPenalty(misses);
      showIntermediateTime = true;
      lastIntermediateTime = totalTime;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showIntermediateTime = false;
        });
      }
    });
    print('Moving to lap $currentLap');
  }

  void _handleSegmentComplete(double progress) {
    final segmentsInLap = (widget.track.lapDistance / 100).ceil();
    if (segmentsCompletedInLap < segmentsInLap) {
      final segmentTime = RaceStats.calculateSegmentTime(progress);
      setState(() {
        segmentTimes.add(segmentTime);
        totalTime += segmentTime;
        segmentsCompletedInLap++;
      });
      _updateLiveLeaderboard();
    }
    if (segmentsCompletedInLap == segmentsInLap) {
      segmentsCompletedInLap = 0;
      _completeLap();
    }
  }

  void _updateLiveLeaderboard() {
    final playerAthlete = widget.career.player;
    int currentSegment = segmentTimes.length;
    // Use precomputed times for all athletes
    partialResults = allSimulatedResults.map((full) {
      // Build partial up to current segment
      final segTimes = full.segmentTimes.take(currentSegment).toList();
      final cumTimes = <double>[];
      double sum = 0;
      for (final t in segTimes) {
        sum += t;
        cumTimes.add(sum);
      }
      // Shooting misses up to current segment (approximate)
      final shootingMisses = <int>[];
      int segsPerLap = (widget.track.lapDistance / 100).ceil();
      int segDone = 0;
      int shootingIdx = 0;
      for (int lap = 0; lap < widget.track.laps; lap++) {
        for (int s = 0; s < segsPerLap; s++) {
          if (++segDone >= currentSegment) break;
        }
        if (segDone >= currentSegment) break;
        if (shootingIdx < full.shootingMisses.length) {
          shootingMisses.add(full.shootingMisses[shootingIdx++]);
          sum += RaceStats.calculateShootingPenalty(shootingMisses.last);
          cumTimes.add(sum);
        }
      }
      return AthleteRaceResult(
        athlete: full.athlete,
        segmentTimes: segTimes,
        shootingMisses: shootingMisses,
        cumulativeTimes: cumTimes,
        totalTime: cumTimes.isNotEmpty ? cumTimes.last : 0,
      );
    }).toList();
    // Player's partial result
    final playerResult = AthleteRaceResult(
      athlete: playerAthlete,
      segmentTimes: List<double>.from(segmentTimes),
      shootingMisses: List<int>.from(shootingMisses),
      cumulativeTimes: _buildPlayerCumulativeTimes(),
      totalTime: totalTime,
    );
    partialResults.add(playerResult);
    partialResults.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final playerIndex = partialResults.indexWhere((r) => r.athlete.name == playerAthlete.name);
    setState(() {
      liveLeaderboard = partialResults.take(10).toList();
      livePlayerIndex = playerIndex;
      lastSimulatedSegment = segmentTimes.length;
    });
  }

  void _showResults() {
    print('Calculating race results');
    final playerAthlete = widget.career.player;
    // Add player result (use actual segmentTimes and shootingMisses)
    final playerResult = AthleteRaceResult(
      athlete: playerAthlete,
      segmentTimes: List<double>.from(segmentTimes),
      shootingMisses: List<int>.from(shootingMisses),
      cumulativeTimes: _buildPlayerCumulativeTimes(),
      totalTime: totalTime,
    );
    allSimulatedResults.add(playerResult);
    // Sort by total time
    allSimulatedResults.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final playerIndex = allSimulatedResults.indexWhere((r) => r.athlete.name == playerAthlete.name);
    // Save points for this race
    final isMass = widget.track.type.toString().contains('mass');
    final pointsTable = isMass ? massStartPoints : usualRacePoints;
    final playerPoints = playerIndex < pointsTable.length ? pointsTable[playerIndex] : 0;
    widget.career.addRacePointsResult(RacePointsResult(
      track: widget.track,
      place: playerIndex + 1,
      points: playerPoints,
      type: widget.track.type.toString().split('.').last,
      athleteName: playerAthlete.name,
      athleteSurname: playerAthlete.surname,
      athleteCountry: playerAthlete.country,
    ));
    // Save all athletes' results for this race
    final List<RacePointsResult> fullRaceResults = allSimulatedResults.asMap().entries.map((entry) {
      final athlete = entry.value.athlete;
      final place = entry.key + 1;
      final points = entry.key < pointsTable.length ? pointsTable[entry.key] : 0;
      return RacePointsResult(
        track: widget.track,
        place: place,
        points: points,
        type: widget.track.type.toString().split('.').last,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        athleteCountry: athlete.country,
      );
    }).toList();
    widget.career.addFullRaceResults(fullRaceResults);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Race Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Time: ${_formatTime(totalTime)}'),
              const SizedBox(height: 8),
              Text('Total Misses: ${shootingMisses.fold(0, (sum, misses) => sum + misses)}'),
              const SizedBox(height: 16),
              const Text('Leaderboard:'),
              ..._buildFinalLeaderboard(allSimulatedResults),
              const SizedBox(height: 16),
              const Text('Cumulative Times After Each Segment:'),
              _buildCumulativeTimesTable(allSimulatedResults, playerIndex),
              const SizedBox(height: 16),
              const Text('Segment Times:'),
              ...segmentTimes.asMap().entries.map((entry) => Text(
                'Segment ${entry.key + 1}: ${entry.value.toStringAsFixed(1)}s',
              )),
              const SizedBox(height: 8),
              const Text('Shooting Penalties:'),
              ...shootingMisses.asMap().entries.map((entry) => Text(
                'Shooting ${entry.key + 1}: ${entry.value * 24}s',
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('Returning to career screen');
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return to Career'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFinalLeaderboard(List<AthleteRaceResult> allSimulated) {
    final allResults = [...allSimulated];
    allResults.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final leaderTime = allResults.first.totalTime;
    final playerIndex = allResults.indexWhere((r) => r.athlete.name == widget.career.player.name);
    // Choose points table
    final isMass = widget.track.type.toString().contains('mass');
    final pointsTable = isMass ? massStartPoints : usualRacePoints;
    return allResults.asMap().entries.map((entry) {
      final diff = entry.value.totalTime - leaderTime;
      final showTime = entry.key == 0
        ? _formatTime(entry.value.totalTime)
        : '+${_formatTimeDiff(diff)}';
      final totalMisses = entry.value.shootingMisses.fold(0, (a, b) => a + b);
      final flag = countryToFlag(entry.value.athlete.country);
      final points = entry.key < pointsTable.length ? pointsTable[entry.key] : 0;
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '${entry.key + 1}. ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
            buildFlagNameSpan(flag, entry.value.athlete.name, entry.value.athlete.surname),
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

  List<double> _buildPlayerCumulativeTimes() {
    List<double> result = [];
    double sum = 0;
    int seg = 0;
    int shoot = 0;
    final segmentsInLap = (widget.track.lapDistance / 100).ceil();
    for (int lap = 0; lap < widget.track.laps; lap++) {
      for (int s = 0; s < segmentsInLap; s++) {
        if (seg < segmentTimes.length) {
          sum += segmentTimes[seg++];
          result.add(sum);
        }
      }
      if (shoot < shootingMisses.length) {
        sum += RaceStats.calculateShootingPenalty(shootingMisses[shoot++]);
        result.add(sum);
      }
    }
    return result;
  }

  Widget _buildCumulativeTimesTable(List<AthleteRaceResult> allResults, int playerIndex) {
    final List<AthleteRaceResult> shown = [
      ...allResults,
    ];
    final int maxSplits = shown.map((r) => r.cumulativeTimes.length).fold(0, (a, b) => a > b ? a : b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Athlete')),
          ...List.generate(maxSplits, (i) => DataColumn(label: Text('S${i + 1}'))),
        ],
        rows: shown.map((r) {
          final flag = countryToFlag(r.athlete.country);
          return DataRow(
            cells: [
              DataCell(RichText(
                text: buildFlagNameSpan(flag, r.athlete.name, r.athlete.surname),
              )),
              ...List.generate(maxSplits, (i) => DataCell(
                i < r.cumulativeTimes.length
                  ? Text(_formatTime(r.cumulativeTimes[i]))
                  : const Text('-'),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building RaceScreen: lap=$currentLap, shooting=$currentShooting, isShooting=$isShooting');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.track.name),
      ),
      body: Stack(
        children: [
          Center(
            child: isShooting
                ? ShootingView(
                    position: widget.track.shootingPositions[currentShooting],
                    onComplete: _completeShooting,
                  )
                : LapView(
                    lapNumber: currentLap + 1,
                    totalLaps: widget.track.laps,
                    lapDistance: widget.track.lapDistance,
                    onSegmentComplete: _handleSegmentComplete,
                  ),
          ),
          // Cumulative time display (now shows place and time diff)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Builder(
                builder: (context) {
                  // Use partialResults for lookup
                  final playerIdx = partialResults.indexWhere((r) => r.athlete.name == widget.career.player.name);
                  final player = playerIdx != -1 ? partialResults[playerIdx] : null;
                  final leaderTime = partialResults.isNotEmpty ? partialResults.first.totalTime : 0.0;
                  final playerTime = player?.totalTime ?? 0.0;
                  final diff = playerTime - leaderTime;
                  final place = playerIdx != -1 ? playerIdx + 1 : '-';
                  final diffStr = diff <= 0 ? (player != null ? _formatTime(player.totalTime) : '0:00') : _formatTimeDiff(diff);
                  final playerName = player != null ? (player.athlete.name + (player.athlete.surname.isNotEmpty ? ' ' + player.athlete.surname : '')) : '';
                  final flag = player != null ? countryToFlag(player.athlete.country) : '';
                  return Text(
                    '№ $place   $flag $playerName   ${diff <= 0 ? diffStr : "+$diffStr"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          // Live leaderboard overlay
          if (segmentTimes.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
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
                    ...List.generate(liveLeaderboard.length, (i) {
                      final leaderTime = liveLeaderboard.first.totalTime;
                      final diff = liveLeaderboard[i].totalTime - leaderTime;
                      final showTime = i == 0
                        ? _formatTime(liveLeaderboard[i].totalTime)
                        : '+${_formatTimeDiff(diff)}';
                      final totalMisses = liveLeaderboard[i].shootingMisses.fold(0, (a, b) => a + b);
                      final flag = countryToFlag(liveLeaderboard[i].athlete.country);
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${i + 1}. ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
                            buildFlagNameSpan(flag, liveLeaderboard[i].athlete.name, liveLeaderboard[i].athlete.surname),
                            TextSpan(text: ' $showTime (${totalMisses} misses)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
                          ],
                          style: TextStyle(
                            fontWeight: i == livePlayerIndex ? FontWeight.bold : FontWeight.normal,
                            color: i == livePlayerIndex ? Colors.blue : DefaultTextStyle.of(context).style.color,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeDiff(double seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).round();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String countryToFlag(String country) {
    final map = {
      'France': 'FR',
      'Norway': 'NO',
      'Germany': 'DE',
      'Russia': 'RU',
      'Italy': 'IT',
      'Poland': 'PL',
      'Czech Republic': 'CZ',
      'Austria': 'AT',
      'Belarus': 'BY',
      'Finland': 'FI',
      'Sweden': 'SE',
      'Slovakia': 'SK',
      'Ukraine': 'UA',
    };
    final code = map[country] ?? '';
    if (code.length != 2) return '';
    return String.fromCharCodes([
      code.codeUnitAt(0) + 0x1F1A5,
      code.codeUnitAt(1) + 0x1F1A5,
    ]);
  }

  // Helper to build a TextSpan with a big flag and normal name
  InlineSpan buildFlagNameSpan(String flag, String name, String surname) {
    return TextSpan(children: [
      TextSpan(text: flag.isNotEmpty ? '$flag ' : '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, height: 1)),
      TextSpan(text: '$name $surname', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
    ]);
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
    print('Building ShootingView: position=${position.name}');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Shooting ${position.name}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
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