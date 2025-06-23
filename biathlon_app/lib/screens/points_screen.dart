import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/points_bloc.dart';
import '../utils/race_utils.dart';
import '../blocs/career_bloc.dart';
import '../models/race_points_result.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsBloc, PointsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Points'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/career-details'),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PointsState state) {
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
                  const DataColumn(label: Text('Total')),
                  ...state.raceKeys.map((rk) {
                    // Try to get the race object from the first athlete's results
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
                rows: List.generate(state.athletes.length, (i) {
                  final athlete = state.athletes[i];
                  final flag = RaceUtils.countryToFlag(athlete.athlete.country);
                  return DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text('${athlete.athlete.name} ${athlete.athlete.surname}')),
                    DataCell(Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(athlete.athlete.country),
                      ],
                    )),
                    DataCell(Text(athlete.totalPoints.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ...state.raceKeys.map((rk) {
                      final result = athlete.resultsByRace[rk];
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
