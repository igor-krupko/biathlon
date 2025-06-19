import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'career_bloc.dart';
import 'race_bloc.dart';
import 'points_bloc.dart';
import 'shooting_bloc.dart';
import 'lap_progress_bloc.dart';
import 'error_bloc.dart';
import 'navigation_bloc.dart';
import 'settings_bloc.dart';
import 'audio_bloc.dart';
import '../repositories/career_repository.dart';
import '../services/race_simulation_service.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/points_service.dart';
import '../services/career_service.dart';

class AppBlocProvider extends StatelessWidget {
  final Widget child;

  const AppBlocProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Core BLoCs
        BlocProvider<ErrorBloc>(
          create: (context) => ErrorBloc(),
        ),
        BlocProvider<NavigationBloc>(
          create: (context) => NavigationBloc(),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc()..add(LoadSettings()),
        ),
        BlocProvider<AudioBloc>(
          create: (context) => AudioBloc()..add(InitializeAudio()),
        ),
        
        // Feature BLoCs
        BlocProvider<CareerBloc>(
          create: (context) => CareerBloc(
            repository: CareerRepositoryImpl(),
          )..add(LoadCareer()),
        ),
        BlocProvider<PointsBloc>(
          create: (context) => PointsBloc(
            pointsService: PointsService(),
          ),
        ),
        
        // Race-specific BLoCs (created when needed)
        BlocProvider<RaceBloc>(
          create: (context) => RaceBloc(
            simulationService: RaceSimulationService(),
            audioService: AudioService(),
            settingsService: SettingsService(),
          ),
        ),
        BlocProvider<LapProgressBloc>(
          create: (context) => LapProgressBloc(),
        ),
      ],
      child: child,
    );
  }
}

// Extension to easily access BLoCs
extension BlocExtension on BuildContext {
  ErrorBloc get errorBloc => BlocProvider.of<ErrorBloc>(this);
  NavigationBloc get navigationBloc => BlocProvider.of<NavigationBloc>(this);
  SettingsBloc get settingsBloc => BlocProvider.of<SettingsBloc>(this);
  AudioBloc get audioBloc => BlocProvider.of<AudioBloc>(this);
  CareerBloc get careerBloc => BlocProvider.of<CareerBloc>(this);
  PointsBloc get pointsBloc => BlocProvider.of<PointsBloc>(this);
  RaceBloc get raceBloc => BlocProvider.of<RaceBloc>(this);
  LapProgressBloc get lapProgressBloc => BlocProvider.of<LapProgressBloc>(this);
} 