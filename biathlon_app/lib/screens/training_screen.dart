import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/career_bloc.dart';
import '../models/career.dart';
import '../models/athlete.dart';
import 'package:go_router/go_router.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  static const int baseStat = 70;

  int _calcCost(int base, int upgrades) {
    final cost = base * pow(1.1, upgrades).toDouble();
    return ((cost / 100).round() * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareerBloc, CareerState>(
      builder: (context, state) {
        if (state is! CareerActive) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final career = state.career;
        final player = career.player;
        final money = player.money;
        final speedUpgrades = player.speed - baseStat;
        final shootingDownUpgrades = player.shootingDown - baseStat;
        final shootingStandingUpgrades = player.shootingStanding - baseStat;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Training'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Money: $money', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.go('/career-details'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatRow(context, 'Speed', player.speed, () {
                  final cost = _calcCost(1000, speedUpgrades);
                  if (money >= cost) {
                    _upgradeStat(context, career, 'speed', cost);
                  }
                }, _calcCost(1000, speedUpgrades)),
                const SizedBox(height: 16),
                _buildStatRow(context, 'Shooting (Prone)', player.shootingDown, () {
                  final cost = _calcCost(1000, shootingDownUpgrades);
                  if (money >= cost) {
                    _upgradeStat(context, career, 'shootingDown', cost);
                  }
                }, _calcCost(1000, shootingDownUpgrades)),
                const SizedBox(height: 16),
                _buildStatRow(context, 'Shooting (Standing)', player.shootingStanding, () {
                  final cost = _calcCost(1000, shootingStandingUpgrades);
                  if (money >= cost) {
                    _upgradeStat(context, career, 'shootingStanding', cost);
                  }
                }, _calcCost(1000, shootingStandingUpgrades)),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/career-details'),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int value, VoidCallback onUpgrade, int cost) {
    final currentMoney = (context.read<CareerBloc>().state is CareerActive)
        ? (context.read<CareerBloc>().state as CareerActive).career.player.money
        : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label: $value', style: Theme.of(context).textTheme.titleLarge),
        ElevatedButton(
          onPressed: cost <= currentMoney ? onUpgrade : null,
          child: Text('Upgrade ($cost)'),
        ),
      ],
    );
  }

  void _upgradeStat(BuildContext context, Career career, String stat, int cost) {
    final player = career.player;
    Athlete upgraded;
    if (stat == 'speed') {
      upgraded = Athlete(
        id: player.id,
        name: player.name,
        surname: player.surname,
        country: player.country,
        speed: player.speed + 1,
        shootingDown: player.shootingDown,
        shootingStanding: player.shootingStanding,
        seasonStats: null,
        money: player.money - cost,
      );
    } else if (stat == 'shootingDown') {
      upgraded = Athlete(
        id: player.id,
        name: player.name,
        surname: player.surname,
        country: player.country,
        speed: player.speed,
        shootingDown: player.shootingDown + 1,
        shootingStanding: player.shootingStanding,
        seasonStats: null,
        money: player.money - cost,
      );
    } else {
      upgraded = Athlete(
        id: player.id,
        name: player.name,
        surname: player.surname,
        country: player.country,
        speed: player.speed,
        shootingDown: player.shootingDown,
        shootingStanding: player.shootingStanding + 1,
        seasonStats: null,
        money: player.money - cost,
      );
    }
    // Update career with upgraded player
    final updatedCareer = Career(
      startDate: career.startDate,
      player: upgraded,
      isActive: career.isActive,
      seasons: career.seasons,
      currentSeasonIndex: career.currentSeasonIndex,
      currentRaceIndex: career.currentRaceIndex,
    );
    // Copy race history
    updatedCareer.racePointsHistory.addAll(career.racePointsHistory);
    updatedCareer.allRacesResults.addAll(career.allRacesResults);
    context.read<CareerBloc>().emit(CareerActive(updatedCareer));
  }
} 