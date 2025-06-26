import '../models/athlete.dart';
import '../models/athlete_season_stats.dart';
// Import all yearly athlete files
import '../data/athletes_by_year/athletes_1999.dart';
import '../data/athletes_by_year/athletes_2000.dart';
import '../data/athletes_by_year/athletes_2001.dart';
import '../data/athletes_by_year/athletes_2002.dart';
import '../data/athletes_by_year/athletes_2003.dart';
import '../data/athletes_by_year/athletes_2004.dart';
import '../data/athletes_by_year/athletes_2005.dart';
import '../data/athletes_by_year/athletes_2006.dart';
import '../data/athletes_by_year/athletes_2007.dart';
import '../data/athletes_by_year/athletes_2008.dart';
import '../data/athletes_by_year/athletes_2009.dart';
import '../data/athletes_by_year/athletes_2010.dart';
import '../data/athletes_by_year/athletes_2011.dart';
import '../data/athletes_by_year/athletes_2012.dart';
import '../data/athletes_by_year/athletes_2013.dart';
import '../data/athletes_by_year/athletes_2014.dart';
import '../data/athletes_by_year/athletes_2015.dart';
import '../data/athletes_by_year/athletes_2016.dart';
import '../data/athletes_by_year/athletes_2017.dart';
import '../data/athletes_by_year/athletes_2018.dart';
import '../data/athletes_by_year/athletes_2019.dart';
import '../data/athletes_by_year/athletes_2020.dart';
import '../data/athletes_by_year/athletes_2021.dart';
import '../data/athletes_by_year/athletes_2022.dart';
import '../data/athletes_by_year/athletes_2023.dart';
import '../data/athletes_by_year/athletes_2024.dart';

final Map<int, List<Map<String, String>>> yearlyAthletes = {
  1999: athletes1999,
  2000: athletes2000,
  2001: athletes2001,
  2002: athletes2002,
  2003: athletes2003,
  2004: athletes2004,
  2005: athletes2005,
  2006: athletes2006,
  2007: athletes2007,
  2008: athletes2008,
  2009: athletes2009,
  2010: athletes2010,
  2011: athletes2011,
  2012: athletes2012,
  2013: athletes2013,
  2014: athletes2014,
  2015: athletes2015,
  2016: athletes2016,
  2017: athletes2017,
  2018: athletes2018,
  2019: athletes2019,
  2020: athletes2020,
  2021: athletes2021,
  2022: athletes2022,
  2023: athletes2023,
  2024: athletes2024,
};

List<Athlete> loadAllPredefinedAthletes() {
  final Map<String, Athlete> athletesMap = {};
  int nextId = 1;

  for (final year in yearlyAthletes.keys) {
    for (final data in yearlyAthletes[year]!) {
      final key = '${data["name"]}|${data["surname"]}|${data["country"]}';
      final speed = int.tryParse(data["speed"] ?? "0") ?? 0;
      final shootingDown = int.tryParse(data["shootingDown"] ?? "0") ?? 0;
      final shootingStanding = int.tryParse(data["shootingStanding"] ?? "0") ?? 0;

      if (!athletesMap.containsKey(key)) {
        athletesMap[key] = Athlete(
          id: nextId++,
          name: data["name"] ?? '',
          surname: data["surname"] ?? '',
          country: data["country"] ?? '',
          speed: speed,
          shootingDown: shootingDown,
          shootingStanding: shootingStanding,
          seasonStats: {year: AthleteSeasonStats(isActive: true, speed: speed, shootingDown: shootingDown, shootingStanding: shootingStanding)},
        );
      } else {
        // Add/Update seasonStats for this year
        final athlete = athletesMap[key]!;
        athlete.seasonStats![year] = AthleteSeasonStats(isActive: true, speed: speed, shootingDown: shootingDown, shootingStanding: shootingStanding);
      }
    }
  }

  // Fill in inactive years for each athlete
  for (final athlete in athletesMap.values) {
    for (final year in yearlyAthletes.keys) {
      athlete.seasonStats!.putIfAbsent(year, () => AthleteSeasonStats(isActive: false, speed: 0, shootingDown: 0, shootingStanding: 0));
    }
  }

  return athletesMap.values.toList();
} 