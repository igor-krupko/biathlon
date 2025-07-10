import 'package:flutter/material.dart';
import '../models/career.dart';
import '../models/season.dart';
import '../models/athlete.dart';
import '../utils/race_utils.dart';
import '../services/athlete_loader.dart';
import '../models/race_points_result.dart';
import '../models/track_type.dart';
import '../models/race.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class RaceDemoPresentation extends StatefulWidget {
  final Career career;
  final Season currentSeason;
  const RaceDemoPresentation({Key? key, required this.career, required this.currentSeason}) : super(key: key);

  @override
  State<RaceDemoPresentation> createState() => _RaceDemoPresentationState();
}

class _RaceDemoPresentationState extends State<RaceDemoPresentation> {
  late List<_AthleteRegalia> _topAthletes;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final top10 = _getTop10AthletesWithRegalia();
    // Reverse order: 10 to 1
    _topAthletes = List<_AthleteRegalia>.from(top10.reversed);
  }

  List<_AthleteRegalia> _getTop10AthletesWithRegalia() {
    // Aggregate points for current season
    final seasonStart = DateTime(widget.currentSeason.year, 6, 1);
    final seasonEnd = DateTime(widget.currentSeason.year + 1, 6, 1);
    final seasonResults = widget.career.allRacesResults.expand((x) => x)
      .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
      .toList();
    final Map<String, int> athletePoints = {};
    for (final r in seasonResults) {
      final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
      athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
    }
    final sorted = athletePoints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10Keys = sorted.take(10).map((e) => e.key).toList();
    // Always include player if not in top 10
    final playerKey = '${widget.career.player.name}|${widget.career.player.surname}|${widget.career.player.country}';
    if (!top10Keys.contains(playerKey)) {
      top10Keys[9] = playerKey;
    }
    // Map key to Athlete
    final Map<String, Athlete> keyToAthlete = {
      for (var a in loadAllPredefinedAthletes()) '${a.name}|${a.surname}|${a.country}': a
    };
    // Compute regalia for each
    return top10Keys.map((key) {
      final athlete = keyToAthlete[key] ?? widget.career.player;
      final regalia = _calculateRegalia(athlete);
      final rank = sorted.indexWhere((e) => e.key == key) + 1;
      return _AthleteRegalia(athlete: athlete, regalia: regalia, rank: rank);
    }).toList();
  }

  _Regalia _calculateRegalia(Athlete athlete) {
    final allRacesResults = widget.career.allRacesResults;
    final seasons = widget.career.seasons.where((s) => s.year <= widget.currentSeason.year).toList();
    final completedSeasons = _completedSeasons(seasons, allRacesResults);
    final allResults = allRacesResults.expand((x) => x).toList();
    final key = '${athlete.name}|${athlete.surname}|${athlete.country}';
    final overallStandings = _calculateSeasonStandings(completedSeasons, allRacesResults);
    final sprintStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.sprint);
    final pursuitStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.pursuit);
    final massStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.mass);
    final individualStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.individual);
    Map<String, List<int>> smallGlobe = {};
    for (final k in {...sprintStandings.keys, ...pursuitStandings.keys, ...massStandings.keys, ...individualStandings.keys}) {
      smallGlobe[k] = [
        (sprintStandings[k]?[0] ?? 0) + (pursuitStandings[k]?[0] ?? 0) + (massStandings[k]?[0] ?? 0) + (individualStandings[k]?[0] ?? 0),
        (sprintStandings[k]?[1] ?? 0) + (pursuitStandings[k]?[1] ?? 0) + (massStandings[k]?[1] ?? 0) + (individualStandings[k]?[1] ?? 0),
        (sprintStandings[k]?[2] ?? 0) + (pursuitStandings[k]?[2] ?? 0) + (massStandings[k]?[2] ?? 0) + (individualStandings[k]?[2] ?? 0),
      ];
    }
    int getStat(String tournament, int place) {
      return allResults.where((result) =>
        result.athlete.name == athlete.name &&
        result.athlete.surname == athlete.surname &&
        result.athlete.country == athlete.country &&
        _tournamentToString(result.race.tournament) == tournament &&
        result.place == place
      ).length;
    }
    int getTotal(String tournament) {
      return allResults.where((result) =>
        result.athlete.name == athlete.name &&
        result.athlete.surname == athlete.surname &&
        result.athlete.country == athlete.country &&
        _tournamentToString(result.race.tournament) == tournament &&
        (result.place == 1 || result.place == 2 || result.place == 3)
      ).length;
    }
    return _Regalia(
      bigGlobe: overallStandings[key]?[0] ?? 0,
      smallGlobe: smallGlobe[key]?[0] ?? 0,
      olympicsGold: getStat('olympics', 1),
      olympicsSilver: getStat('olympics', 2),
      olympicsBronze: getStat('olympics', 3),
      worldGold: getStat('wc', 1),
      worldSilver: getStat('wc', 2),
      worldBronze: getStat('wc', 3),
      raceWinner: getStat('worldCup', 1),
      raceSilver: getStat('worldCup', 2),
      raceBronze: getStat('worldCup', 3),
      raceMedalist: getTotal('worldCup'),
    );
  }

  // Helper functions from AthletesScreen
  Map<String, List<int>> _calculateSeasonStandings(List<Season> seasons, List<List<RacePointsResult>> allRacesResults, {TrackType? discipline}) {
    final Map<String, List<int>> standings = {};
    for (final season in seasons) {
      final seasonStart = DateTime(season.year, 6, 1);
      final seasonEnd = DateTime(season.year + 1, 6, 1);
      final seasonResults = allRacesResults.expand((x) => x)
        .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
        .where((r) => discipline == null || r.race.track.type == discipline)
        .toList();
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

  List<Season> _completedSeasons(List<Season> seasons, List<List<RacePointsResult>> allRacesResults) {
    final allResultsFlat = allRacesResults.expand((x) => x).toList();
    return seasons.where((season) {
      final raceIds = season.races.map((r) => r.id).toSet();
      final resultRaceIds = allResultsFlat.map((r) => r.race.id).toSet();
      return raceIds.difference(resultRaceIds).isEmpty && raceIds.isNotEmpty;
    }).toList();
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

  void _onNext() {
    if (_currentIndex < _topAthletes.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _onSkip() {
    Navigator.of(context).pop(true);
  }

  TrackType? get _currentDiscipline {
    final race = widget.career.currentRace;
    if (race == null) return null;
    return race.track.type;
  }

  int _getScore(Athlete athlete) {
    // Copy of _getScore from AthletesScreen
    final allRacesResults = widget.career.allRacesResults;
    final seasons = widget.career.seasons.where((s) => s.year <= widget.currentSeason.year).toList();
    final completedSeasons = _completedSeasons(seasons, allRacesResults);
    final overallStandings = _calculateSeasonStandings(completedSeasons, allRacesResults);
    final sprintStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.sprint);
    final pursuitStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.pursuit);
    final massStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.mass);
    final individualStandings = _calculateSeasonStandings(completedSeasons, allRacesResults, discipline: TrackType.individual);
    Map<String, List<int>> smallGlobe = {};
    for (final key in {...sprintStandings.keys, ...pursuitStandings.keys, ...massStandings.keys, ...individualStandings.keys}) {
      smallGlobe[key] = [
        (sprintStandings[key]?[0] ?? 0) + (pursuitStandings[key]?[0] ?? 0) + (massStandings[key]?[0] ?? 0) + (individualStandings[key]?[0] ?? 0),
        (sprintStandings[key]?[1] ?? 0) + (pursuitStandings[key]?[1] ?? 0) + (massStandings[key]?[1] ?? 0) + (individualStandings[key]?[1] ?? 0),
        (sprintStandings[key]?[2] ?? 0) + (pursuitStandings[key]?[2] ?? 0) + (massStandings[key]?[2] ?? 0) + (individualStandings[key]?[2] ?? 0),
      ];
    }
    String key = '${athlete.name}|${athlete.surname}|${athlete.country}';
    int score = 0;
    int getStat(String tournament, int place) {
      final allResults = allRacesResults.expand((x) => x).toList();
      return allResults.where((result) =>
        result.athlete.name == athlete.name &&
        result.athlete.surname == athlete.surname &&
        result.athlete.country == athlete.country &&
        _tournamentToString(result.race.tournament) == tournament &&
        result.place == place
      ).length;
    }
    score += getStat('olympics', 1) * 100;
    score += getStat('olympics', 2) * 20;
    score += getStat('olympics', 3) * 10;
    score += getStat('wc', 1) * 40;
    score += getStat('wc', 2) * 10;
    score += getStat('wc', 3) * 5;
    score += getStat('worldCup', 1) * 5;
    score += getStat('worldCup', 2) * 2;
    score += getStat('worldCup', 3) * 1;
    score += (overallStandings[key]?[0] ?? 0) * 120;
    score += (overallStandings[key]?[1] ?? 0) * 20;
    score += (overallStandings[key]?[2] ?? 0) * 10;
    score += (smallGlobe[key]?[0] ?? 0) * 15;
    score += (smallGlobe[key]?[1] ?? 0) * 3;
    score += (smallGlobe[key]?[2] ?? 0) * 2;
    return score;
  }

  String? _getTshirtAsset(Athlete athlete, int rank, Map<String, int> disciplineLeaders) {
    // Yellow: 1st overall
    if (rank == 1) return 'assets/icons/tshirt_yellow.png';
    // Red: 1st in discipline (but not overall)
    final key = '${athlete.name}|${athlete.surname}|${athlete.country}';
    if (disciplineLeaders.containsKey(key) && disciplineLeaders[key] == 1) {
      return 'assets/icons/tshirt_red.png';
    }
    // Default
    return 'assets/icons/tshirt.png';
  }

  Map<String, int> _getDisciplineLeaders(TrackType? discipline) {
    if (discipline == null) return {};
    // Aggregate points for current season and discipline
    final seasonStart = DateTime(widget.currentSeason.year, 6, 1);
    final seasonEnd = DateTime(widget.currentSeason.year + 1, 6, 1);
    final seasonResults = widget.career.allRacesResults.expand((x) => x)
      .where((r) => r.race.date.isAfter(seasonStart) && r.race.date.isBefore(seasonEnd))
      .where((r) => r.race.track.type == discipline)
      .toList();
    final Map<String, int> athletePoints = {};
    for (final r in seasonResults) {
      final key = '${r.athlete.name}|${r.athlete.surname}|${r.athlete.country}';
      athletePoints[key] = (athletePoints[key] ?? 0) + r.points;
    }
    final sorted = athletePoints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final Map<String, int> leaders = {};
    for (int i = 0; i < sorted.length; i++) {
      leaders[sorted[i].key] = i + 1;
    }
    return leaders;
  }

  @override
  Widget build(BuildContext context) {
    final athleteRegalia = _topAthletes[_currentIndex];
    final discipline = _currentDiscipline;
    final disciplineLeaders = _getDisciplineLeaders(discipline);
    final rating = _getScore(athleteRegalia.athlete);
    final tshirtAsset = _getTshirtAsset(athleteRegalia.athlete, athleteRegalia.rank, disciplineLeaders) ?? 'assets/icons/tshirt.png';
    final flagAsset = RaceUtils.countryToFlagAsset(athleteRegalia.athlete.country);
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).dialogBackgroundColor,
            child: Stack(
              children: [
                // Flag as background, more transparent
                if (flagAsset.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.25,
                      child: Image.asset(
                        flagAsset,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // T-shirt inside white box
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(18),
                              child: _TshirtWithRatingWidget(
                                asset: tshirtAsset,
                                position: athleteRegalia.rank,
                                sizeFactor: 0.32, // slightly smaller
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Athlete info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Country name above name/surname
                                  Text(
                                    athleteRegalia.athlete.country,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 22,
                                      color: Colors.grey[700],
                                      letterSpacing: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Name (nicer font)
                                  Text(
                                    '${athleteRegalia.athlete.name} ${athleteRegalia.athlete.surname}',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 54,
                                      letterSpacing: 1.2,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  // Major regalia
                                  _MajorRegaliaText(regalia: athleteRegalia.regalia),
                                  const SizedBox(height: 36),
                                  _RegaliaCardsWidget(regalia: athleteRegalia.regalia),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _onSkip,
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: _onNext,
                          child: Text(_currentIndex < _topAthletes.length - 1 ? 'Next' : 'Start Race'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 32),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AthleteRegalia {
  final Athlete athlete;
  final _Regalia regalia;
  final int rank;
  _AthleteRegalia({required this.athlete, required this.regalia, required this.rank});
}

class _Regalia {
  final int bigGlobe;
  final int smallGlobe;
  final int olympicsGold;
  final int olympicsSilver;
  final int olympicsBronze;
  final int worldGold;
  final int worldSilver;
  final int worldBronze;
  final int raceWinner;
  final int raceSilver;
  final int raceBronze;
  final int raceMedalist;
  _Regalia({
    required this.bigGlobe,
    required this.smallGlobe,
    required this.olympicsGold,
    required this.olympicsSilver,
    required this.olympicsBronze,
    required this.worldGold,
    required this.worldSilver,
    required this.worldBronze,
    required this.raceWinner,
    required this.raceSilver,
    required this.raceBronze,
    required this.raceMedalist,
  });
}

// Add T-shirt with rating widget
class _TshirtWithRatingWidget extends StatelessWidget {
  final String asset;
  final int position;
  final double sizeFactor; // fraction of screen height
  const _TshirtWithRatingWidget({required this.asset, required this.position, this.sizeFactor = 0.5});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * sizeFactor;
    final width = height * 0.75;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(asset, width: width, height: width, fit: BoxFit.contain),
          Positioned(
            top: width * 0.58,
            left: width * 0.28,
            right: width * 0.28,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 44,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add new widget for regalia cards
class _RegaliaCardsWidget extends StatelessWidget {
  final _Regalia regalia;
  const _RegaliaCardsWidget({Key? key, required this.regalia}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final olympicsTotal = regalia.olympicsGold + regalia.olympicsSilver + regalia.olympicsBronze;
    final worldTotal = regalia.worldGold + regalia.worldSilver + regalia.worldBronze;
    final bigGlobesTotal = regalia.bigGlobe;
    final smallGlobesTotal = regalia.smallGlobe;
    final wcTotal = regalia.raceWinner + regalia.raceSilver + regalia.raceBronze;
    final hasAnyGlobe = bigGlobesTotal > 0 || smallGlobesTotal > 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(
            title: 'Olympics',
            icon: Image.asset('assets/icons/olympic_rings.png', width: 36, height: 36),
            children: [
              if (regalia.olympicsGold > 0) _medalRow('🥇', regalia.olympicsGold),
              if (regalia.olympicsSilver > 0) _medalRow('🥈', regalia.olympicsSilver),
              if (regalia.olympicsBronze > 0) _medalRow('🥉', regalia.olympicsBronze),
              if (olympicsTotal > 0) _totalRow(olympicsTotal),
              if (olympicsTotal == 0) const Text('No medals', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 16),
          if (hasAnyGlobe) ...[
            _StatCard(
              title: 'Big Globes',
              icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
              children: [
                Text('🏆 $bigGlobesTotal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Small Globes',
              icon: const Icon(Icons.sports_martial_arts, color: Colors.lightBlue, size: 36),
              children: [
                Text('🏆 $smallGlobesTotal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
          ] else ...[
            _StatCard(
              title: 'Globes',
              icon: const Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 36),
              children: [
                const Text('No regalia', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          _StatCard(
            title: 'World Champs',
            icon: const Icon(Icons.emoji_events, color: Colors.blueGrey, size: 36),
            children: [
              if (regalia.worldGold > 0) _medalRow('🥇', regalia.worldGold),
              if (regalia.worldSilver > 0) _medalRow('🥈', regalia.worldSilver),
              if (regalia.worldBronze > 0) _medalRow('🥉', regalia.worldBronze),
              if (worldTotal > 0) _totalRow(worldTotal),
              if (worldTotal == 0) const Text('No medals', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 16),
          _StatCard(
            title: 'World Cup',
            icon: const Icon(Icons.flag, color: Colors.deepOrange, size: 36),
            children: [
              if (regalia.raceWinner > 0) _medalRow('🥇', regalia.raceWinner),
              if (regalia.raceSilver > 0) _medalRow('🥈', regalia.raceSilver),
              if (regalia.raceBronze > 0) _medalRow('🥉', regalia.raceBronze),
              if (wcTotal > 0) _totalRow(wcTotal),
              if (wcTotal == 0) const Text('No medals', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medalRow(String emoji, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _totalRow(int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text('Total: $total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Widget> children;
  const _StatCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Add major regalia text widget
class _MajorRegaliaText extends StatelessWidget {
  final _Regalia regalia;
  const _MajorRegaliaText({required this.regalia});

  @override
  Widget build(BuildContext context) {
    final List<String> lines = [];
    if (regalia.olympicsGold > 0) {
      lines.add('${regalia.olympicsGold} Olympics Champion');
    }
    if (regalia.worldGold > 0) {
      lines.add('${regalia.worldGold} World Champion');
    }
    if (regalia.bigGlobe > 0) {
      lines.add('${regalia.bigGlobe} Big Globe Winner');
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: lines.map((line) => Text(
        line,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
          letterSpacing: 1.1,
        ),
        textAlign: TextAlign.center,
      )).toList(),
    );
  }
} 