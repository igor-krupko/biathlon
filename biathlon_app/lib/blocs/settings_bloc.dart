import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/settings_service.dart';
import 'base_bloc.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateDifficulty extends SettingsEvent {
  final GameDifficulty difficulty;

  const UpdateDifficulty(this.difficulty);

  @override
  List<Object?> get props => [difficulty];
}

class UpdateSoundEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateSoundEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateVibrationEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateVibrationEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateShootingSoundEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateShootingSoundEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateCrowdSoundEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateCrowdSoundEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateBackgroundSoundEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateBackgroundSoundEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateSoundVolume extends SettingsEvent {
  final double volume;

  const UpdateSoundVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class ResetSettings extends SettingsEvent {}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final GameSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];

  SettingsLoaded copyWith({
    GameSettings? settings,
  }) {
    return SettingsLoaded(settings ?? this.settings);
  }
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Data classes
class GameSettings {
  final GameDifficulty difficulty;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String language;
  final bool shootingSoundEnabled;
  final bool crowdSoundEnabled;
  final bool backgroundSoundEnabled;
  final double soundVolume;

  const GameSettings({
    this.difficulty = GameDifficulty.medium,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.language = 'en',
    this.shootingSoundEnabled = true,
    this.crowdSoundEnabled = true,
    this.backgroundSoundEnabled = true,
    this.soundVolume = 0.7,
  });

  List<Object?> get props => [
        difficulty,
        soundEnabled,
        vibrationEnabled,
        language,
        shootingSoundEnabled,
        crowdSoundEnabled,
        backgroundSoundEnabled,
        soundVolume,
      ];

  GameSettings copyWith({
    GameDifficulty? difficulty,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? language,
    bool? shootingSoundEnabled,
    bool? crowdSoundEnabled,
    bool? backgroundSoundEnabled,
    double? soundVolume,
  }) {
    return GameSettings(
      difficulty: difficulty ?? this.difficulty,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
      shootingSoundEnabled: shootingSoundEnabled ?? this.shootingSoundEnabled,
      crowdSoundEnabled: crowdSoundEnabled ?? this.crowdSoundEnabled,
      backgroundSoundEnabled: backgroundSoundEnabled ?? this.backgroundSoundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }
}

enum GameDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
      case GameDifficulty.expert:
        return 'Expert';
    }
  }
}

// BLoC
class SettingsBloc extends BaseBloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService(),
        super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateDifficulty>(_onUpdateDifficulty);
    on<UpdateSoundEnabled>(_onUpdateSoundEnabled);
    on<UpdateVibrationEnabled>(_onUpdateVibrationEnabled);
    on<UpdateShootingSoundEnabled>(_onUpdateShootingSoundEnabled);
    on<UpdateCrowdSoundEnabled>(_onUpdateCrowdSoundEnabled);
    on<UpdateBackgroundSoundEnabled>(_onUpdateBackgroundSoundEnabled);
    on<UpdateSoundVolume>(_onUpdateSoundVolume);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    
    await safeAsync(
      () async {
        await _settingsService.initialize();
        
        final settings = GameSettings(
          soundEnabled: _settingsService.soundEnabled,
          shootingSoundEnabled: _settingsService.shootingSoundEnabled,
          crowdSoundEnabled: _settingsService.crowdSoundEnabled,
          backgroundSoundEnabled: _settingsService.backgroundSoundEnabled,
          soundVolume: _settingsService.soundVolume,
        );
        
        emit(SettingsLoaded(settings));
      },
      (error) => emit(SettingsError('Failed to load settings: $error')),
    );
  }

  Future<void> _onUpdateDifficulty(UpdateDifficulty event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(difficulty: event.difficulty);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        // TODO: Implement saving difficulty to storage
      },
      (error) => emit(SettingsError('Failed to update difficulty: $error')),
    );
  }

  Future<void> _onUpdateSoundEnabled(UpdateSoundEnabled event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(soundEnabled: event.enabled);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setSoundEnabled(event.enabled);
      },
      (error) => emit(SettingsError('Failed to update sound setting: $error')),
    );
  }

  Future<void> _onUpdateVibrationEnabled(UpdateVibrationEnabled event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(vibrationEnabled: event.enabled);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        // TODO: Implement saving vibration setting to storage
      },
      (error) => emit(SettingsError('Failed to update vibration setting: $error')),
    );
  }

  Future<void> _onUpdateShootingSoundEnabled(UpdateShootingSoundEnabled event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(shootingSoundEnabled: event.enabled);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setShootingSoundEnabled(event.enabled);
      },
      (error) => emit(SettingsError('Failed to update shooting sound setting: $error')),
    );
  }

  Future<void> _onUpdateCrowdSoundEnabled(UpdateCrowdSoundEnabled event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(crowdSoundEnabled: event.enabled);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setCrowdSoundEnabled(event.enabled);
      },
      (error) => emit(SettingsError('Failed to update crowd sound setting: $error')),
    );
  }

  Future<void> _onUpdateBackgroundSoundEnabled(UpdateBackgroundSoundEnabled event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(backgroundSoundEnabled: event.enabled);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setBackgroundSoundEnabled(event.enabled);
      },
      (error) => emit(SettingsError('Failed to update background sound setting: $error')),
    );
  }

  Future<void> _onUpdateSoundVolume(UpdateSoundVolume event, Emitter<SettingsState> emit) async {
    final currentState = castState<SettingsLoaded>();
    if (currentState == null) return;

    final newSettings = currentState.settings.copyWith(soundVolume: event.volume);
    emit(currentState.copyWith(settings: newSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setSoundVolume(event.volume);
      },
      (error) => emit(SettingsError('Failed to update sound volume: $error')),
    );
  }

  Future<void> _onResetSettings(ResetSettings event, Emitter<SettingsState> emit) async {
    const defaultSettings = GameSettings();
    emit(SettingsLoaded(defaultSettings));
    
    await safeAsync(
      () async {
        await _settingsService.setSoundEnabled(true);
        await _settingsService.setShootingSoundEnabled(true);
        await _settingsService.setCrowdSoundEnabled(true);
        await _settingsService.setBackgroundSoundEnabled(true);
        await _settingsService.setSoundVolume(0.7);
      },
      (error) => emit(SettingsError('Failed to reset settings: $error')),
    );
  }
} 