import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(LoadSettings());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is SettingsLoaded) {
            return _SettingsContent(settings: state.settings);
          }
          
          return const Center(child: Text('No settings available'));
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final GameSettings settings;

  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          context,
          'Game Difficulty',
          [
            _buildDifficultySelector(context),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Audio & Haptics',
          [
            _buildSwitchTile(
              context,
              'Sound Effects',
              'Enable all sound effects during gameplay',
              Icons.volume_up,
              settings.soundEnabled,
              (value) {
                context.read<SettingsBloc>().add(UpdateSoundEnabled(value));
              },
            ),
            if (settings.soundEnabled) ...[
              _buildSwitchTile(
                context,
                'Shooting Sounds',
                'Play rifle shooting sounds',
                Icons.gps_fixed,
                settings.shootingSoundEnabled,
                (value) {
                  context.read<SettingsBloc>().add(UpdateShootingSoundEnabled(value));
                },
              ),
              _buildSwitchTile(
                context,
                'Crowd Reactions',
                'Play crowd cheers and reactions',
                Icons.people,
                settings.crowdSoundEnabled,
                (value) {
                  context.read<SettingsBloc>().add(UpdateCrowdSoundEnabled(value));
                },
              ),
              _buildSwitchTile(
                context,
                'Background Ambience',
                'Play background stadium sounds',
                Icons.music_note,
                settings.backgroundSoundEnabled,
                (value) {
                  context.read<SettingsBloc>().add(UpdateBackgroundSoundEnabled(value));
                },
              ),
              _buildVolumeSlider(context),
            ],
            _buildSwitchTile(
              context,
              'Vibration',
              'Enable vibration feedback',
              Icons.vibration,
              settings.vibrationEnabled,
              (value) {
                context.read<SettingsBloc>().add(UpdateVibrationEnabled(value));
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Actions',
          [
            _buildActionTile(
              context,
              'Reset to Defaults',
              'Reset all settings to default values',
              Icons.restore,
              Colors.orange,
              () {
                _showResetConfirmation(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text(
                'Difficulty Level',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: GameDifficulty.values.map((difficulty) {
              final isSelected = settings.difficulty == difficulty;
              return ChoiceChip(
                label: Text(difficulty.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    context.read<SettingsBloc>().add(UpdateDifficulty(difficulty));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildVolumeSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text(
                'Sound Volume',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: settings.soundVolume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(settings.soundVolume * 100).round()}%',
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateSoundVolume(value));
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(ResetSettings());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 