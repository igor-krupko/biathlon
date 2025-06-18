import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _shootingSoundEnabledKey = 'shooting_sound_enabled';
  static const String _crowdSoundEnabledKey = 'crowd_sound_enabled';
  static const String _backgroundSoundEnabledKey = 'background_sound_enabled';
  static const String _soundVolumeKey = 'sound_volume';

  bool _soundEnabled = true;
  bool _shootingSoundEnabled = true;
  bool _crowdSoundEnabled = true;
  bool _backgroundSoundEnabled = true;
  double _soundVolume = 0.7;

  bool get soundEnabled => _soundEnabled;
  bool get shootingSoundEnabled => _shootingSoundEnabled;
  bool get crowdSoundEnabled => _crowdSoundEnabled;
  bool get backgroundSoundEnabled => _backgroundSoundEnabled;
  double get soundVolume => _soundVolume;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _shootingSoundEnabled = prefs.getBool(_shootingSoundEnabledKey) ?? true;
    _crowdSoundEnabled = prefs.getBool(_crowdSoundEnabledKey) ?? true;
    _backgroundSoundEnabled = prefs.getBool(_backgroundSoundEnabledKey) ?? true;
    _soundVolume = prefs.getDouble(_soundVolumeKey) ?? 0.7;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<void> setShootingSoundEnabled(bool enabled) async {
    _shootingSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shootingSoundEnabledKey, enabled);
  }

  Future<void> setCrowdSoundEnabled(bool enabled) async {
    _crowdSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crowdSoundEnabledKey, enabled);
  }

  Future<void> setBackgroundSoundEnabled(bool enabled) async {
    _backgroundSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundSoundEnabledKey, enabled);
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_soundVolumeKey, _soundVolume);
  }
} 