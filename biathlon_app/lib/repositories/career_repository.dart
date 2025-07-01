import '../models/career.dart';
import '../models/athlete.dart';
import '../models/race_points_result.dart';
import '../services/athlete_loader.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

abstract class CareerRepository {
  Future<Career> createCareer(Athlete player);
  Future<void> saveCareer(Career career);
  Future<Career?> loadCareer();
  Future<void> addRaceResult(Career career, RacePointsResult result);
  Future<void> addFullRaceResults(Career career, List<RacePointsResult> results);
  List<Athlete> getAllPredefinedAthletes();

  // New methods for named saves
  Future<void> saveCareerAs(Career career, String name);
  Future<Career?> loadCareerByName(String name);
  Future<List<String>> listSaves();
  Future<void> deleteSave(String name);
}

class CareerRepositoryImpl implements CareerRepository {
  Career? _currentCareer;

  static const String _savePrefix = 'career_save_';
  static const String _saveExtension = '.json';

  Future<Directory> get _savesDir async {
    final dir = await getApplicationDocumentsDirectory();
    final savesDir = Directory('${dir.path}/saves');
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    return savesDir;
  }

  Future<File> _getSaveFile(String name) async {
    final dir = await _savesDir;
    return File('${dir.path}/$_savePrefix$name$_saveExtension');
  }

  Future<List<String>> listSaves() async {
    final dir = await _savesDir;
    final files = dir.listSync().whereType<File>().toList();
    return files
        .where((f) => f.path.endsWith(_saveExtension))
        .map((f) => f.uri.pathSegments.last
            .replaceAll(_savePrefix, '')
            .replaceAll(_saveExtension, ''))
        .toList();
  }

  Future<void> deleteSave(String name) async {
    final file = await _getSaveFile(name);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> saveCareerAs(Career career, String name) async {
    final file = await _getSaveFile(name);
    await file.writeAsString(jsonEncode(career.toJson()));
    _currentCareer = career;
  }

  Future<Career?> loadCareerByName(String name) async {
    final file = await _getSaveFile(name);
    if (await file.exists()) {
      final jsonStr = await file.readAsString();
      final jsonMap = jsonDecode(jsonStr);
      final career = Career.fromJson(jsonMap);
      _currentCareer = career;
      return career;
    }
    return null;
  }

  /// Returns all predefined athletes dynamically loaded from yearly files
  List<Athlete> getAllPredefinedAthletes() {
    return loadAllPredefinedAthletes();
  }

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
    // Default save (could use a default name or last used)
    await saveCareerAs(career, 'autosave');
  }

  @override
  Future<Career?> loadCareer() async {
    // Default load (could use a default name or last used)
    return loadCareerByName('autosave');
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