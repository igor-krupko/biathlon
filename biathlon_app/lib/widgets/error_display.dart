import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/error_bloc.dart';

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBloc, ErrorState>(
      builder: (context, state) {
        if (state is ErrorActive && state.errors.isNotEmpty) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Column(
              children: state.errors.map((error) => _ErrorCard(error: error)).toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final AppError error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getErrorColor(error.type),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getErrorIcon(error.type),
          color: Colors.white,
        ),
        title: Text(
          error.title ?? 'Error',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          error.message,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            context.read<ErrorBloc>().add(ClearError(error.id));
          },
        ),
      ),
    );
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.general:
        return Colors.red;
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.permission:
        return Colors.purple;
      case ErrorType.notFound:
        return Colors.blue;
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.general:
        return Icons.error;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.permission:
        return Icons.lock;
      case ErrorType.notFound:
        return Icons.search_off;
    }
  }
} 