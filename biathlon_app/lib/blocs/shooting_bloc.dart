import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'dart:async';
import '../models/track.dart';
import 'audio_bloc.dart';
import '../models/athlete.dart';

// Events
abstract class ShootingEvent extends Equatable {
  const ShootingEvent();

  @override
  List<Object?> get props => [];
}

class StartShooting extends ShootingEvent {
  final ShootingPosition position;

  const StartShooting(this.position);

  @override
  List<Object?> get props => [position];
}

class ShootWithResult extends ShootingEvent {
  final int targetIndex;
  final Offset position;
  final bool isHit;

  const ShootWithResult(this.targetIndex, this.position, this.isHit);

  @override
  List<Object?> get props => [targetIndex, position, isHit];
}

class UpdateSway extends ShootingEvent {
  const UpdateSway();
}

class CompleteShooting extends ShootingEvent {
  const CompleteShooting();
}

// States
abstract class ShootingState extends Equatable {
  const ShootingState();

  @override
  List<Object?> get props => [];
}

class ShootingInitial extends ShootingState {}

class ShootingInProgress extends ShootingState {
  final List<bool> hits;
  final List<Offset?> hitLocations;
  final int currentTarget;
  final bool isAnimating;
  final Offset swayOffset;
  final ShootingPosition position;

  const ShootingInProgress({
    required this.hits,
    required this.hitLocations,
    required this.currentTarget,
    required this.isAnimating,
    required this.swayOffset,
    required this.position,
  });

  @override
  List<Object?> get props => [hits, hitLocations, currentTarget, isAnimating, swayOffset, position];

  ShootingInProgress copyWith({
    List<bool>? hits,
    List<Offset?>? hitLocations,
    int? currentTarget,
    bool? isAnimating,
    Offset? swayOffset,
    ShootingPosition? position,
  }) {
    return ShootingInProgress(
      hits: hits ?? this.hits,
      hitLocations: hitLocations ?? this.hitLocations,
      currentTarget: currentTarget ?? this.currentTarget,
      isAnimating: isAnimating ?? this.isAnimating,
      swayOffset: swayOffset ?? this.swayOffset,
      position: position ?? this.position,
    );
  }
}

class ShootingCompleted extends ShootingState {
  final List<bool> results;

  const ShootingCompleted(this.results);

  @override
  List<Object?> get props => [results];
}

// BLoC
class ShootingBloc extends Bloc<ShootingEvent, ShootingState> {
  Timer? _swayTimer;
  final Random _random = Random();
  final Athlete player;

  ShootingBloc({required this.player}) : super(ShootingInitial()) {
    on<StartShooting>(_onStartShooting);
    on<ShootWithResult>(_onShootWithResult);
    on<UpdateSway>(_onUpdateSway);
    on<CompleteShooting>(_onCompleteShooting);
  }

  void _onStartShooting(StartShooting event, Emitter<ShootingState> emit) {
    // Cancel any existing timers
    _swayTimer?.cancel();
    
    // Reset to initial shooting state
    emit(ShootingInProgress(
      hits: List.filled(5, false),
      hitLocations: List.filled(5, null),
      currentTarget: 0,
      isAnimating: false,
      swayOffset: Offset.zero,
      position: event.position,
    ));
    
    // Start sway animation
    _startSway();
  }

  void _onShootWithResult(ShootWithResult event, Emitter<ShootingState> emit) async {
    if (state is! ShootingInProgress) return;
    
    final currentState = state as ShootingInProgress;
    if (currentState.isAnimating || event.targetIndex != currentState.currentTarget) {
      return;
    }

    final newHits = List<bool>.from(currentState.hits);
    final newHitLocations = List<Offset?>.from(currentState.hitLocations);
    newHits[currentState.currentTarget] = event.isHit;
    newHitLocations[currentState.currentTarget] = event.position;

    final newCurrentTarget = currentState.currentTarget + 1;
    
    if (newCurrentTarget >= 5) {
      // Update state with the last shot's result first
      emit(currentState.copyWith(
        hits: newHits,
        hitLocations: newHitLocations,
        currentTarget: newCurrentTarget,
        isAnimating: false,
      ));
      
      // All targets completed - check for perfect round
      final hitCount = newHits.where((hit) => hit).length;
      
      // Add delay after last shot before completing shooting phase
      await Future.delayed(const Duration(milliseconds: 800));
      
      // All targets completed
      emit(ShootingCompleted(newHits));
    } else {
      // Move to next target immediately
      emit(currentState.copyWith(
        hits: newHits,
        hitLocations: newHitLocations,
        currentTarget: newCurrentTarget,
        isAnimating: false,
      ));
    }
  }

  void _onUpdateSway(UpdateSway event, Emitter<ShootingState> emit) {
    if (state is! ShootingInProgress) return;
    
    final currentState = state as ShootingInProgress;
    final isProne = currentState.position == ShootingPosition.down;
    final stat = isProne ? player.shootingDown : player.shootingStanding;
    final statFraction = stat / 100.0;
    final maxSway = (isProne ? 12.0 : 36.0);
    final swayStep = (isProne ? 6.0 : 18.0) / statFraction;

    double dx = currentState.swayOffset.dx + (_random.nextDouble() * 2 - 1) * swayStep;
    double dy = currentState.swayOffset.dy + (_random.nextDouble() * 2 - 1) * swayStep;

    final distance = sqrt(dx * dx + dy * dy);
    if (distance > maxSway) {
      final scale = maxSway / distance;
      dx *= scale;
      dy *= scale;
    }

    emit(currentState.copyWith(swayOffset: Offset(dx, dy)));
  }

  void _onCompleteShooting(CompleteShooting event, Emitter<ShootingState> emit) {
    if (state is! ShootingInProgress) return;
    
    final currentState = state as ShootingInProgress;
    _swayTimer?.cancel();
    emit(ShootingCompleted(currentState.hits));
  }

  void _startSway() {
    _swayTimer?.cancel();
    _updateSway();
  }

  void _updateSway() {
    add(const UpdateSway());
    final currentState = state as ShootingInProgress;
    final isProne = currentState.position == ShootingPosition.down;
    final stat = isProne ? player.shootingDown : player.shootingStanding;
    final statFraction = stat / 100.0;
    final minDuration = (100 * statFraction).toInt();
    final maxDuration = (400 * statFraction).toInt();
    _swayTimer = Timer(
      Duration(milliseconds: minDuration + _random.nextInt(maxDuration - minDuration)),
      _updateSway,
    );
  }

  @override
  Future<void> close() {
    _swayTimer?.cancel();
    return super.close();
  }
} 