import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

// Events
abstract class LapProgressEvent extends Equatable {
  const LapProgressEvent();

  @override
  List<Object?> get props => [];
}

class StartLapProgress extends LapProgressEvent {
  final double lapDistance;

  const StartLapProgress(this.lapDistance);

  @override
  List<Object?> get props => [lapDistance];
}

class CompleteSegment extends LapProgressEvent {
  final double progress;

  const CompleteSegment(this.progress);

  @override
  List<Object?> get props => [progress];
}

class StopAnimation extends LapProgressEvent {
  const StopAnimation();
}

class ResumeAnimation extends LapProgressEvent {
  const ResumeAnimation();
}

class StartNextSegmentAnimation extends LapProgressEvent {}

// States
abstract class LapProgressState extends Equatable {
  const LapProgressState();

  @override
  List<Object?> get props => [];
}

class LapProgressInitial extends LapProgressState {}

class LapProgressInProgress extends LapProgressState {
  final int currentSegment;
  final int totalSegments;
  final double currentProgress;
  final bool isAnimating;
  final double? stoppedProgress;

  const LapProgressInProgress({
    required this.currentSegment,
    required this.totalSegments,
    required this.currentProgress,
    required this.isAnimating,
    this.stoppedProgress,
  });

  @override
  List<Object?> get props => [currentSegment, totalSegments, currentProgress, isAnimating, stoppedProgress];

  LapProgressInProgress copyWith({
    int? currentSegment,
    int? totalSegments,
    double? currentProgress,
    bool? isAnimating,
    double? stoppedProgress,
  }) {
    return LapProgressInProgress(
      currentSegment: currentSegment ?? this.currentSegment,
      totalSegments: totalSegments ?? this.totalSegments,
      currentProgress: currentProgress ?? this.currentProgress,
      isAnimating: isAnimating ?? this.isAnimating,
      stoppedProgress: stoppedProgress ?? this.stoppedProgress,
    );
  }
}

class LapProgressCompleted extends LapProgressState {
  final double totalProgress;

  const LapProgressCompleted(this.totalProgress);

  @override
  List<Object?> get props => [totalProgress];
}

// BLoC
class LapProgressBloc extends Bloc<LapProgressEvent, LapProgressState> {
  Timer? _animationTimer;
  static const Duration _animationDuration = Duration(seconds: 2);

  LapProgressBloc() : super(LapProgressInitial()) {
    on<StartLapProgress>(_onStartLapProgress);
    on<CompleteSegment>(_onCompleteSegmentAsync);
    on<StopAnimation>(_onStopAnimation);
    on<ResumeAnimation>(_onResumeAnimation);
    on<_UpdateProgressInternal>(_onUpdateProgressInternal);
    on<StartNextSegmentAnimation>(_onStartNextSegmentAnimation);
  }

  void _onStartLapProgress(StartLapProgress event, Emitter<LapProgressState> emit) {
    final totalSegments = (event.lapDistance / 100).ceil();
    emit(LapProgressInProgress(
      currentSegment: 0,
      totalSegments: totalSegments,
      currentProgress: 0.0,
      isAnimating: true,
    ));
    _startNextSegment();
  }

  Future<void> _onCompleteSegmentAsync(CompleteSegment event, Emitter<LapProgressState> emit) async {
    if (state is! LapProgressInProgress) return;
    final currentState = state as LapProgressInProgress;
    if (!currentState.isAnimating) return;

    _animationTimer?.cancel();

    emit(currentState.copyWith(
      isAnimating: false,
      stoppedProgress: event.progress,
    ));

    await Future.delayed(const Duration(milliseconds: 500));
    if (emit.isDone) return;

    if (state is LapProgressInProgress) {
      final updatedState = state as LapProgressInProgress;
      final newCurrentSegment = updatedState.currentSegment + 1;

      if (newCurrentSegment >= updatedState.totalSegments) {
        emit(LapProgressCompleted(1.0));
      } else {
        emit(updatedState.copyWith(
          currentSegment: newCurrentSegment,
          isAnimating: true,
          stoppedProgress: null,
          currentProgress: 0.0,
        ));
        add(StartNextSegmentAnimation());
      }
    }
  }

  void _onStopAnimation(StopAnimation event, Emitter<LapProgressState> emit) {
    if (state is! LapProgressInProgress) return;
    
    final currentState = state as LapProgressInProgress;
    if (!currentState.isAnimating) return;

    _animationTimer?.cancel();
    
    // Calculate current progress based on elapsed time
    final elapsed = _animationDuration.inMilliseconds * currentState.currentProgress;
    final progress = elapsed / _animationDuration.inMilliseconds;
    
    emit(currentState.copyWith(
      isAnimating: false,
      stoppedProgress: progress,
      currentProgress: progress
    ));
  }

  void _onResumeAnimation(ResumeAnimation event, Emitter<LapProgressState> emit) {
    if (state is! LapProgressInProgress) return;
    
    final currentState = state as LapProgressInProgress;
    if (currentState.isAnimating) return;

    emit(currentState.copyWith(
      isAnimating: true,
      stoppedProgress: null,
      currentProgress: 0.0,
    ));
    add(StartNextSegmentAnimation());
  }

  void _onStartNextSegmentAnimation(StartNextSegmentAnimation event, Emitter<LapProgressState> emit) {
    if (state is LapProgressInProgress) {
      final currentState = state as LapProgressInProgress;
      if (currentState.isAnimating) {
        _startNextSegment();
      }
    }
  }

  void _startNextSegment() {
    if (state is! LapProgressInProgress) return;
    
    final currentState = state as LapProgressInProgress;
    if (!currentState.isAnimating) return;

    final startTime = DateTime.now();
    
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (state is! LapProgressInProgress) {
        timer.cancel();
        return;
      }

      final currentState = state as LapProgressInProgress;
      if (!currentState.isAnimating) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / _animationDuration.inMilliseconds).clamp(0.0, 1.0);

      add(_UpdateProgressInternal(progress));

      if (progress >= 1.0) {
        timer.cancel();
        add(const CompleteSegment(1.0));
      }
    });
  }

  void _onUpdateProgressInternal(_UpdateProgressInternal event, Emitter<LapProgressState> emit) {
    if (state is LapProgressInProgress) {
      final currentState = state as LapProgressInProgress;
      emit(currentState.copyWith(currentProgress: event.progress));
    }
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }
}

// Internal event for timer updates
class _UpdateProgressInternal extends LapProgressEvent {
  final double progress;

  const _UpdateProgressInternal(this.progress);

  @override
  List<Object?> get props => [progress];
} 