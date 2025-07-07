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

  int _getScore(Athlete athlete) {
    return _getStat(athlete, 'olympics', 1) * 100 +
           _getStat(athlete, 'olympics', 2) * 20 +
           _getStat(athlete, 'olympics', 3) * 10 +
           _getStat(athlete, 'wc', 1) * 40 +
           _getStat(athlete, 'wc', 2) * 10 +
           _getStat(athlete, 'wc', 3) * 5 +
           _getStat(athlete, 'worldCup', 1) * 5 +
           _getStat(athlete, 'worldCup', 2) * 2 +
           _getStat(athlete, 'worldCup', 3) * 1;
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
    final columns = [
      DataColumn(label: const Text('№')),
      DataColumn(label: const Text('Country')),
      DataColumn(label: const Text('Name')),
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
      DataColumn(
        label: Row(children: [
          Icon(Icons.star, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 4),
          Text('Score'),
        ]),
        tooltip: 'Custom score: Olympics 1st*100 + 2nd*20 + 3rd*10 + WC 1st*40 + 2nd*10 + 3rd*5 + WorldCup 1st*5 + 2nd*2 + 3rd*1',
        onSort: (i, _) => _onSort(i, (a) => _getScore(a)),
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
            final isPlayer = athlete.name == player.name && athlete.surname == player.surname && athlete.country == player.country;
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
                DataCell(Text(_getScore(athlete).toString())),
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
      DataColumn(
        label: Row(children: [
          Icon(Icons.star, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 4),
          Text('Score'),
        ]),
        tooltip: 'Custom score: Olympics 1st*100 + 2nd*20 + 3rd*10 + WC 1st*40 + 2nd*10 + 3rd*5 + WorldCup 1st*5 + 2nd*2 + 3rd*1',
        onSort: (i, _) => _onCountrySort(i, (c) => _sumScore(c)),
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
  int _sumScore(List<Athlete> athletes) => athletes.fold(0, (sum, a) => sum + _getScore(a));

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
    // Helper to get max entry
    MapEntry<String, int>? maxEntry(Map<String, int> map) {
      if (map.isEmpty) return null;
      return map.entries.reduce((a, b) => a.value >= b.value ? a : b);
    }
    Widget recordRow(String label, Map<String, int> map) {
      final entry = maxEntry(map);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (entry != null)
              Text('${athleteName(keyToAthlete[entry.key] ?? _athletes.firstWhere((a) => "${a.name}|${a.surname}|${a.country}" == entry.key, orElse: () => _athletes.first))}: ${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (entry == null)
              const Text('-', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              recordRow('Most Races Win', wins),
              recordRow('Most WC Win', wcWins),
              recordRow('Most Olympics Win', olympicsWins),
              recordRow('Most Races Podiums', podiums),
              recordRow('Most WC Podiums', wcPodiums),
              recordRow('Most Olympics Podiums', olympicsPodiums),
              recordRow('Most Sprint Wins', sprintWins),
              recordRow('Most Pursuit Wins', pursuitWins),
              recordRow('Most Individual Wins', individualWins),
              recordRow('Most Mass Wins', massWins),
              recordRow('Longest series of Wins', maxWinStreak),
              recordRow('Longest series of Podiums', maxPodiumStreak),
            ],
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