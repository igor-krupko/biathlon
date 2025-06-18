import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/career_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Biathlon Career'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocBuilder<CareerBloc, CareerState>(
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (state is CareerInitial || state is CareerInactive)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/player-setup'),
                        child: const Text('Start Career'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                    ],
                  )
                else if (state is CareerActive)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.go('/career-details');
                        },
                        child: const Text('Continue Career'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CareerBloc>().add(StopCareer());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Stop Career'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} 