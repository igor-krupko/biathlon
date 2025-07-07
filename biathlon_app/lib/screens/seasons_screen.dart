import 'package:flutter/material.dart';
import '../models/career.dart';
import '../models/race_points_result.dart';
import '../models/track_type.dart';
import '../models/season.dart';
import '../utils/race_utils.dart';
import 'package:go_router/go_router.dart';

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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seasons Results'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/career-details'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Athletes'),
              Tab(text: 'Countries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAthletesTab(context, completedSeasons, playerKey),
            _buildCountriesTab(context, completedSeasons),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesTab(BuildContext context, List<Season> completedSeasons, String playerKey) {
    if (completedSeasons.isEmpty) {
      return const Center(child: Text('No completed seasons yet'));
    }
    return ListView.builder(
      itemCount: completedSeasons.length,
      itemBuilder: (context, idx) {
        final season = completedSeasons[idx];
        final year = season.year;
        final seasonStart = DateTime(year, 6, 1);
        final seasonEnd = DateTime(year + 1, 6, 1);
        final seasonResults = career.allRacesResults.expand((x) => x)
          .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
          .toList();
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
    );
  }

  Widget _buildCountriesTab(BuildContext context, List<Season> completedSeasons) {
    if (completedSeasons.isEmpty) {
      return const Center(child: Text('No completed seasons yet'));
    }
    return ListView.builder(
      itemCount: completedSeasons.length,
      itemBuilder: (context, idx) {
        final season = completedSeasons[idx];
        final year = season.year;
        final seasonStart = DateTime(year, 6, 1);
        final seasonEnd = DateTime(year + 1, 6, 1);
        final seasonResults = career.allRacesResults.expand((x) => x)
          .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
          .toList();
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
                  _buildCountryPodiumTable(context, seasonResults, null, 'Total'),
                  _buildCountryPodiumTable(context, seasonResults, TrackType.sprint, 'Sprint'),
                  _buildCountryPodiumTable(context, seasonResults, TrackType.pursuit, 'Pursuit'),
                  _buildCountryPodiumTable(context, seasonResults, TrackType.mass, 'Mass'),
                  _buildCountryPodiumTable(context, seasonResults, TrackType.individual, 'Individual'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountryPodiumTable(BuildContext context, List<RacePointsResult> results, TrackType? filterType, String label) {
    // Aggregate points by country (sum of best 4 athletes)
    final Map<String, List<int>> countryToAthletePoints = {};
    for (final r in results) {
      if (filterType == null || r.race.track.type == filterType) {
        final country = r.athlete.country;
        countryToAthletePoints.putIfAbsent(country, () => <int>[]);
      }
    }
    // For each athlete, sum their points for this season/discipline
    final Map<String, int> athletePoints = {};
    for (final r in results) {
      if (filterType == null || r.race.track.type == filterType) {
        final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
        athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
      }
    }
    // Assign athlete points to their country
    for (final entry in athletePoints.entries) {
      final parts = entry.key.split('|');
      final country = parts[2];
      if (countryToAthletePoints.containsKey(country)) {
        countryToAthletePoints[country]!.add(entry.value);
      }
    }
    // For each country, sum the best 4 athletes
    final List<_CountryPoints> countryPoints = countryToAthletePoints.entries.map((entry) {
      final best4 = entry.value..sort((a, b) => b.compareTo(a));
      final total = best4.take(4).fold(0, (sum, p) => sum + p);
      return _CountryPoints(
        country: entry.key,
        flag: RaceUtils.flagImage(entry.key, size: 24),
        totalPoints: total,
      );
    }).toList();
    countryPoints.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Points')),
          ],
          rows: [
            for (int i = 0; i < countryPoints.length && i < 3; i++)
              DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Row(
                  children: [
                    countryPoints[i].flag,
                    const SizedBox(width: 4),
                    Text(countryPoints[i].country),
                  ],
                )),
                DataCell(Text(countryPoints[i].totalPoints.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
          ],
        ),
        const SizedBox(height: 12),
      ],
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
    return DataRow(
      color: highlight || isPlayer
          ? MaterialStateProperty.all(Colors.yellow.withOpacity(0.2))
          : null,
      cells: [
        DataCell(Text('$place', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
        DataCell(Text('${parts[0]} ${parts[1]}', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
        DataCell(Row(
          children: [
            RaceUtils.flagImage(parts[2], size: 18),
            const SizedBox(width: 4),
            Text(parts[2]),
          ],
        )),
        DataCell(Text('${entry.value}', style: TextStyle(fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }
}

class _CountryPoints {
  final String country;
  final Widget flag;
  final int totalPoints;
  _CountryPoints({required this.country, required this.flag, required this.totalPoints});
} 