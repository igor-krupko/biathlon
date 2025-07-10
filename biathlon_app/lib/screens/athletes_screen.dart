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
import '../models/season.dart';
import '../models/track_type.dart';

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

  int _getScore(Athlete athlete, Map<String, List<int>> overallStandings, Map<String, List<int>> smallGlobe) {
    final key = '${athlete.name}|${athlete.surname}|${athlete.country}';
    int score = 0;
    // Medals and races
    score += _getStat(athlete, 'olympics', 1) * 100;
    score += _getStat(athlete, 'olympics', 2) * 20;
    score += _getStat(athlete, 'olympics', 3) * 10;
    score += _getStat(athlete, 'wc', 1) * 40;
    score += _getStat(athlete, 'wc', 2) * 10;
    score += _getStat(athlete, 'wc', 3) * 5;
    score += _getStat(athlete, 'worldCup', 1) * 5;
    score += _getStat(athlete, 'worldCup', 2) * 2;
    score += _getStat(athlete, 'worldCup', 3) * 1;
    // Big globe
    score += (overallStandings[key]?[0] ?? 0) * 120;
    score += (overallStandings[key]?[1] ?? 0) * 20;
    score += (overallStandings[key]?[2] ?? 0) * 10;
    // Small globe
    score += (smallGlobe[key]?[0] ?? 0) * 15;
    score += (smallGlobe[key]?[1] ?? 0) * 3;
    score += (smallGlobe[key]?[2] ?? 0) * 2;
    return score;
  }

  // Helper to calculate season standings (overall and by discipline)
  Map<String, List<int>> _calculateSeasonStandings(List<Season> seasons, List<List<RacePointsResult>> allRacesResults, {TrackType? discipline}) {
    // Map athleteKey -> [#1st, #2nd, #3rd]
    final Map<String, List<int>> standings = {};
    for (final season in seasons) {
      final seasonStart = DateTime(season.year, 6, 1);
      final seasonEnd = DateTime(season.year + 1, 6, 1);
      final seasonResults = allRacesResults.expand((x) => x)
        .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
        .where((r) => discipline == null || r.race.track.type == discipline)
        .toList();
      // Aggregate points by athlete
      final Map<String, int> athletePoints = {};
      for (final r in seasonResults) {
        final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
        athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
      }
      final sorted = athletePoints.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < sorted.length && i < 3; i++) {
        final key = sorted[i].key;
        standings.putIfAbsent(key, () => [0, 0, 0]);
        standings[key]![i] += 1;
      }
    }
    return standings;
  }

  // Helper to get only completed seasons
  List<Season> _completedSeasons(List<Season> seasons, List<List<RacePointsResult>> allRacesResults) {
    // A season is completed if all its races have at least one result in allRacesResults
    final allResultsFlat = allRacesResults.expand((x) => x).toList();
    return seasons.where((season) {
      final raceIds = season.races.map((r) => r.id).toSet();
      final resultRaceIds = allResultsFlat.map((r) => r.race.id).toSet();
      return raceIds.difference(resultRaceIds).isEmpty && raceIds.isNotEmpty;
    }).toList();
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

    // Ensure player is included in the athletes list
    final player = state.career.player;
    final playerKey = '${player.name}|${player.surname}|${player.country}';
    final athleteKeys = _athletes.map((a) => '${a.name}|${a.surname}|${a.country}').toSet();
    if (!athleteKeys.contains(playerKey)) {
      _athletes.insert(0, player);
    }

    return DefaultTabController(
      length: 3,
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
              Tab(text: 'Records'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAthletesTable(player),
            _buildCountriesTable(),
            _buildRecordsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesTable(Athlete player) {
    final state = context.watch<CareerBloc>().state as CareerActive;
    final seasons = _completedSeasons(state.career.seasons, state.career.allRacesResults);
    final allRacesResults = state.career.allRacesResults;
    final overallStandings = _calculateSeasonStandings(seasons, allRacesResults);
    final sprintStandings = _calculateSeasonStandings(seasons, allRacesResults, discipline: TrackType.sprint);
    final pursuitStandings = _calculateSeasonStandings(seasons, allRacesResults, discipline: TrackType.pursuit);
    final massStandings = _calculateSeasonStandings(seasons, allRacesResults, discipline: TrackType.mass);
    final individualStandings = _calculateSeasonStandings(seasons, allRacesResults, discipline: TrackType.individual);
    // Combine small globe stats
    Map<String, List<int>> smallGlobe = {};
    for (final key in {...sprintStandings.keys, ...pursuitStandings.keys, ...massStandings.keys, ...individualStandings.keys}) {
      smallGlobe[key] = [
        (sprintStandings[key]?[0] ?? 0) + (pursuitStandings[key]?[0] ?? 0) + (massStandings[key]?[0] ?? 0) + (individualStandings[key]?[0] ?? 0),
        (sprintStandings[key]?[1] ?? 0) + (pursuitStandings[key]?[1] ?? 0) + (massStandings[key]?[1] ?? 0) + (individualStandings[key]?[1] ?? 0),
        (sprintStandings[key]?[2] ?? 0) + (pursuitStandings[key]?[2] ?? 0) + (massStandings[key]?[2] ?? 0) + (individualStandings[key]?[2] ?? 0),
      ];
    }
    final columns = [
      DataColumn(label: const Text('№')),
      DataColumn(label: const Text('Country')),
      DataColumn(label: const Text('Name')),
      DataColumn(
        label: Row(children: [
          Icon(Icons.star, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 4),
          Text('Score'),
        ]),
        tooltip: 'Custom score: Olympics 1st*100 + 2nd*20 + 3rd*10 + WC 1st*40 + 2nd*10 + 3rd*5 + WorldCup 1st*5 + 2nd*2 + 3rd*1 + Big Globe 1st*120 + 2nd*20 + 3rd*10 + Small Globe 1st*15 + 2nd*3 + 3rd*2',
        onSort: (i, _) => _onSort(i, (a) => _getScore(a, overallStandings, smallGlobe)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Gold medals (1st place) in World Cup',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Silver medals (2nd place) in World Cup',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Bronze medals (3rd place) in World Cup',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'worldCup', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Total medals in World Cup',
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'worldCup')),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Gold medals (1st place) in World Championships',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Silver medals (2nd place) in World Championships',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Bronze medals (3rd place) in World Championships',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'wc', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Total medals in World Championships',
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'wc')),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Gold medals (1st place) in Olympics',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Silver medals (2nd place) in Olympics',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Bronze medals (3rd place) in Olympics',
        onSort: (i, _) => _onSort(i, (a) => _getStat(a, 'olympics', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Total medals in Olympics',
        onSort: (i, _) => _onSort(i, (a) => _getTotal(a, 'olympics')),
      ),
      DataColumn(label: Row(children:[Icon(Icons.emoji_events, color: Colors.blue, size: 18), Text(' Big Globe 1st')]), tooltip: 'Seasons won by points'),
      DataColumn(label: Row(children:[Icon(Icons.emoji_events, color: Colors.grey, size: 18), Text(' Big Globe 2nd')]), tooltip: 'Seasons 2nd by points'),
      DataColumn(label: Row(children:[Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 18), Text(' Big Globe 3rd')]), tooltip: 'Seasons 3rd by points'),
      DataColumn(label: Row(children:[Icon(Icons.sports_martial_arts, color: Colors.lightBlue, size: 18), Text(' Small Globe 1st')]), tooltip: 'Discipline seasons won (sum of all disciplines)'),
      DataColumn(label: Row(children:[Icon(Icons.sports_martial_arts, color: Colors.grey, size: 18), Text(' Small Globe 2nd')]), tooltip: 'Discipline seasons 2nd (sum of all disciplines)'),
      DataColumn(label: Row(children:[Icon(Icons.sports_martial_arts, color: Color(0xFFCD7F32), size: 18), Text(' Small Globe 3rd')]), tooltip: 'Discipline seasons 3rd (sum of all disciplines)'),
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
            final isPlayer = athlete.name == player.name && athlete.surname == player.surname && athlete.country == player.country;
            final key = '${athlete.name}|${athlete.surname}|${athlete.country}';
            return DataRow(
              color: isPlayer ? MaterialStateProperty.all(Colors.yellow.withOpacity(0.2)) : null,
              cells: [
                DataCell(Text((i + 1).toString())),
                DataCell(Row(
                  children: [
                    RaceUtils.flagImage(athlete.country, size: 20),
                    const SizedBox(width: 4),
                    Text(athlete.country),
                  ],
                )),
                DataCell(Text('${athlete.name} ${athlete.surname}')),
                DataCell(Text(_getScore(athlete, overallStandings, smallGlobe).toString())),
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
                DataCell(Text((overallStandings[key]?[0] ?? 0).toString())),
                DataCell(Text((overallStandings[key]?[1] ?? 0).toString())),
                DataCell(Text((overallStandings[key]?[2] ?? 0).toString())),
                DataCell(Text((smallGlobe[key]?[0] ?? 0).toString())),
                DataCell(Text((smallGlobe[key]?[1] ?? 0).toString())),
                DataCell(Text((smallGlobe[key]?[2] ?? 0).toString())),
              ]
            );
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
        label: Row(children: [
          Icon(Icons.star, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 4),
          Text('Score'),
        ]),
        tooltip: 'Custom score: Olympics 1st*100 + 2nd*20 + 3rd*10 + WC 1st*40 + 2nd*10 + 3rd*5 + WorldCup 1st*5 + 2nd*2 + 3rd*1',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumScore(c)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Gold medals (1st place) in World Cup',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Silver medals (2nd place) in World Cup',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Bronze medals (3rd place) in World Cup',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'worldCup', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('World Cup'),
        ]),
        tooltip: 'Total medals in World Cup',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumTotal(c, 'worldCup')),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Gold medals (1st place) in World Championships',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Silver medals (2nd place) in World Championships',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Bronze medals (3rd place) in World Championships',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'wc', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('WC'),
        ]),
        tooltip: 'Total medals in World Championships',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumTotal(c, 'wc')),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Gold medals (1st place) in Olympics',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 1)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Silver medals (2nd place) in Olympics',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 2)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Bronze medals (3rd place) in Olympics',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumStat(c, 'olympics', 3)),
      ),
      DataColumn(
        label: Row(children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 20),
          Icon(Icons.military_tech, color: Colors.grey, size: 20),
          Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 4),
          Text('Olympics'),
        ]),
        tooltip: 'Total medals in Olympics',
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
      // Score column is the last column, not in stats
      if (col < countryRows.first.stats.length) {
        countryRows.sort((a, b) => _countrySortAscending
          ? a.stats[col].compareTo(b.stats[col])
          : b.stats[col].compareTo(a.stats[col]));
      } else {
        // Score column
        countryRows.sort((a, b) => _countrySortAscending
          ? _sumScore(countryAthletes[a.country]!).compareTo(_sumScore(countryAthletes[b.country]!))
          : _sumScore(countryAthletes[b.country]!).compareTo(_sumScore(countryAthletes[a.country]!)));
      }
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
              DataCell(Text(_sumScore(countryAthletes[c.country]!).toString())),
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
  int _sumScore(List<Athlete> athletes) => athletes.fold(0, (sum, a) => sum + _getScore(a, {}, {}));

  Widget _buildRecordsTab() {
    // Helper to get athlete display name
    String athleteName(Athlete a) => '${a.name} ${a.surname} (${a.country})';
    // All results
    final results = _allResults;
    // Group by athlete
    final Map<String, Athlete> keyToAthlete = {
      for (var a in _athletes) '${a.name}|${a.surname}|${a.country}': a
    };
    final Map<String, int> wins = {};
    final Map<String, int> wcWins = {};
    final Map<String, int> olympicsWins = {};
    final Map<String, int> podiums = {};
    final Map<String, int> wcPodiums = {};
    final Map<String, int> olympicsPodiums = {};
    final Map<String, int> sprintWins = {};
    final Map<String, int> pursuitWins = {};
    final Map<String, int> individualWins = {};
    final Map<String, int> massWins = {};
    // For streaks
    final Map<String, int> maxWinStreak = {};
    final Map<String, int> maxPodiumStreak = {};
    // Sort results by date for streaks
    final sortedResults = List<RacePointsResult>.from(results)..sort((a, b) => a.race.date.compareTo(b.race.date));
    // For each athlete, track current streaks
    final Map<String, int> currentWinStreak = {};
    final Map<String, int> currentPodiumStreak = {};
    DateTime? lastDate;
    for (final r in sortedResults) {
      final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
      // Wins
      if (r.place == 1) {
        wins[key] = (wins[key] ?? 0) + 1;
        if (r.race.tournament == Tournament.wc) wcWins[key] = (wcWins[key] ?? 0) + 1;
        if (r.race.tournament == Tournament.olympics) olympicsWins[key] = (olympicsWins[key] ?? 0) + 1;
        if (r.race.track.type.name == 'sprint') sprintWins[key] = (sprintWins[key] ?? 0) + 1;
        if (r.race.track.type.name == 'pursuit') pursuitWins[key] = (pursuitWins[key] ?? 0) + 1;
        if (r.race.track.type.name == 'individual') individualWins[key] = (individualWins[key] ?? 0) + 1;
        if (r.race.track.type.name == 'mass') massWins[key] = (massWins[key] ?? 0) + 1;
        // Win streak
        currentWinStreak[key] = (currentWinStreak[key] ?? 0) + 1;
        if ((maxWinStreak[key] ?? 0) < currentWinStreak[key]!) maxWinStreak[key] = currentWinStreak[key]!;
      } else {
        currentWinStreak[key] = 0;
      }
      // Podiums
      if (r.place == 1 || r.place == 2 || r.place == 3) {
        podiums[key] = (podiums[key] ?? 0) + 1;
        if (r.race.tournament == Tournament.wc) wcPodiums[key] = (wcPodiums[key] ?? 0) + 1;
        if (r.race.tournament == Tournament.olympics) olympicsPodiums[key] = (olympicsPodiums[key] ?? 0) + 1;
        // Podium streak
        currentPodiumStreak[key] = (currentPodiumStreak[key] ?? 0) + 1;
        if ((maxPodiumStreak[key] ?? 0) < currentPodiumStreak[key]!) maxPodiumStreak[key] = currentPodiumStreak[key]!;
      } else {
        currentPodiumStreak[key] = 0;
      }
    }
    // Helper to get max entries (all with max value)
    List<MapEntry<String, int>> maxEntries(Map<String, int> map) {
      if (map.isEmpty) return [];
      final maxValue = map.values.fold<int>(0, (prev, v) => v > prev ? v : prev);
      return map.entries.where((e) => e.value == maxValue).toList();
    }
    Widget recordRowMulti(String label, Map<String, int> map) {
      final entries = maxEntries(map);
      if (entries.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Text('-', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: entries.map((entry) {
                final athlete = keyToAthlete[entry.key];
                if (athlete == null) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RaceUtils.flagImage(athlete.country, size: 18),
                    const SizedBox(width: 4),
                    Text('${athlete.name} ${athlete.surname}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Text('(${athlete.country})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      );
    }
    // --- Most Wins at Place ---
    // Group all wins by (track name, country)
    final Map<String, Map<String, int>> placeToAthleteWins = {}; // key: 'name|country', value: {athleteKey: count}
    final Map<String, int> placeRaceCount = {}; // key: 'name|country', value: number of races
    for (final r in results) {
      final placeKey = '${r.race.track.name}|${r.race.track.country}';
      placeRaceCount[placeKey] = (placeRaceCount[placeKey] ?? 0) + 1;
      if (r.place == 1) {
        placeToAthleteWins.putIfAbsent(placeKey, () => {});
        final athleteKey = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
        placeToAthleteWins[placeKey]![athleteKey] = (placeToAthleteWins[placeKey]![athleteKey] ?? 0) + 1;
      }
    }
    // Get all places sorted by number of races descending
    final allPlaces = placeRaceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    Widget mostWinsAtPlaceSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Most Wins at Place', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...allPlaces.map((placeEntry) {
            final placeKey = placeEntry.key;
            final split = placeKey.split('|');
            final placeName = split[0];
            final placeCountry = split[1];
            final winsMap = placeToAthleteWins[placeKey] ?? {};
            final maxWinEntries = maxEntries(winsMap);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$placeName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(width: 8),
                      RaceUtils.flagImage(placeCountry, size: 20),
                      const SizedBox(width: 8),
                      Text('($placeCountry)', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (maxWinEntries.isNotEmpty)
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: maxWinEntries.map((entry) {
                        final athlete = keyToAthlete[entry.key];
                        if (athlete == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RaceUtils.flagImage(athlete.country, size: 18),
                            const SizedBox(width: 4),
                            Text('${athlete.name} ${athlete.surname}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Text('(${athlete.country})', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text('Wins: ${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ],
                        );
                      }).toList(),
                    )
                  else
                    const Text('-', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                recordRowMulti('Most Races Win', wins),
                recordRowMulti('Most WC Win', wcWins),
                recordRowMulti('Most Olympics Win', olympicsWins),
                recordRowMulti('Most Races Podiums', podiums),
                recordRowMulti('Most WC Podiums', wcPodiums),
                recordRowMulti('Most Olympics Podiums', olympicsPodiums),
                recordRowMulti('Most Sprint Wins', sprintWins),
                recordRowMulti('Most Pursuit Wins', pursuitWins),
                recordRowMulti('Most Individual Wins', individualWins),
                recordRowMulti('Most Mass Wins', massWins),
                recordRowMulti('Longest series of Wins', maxWinStreak),
                recordRowMulti('Longest series of Podiums', maxPodiumStreak),
                mostWinsAtPlaceSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryRow {
  final String country;
  final Widget flag;
  final List<int> stats;
  _CountryRow({required this.country, required this.flag, required this.stats});
} 