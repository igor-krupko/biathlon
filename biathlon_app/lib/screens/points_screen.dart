import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/points_bloc.dart';
import '../utils/race_utils.dart';
import '../blocs/career_bloc.dart';
import '../models/race_points_result.dart';
import '../models/track_type.dart';
import '../services/points_service.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  static const List<Tab> _tabs = [
    Tab(text: 'Total'),
    Tab(text: 'Sprint'),
    Tab(text: 'Pursuit'),
    Tab(text: 'Individual'),
    Tab(text: 'Mass'),
    Tab(text: 'Countries'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: BlocBuilder<PointsBloc, PointsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Points'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/career-details'),
              ),
              bottom: const TabBar(tabs: _tabs),
            ),
            body: TabBarView(
              children: [
                _buildBody(context, state, null), // Total
                _buildBody(context, state, TrackType.sprint),
                _buildBody(context, state, TrackType.pursuit),
                _buildBody(context, state, TrackType.individual),
                _buildBody(context, state, TrackType.mass),
                _buildCountriesBody(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PointsState state, TrackType? filterType) {
    if (state is PointsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PointsError) {
      return Center(child: Text('Error: ${state.message}'));
    }

    if (state is PointsLoaded) {
      final career = (context.read<CareerBloc>().state as CareerActive).career;
      final seasonToShow = career.currentSeason;

      if (state.athletes.isEmpty) {
        return const Center(child: Text('No races completed yet'));
      }

      // Filter raceKeys by type if needed
      List<String> filteredRaceKeys = state.raceKeys;
      if (filterType != null) {
        filteredRaceKeys = state.raceKeys.where((rk) {
          final result = state.athletes.first.resultsByRace[rk];
          return result != null && result.race.track.type == filterType;
        }).toList();
      }

      // Sort athletes by points for the current tab
      List<AthletePointsData> sortedAthletes = List<AthletePointsData>.from(state.athletes);
      sortedAthletes.sort((a, b) {
        int pointsA, pointsB;
        if (filterType == null) {
          pointsA = a.totalPoints;
          pointsB = b.totalPoints;
        } else {
          final filteredA = a.resultsByRace.values.where((r) => r.race.track.type == filterType);
          final filteredB = b.resultsByRace.values.where((r) => r.race.track.type == filterType);
          pointsA = filteredA.fold(0, (sum, r) => sum + r.points);
          pointsB = filteredB.fold(0, (sum, r) => sum + r.points);
        }
        return pointsB.compareTo(pointsA); // Descending
      });

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points for Season: ' +
                  seasonToShow.name +
                  ' (' +
                  seasonToShow.year.toString() +
                  ')',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('#')),
                  const DataColumn(label: Text('Athlete')),
                  const DataColumn(label: Text('Country')),
                  DataColumn(label: Text(filterType == null ? 'Total' : filterType.name[0].toUpperCase() + filterType.name.substring(1))),
                  ...filteredRaceKeys.map((rk) {
                    RacePointsResult? result;
                    if (state.athletes.isNotEmpty) {
                      result = state.athletes.first.resultsByRace[rk];
                    }
                    final label = result != null
                      ? '${result.race.track.name}\n${result.type}'
                      : rk;
                    return DataColumn(label: Text(label));
                  }),
                ],
                rows: List.generate(sortedAthletes.length, (i) {
                  final athlete = sortedAthletes[i];
                  final flag = RaceUtils.countryToFlag(athlete.athlete.country);
                  // Filter resultsByRace for this athlete
                  final filteredResults = filterType == null
                    ? athlete.resultsByRace
                    : Map.fromEntries(
                        athlete.resultsByRace.entries.where((e) => e.value.race.track.type == filterType),
                      );
                  final points = filterType == null
                    ? athlete.totalPoints
                    : filteredResults.values.fold(0, (sum, r) => sum + r.points);
                  final player = (context.read<CareerBloc>().state as CareerActive).career.player;
                  final isPlayer = athlete.athlete.id == player.id;
                  Color? rowColor;
                  if (i == 0) {
                    rowColor = filterType == null ? Colors.yellow[200] : Colors.red[200];
                  } else if (isPlayer) {
                    rowColor = Colors.yellow[100];
                  }
                  return DataRow(
                    color: rowColor != null ? MaterialStateProperty.all(rowColor) : null,
                    cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(Text('${athlete.athlete.name} ${athlete.athlete.surname}')),
                      DataCell(Row(
                        children: [
                          RaceUtils.flagImage(athlete.athlete.country, size: 20),
                          const SizedBox(width: 4),
                          Text(athlete.athlete.country),
                        ],
                      )),
                      DataCell(Text(points.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      ...filteredRaceKeys.map((rk) {
                        final result = filteredResults[rk];
                        if (result == null) return const DataCell(Text('-'));
                        Color? bg;
                        if (result.place == 1)
                          bg = Colors.amber[300];
                        else if (result.place == 2)
                          bg = Colors.grey[300];
                        else if (result.place == 3) bg = Colors.brown[200];
                        return DataCell(Container(
                          color: bg,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('${result.points}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ));
                      }),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('No data available'));
  }

  Widget _buildCountriesBody(BuildContext context, PointsState state) {
    if (state is PointsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PointsError) {
      return Center(child: Text('Error: \\${state.message}'));
    }
    if (state is PointsLoaded) {
      final career = (context.read<CareerBloc>().state as CareerActive).career;
      final seasonToShow = career.currentSeason;
      if (state.athletes.isEmpty) {
        return const Center(child: Text('No races completed yet'));
      }
      // Group athletes by country
      final Map<String, List<AthletePointsData>> countryMap = {};
      for (final athlete in state.athletes) {
        final country = athlete.athlete.country;
        countryMap.putIfAbsent(country, () => []).add(athlete);
      }
      // For each country, take best 4 athletes by total points
      final List<_CountryPoints> countryPoints = countryMap.entries.map((entry) {
        final athletes = entry.value;
        athletes.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        final best4 = athletes.take(4).toList();
        final total = best4.fold(0, (sum, a) => sum + a.totalPoints);
        return _CountryPoints(
          country: entry.key,
          flag: RaceUtils.flagImage(entry.key, size: 24),
          totalPoints: total,
          athletes: best4,
        );
      }).toList();
      // Sort countries by total points descending
      countryPoints.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Country Points for Season: ' +
                  seasonToShow.name +
                  ' (' +
                  seasonToShow.year.toString() +
                  ')',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('Total Points')),
                  DataColumn(label: Text('Best 4 Athletes')),
                ],
                rows: List.generate(countryPoints.length, (i) {
                  final c = countryPoints[i];
                  return DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Row(
                      children: [
                        c.flag,
                        const SizedBox(width: 6),
                        Text(c.country),
                      ],
                    )),
                    DataCell(Text(c.totalPoints.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(
                      c.athletes.map((a) => '${a.athlete.name} ${a.athlete.surname} (${a.totalPoints})').join(', '),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]);
                }),
              ),
            ),
          ],
        ),
      );
    }
    return const Center(child: Text('No data available'));
  }
}

class _CountryPoints {
  final String country;
  final Widget flag;
  final int totalPoints;
  final List<AthletePointsData> athletes;
  _CountryPoints({required this.country, required this.flag, required this.totalPoints, required this.athletes});
}
