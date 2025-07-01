import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/athlete_loader.dart';
import '../models/athlete.dart';
import '../models/career.dart';
import '../models/race_points_result.dart';
import '../models/race.dart';
import '../blocs/career_bloc.dart';
import '../utils/race_utils.dart';
import 'package:go_router/go_router.dart';

class _CountryResults {
  final String country;
  final Widget flag;
  final int totalResults;
  _CountryResults({required this.country, required this.flag, required this.totalResults});
}

class AthletesScreen extends StatefulWidget {
  const AthletesScreen({super.key});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  late List<Athlete> _athletes;
  int? _sortColumnIndex;
  bool _sortAscending = false;
  List<RacePointsResult> _allResults = [];
  int? _countrySortColumnIndex;
  bool _countrySortAscending = false;

  @override
  void initState() {
    super.initState();
    _athletes = loadAllPredefinedAthletes();
    // Default sort by World Cup 1 (descending)
    _sortColumnIndex = 2;
    _athletes.sort((a, b) => _getStat(b, 'worldCup', 1).compareTo(_getStat(a, 'worldCup', 1)));
  }

  void _onSort(int columnIndex, int Function(Athlete) getValue) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _athletes.sort((a, b) {
        final aValue = getValue(a);
        final bValue = getValue(b);
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      });
    });
  }

  int _getStat(Athlete athlete, String tournament, int place) {
    return _allResults.where((result) =>
      result.athlete.name == athlete.name &&
      result.athlete.surname == athlete.surname &&
      result.athlete.country == athlete.country &&
      _tournamentToString(result.race.tournament) == tournament &&
      result.place == place
    ).length;
  }

  int _getTotal(Athlete athlete, String tournament) {
    return _allResults.where((result) =>
      result.athlete.name == athlete.name &&
      result.athlete.surname == athlete.surname &&
      result.athlete.country == athlete.country &&
      _tournamentToString(result.race.tournament) == tournament &&
      (result.place == 1 || result.place == 2 || result.place == 3)
    ).length;
  }

  String _tournamentToString(Tournament t) {
    switch (t) {
      case Tournament.worldCup:
        return 'worldCup';
      case Tournament.wc:
        return 'wc';
      case Tournament.olympics:
        return 'olympics';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CareerBloc>().state;
    if (state is! CareerActive) {
      return const Scaffold(
        body: Center(child: Text('No active career found')),
      );
    }
    // Flatten allRacesResults
    _allResults = state.career.allRacesResults.expand((x) => x).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Athletes'),
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
            _buildAthletesTable(),
            _buildCountriesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesTable() {
    final columns = [
      DataColumn(label: const Text('№')),
      DataColumn(label: const Text('Country')),
      DataColumn(label: const Text('Name')),
      DataColumn(
        label: const Text('World Cup 1'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 1)),
      ),
      DataColumn(
        label: const Text('World Cup 2'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 2)),
      ),
      DataColumn(
        label: const Text('World Cup 3'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 3)),
      ),
      DataColumn(
        label: const Text('World Cup Total'),
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'worldCup')),
      ),
      DataColumn(
        label: const Text('WC 1'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 1)),
      ),
      DataColumn(
        label: const Text('WC 2'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 2)),
      ),
      DataColumn(
        label: const Text('WC 3'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 3)),
      ),
      DataColumn(
        label: const Text('WC Total'),
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'wc')),
      ),
      DataColumn(
        label: const Text('Olympics 1'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 1)),
      ),
      DataColumn(
        label: const Text('Olympics 2'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 2)),
      ),
      DataColumn(
        label: const Text('Olympics 3'),
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 3)),
      ),
      DataColumn(
        label: const Text('Olympics Total'),
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'olympics')),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: columns,
          rows: List.generate(_athletes.length, (i) {
            final athlete = _athletes[i];
            final flag = RaceUtils.countryToFlag(athlete.country);
            return DataRow(cells: [
              DataCell(Text((i + 1).toString())),
              DataCell(Row(
                children: [
                  RaceUtils.flagImage(athlete.country, size: 20),
                  const SizedBox(width: 4),
                  Text(athlete.country),
                ],
              )),
              DataCell(Text('${athlete.name} ${athlete.surname}')),
              DataCell(Text(_getStat(athlete, 'worldCup', 1).toString())),
              DataCell(Text(_getStat(athlete, 'worldCup', 2).toString())),
              DataCell(Text(_getStat(athlete, 'worldCup', 3).toString())),
              DataCell(Text(_getTotal(athlete, 'worldCup').toString())),
              DataCell(Text(_getStat(athlete, 'wc', 1).toString())),
              DataCell(Text(_getStat(athlete, 'wc', 2).toString())),
              DataCell(Text(_getStat(athlete, 'wc', 3).toString())),
              DataCell(Text(_getTotal(athlete, 'wc').toString())),
              DataCell(Text(_getStat(athlete, 'olympics', 1).toString())),
              DataCell(Text(_getStat(athlete, 'olympics', 2).toString())),
              DataCell(Text(_getStat(athlete, 'olympics', 3).toString())),
              DataCell(Text(_getTotal(athlete, 'olympics').toString())),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildCountriesTable() {
    // Aggregate all results by country
    final Map<String, List<Athlete>> countryAthletes = {};
    for (final athlete in _athletes) {
      countryAthletes.putIfAbsent(athlete.country, () => []).add(athlete);
    }
    final List<String> countries = countryAthletes.keys.toList();
    countries.sort((a, b) => a.compareTo(b));
    final columns = [
      DataColumn(label: const Text('№')),
      DataColumn(label: const Text('Country')),
      DataColumn(label: const Text('Name')),
      DataColumn(
        label: const Text('World Cup 1'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 1)),
      ),
      DataColumn(
        label: const Text('World Cup 2'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 2)),
      ),
      DataColumn(
        label: const Text('World Cup 3'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 3)),
      ),
      DataColumn(
        label: const Text('World Cup Total'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumTotal(c, 'worldCup')),
      ),
      DataColumn(
        label: const Text('WC 1'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 1)),
      ),
      DataColumn(
        label: const Text('WC 2'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 2)),
      ),
      DataColumn(
        label: const Text('WC 3'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 3)),
      ),
      DataColumn(
        label: const Text('WC Total'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumTotal(c, 'wc')),
      ),
      DataColumn(
        label: const Text('Olympics 1'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 1)),
      ),
      DataColumn(
        label: const Text('Olympics 2'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 2)),
      ),
      DataColumn(
        label: const Text('Olympics 3'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 3)),
      ),
      DataColumn(
        label: const Text('Olympics Total'),
        onSort: (i, _) => _onCountrySort(i, (c) => _sumTotal(c, 'olympics')),
      ),
    ];
    // Build country data
    final List<_CountryRow> countryRows = countries.map((country) {
      final athletes = countryAthletes[country]!;
      return _CountryRow(
        country: country,
        flag: RaceUtils.flagImage(country, size: 20),
        stats: [
          // Name column is empty
          _sumStat(athletes, 'worldCup', 1),
          _sumStat(athletes, 'worldCup', 2),
          _sumStat(athletes, 'worldCup', 3),
          _sumTotal(athletes, 'worldCup'),
          _sumStat(athletes, 'wc', 1),
          _sumStat(athletes, 'wc', 2),
          _sumStat(athletes, 'wc', 3),
          _sumTotal(athletes, 'wc'),
          _sumStat(athletes, 'olympics', 1),
          _sumStat(athletes, 'olympics', 2),
          _sumStat(athletes, 'olympics', 3),
          _sumTotal(athletes, 'olympics'),
        ],
      );
    }).toList();
    // Sort by selected column
    if (_countrySortColumnIndex != null && _countrySortColumnIndex! >= 3) {
      final col = _countrySortColumnIndex! - 3;
      countryRows.sort((a, b) => _countrySortAscending
        ? a.stats[col].compareTo(b.stats[col])
        : b.stats[col].compareTo(a.stats[col]));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          sortColumnIndex: _countrySortColumnIndex,
          sortAscending: _countrySortAscending,
          columns: columns,
          rows: List.generate(countryRows.length, (i) {
            final c = countryRows[i];
            return DataRow(cells: [
              DataCell(Text((i + 1).toString())),
              DataCell(Row(
                children: [
                  c.flag,
                  const SizedBox(width: 4),
                  Text(c.country),
                ],
              )),
              const DataCell(Text('')),
              ...c.stats.map((v) => DataCell(Text(v.toString()))),
            ]);
          }),
        ),
      ),
    );
  }

  void _onCountrySort(int columnIndex, int Function(List<Athlete>) getValue) {
    setState(() {
      if (_countrySortColumnIndex == columnIndex) {
        _countrySortAscending = !_countrySortAscending;
      } else {
        _countrySortColumnIndex = columnIndex;
        _countrySortAscending = false;
      }
    });
  }

  int _sumStat(List<Athlete> athletes, String tournament, int place) => athletes.fold(0, (sum, a) => sum + _getStat(a, tournament, place));
  int _sumTotal(List<Athlete> athletes, String tournament) => athletes.fold(0, (sum, a) => sum + _getTotal(a, tournament));
}

class _CountryRow {
  final String country;
  final Widget flag;
  final List<int> stats;
  _CountryRow({required this.country, required this.flag, required this.stats});
} 