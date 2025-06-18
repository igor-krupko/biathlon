import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';

// Events
abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAudio extends AudioEvent {}

class PlayShootingSound extends AudioEvent {}

class PlayHitSound extends AudioEvent {}

class PlayMissSound extends AudioEvent {}

class PlayPerfectRoundSound extends AudioEvent {}

class PlayBackgroundAmbience extends AudioEvent {}

class StopBackgroundAmbience extends AudioEvent {}

class UpdateAudioSettings extends AudioEvent {
  final bool soundEnabled;
  final bool shootingSoundEnabled;
  final bool crowdSoundEnabled;
  final bool backgroundSoundEnabled;

  const UpdateAudioSettings({
    required this.soundEnabled,
    required this.shootingSoundEnabled,
    required this.crowdSoundEnabled,
    required this.backgroundSoundEnabled,
  });

  @override
  List<Object?> get props => [soundEnabled, shootingSoundEnabled, crowdSoundEnabled, backgroundSoundEnabled];
}

// States
abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioReady extends AudioState {
  final bool soundEnabled;
  final bool shootingSoundEnabled;
  final bool crowdSoundEnabled;
  final bool backgroundSoundEnabled;
  final bool isBackgroundPlaying;

  const AudioReady({
    required this.soundEnabled,
    required this.shootingSoundEnabled,
    required this.crowdSoundEnabled,
    required this.backgroundSoundEnabled,
    required this.isBackgroundPlaying,
  });

  @override
  List<Object?> get props => [
        soundEnabled,
        shootingSoundEnabled,
        crowdSoundEnabled,
        backgroundSoundEnabled,
        isBackgroundPlaying,
      ];

  AudioReady copyWith({
    bool? soundEnabled,
    bool? shootingSoundEnabled,
    bool? crowdSoundEnabled,
    bool? backgroundSoundEnabled,
    bool? isBackgroundPlaying,
  }) {
    return AudioReady(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      shootingSoundEnabled: shootingSoundEnabled ?? this.shootingSoundEnabled,
      crowdSoundEnabled: crowdSoundEnabled ?? this.crowdSoundEnabled,
      backgroundSoundEnabled: backgroundSoundEnabled ?? this.backgroundSoundEnabled,
      isBackgroundPlaying: isBackgroundPlaying ?? this.isBackgroundPlaying,
    );
  }
}

class AudioError extends AudioState {
  final String message;

  const AudioError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioService _audioService;
  final SettingsService _settingsService;

  AudioBloc({
    AudioService? audioService,
    SettingsService? settingsService,
  }) : _audioService = audioService ?? AudioService(),
       _settingsService = settingsService ?? SettingsService(),
       super(AudioInitial()) {
    on<InitializeAudio>(_onInitializeAudio);
    on<PlayShootingSound>(_onPlayShootingSound);
    on<PlayHitSound>(_onPlayHitSound);
    on<PlayMissSound>(_onPlayMissSound);
    on<PlayPerfectRoundSound>(_onPlayPerfectRoundSound);
    on<PlayBackgroundAmbience>(_onPlayBackgroundAmbience);
    on<StopBackgroundAmbience>(_onStopBackgroundAmbience);
    on<UpdateAudioSettings>(_onUpdateAudioSettings);
  }

  void _onInitializeAudio(InitializeAudio event, Emitter<AudioState> emit) async {
    emit(AudioLoading());
    
    try {
      await _settingsService.initialize();
      await _audioService.initialize();
      
      emit(AudioReady(
        soundEnabled: _settingsService.soundEnabled,
        shootingSoundEnabled: _settingsService.shootingSoundEnabled,
        crowdSoundEnabled: _settingsService.crowdSoundEnabled,
        backgroundSoundEnabled: _settingsService.backgroundSoundEnabled,
        isBackgroundPlaying: false,
      ));
    } catch (e) {
      emit(AudioError('Failed to initialize audio: $e'));
    }
  }

  void _onPlayShootingSound(PlayShootingSound event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      if (currentState.soundEnabled && currentState.shootingSoundEnabled) {
        try {
          await _audioService.playShootingSound();
        } catch (e) {
          emit(AudioError('Failed to play shooting sound: $e'));
        }
      }
    }
  }

  void _onPlayHitSound(PlayHitSound event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      if (currentState.soundEnabled && currentState.crowdSoundEnabled) {
        try {
          await _audioService.playHitSound();
        } catch (e) {
          emit(AudioError('Failed to play hit sound: $e'));
        }
      }
    }
  }

  void _onPlayMissSound(PlayMissSound event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      if (currentState.soundEnabled && currentState.crowdSoundEnabled) {
        try {
          await _audioService.playMissSound();
        } catch (e) {
          emit(AudioError('Failed to play miss sound: $e'));
        }
      }
    }
  }

  void _onPlayPerfectRoundSound(PlayPerfectRoundSound event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      if (currentState.soundEnabled && currentState.crowdSoundEnabled) {
        try {
          await _audioService.playPerfectRoundSound();
        } catch (e) {
          emit(AudioError('Failed to play perfect round sound: $e'));
        }
      }
    }
  }

  void _onPlayBackgroundAmbience(PlayBackgroundAmbience event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      if (currentState.soundEnabled && currentState.backgroundSoundEnabled) {
        try {
          await _audioService.playBackgroundAmbience();
          emit(currentState.copyWith(isBackgroundPlaying: true));
        } catch (e) {
          emit(AudioError('Failed to play background ambience: $e'));
        }
      }
    }
  }

  void _onStopBackgroundAmbience(StopBackgroundAmbience event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      try {
        await _audioService.stopBackgroundAmbience();
        emit(currentState.copyWith(isBackgroundPlaying: false));
      } catch (e) {
        emit(AudioError('Failed to stop background ambience: $e'));
      }
    }
  }

  void _onUpdateAudioSettings(UpdateAudioSettings event, Emitter<AudioState> emit) async {
    if (state is AudioReady) {
      final currentState = state as AudioReady;
      
      // Update settings service
      await _settingsService.setSoundEnabled(event.soundEnabled);
      await _settingsService.setShootingSoundEnabled(event.shootingSoundEnabled);
      await _settingsService.setCrowdSoundEnabled(event.crowdSoundEnabled);
      await _settingsService.setBackgroundSoundEnabled(event.backgroundSoundEnabled);
      
      // Stop background music if disabled
      if (!event.backgroundSoundEnabled && currentState.isBackgroundPlaying) {
        await _audioService.stopBackgroundAmbience();
      }
      
      emit(currentState.copyWith(
        soundEnabled: event.soundEnabled,
        shootingSoundEnabled: event.shootingSoundEnabled,
        crowdSoundEnabled: event.crowdSoundEnabled,
        backgroundSoundEnabled: event.backgroundSoundEnabled,
        isBackgroundPlaying: event.backgroundSoundEnabled && currentState.isBackgroundPlaying,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _audioService.dispose();
    return super.close();
  }
} 