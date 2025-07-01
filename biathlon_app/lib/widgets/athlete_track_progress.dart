import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/athlete_race_result.dart';
import '../models/athlete.dart';
import '../utils/race_utils.dart';

class AthleteTrackProgress extends StatelessWidget {
  final List<AthleteRaceResult> partialResults;
  final Athlete player;
  final double currentDistance;
  final double segmentLength;
  final double totalDistance;

  const AthleteTrackProgress({
    super.key,
    required this.partialResults,
    required this.player,
    required this.currentDistance,
    required this.segmentLength,
    required this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    const double widgetHeight = 300;
    const double roadHeight = 12;
    const double circleRadius = 24;
    const double nameAngle = -math.pi / 4; // 45 degrees
    const double metersPerSecond = 100 / 16; // 16s = 100m
    const double windowHalf = 300;
    final double windowStart = math.max(0, currentDistance - windowHalf);
    final double windowEnd = math.min(totalDistance, currentDistance + windowHalf);
    final double windowWidth = windowEnd - windowStart;

    // print('AthleteTrackProgress: build, partialResults.length = \\${partialResults.length}');
    // print('AthleteTrackProgress: player = \\${player.name} \\${player.surname}');
    // for (final r in partialResults) {
    //   print('AthleteTrackProgress: athlete = \\${r.athlete.name} \\${r.athlete.surname}, totalTime = \\${r.totalTime}');
    // }

    if (partialResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widgetHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double centerX = width / 2;

          // Find player result
          final playerResult = partialResults.firstWhere((r) => r.athlete.id == player.id, orElse: () => partialResults.first);
          final playerTime = playerResult.totalTime;

          // If before first segment, show all in center
          final bool beforeFirstSegment = currentDistance == 0;

          // Calculate positions
          List<_AthleteVisual> visuals = partialResults.map((r) {
            double metersDiff = 0;
            if (!beforeFirstSegment) {
              final timeDiff = r.totalTime - playerTime;
              metersDiff = -timeDiff * metersPerSecond;
            }
            double athleteDistance = beforeFirstSegment ? currentDistance : (currentDistance + metersDiff);
            // Clamp to track
            athleteDistance = athleteDistance.clamp(0, totalDistance);
            // Map to X
            double x = beforeFirstSegment
                ? centerX
                : centerX + ((athleteDistance - currentDistance) * (width / (windowWidth == 0 ? 1 : windowWidth)));
            return _AthleteVisual(
              athlete: r.athlete,
              x: x,
              isPlayer: r.athlete.id == player.id,
              startNumber: r.startNumber,
            );
          }).toList();

          // Separate player and others
          final playerVisual = visuals.firstWhere((v) => v.isPlayer, orElse: () => visuals.first);
          final otherVisuals = visuals.where((v) => !v.isPlayer).toList();

          // Split otherVisuals into top 10 by current race position and the rest
          final top10Visuals = <_AthleteVisual>[];
          final restVisuals = <_AthleteVisual>[];
          for (int i = 0; i < otherVisuals.length; i++) {
            final v = otherVisuals[i];
            // Race position is determined by order in partialResults
            final racePosition = partialResults.indexWhere((r) => r.athlete.id == v.athlete.id) + 1;
            if (racePosition > 0 && racePosition <= 10) {
              top10Visuals.add(v);
            } else {
              restVisuals.add(v);
            }
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              // Road
              Positioned(
                left: 0,
                right: 0,
                top: widgetHeight / 2 - roadHeight / 2,
                child: Container(
                  height: roadHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(roadHeight / 2),
                  ),
                ),
              ),
              // 500m lines
              ...List.generate(((windowEnd - windowStart) / 500).ceil() + 1, (i) {
                final meter = (windowStart / 500).floor() * 500 + i * 500;
                if (meter < windowStart || meter > windowEnd) return const SizedBox.shrink();
                final x = centerX + ((meter - currentDistance) * (width / (windowWidth == 0 ? 1 : windowWidth)));
                return Positioned(
                  left: x - 1,
                  top: widgetHeight / 2 - 20,
                  child: Column(
                    children: [
                      Container(width: 2, height: 40, color: Colors.black26),
                      Text('${meter.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    ],
                  ),
                );
              }),
              // Rest of the athletes (very transparent)
              ...restVisuals.map((v) => Positioned(
                left: v.x - circleRadius,
                top: widgetHeight / 2 - circleRadius,
                child: Opacity(
                  opacity: 0.2,
                  child: _AthleteCircleWithName(v: v, nameAngle: nameAngle, circleRadius: circleRadius, player: player),
                ),
              )),
              // Top 10 race position athletes (normal or semi-transparent if startNumber > 10)
              ...top10Visuals.map((v) => Positioned(
                left: v.x - circleRadius,
                top: widgetHeight / 2 - circleRadius,
                child: Opacity(
                  opacity: (v.startNumber != null && v.startNumber! > 10) ? 0.5 : 1.0,
                  child: _AthleteCircleWithName(v: v, nameAngle: nameAngle, circleRadius: circleRadius, player: player),
                ),
              )),
              // Player circle always on top and fully visible
              Positioned(
                left: playerVisual.x - circleRadius,
                top: widgetHeight / 2 - circleRadius,
                child: _AthleteCircleWithName(v: playerVisual, nameAngle: nameAngle, circleRadius: circleRadius, player: player),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AthleteVisual {
  final Athlete athlete;
  final double x;
  final bool isPlayer;
  final int? startNumber;
  _AthleteVisual({required this.athlete, required this.x, required this.isPlayer, this.startNumber});
}

class _AthleteCircleWithName extends StatelessWidget {
  final _AthleteVisual v;
  final double nameAngle;
  final double circleRadius;
  final Athlete player;

  const _AthleteCircleWithName({required this.v, required this.nameAngle, required this.circleRadius, required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Name above the circle, rotated, with white border
        Transform.rotate(
          angle: nameAngle,
          child: Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Stack(
              children: [
                // White border
                Text(
                  '${v.athlete.name.isNotEmpty ? v.athlete.name[0] : ''}.${v.athlete.surname}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: v.isPlayer ? FontWeight.bold : FontWeight.normal,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // Fill color
                Text(
                  '${v.athlete.name.isNotEmpty ? v.athlete.name[0] : ''}.${v.athlete.surname}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: v.isPlayer ? FontWeight.bold : FontWeight.normal,
                    color: v.isPlayer ? Colors.blue : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: circleRadius * 2,
          height: circleRadius * 2,
          decoration: BoxDecoration(
            color: (v.startNumber == 1) ? Colors.yellow : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Stack(
            children: [
              // Start number in top half
              if (v.startNumber != null)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      v.startNumber.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              // Flag at the bottom, filling width, half height, rounded bottom corners
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(circleRadius),
                    bottomRight: Radius.circular(circleRadius),
                  ),
                  child: RaceUtils.flagImage(
                    v.athlete.country,
                    size: circleRadius, // width will be set by SizedBox
                  ),
                ),
              ),
              // SizedBox to force flag to fill width and half height
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: circleRadius * 2,
                  height: circleRadius,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(circleRadius),
                      bottomRight: Radius.circular(circleRadius),
                    ),
                    child: RaceUtils.flagImage(
                      v.athlete.country,
                      size: circleRadius * 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 