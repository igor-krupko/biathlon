import '../models/career.dart';
import '../models/athlete.dart';

abstract class CareerRepository {
  Future<Career> createCareer(Athlete player);
  Future<void> saveCareer(Career career);
  Future<Career?> loadCareer();
  Future<void> addRaceResult(Career career, RacePointsResult result);
  Future<void> addFullRaceResults(Career career, List<RacePointsResult> results);
}

class CareerRepositoryImpl implements CareerRepository {
  Career? _currentCareer;

  @override
  Future<Career> createCareer(Athlete player) async {
    final career = Career(
      startDate: DateTime.now(),
      player: player,
      isActive: true,
    );
    _currentCareer = career;
    await saveCareer(career);
    return career;
  }

  @override
  Future<void> saveCareer(Career career) async {
    _currentCareer = career;
    // TODO: Implement actual persistence (SharedPreferences, SQLite, etc.)
  }

  @override
  Future<Career?> loadCareer() async {
    // TODO: Implement actual loading from persistence
    return _currentCareer;
  }

  @override
  Future<void> addRaceResult(Career career, RacePointsResult result) async {
    career.addRacePointsResult(result);
    await saveCareer(career);
  }

  @override
  Future<void> addFullRaceResults(Career career, List<RacePointsResult> results) async {
    career.addFullRaceResults(results);
    await saveCareer(career);
  }
} 