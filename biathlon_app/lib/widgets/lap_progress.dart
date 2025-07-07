import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../blocs/lap_progress_bloc.dart';

class LapProgress extends StatefulWidget {
  final double lapDistance;
  final Function(double) onSegmentComplete;

  const LapProgress({
    super.key,
    required this.lapDistance,
    required this.onSegmentComplete,
  });

  @override
  State<LapProgress> createState() => _LapProgressState();
}

class _LapProgressState extends State<LapProgress> {
  final FocusNode _focusNode = FocusNode();
  bool _started = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LapProgressBloc>(
      create: (_) => LapProgressBloc(),
      child: Builder(
        builder: (innerContext) {
          if (!_started) {
            _started = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                BlocProvider.of<LapProgressBloc>(innerContext).add(StartLapProgress(widget.lapDistance));
                _focusNode.requestFocus();
              }
            });
          }

          void handleGoButton() {
            final state = BlocProvider.of<LapProgressBloc>(innerContext).state;
            if (state is LapProgressInProgress && state.isAnimating) {
              BlocProvider.of<LapProgressBloc>(innerContext).add(StopAnimation());
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  final currentState = BlocProvider.of<LapProgressBloc>(innerContext).state;
                  if (currentState is LapProgressInProgress) {
                    widget.onSegmentComplete(currentState.stoppedProgress ?? 1.0);
                    BlocProvider.of<LapProgressBloc>(innerContext).add(ResumeAnimation());
                  }
                }
              });
            }
          }

          KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
            if (event is RawKeyDownEvent && (event.logicalKey.keyLabel == ' ' || event.logicalKey.keyId == 0x20)) {
              handleGoButton();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }

          return Focus(
            focusNode: _focusNode,
            onKey: onKey,
            autofocus: true,
            child: BlocListener<LapProgressBloc, LapProgressState>(
              listener: (context, state) {
                if (state is LapProgressCompleted) {
                  widget.onSegmentComplete(state.totalProgress);
                }
                if (state is LapProgressInProgress && state.stoppedProgress != null && state.stoppedProgress! > 0.999 && !state.isAnimating) {
                  widget.onSegmentComplete(state.stoppedProgress!);
                }
              },
              child: BlocBuilder<LapProgressBloc, LapProgressState>(
                builder: (context, state) {
                  if (state is! LapProgressInProgress) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final screenWidth = MediaQuery.of(context).size.width;
                  final segmentWidth = screenWidth * 0.75;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Show current segment
                        if (state.currentSegment < state.totalSegments)
                          Container(
                            width: segmentWidth,
                            height: 30,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Stack(
                              children: [
                                // Progress fill
                                FractionallySizedBox(
                                  widthFactor: state.currentProgress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                // Green line at 75%
                                Positioned(
                                  right: segmentWidth * 0.25,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 2,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // GO button
                        if (state.isAnimating)
                          GestureDetector(
                            onTap: handleGoButton,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'GO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Progress percentage
                        if (state.stoppedProgress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              '${(state.stoppedProgress! * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 