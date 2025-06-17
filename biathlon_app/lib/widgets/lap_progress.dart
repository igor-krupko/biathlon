import 'package:flutter/material.dart';

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

class _LapProgressState extends State<LapProgress> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  int _currentSegment = 0;
  bool _isAnimating = false;
  double? _stoppedProgress;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.addListener(() {
      setState(() {});
    });
    _startNextSegment();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startNextSegment() {
    final totalSegments = (widget.lapDistance / 100).ceil();
    if (_currentSegment >= totalSegments) {
      return;
    }

    setState(() {
      _isAnimating = true;
      _stoppedProgress = null;
    });

    _animationController.reset();
    _animationController.forward().then((_) async {
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _stoppedProgress = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _currentSegment++;
        });
        _startNextSegment();
      }
    });
  }

  void _handleGoButton() {
    if (_isAnimating) {
      _animationController.stop();
      setState(() {
        _isAnimating = false;
        _stoppedProgress = _progressAnimation.value;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentSegment++;
          });
          widget.onSegmentComplete(_stoppedProgress!);
          _startNextSegment();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final segments = (widget.lapDistance / 100).ceil();
    final segmentWidth = screenWidth * 0.75;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show current segment
          if (_currentSegment < segments)
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
                    widthFactor: _stoppedProgress ?? _progressAnimation.value,
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
          if (_isAnimating)
            GestureDetector(
              onTap: _handleGoButton,
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
          if (_stoppedProgress != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                '${(_stoppedProgress! * 100).toStringAsFixed(1)}%',
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
  }
} 