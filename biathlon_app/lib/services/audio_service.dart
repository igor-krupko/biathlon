import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _shootingPlayer;
  late AudioPlayer _crowdPlayer;
  late AudioPlayer _backgroundPlayer;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _shootingPlayer = AudioPlayer();
    _crowdPlayer = AudioPlayer();
    _backgroundPlayer = AudioPlayer();
    
    _isInitialized = true;
  }

  Future<void> playShootingSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _shootingPlayer.play(AssetSource('audio/shooting_sound.wav'));
    } catch (e) {
      // Fallback: play a simple beep sound if file not found
      print('Could not play shooting sound: $e');
      // For now, we'll just log the error since we don't have actual audio files
    }
  }

  Future<void> playHitSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _crowdPlayer.play(AssetSource('audio/crowd_hit.wav'));
    } catch (e) {
      // Fallback: play a success sound
      print('Could not play hit sound: $e');
      // For now, we'll just log the error since we don't have actual audio files
    }
  }

  Future<void> playMissSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _crowdPlayer.play(AssetSource('audio/crowd_miss.wav'));
    } catch (e) {
      // Fallback: play a failure sound
      print('Could not play miss sound: $e');
      // For now, we'll just log the error since we don't have actual audio files
    }
  }

  Future<void> playPerfectRoundSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _crowdPlayer.play(AssetSource('audio/crowd_perfect.wav'));
    } catch (e) {
      print('Could not play perfect round sound: $e');
      // For now, we'll just log the error since we don't have actual audio files
    }
  }

  Future<void> playBackgroundAmbience() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _backgroundPlayer.play(AssetSource('audio/background_ambience.wav'));
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Could not play background ambience: $e');
      // For now, we'll just log the error since we don't have actual audio files
    }
  }

  Future<void> stopBackgroundAmbience() async {
    if (!_isInitialized) return;
    
    await _backgroundPlayer.stop();
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    await _shootingPlayer.dispose();
    await _crowdPlayer.dispose();
    await _backgroundPlayer.dispose();
    _isInitialized = false;
  }
} 