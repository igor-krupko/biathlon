import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ErrorEvent extends Equatable {
  const ErrorEvent();

  @override
  List<Object?> get props => [];
}

class ShowError extends ErrorEvent {
  final String message;
  final String? title;
  final ErrorType type;

  const ShowError(this.message, {this.title, this.type = ErrorType.general});

  @override
  List<Object?> get props => [message, title, type];
}

class ClearError extends ErrorEvent {
  final String? errorId;

  const ClearError([this.errorId]);

  @override
  List<Object?> get props => [errorId];
}

// States
abstract class ErrorState extends Equatable {
  const ErrorState();

  @override
  List<Object?> get props => [];
}

class ErrorInitial extends ErrorState {}

class ErrorActive extends ErrorState {
  final List<AppError> errors;

  const ErrorActive(this.errors);

  @override
  List<Object?> get props => [errors];

  ErrorActive copyWith({
    List<AppError>? errors,
  }) {
    return ErrorActive(errors ?? this.errors);
  }
}

// Data classes
class AppError {
  final String id;
  final String message;
  final String? title;
  final ErrorType type;
  final DateTime timestamp;

  AppError({
    required this.id,
    required this.message,
    this.title,
    this.type = ErrorType.general,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  List<Object?> get props => [id, message, title, type, timestamp];
}

enum ErrorType {
  general,
  network,
  validation,
  permission,
  notFound,
}

// BLoC
class ErrorBloc extends Bloc<ErrorEvent, ErrorState> {
  ErrorBloc() : super(ErrorInitial()) {
    on<ShowError>(_onShowError);
    on<ClearError>(_onClearError);
  }

  void _onShowError(ShowError event, Emitter<ErrorState> emit) {
    final error = AppError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: event.message,
      title: event.title,
      type: event.type,
    );

    if (state is ErrorActive) {
      final currentState = state as ErrorActive;
      final newErrors = List<AppError>.from(currentState.errors)..add(error);
      emit(currentState.copyWith(errors: newErrors));
    } else {
      emit(ErrorActive([error]));
    }

    // Auto-clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      add(ClearError(error.id));
    });
  }

  void _onClearError(ClearError event, Emitter<ErrorState> emit) {
    if (state is ErrorActive) {
      final currentState = state as ErrorActive;
      if (event.errorId != null) {
        final newErrors = currentState.errors
            .where((error) => error.id != event.errorId)
            .toList();
        emit(currentState.copyWith(errors: newErrors));
      } else {
        emit(ErrorActive([]));
      }
    }
  }
} 