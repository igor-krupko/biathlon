import 'package:flutter/material.dart';
import '../models/career.dart';
import '../screens/race_screen.dart';
import 'package:provider/provider.dart';

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

class PointsScreen extends StatelessWidget {
  final Career career;
  const PointsScreen({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    // Flatten allRacesResults to a single list
    final races = career.allRacesResults.expand((x) => x).toList();
    if (races.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No races completed yet')),
      );
    }
    // Group results by race
    final raceGroups = <String, List<RacePointsResult>>{};
    for (final r in races) {
      final key = '${r.track.name}|${r.type}';
      raceGroups.putIfAbsent(key, () => []).add(r);
    }
    // Get unique race keys sorted by track name
    final raceKeys = raceGroups.keys.toList()..sort();
    // Get all unique athletes
    final athletes = <String, Map<String, dynamic>>{};
    for (final r in races) {
      final key = '${r.athleteName}|${r.athleteSurname}|${r.athleteCountry}';
      if (!athletes.containsKey(key)) {
        athletes[key] = {
          'name': r.athleteName,
          'surname': r.athleteSurname,
          'country': r.athleteCountry,
          'points': 0,
          'results': <RacePointsResult>[],
        };
      }
      athletes[key]!['points'] += r.points;
      athletes[key]!['results'].add(r);
    }
    // Sort athletes by total points
    final sortedAthletes = athletes.values.toList()
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    return Scaffold(
      appBar: AppBar(title: const Text('Points')), 
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('#')),
              const DataColumn(label: Text('Athlete')),
              const DataColumn(label: Text('Country')),
              ...raceKeys.map((rk) {
                final r = raceGroups[rk]!.first;
                return DataColumn(label: Text('${r.track.name}\n${r.type}'));
              }),
              const DataColumn(label: Text('Total')),
            ],
            rows: List.generate(sortedAthletes.length, (i) {
              final rawA = sortedAthletes[i];
              final Map<String, dynamic> a = rawA is Map ? Map<String, dynamic>.from(rawA) : <String, dynamic>{};
              final name = a['name'] is String ? a['name'] as String : '';
              final surname = a['surname'] is String ? a['surname'] as String : '';
              final country = a['country'] is String ? a['country'] as String : '';
              final points = a['points'] is int ? a['points'] as int : 0;
              final flag = countryToFlag(country);
              final resultsList = a['results'] is List ? a['results'] as List<RacePointsResult> : <RacePointsResult>[];
              final resultsByRace = {for (var r in resultsList) '${r.track.name}|${r.type}': r};
              return DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text('$name $surname')),
                DataCell(Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(country),
                  ],
                )),
                ...raceKeys.map((rk) {
                  final r = resultsByRace[rk];
                  if (r == null) return const DataCell(Text('-'));
                  Color? bg;
                  if (r.place == 1) bg = Colors.amber[300];
                  else if (r.place == 2) bg = Colors.grey[300];
                  else if (r.place == 3) bg = Colors.brown[200];
                  return DataCell(Container(
                    color: bg,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text('${r.points}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ));
                }),
                DataCell(Text(points.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              ]);
            }),
          ),
        ),
      ),
    );
  }
} 