import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/device_performance.dart';

/// Small 3-bar "now playing" indicator. Bars animate while [animate] is true;
/// on the reduced visual-effects tier they render static regardless (each
/// animation frame re-rasterizes the host row on weak TV GPUs).
///
/// Shared between [TrackRow]'s leading column, the queue sheet's current-track
/// header, and the side navigation rail's Now Playing item.
class EqualizerIcon extends StatefulWidget {
  final bool animate;
  final Color color;

  const EqualizerIcon({super.key, required this.animate, required this.color});

  @override
  State<EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<EqualizerIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _shouldAnimate => widget.animate && !DevicePerformance.isReduced;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(EqualizerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _EqualizerPainter(t: _controller.value, color: widget.color, animate: _shouldAnimate),
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final double t;
  final Color color;
  final bool animate;

  /// Static bar heights (fraction of full height) for the paused/reduced look.
  static const List<double> _staticHeights = [0.55, 0.9, 0.4];

  /// Per-bar phase offsets so the animated bars move out of step.
  static const List<double> _phases = [0.0, 0.35, 0.7];

  const _EqualizerPainter({required this.t, required this.color, required this.animate});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 3;
    const gap = 2.5;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final paint = Paint()..color = color;

    for (var i = 0; i < barCount; i++) {
      final fraction = animate ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + _phases[i]))) : _staticHeights[i];
      final barHeight = size.height * fraction;
      final left = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color || oldDelegate.animate != animate;
}
