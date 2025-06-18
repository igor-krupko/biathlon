import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/career.dart';
import '../services/points_service.dart';
import 'base_bloc.dart';

// Events
abstract class PointsEvent extends Equatable {
  const PointsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPoints extends PointsEvent {
  final Career career;

  const LoadPoints(this.career);

  @override
  List<Object?> get props => [career];
}

// States
abstract class PointsState extends Equatable {
  const PointsState();

  @override
  List<Object?> get props => [];
}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsLoaded extends PointsState {
  final List<AthletePointsData> athletes;
  final List<String> raceKeys;

  const PointsLoaded({
    required this.athletes,
    required this.raceKeys,
  });

  @override
  List<Object?> get props => [athletes, raceKeys];
}

class PointsError extends PointsState {
  final String message;

  const PointsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PointsBloc extends BaseBloc<PointsEvent, PointsState> {
  final PointsService _pointsService;

  PointsBloc({PointsService? pointsService})
      : _pointsService = pointsService ?? PointsService(),
        super(PointsInitial()) {
    on<LoadPoints>(_onLoadPoints);
  }

  void _onLoadPoints(LoadPoints event, Emitter<PointsState> emit) {
    emit(PointsLoading());

    safeSync(
      () {
        final result = _pointsService.calculatePoints(event.career);
        emit(PointsLoaded(
          athletes: result.athletes,
          raceKeys: result.raceKeys,
        ));
      },
      (error) => emit(PointsError(error)),
    );
  }
} 