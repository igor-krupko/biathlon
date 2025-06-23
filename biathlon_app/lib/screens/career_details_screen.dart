import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/career.dart';
import '../blocs/career_bloc.dart';
import '../models/season.dart';
import '../models/race.dart';

class CareerDetailsScreen extends StatelessWidget {
  const CareerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CareerBloc>().state;
    if (state is! CareerActive) {
      return const Scaffold(
        body: Center(child: Text('No active career found')),
      );
    }
    final career = state.career;
    final currentSeason = career.currentSeason;
    final currentRaceIndex = career.currentRaceIndex;
    final bool isSeasonEnded = career.isSeasonEnded();
    final bool isCareerCompleted = !career.hasNextSeason() && isSeasonEnded;
    final currentRace = career.currentRace;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Speed: ${career.player.speed}', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Shooting (Prone): ${career.player.shootingDown}', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Shooting (Standing): ${career.player.shootingStanding}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Money: ${career.playerMoney}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Season: ${currentSeason.name} (${currentSeason.year})', style: Theme.of(context).textTheme.bodyMedium),
                  if (currentRace != null)
                    Text('Race: ${currentRace.track.name} (${currentRace.track.country})', style: Theme.of(context).textTheme.bodyMedium)
                  else
                    Text('No upcoming race', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCareerCompleted)
                  Column(
                    children: [
                      Text(
                        'Career Completed!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have completed all races in your career.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                else if (isSeasonEnded)
                  Column(
                    children: [
                      Text(
                        'Season ended!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have completed all races in this season.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      if (career.hasNextSeason())
                        ElevatedButton(
                          onPressed: () {
                            context.read<CareerBloc>().add(MoveToNextSeason());
                          },
                          child: const Text('Go to next season'),
                        ),
                    ],
                  )
                else ...[
                  if (currentRace != null) ...[
                    Text(
                      'Next Race: ${currentRace.track.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentRace.track.type.toString().split('.').last} - ${currentRace.track.totalDistance}m',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/race');
                      },
                      child: const Text('Next Race'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/points');
                  },
                  child: const Text('Points'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/training');
                  },
                  child: const Text('Training'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 