import 'package:flutter/material.dart';
import '../models/career.dart';
import 'race_screen.dart';
import 'points_screen.dart';

class CareerDetailsScreen extends StatefulWidget {
  final Career career;

  const CareerDetailsScreen({
    super.key,
    required this.career,
  });

  @override
  State<CareerDetailsScreen> createState() => _CareerDetailsScreenState();
}

class _CareerDetailsScreenState extends State<CareerDetailsScreen> {
  late Career career;

  @override
  void initState() {
    super.initState();
    career = widget.career;
  }

  void _handleRaceComplete() {
    setState(() {
      if (career.hasNextTrack()) {
        career.moveToNextTrack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCareerCompleted = !career.hasNextTrack();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RaceScreen(
                              track: career.currentTrack!,
                              career: career,
                            ),
                          ),
                        ).then((_) => _handleRaceComplete());
                      }
                    },
              child: const Text('Next Race'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PointsScreen(career: career),
                  ),
                );
              },
              child: const Text('Points'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
} 