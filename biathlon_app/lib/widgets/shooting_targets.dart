import 'package:flutter/material.dart';
import '../models/track.dart';
import 'dart:math';
import 'dart:async';

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
  final List<bool> hits = List.filled(5, false);
  final List<Offset?> hitLocations = List.filled(5, null);
  int currentTarget = 0;
  bool isAnimating = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Offset cursorPosition = Offset.zero;
  final List<GlobalKey> targetKeys = List.generate(5, (_) => GlobalKey());
  Offset swayOffset = Offset.zero;
  Timer? swayTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    print('ShootingTargets initialized with position: ${widget.position}');
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);
    _startSway();
  }

  void _startSway() {
    swayTimer?.cancel();
    _updateSway();
  }

  void _updateSway() {
    // Sway parameters
    final isProne = widget.position == ShootingPosition.down;
    final maxSway = isProne ? 10.0 : 30.0; // pixels
    final minDuration = isProne ? 100 : 50;
    final maxDuration = isProne ? 400 : 200;
    final swayStep = isProne ? 10.0 : 30.0; // max delta per update

    // Add a small random delta to the previous offset
    double dx = swayOffset.dx + (_random.nextDouble() * 2 - 1) * swayStep;
    double dy = swayOffset.dy + (_random.nextDouble() * 2 - 1) * swayStep;

    // Clamp to max sway distance
    final distance = sqrt(dx * dx + dy * dy);
    if (distance > maxSway) {
      final scale = maxSway / distance;
      dx *= scale;
      dy *= scale;
    }
    swayOffset = Offset(dx, dy);
    setState(() {});
    swayTimer = Timer(Duration(milliseconds: minDuration + _random.nextInt(maxDuration - minDuration)), _updateSway);
  }

  @override
  void dispose() {
    print('ShootingTargets disposed');
    _flashController.dispose();
    swayTimer?.cancel();
    super.dispose();
  }

  void _handleShoot(int index, Offset position) {
    if (isAnimating || index != currentTarget) {
      print('Shot ignored: isAnimating=$isAnimating, index=$index, currentTarget=$currentTarget');
      return;
    }

    final RenderBox targetBox = targetKeys[index].currentContext!.findRenderObject() as RenderBox;
    final targetCenter = Offset(targetBox.size.width / 2, targetBox.size.height / 2);
    final hitPosition = targetBox.globalToLocal(position);
    
    // Calculate if hit is within target
    final hitDistance = (hitPosition - targetCenter).distance;
    final targetRadius = widget.position == ShootingPosition.down ? 15.0 : 30.0;
    final isHit = hitDistance <= targetRadius;

    print('Shot fired at target $index: distance=$hitDistance, radius=$targetRadius, isHit=$isHit');

    setState(() {
      hits[currentTarget] = isHit;
      hitLocations[currentTarget] = hitPosition;
      isAnimating = true;
    });

    if (!isHit) {
      print('Miss animation triggered');
      _flashController.forward().then((_) {
        _flashController.reverse();
      });
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isAnimating = false;
          currentTarget++;
          print('Moving to next target: $currentTarget');
          if (currentTarget >= 5) {
            print('All targets completed, calling onComplete');
            widget.onComplete(List<bool>.from(hits));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          cursorPosition = event.localPosition;
        });
      },
      cursor: SystemMouseCursors.none,
      child: Listener(
        onPointerDown: (event) {
          print('Pointer down at position: ${event.position}');
          bool shotHandled = false;
          
          // First check if the shot is within any target area
          for (int i = 0; i < 5; i++) {
            if (i >= currentTarget) {
              final RenderBox? targetBox = targetKeys[i].currentContext?.findRenderObject() as RenderBox?;
              if (targetBox != null) {
                final targetPosition = targetBox.localToGlobal(Offset.zero);
                final targetSize = targetBox.size;
                if (event.position.dx >= targetPosition.dx &&
                    event.position.dx <= targetPosition.dx + targetSize.width &&
                    event.position.dy >= targetPosition.dy &&
                    event.position.dy <= targetPosition.dy + targetSize.height) {
                  print('Target $i hit at position: ${event.position}');
                  _handleShoot(i, event.position);
                  shotHandled = true;
                  break;
                }
              }
            }
          }

          // If shot wasn't within any target area, count it as a miss on the current target
          if (!shotHandled && !isAnimating) {
            print('Shot outside target area, counting as miss');
            final currentTargetBox = targetKeys[currentTarget].currentContext?.findRenderObject() as RenderBox?;
            if (currentTargetBox != null) {
              _handleShoot(currentTarget, event.position);
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
                  final isHit = hits[index];
                  final hitLocation = hitLocations[index];
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
                            color: isHit ? Colors.green : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: isHit
                            ? const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 24,
                              )
                            : null,
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
            // Cursor with sway
            Positioned(
              left: cursorPosition.dx - 20 + swayOffset.dx,
              top: cursorPosition.dy - 20 + swayOffset.dy,
              child: CustomPaint(
                size: const Size(40, 40),
                painter: AimCursorPainter(),
              ),
            ),
          ],
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
    const radius = 20.0;

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