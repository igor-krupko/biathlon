import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/career.dart';
import '../blocs/career_bloc.dart';

class CareerDetailsScreen extends StatelessWidget {
  final Career career;

  const CareerDetailsScreen({
    super.key,
    required this.career,
  });

  void _handleRaceComplete(BuildContext context) {
    if (career.hasNextTrack()) {
      context.read<CareerBloc>().add(MoveToNextTrack());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCareerCompleted = !career.hasNextTrack();

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
                else if (career.currentTrack != null) ...[
                  Text(
                    'Next Race: ${career.currentTrack!.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${career.currentTrack!.type.toString().split('.').last} - ${career.currentTrack!.totalDistance}m',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                ],
                ElevatedButton(
                  onPressed: isCareerCompleted
                      ? null
                      : () {
                          if (career.currentTrack != null) {
                            context.go('/race');
                          }
                        },
                  child: const Text('Next Race'),
                ),
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