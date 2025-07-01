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
    final bool isSeasonEnded = career.isSeasonEnded();
    final bool isCareerCompleted = !career.hasNextSeason() && isSeasonEnded;
    final currentRace = career.currentRace;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Details'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.background, theme.colorScheme.surfaceVariant],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Card: T-shirt and Stats
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (career.seasonRating != null)
                          PlaceCircleWidget(place: career.seasonRating!)
                        else
                          const SizedBox(width: 80, height: 80),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatRow(icon: Icons.speed, label: 'Speed', value: career.player.speed.toString()),
                              _StatRow(icon: Icons.radio_button_checked, label: 'Shooting (Prone)', value: career.player.shootingDown.toString()),
                              _StatRow(icon: Icons.adjust, label: 'Shooting (Standing)', value: career.player.shootingStanding.toString()),
                              _StatRow(icon: Icons.attach_money, label: 'Money', value: career.playerMoney.toString()),
                              const SizedBox(height: 8),
                              _StatRow(icon: Icons.calendar_today, label: 'Season', value: '${currentSeason.name} (${currentSeason.year})'),
                              if (currentRace != null)
                                _StatRow(icon: Icons.flag, label: 'Race', value: '${currentRace.track.name} (${currentRace.track.country})')
                              else
                                _StatRow(icon: Icons.flag, label: 'Race', value: 'No upcoming race'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Main Content Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          if (isCareerCompleted)
                            Column(
                              children: [
                                Text('Career Completed!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Text('You have completed all races in your career.', style: theme.textTheme.bodyLarge),
                              ],
                            )
                          else if (isSeasonEnded)
                            Column(
                              children: [
                                Text('Season Ended!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Text('You have completed all races in this season.', style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 24),
                                if (career.hasNextSeason())
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.skip_next),
                                    onPressed: () {
                                      context.read<CareerBloc>().add(MoveToNextSeason());
                                    },
                                    label: const Text('Go to Next Season'),
                                  ),
                              ],
                            )
                          else if (currentRace != null) ...[
                            Text('Next Race: ${currentRace.track.name}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Date: ${currentRace.date.toLocal().toString().split(' ')[0]}', style: theme.textTheme.bodyMedium),
                            Text(
                              currentRace.tournament == Tournament.worldCup
                                  ? 'Stage ${currentRace.stage} of World Cup'
                                  : currentRace.tournament == Tournament.wc
                                      ? 'World Championship'
                                      : 'Olympics',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text('${currentRace.track.type.toString().split('.').last} - ${currentRace.track.totalDistance}m', style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.sports_score),
                              onPressed: () {
                                context.go('/race');
                              },
                              label: const Text('Next Race'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Navigation Buttons
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _NavButton(icon: Icons.emoji_events, label: 'Points', onTap: () => context.go('/points')),
                        _NavButton(icon: Icons.people, label: 'Athletes', onTap: () => context.go('/athletes')),
                        _NavButton(icon: Icons.fitness_center, label: 'Training', onTap: () => context.go('/training')),
                        _NavButton(icon: Icons.timeline, label: 'Seasons', onTap: () => context.go('/seasons')),
                        _NavButton(icon: Icons.bar_chart, label: 'Results', onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CareerResultsScreen()),
                        )),
                        _NavButton(icon: Icons.arrow_back, label: 'Back', onTap: () => context.go('/')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Game'),
                      onPressed: () async {
                        final saveName = await _showSaveDialog(context);
                        if (saveName != null && saveName.trim().isNotEmpty) {
                          await context.read<CareerBloc>().repository.saveCareerAs(career, saveName.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Game saved as "$saveName"')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Load Game'),
                      onPressed: () async {
                        final saveName = await _showLoadDialog(context);
                        if (saveName != null && saveName.trim().isNotEmpty) {
                          final loaded = await context.read<CareerBloc>().repository.loadCareerByName(saveName.trim());
                          if (loaded != null) {
                            context.read<CareerBloc>().emit(CareerActive(loaded));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Loaded save "$saveName"')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to load save "$saveName"')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<String?> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Game'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Save name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _showLoadDialog(BuildContext context) async {
    final repo = context.read<CareerBloc>().repository;
    final saves = await repo.listSaves();
    String? selected = saves.isNotEmpty ? saves.first : null;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Game'),
        content: SizedBox(
          width: 300,
          child: saves.isEmpty
              ? const Text('No saves found.')
              : StatefulBuilder(
                  builder: (context, setState) => DropdownButtonFormField<String>(
                    value: selected,
                    items: saves.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selected = v),
                    decoration: const InputDecoration(labelText: 'Select save'),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}

class PlaceCircleWidget extends StatelessWidget {
  final int place;
  const PlaceCircleWidget({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final bool isFirst = place == 1;
    final Color bgColor = isFirst ? Colors.yellow[700]! : Colors.grey[300]!;
    final Color textColor = isFirst ? Colors.deepOrange : Colors.black87;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '#$place',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.12),
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Your Place in Season', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: Theme.of(context).textTheme.titleMedium,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    );
  }
}

class CareerResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.read<CareerBloc>().state;
    if (state is! CareerActive) {
      return const Scaffold(
        body: Center(child: Text('No active career found')),
      );
    }
    final career = state.career;
    final playerId = career.player.id;
    final completedRaces = career.allRacesResults.expand((x) => x)
      .where((r) => r.athlete.id == playerId)
      .toList();
    completedRaces.sort((a, b) => a.race.date.compareTo(b.race.date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: completedRaces.isEmpty
          ? const Center(child: Text('No completed races yet'))
          : ListView.separated(
              itemCount: completedRaces.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final r = completedRaces[idx];
                return ListTile(
                  leading: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  title: Row(
                    children: [
                      Text('${r.race.track.name} (${r.race.track.country})', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Text('Place: ${r.place}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrange)),
                    ],
                  ),
                  subtitle: Text('${r.race.date.toLocal().toString().split(' ')[0]} - ${r.type}'),
                );
              },
            ),
    );
  }
} 