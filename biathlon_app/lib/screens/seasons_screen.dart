import 'package:flutter/material.dart';
import '../models/career.dart';
import '../models/athlete.dart';
import '../models/season.dart';
import '../utils/race_utils.dart';
import 'package:go_router/go_router.dart';
import '../models/track_type.dart';

class SeasonsScreen extends StatelessWidget {
  final Career career;
  const SeasonsScreen({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    final playerKey = '${career.player.name}|${career.player.surname}|${career.player.country}';
    final completedSeasons = career.seasons.where((season) {
      final seasonStart = DateTime(season.year, 6, 1);
      final seasonEnd = DateTime(season.year + 1, 6, 1);
      final results = career.allRacesResults.expand((x) => x)
        .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
        .toList();
      return results.isNotEmpty && season.year < career.currentSeason.year;
    }).toList();

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seasons Results'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/career-details'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Total'),
              Tab(text: 'Sprint'),
              Tab(text: 'Pursuit'),
              Tab(text: 'Mass'),
              Tab(text: 'Individual'),
              Tab(text: 'Countries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAthletesTab(context, completedSeasons, playerKey, null),
            _buildAthletesTab(context, completedSeasons, playerKey, TrackType.sprint),
            _buildAthletesTab(context, completedSeasons, playerKey, TrackType.pursuit),
            _buildAthletesTab(context, completedSeasons, playerKey, TrackType.mass),
            _buildAthletesTab(context, completedSeasons, playerKey, TrackType.individual),
            _buildCountriesTab(context, completedSeasons),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesTab(BuildContext context, List<Season> completedSeasons, String playerKey, TrackType? discipline) {
    if (completedSeasons.isEmpty) {
      return const Center(child: Text('No completed seasons yet'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: completedSeasons.map((season) {
          final year = season.year;
          final seasonStart = DateTime(year, 6, 1);
          final seasonEnd = DateTime(year + 1, 6, 1);
          final allResults = career.allRacesResults.expand((x) => x)
            .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
            .toList();
          final Map<String, int> athletePoints = {};
          final Map<String, Athlete> keyToAthlete = {};
          if (discipline == null) {
            // Total: sum all points
            for (final r in allResults) {
              final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
              athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
              keyToAthlete[key] = r.athlete;
            }
          } else {
            // Discipline: sum only for that discipline
            for (final r in allResults.where((r) => r.race.track.type == discipline)) {
              final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
              athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
              keyToAthlete[key] = r.athlete;
            }
          }
          final sorted = athletePoints.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topN = discipline == null ? 10 : 3;
          final displayRows = discipline == null ? 11 : 4;
          final top = sorted.take(topN).toList();
          final playerPlace = sorted.indexWhere((e) => e.key == playerKey);
          bool playerInTop = playerPlace >= 0 && playerPlace < topN;
          // Always displayRows rows: topN + 1 (player or empty)
          final List<MapEntry<String, int>?> rows = List.generate(displayRows, (i) => i < top.length ? top[i] : null);
          if (!playerInTop && playerPlace != -1) {
            rows[topN] = sorted[playerPlace];
          }
          return Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            child: SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${season.name} (${season.year})', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      discipline == null
                        ? 'Top 10 by Total Points'
                        : 'Top 3 by ${discipline.name[0].toUpperCase()}${discipline.name.substring(1)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DataTable(
                      columnSpacing: 8,
                      columns: const [
                        DataColumn(label: SizedBox(width: 24, child: Text('#'))),
                        DataColumn(label: Text('Athlete')),
                        DataColumn(label: Text('Country')),
                        DataColumn(label: Text('Points')),
                      ],
                      rows: List.generate(displayRows, (i) {
                        final entry = rows[i];
                        if (entry == null) {
                          return const DataRow(cells: [
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                          ]);
                        }
                        final athlete = keyToAthlete[entry.key]!;
                        final isPlayer = entry.key == playerKey;
                        final isFirst = i == 0;
                        // Show actual player place if this is the player row
                        final placeText = isPlayer ? (playerPlace + 1).toString() : (i + 1).toString();
                        return DataRow(
                          color: isFirst
                            ? (discipline == null
                                ? MaterialStateProperty.all(Colors.yellow[200])
                                : MaterialStateProperty.all(Colors.red[200]))
                            : isPlayer
                              ? MaterialStateProperty.all(Colors.yellow.withOpacity(0.2))
                              : null,
                          cells: [
                            DataCell(SizedBox(width: 24, child: Text(placeText))),
                            DataCell(Text('${athlete.name} ${athlete.surname}')),
                            DataCell(Row(children:[RaceUtils.flagImage(athlete.country, size: 18), const SizedBox(width: 4), Text(athlete.country)])),
                            DataCell(Text(entry.value.toString())),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountriesTab(BuildContext context, List<Season> completedSeasons) {
    if (completedSeasons.isEmpty) {
      return const Center(child: Text('No completed seasons yet'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: completedSeasons.map((season) {
          final year = season.year;
          final seasonStart = DateTime(year, 6, 1);
          final seasonEnd = DateTime(year + 1, 6, 1);
          final allResults = career.allRacesResults.expand((x) => x)
            .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
            .toList();
          // Correct country points calculation: sum points for each athlete, take best 4 athletes' total points
          final Map<String, Map<String, int>> countryAthletePoints = {};
          for (final r in allResults) {
            final country = r.athlete.country;
            final athleteKey = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
            countryAthletePoints.putIfAbsent(country, () => {});
            countryAthletePoints[country]![athleteKey] = (countryAthletePoints[country]![athleteKey] ?? 0) + r.points;
          }
          final Map<String, int> countryPoints = {};
          for (final entry in countryAthletePoints.entries) {
            final best4 = entry.value.values.toList()..sort((a, b) => b.compareTo(a));
            final total = best4.take(4).fold(0, (sum, p) => sum + p);
            countryPoints[entry.key] = total;
          }
          final sorted = countryPoints.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top10 = sorted.take(10).toList();
          // Always 11 rows for countries for alignment
          final List<MapEntry<String, int>?> countryRows = List.generate(11, (i) => i < top10.length ? top10[i] : null);
          return Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            child: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${season.name} (${season.year})', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      DataTable(
                        columns: const [
                          DataColumn(label: SizedBox(width: 24, child: Text('#'))),
                          DataColumn(label: Text('Country')),
                          DataColumn(label: Text('Points')),
                        ],
                        rows: List.generate(11, (i) {
                          final entry = countryRows[i];
                          final isFirst = i == 0;
                          if (entry == null) {
                            return const DataRow(cells: [
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                            ]);
                          }
                          return DataRow(
                            color: isFirst ? MaterialStateProperty.all(Colors.yellow[200]) : null,
                            cells: [
                              DataCell(SizedBox(width: 24, child: Text((i + 1).toString()))),
                              DataCell(Row(children:[RaceUtils.flagImage(entry.key, size: 18), const SizedBox(width: 4), Text(entry.key)])),
                              DataCell(Text(entry.value.toString())),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 