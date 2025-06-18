import 'package:flutter_bloc/flutter_bloc.dart';

/// Base BLoC class that provides common error handling patterns
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(State initialState) : super(initialState);

  /// Safely execute an async operation with error handling
  Future<void> safeAsync(
    Future<void> Function() operation,
    void Function(String error) onError,
  ) async {
    try {
      await operation();
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Safely execute a sync operation with error handling
  void safeSync(
    void Function() operation,
    void Function(String error) onError,
  ) {
    try {
      operation();
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Check if the current state is of a specific type
  bool isState<T extends State>() {
    return state is T;
  }

  /// Cast current state to a specific type, returns null if not possible
  T? castState<T extends State>() {
    return state is T ? state as T : null;
  }

  /// Require current state to be of a specific type, throws if not
  T requireState<T extends State>() {
    if (state is T) {
      return state as T;
    }
    throw StateError('Expected state of type $T, but got ${state.runtimeType}');
  }
} 