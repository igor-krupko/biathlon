import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/career.dart';
import '../blocs/career_bloc.dart';
import '../models/season.dart';
import '../models/race.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: career.seasonRating != null
                  ? TShirtWidget(place: career.seasonRating!)
                  : const SizedBox.shrink(),
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
                      'Date: 	${currentRace.date.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      currentRace.tournament == Tournament.worldCup
                          ? 'Stage ${currentRace.stage} of World Cup'
                          : currentRace.tournament == Tournament.wc
                              ? 'World Championship'
                              : 'Olympics',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                    context.go('/athletes');
                  },
                  child: const Text('Athletes'),
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
                    context.go('/seasons');
                  },
                  child: const Text('Seasons'),
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

class TShirtWidget extends StatelessWidget {
  final int place;
  const TShirtWidget({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final bool isFirst = place == 1;
    final Color shirtColor = isFirst ? Colors.yellow : Colors.orangeAccent;
    // SVG string for the T-shirt icon (from user)
    const String tshirtSvg = '''<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M256 32L32 112V176H96V464H416V176H480V112L256 32Z" fill="currentColor"/></svg>''';
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.string(
                tshirtSvg,
                color: shirtColor,
                width: 140,
                height: 160,
              ),
              Positioned(
                bottom: 60,
                child: Text(
                  '#$place',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isFirst ? Colors.deepOrange : Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Your Place in Season', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
} 