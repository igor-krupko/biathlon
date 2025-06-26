import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/career_bloc.dart';
import '../blocs/points_bloc.dart';
import '../screens/home_screen.dart';
import '../screens/player_setup_screen.dart';
import '../screens/career_details_screen.dart';
import '../screens/race_screen.dart';
import '../screens/points_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/training_screen.dart';
import '../screens/athletes_screen.dart';
import '../screens/seasons_screen.dart';
import '../models/career.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/player-setup',
        name: 'player-setup',
        builder: (context, state) => const PlayerSetupScreen(),
      ),
      GoRoute(
        path: '/career-details',
        name: 'career-details',
        builder: (context, state) {
          final careerState = context.read<CareerBloc>().state;
          int seasonIndex = 0;
          if (careerState is CareerActive) {
            seasonIndex = careerState.career.currentSeasonIndex;
          }
          return CareerDetailsScreenWrapper(key: ValueKey(seasonIndex));
        },
      ),
      GoRoute(
        path: '/race',
        name: 'race',
        builder: (context, state) => const RaceScreenWrapper(),
      ),
      GoRoute(
        path: '/points',
        name: 'points',
        builder: (context, state) => BlocProvider(
          create: (context) => PointsBloc(),
          child: const PointsScreenWrapper(),
        ),
      ),
      GoRoute(
        path: '/training',
        name: 'training',
        builder: (context, state) => const TrainingScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/athletes',
        name: 'athletes',
        builder: (context, state) => const AthletesScreen(),
      ),
      GoRoute(
        path: '/seasons',
        name: 'seasons',
        builder: (context, state) => const SeasonsScreenWrapper(),
      ),
    ],
  );
}

// Wrapper screens that get data from BLoC
class CareerDetailsScreenWrapper extends StatelessWidget {
  const CareerDetailsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareerBloc, CareerState>(
      builder: (context, state) {
        if (state is CareerActive) {
          return const CareerDetailsScreen();
        } else {
          return const Scaffold(
            body: Center(child: Text('No active career found')),
          );
        }
      },
    );
  }
}

class RaceScreenWrapper extends StatelessWidget {
  const RaceScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareerBloc, CareerState>(
      builder: (context, state) {
        if (state is CareerActive) {
          final career = state.career;
          final race = career.currentRace;
          if (race != null) {
            return RaceScreen(
              race: race,
              career: career,
            );
          } else {
            return const Scaffold(
              body: Center(child: Text('No active race found')),
            );
          }
        } else {
          return const Scaffold(
            body: Center(child: Text('No active race found')),
          );
        }
      },
    );
  }
}

class PointsScreenWrapper extends StatefulWidget {
  const PointsScreenWrapper({super.key});

  @override
  State<PointsScreenWrapper> createState() => _PointsScreenWrapperState();
}

class _PointsScreenWrapperState extends State<PointsScreenWrapper> {
  Career? _lastCareer;

  void _maybeLoadPoints(Career career) {
    if (_lastCareer != career) {
      _lastCareer = career;
      context.read<PointsBloc>().add(LoadPoints(career));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareerBloc, CareerState>(
      builder: (context, careerState) {
        if (careerState is CareerActive) {
          _maybeLoadPoints(careerState.career);
          return const PointsScreen();
        } else {
          return const Scaffold(
            body: Center(child: Text('No active career found')),
          );
        }
      },
    );
  }
}

class SeasonsScreenWrapper extends StatelessWidget {
  const SeasonsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareerBloc, CareerState>(
      builder: (context, state) {
        if (state is CareerActive) {
          return SeasonsScreen(career: state.career);
        } else {
          return const Scaffold(
            body: Center(child: Text('No active career found')),
          );
        }
      },
    );
  }
} 