import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/track.dart';
import '../blocs/shooting_bloc.dart';
import '../blocs/audio_bloc.dart';

class ShootingTargets extends StatefulWidget {
  final ShootingPosition position;
  final void Function(List<bool>) onComplete;

  const ShootingTargets({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ShootingTargets> createState() => _ShootingTargetsState();
}

class _ShootingTargetsState extends State<ShootingTargets> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Offset cursorPosition = Offset.zero;
  final List<GlobalKey> targetKeys = List.generate(5, (_) => GlobalKey());
  int _lastProcessedTarget = -1; // Track which target was last processed for audio
  bool _perfectRoundSoundPlayed = false; // Track if perfect round sound was played

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);
    
    // Start shooting after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ShootingBloc>().add(StartShooting(widget.position));
      }
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _handleShoot(int index, Offset position) {
    final state = context.read<ShootingBloc>().state;
    if (state is! ShootingInProgress) return;

    if (state.isAnimating || index != state.currentTarget) {
      return;
    }

    final RenderBox targetBox = targetKeys[index].currentContext!.findRenderObject() as RenderBox;
    final targetCenter = Offset(targetBox.size.width / 2, targetBox.size.height / 2);
    final hitPosition = targetBox.globalToLocal(position);
    
    // Calculate if hit is within target
    final hitDistance = (hitPosition - targetCenter).distance;
    final targetRadius = widget.position == ShootingPosition.down ? 15.0 : 30.0;
    final isHit = hitDistance <= targetRadius;

    // Play shooting sound immediately when shot is fired
    context.read<AudioBloc>().add(PlayShootingSound());

    if (!isHit) {
      // Add a small delay before the flash animation to match audio timing
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _flashController.forward().then((_) {
            _flashController.reverse();
          });
        }
      });
    }

    // Send the hit result and position to the BLoC
    context.read<ShootingBloc>().add(ShootWithResult(index, hitPosition, isHit));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShootingBloc, ShootingState>(
      listener: (context, state) {
        if (state is ShootingCompleted) {
          widget.onComplete(state.results);
        }
      },
      child: BlocListener<ShootingBloc, ShootingState>(
        listener: (context, shootingState) {
          // Handle audio for shooting results (hit/miss sounds and perfect round)
          if (shootingState is ShootingInProgress) {
            // Play hit/miss sounds after a delay when a shot result is processed
            // Only process if we haven't already processed this target
            if (shootingState.currentTarget > 0 && shootingState.currentTarget > _lastProcessedTarget) {
              final lastShotIndex = shootingState.currentTarget - 1;
              final wasHit = shootingState.hits[lastShotIndex];
              
              // Mark this target as processed
              _lastProcessedTarget = shootingState.currentTarget;
              
              Future.delayed(const Duration(milliseconds: 300), () {
                if (wasHit) {
                  context.read<AudioBloc>().add(PlayHitSound());
                } else {
                  context.read<AudioBloc>().add(PlayMissSound());
                }
              });
              
              // Check for perfect round after the 5th shot (when currentTarget becomes 5)
              if (shootingState.currentTarget == 5) {
                final hitCount = shootingState.hits.where((hit) => hit).length;
                if (hitCount == 5 && !_perfectRoundSoundPlayed) {
                  _perfectRoundSoundPlayed = true;
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      context.read<AudioBloc>().add(PlayPerfectRoundSound());
                    }
                  });
                }
              }
            }
          } else if (shootingState is ShootingCompleted) {
            // Fallback: Check for perfect round when shooting is completed
            final hitCount = shootingState.results.where((hit) => hit).length;
            if (hitCount == 5 && !_perfectRoundSoundPlayed) {
              _perfectRoundSoundPlayed = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.read<AudioBloc>().add(PlayPerfectRoundSound());
                }
              });
            }
          }
        },
        child: BlocBuilder<ShootingBloc, ShootingState>(
          builder: (context, state) {
            if (state is! ShootingInProgress) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sway offset from BLoC state
            final swayOffset = state.swayOffset;

            return MouseRegion(
              cursor: SystemMouseCursors.none,
              child: Listener(
                onPointerHover: (event) {
                  setState(() {
                    cursorPosition = event.localPosition;
                  });
                },
                onPointerDown: (event) {
                  setState(() {
                    cursorPosition = event.localPosition;
                  });
                  bool shotHandled = false;
                  
                  // Check if the shot is within any target area
                  for (int i = 0; i < 5; i++) {
                    if (i >= state.currentTarget) {
                      final RenderBox? targetBox = targetKeys[i].currentContext?.findRenderObject() as RenderBox?;
                      if (targetBox != null) {
                        final targetPosition = targetBox.localToGlobal(Offset.zero);
                        final targetSize = targetBox.size;
                        // Use a slightly larger area for easier targeting
                        final expandedSize = Size(targetSize.width + 20, targetSize.height + 20);
                        final expandedPosition = Offset(
                          targetPosition.dx - 10,
                          targetPosition.dy - 10,
                        );
                        
                        if (event.position.dx >= expandedPosition.dx &&
                            event.position.dx <= expandedPosition.dx + expandedSize.width &&
                            event.position.dy >= expandedPosition.dy &&
                            event.position.dy <= expandedPosition.dy + expandedSize.height) {
                          _handleShoot(i, event.position);
                          shotHandled = true;
                          break;
                        }
                      }
                    }
                  }

                  // If shot wasn't within any target area, count it as a miss on the current target
                  if (!shotHandled && !state.isAnimating) {
                    final currentTargetBox = targetKeys[state.currentTarget].currentContext?.findRenderObject() as RenderBox?;
                    if (currentTargetBox != null) {
                      _handleShoot(state.currentTarget, event.position);
                    }
                  }
                },
                child: Stack(
                  children: [
                    // Flash animation overlay
                    AnimatedBuilder(
                      animation: _flashAnimation,
                      builder: (context, child) {
                        return Container(
                          color: Colors.red.withOpacity(_flashAnimation.value * 0.5),
                        );
                      },
                    ),
                    // Targets
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final isHit = state.hits[index];
                          final hitLocation = state.hitLocations[index];
                          final targetSize = widget.position == ShootingPosition.down ? 30.0 : 60.0;

                          return Stack(
                            key: targetKeys[index],
                            children: [
                              Container(
                                width: targetSize,
                                height: targetSize,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isHit ? Colors.grey : Colors.white,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (hitLocation != null)
                                Positioned(
                                  left: hitLocation.dx - 4,
                                  top: hitLocation.dy - 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isHit ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    // Custom aim/crosshair overlay
                    Positioned(
                      left: cursorPosition.dx + swayOffset.dx - 20,
                      top: cursorPosition.dy + swayOffset.dy - 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: AimCursorPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AimCursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 16.0;

    // Draw crosshair
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );

    // Draw circle
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 