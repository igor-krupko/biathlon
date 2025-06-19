import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/career.dart';
import '../models/athlete.dart';
import '../repositories/career_repository.dart';
import 'base_bloc.dart';

// Events
abstract class CareerEvent extends Equatable {
  const CareerEvent();

  @override
  List<Object?> get props => [];
}

class StartCareer extends CareerEvent {
  final Athlete player;

  const StartCareer(this.player);

  @override
  List<Object?> get props => [player];
}

class LoadCareer extends CareerEvent {}

class StopCareer extends CareerEvent {}

class ContinueCareer extends CareerEvent {}

class MoveToNextTrack extends CareerEvent {}

class MoveToPreviousTrack extends CareerEvent {}

class AddRaceResult extends CareerEvent {
  final RacePointsResult result;

  const AddRaceResult(this.result);

  @override
  List<Object?> get props => [result];
}

class AddFullRaceResults extends CareerEvent {
  final List<RacePointsResult> results;

  const AddFullRaceResults(this.results);

  @override
  List<Object?> get props => [results];
}

// States
abstract class CareerState extends Equatable {
  const CareerState();

  @override
  List<Object?> get props => [];
}

class CareerInitial extends CareerState {}

class CareerLoading extends CareerState {}

class CareerActive extends CareerState {
  final Career career;

  const CareerActive(this.career);

  @override
  List<Object?> get props => [career];
}

class CareerInactive extends CareerState {
  final Career career;

  const CareerInactive(this.career);

  @override
  List<Object?> get props => [career];
}

class CareerError extends CareerState {
  final String message;

  const CareerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CareerBloc extends BaseBloc<CareerEvent, CareerState> {
  final CareerRepository _repository;

  CareerBloc({CareerRepository? repository})
      : _repository = repository ?? CareerRepositoryImpl(),
        super(CareerInitial()) {
    on<StartCareer>(_onStartCareer);
    on<LoadCareer>(_onLoadCareer);
    on<StopCareer>(_onStopCareer);
    on<ContinueCareer>(_onContinueCareer);
    on<MoveToNextTrack>(_onMoveToNextTrack);
    on<MoveToPreviousTrack>(_onMoveToPreviousTrack);
    on<AddRaceResult>(_onAddRaceResult);
    on<AddFullRaceResults>(_onAddFullRaceResults);
  }

  Future<void> _onStartCareer(StartCareer event, Emitter<CareerState> emit) async {
    emit(CareerLoading());
    
    await safeAsync(
      () async {
        final career = await _repository.createCareer(event.player);
        emit(CareerActive(career));
      },
      (error) => emit(CareerError('Failed to start career: $error')),
    );
  }

  Future<void> _onLoadCareer(LoadCareer event, Emitter<CareerState> emit) async {
    emit(CareerLoading());
    
    await safeAsync(
      () async {
        final career = await _repository.loadCareer();
        if (career != null) {
          if (career.isActive) {
            emit(CareerActive(career));
          } else {
            emit(CareerInactive(career));
          }
        } else {
          emit(CareerInitial());
        }
      },
      (error) => emit(CareerError('Failed to load career: $error')),
    );
  }

  Future<void> _onStopCareer(StopCareer event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerActive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        currentCareer.stopCareer();
        await _repository.saveCareer(currentCareer);
        emit(CareerInactive(currentCareer));
      },
      (error) => emit(CareerError('Failed to stop career: $error')),
    );
  }

  Future<void> _onContinueCareer(ContinueCareer event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerInactive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        currentCareer.continueCareer();
        await _repository.saveCareer(currentCareer);
        emit(CareerActive(currentCareer));
      },
      (error) => emit(CareerError('Failed to continue career: $error')),
    );
  }

  Future<void> _onMoveToNextTrack(MoveToNextTrack event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerActive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        currentCareer.moveToNextTrack();
        await _repository.saveCareer(currentCareer);
        emit(CareerActive(currentCareer));
      },
      (error) => emit(CareerError('Failed to move to next track: $error')),
    );
  }

  Future<void> _onMoveToPreviousTrack(MoveToPreviousTrack event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerActive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        currentCareer.moveToPreviousTrack();
        await _repository.saveCareer(currentCareer);
        emit(CareerActive(currentCareer));
      },
      (error) => emit(CareerError('Failed to move to previous track: $error')),
    );
  }

  Future<void> _onAddRaceResult(AddRaceResult event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerActive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        await _repository.addRaceResult(currentCareer, event.result);
        // Add money to player: 100$ per point
        if (event.result.athleteName == currentCareer.player.name && event.result.athleteSurname == currentCareer.player.surname) {
          currentCareer.addMoneyToPlayer(event.result.points * 1000000000);
        }
        emit(CareerActive(currentCareer));
      },
      (error) => emit(CareerError('Failed to add race result: $error')),
    );
  }

  Future<void> _onAddFullRaceResults(AddFullRaceResults event, Emitter<CareerState> emit) async {
    final currentCareer = castState<CareerActive>()?.career;
    if (currentCareer == null) return;

    await safeAsync(
      () async {
        await _repository.addFullRaceResults(currentCareer, event.results);
        emit(CareerActive(currentCareer));
      },
      (error) => emit(CareerError('Failed to add full race results: $error')),
    );
  }
} 