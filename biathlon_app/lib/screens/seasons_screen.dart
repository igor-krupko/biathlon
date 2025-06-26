import 'package:flutter/material.dart';
import '../models/career.dart';
import '../models/race_points_result.dart';
import '../models/track_type.dart';
import '../utils/race_utils.dart';
import 'package:go_router/go_router.dart';

class SeasonsScreen extends StatelessWidget {
  final Career career;
  const SeasonsScreen({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    final playerKey = '${career.player.name}|${career.player.surname}|${career.player.country}';
    final completedSeasons = career.seasons.where((season) {
      final results = career.allRacesResults.expand((x) => x).where((r) => r.race.date.year == season.year).toList();
      return results.isNotEmpty && season.year < career.currentSeason.year;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasons Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/career-details'),
        ),
      ),
      body: completedSeasons.isEmpty
          ? const Center(child: Text('No completed seasons yet'))
          : ListView.builder(
              itemCount: completedSeasons.length,
              itemBuilder: (context, idx) {
                final season = completedSeasons[idx];
                final year = season.year;
                final seasonResults = career.allRacesResults.expand((x) => x).where((r) => r.race.date.year == year).toList();
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${season.name} (${season.year})', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _buildPodiumTable(context, seasonResults, playerKey, null, 'Total'),
                          _buildPodiumTable(context, seasonResults, playerKey, TrackType.sprint, 'Sprint'),
                          _buildPodiumTable(context, seasonResults, playerKey, TrackType.pursuit, 'Pursuit'),
                          _buildPodiumTable(context, seasonResults, playerKey, TrackType.mass, 'Mass'),
                          _buildPodiumTable(context, seasonResults, playerKey, TrackType.individual, 'Individual'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPodiumTable(BuildContext context, List<RacePointsResult> results, String playerKey, TrackType? filterType, String label) {
    // Aggregate points by athlete
    final Map<String, int> athletePoints = {};
    for (final r in results) {
      if (filterType == null || r.race.track.type == filterType) {
        final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
        athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
      }
    }
    final sorted = athletePoints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final playerPlace = sorted.indexWhere((e) => e.key == playerKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Athlete')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Points')),
          ],
          rows: [
            for (int i = 0; i < sorted.length && i < 3; i++)
              _buildDataRow(context, sorted[i], i + 1, playerKey),
            if (playerPlace >= 3)
              _buildDataRow(context, sorted[playerPlace], playerPlace + 1, playerKey, highlight: true),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  DataRow _buildDataRow(BuildContext context, MapEntry<String, int> entry, int place, String playerKey, {bool highlight = false}) {
    final parts = entry.key.split('|');
    final isPlayer = entry.key == playerKey;
    final flag = RaceUtils.countryToFlag(parts[2]);
    return DataRow(
      color: highlight || isPlayer
          ? MaterialStateProperty.all(Colors.yellow.withOpacity(0.2))
          : null,
      cells: [
        DataCell(Text('$place', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
        DataCell(Text('${parts[0]} ${parts[1]}', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
        DataCell(Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(parts[2]),
          ],
        )),
        DataCell(Text('${entry.value}', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }
} 