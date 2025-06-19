import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/athlete.dart';
import '../blocs/career_bloc.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  String _selectedCountry = 'Norway';

  final List<String> _countries = [
    'Norway',
    'France',
    'Germany',
    'Russia',
    'Italy',
    'Poland',
    'Czech Republic',
    'Austria',
    'Belarus',
    'Finland',
    'Sweden',
    'Slovakia',
    'Ukraine',
    'Japan',
    'South Korea',
    'Slovenia',
    'Estonia',
    'Switzerland',
    'Lithuania',
    'Latvia',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _startCareer() {
    if (_formKey.currentState!.validate()) {
      final player = Athlete(
        name: _nameController.text,
        surname: _surnameController.text,
        country: _selectedCountry,
        speed: 90,
        shootingDown: 90,
        shootingStanding: 90,
      );
      
      context.read<CareerBloc>().add(StartCareer(player));
      context.go('/career-details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Athlete'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                items: _countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCountry = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startCareer,
                child: const Text('Start Career'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 