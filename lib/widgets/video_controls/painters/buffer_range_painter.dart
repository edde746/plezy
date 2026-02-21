import 'package:flutter/material.dart';
import '../../../mpv/models.dart';

/// Custom painter that draws a background track and buffered range bars
/// on the video timeline slider.
class BufferRangePainter extends CustomPainter {
  final List<BufferRange> ranges;
  final Duration duration;

  BufferRangePainter({required this.ranges, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = 4.0;
    final y = (size.height - trackHeight) / 2;

    // Background track (full width)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, y, size.width, trackHeight), const Radius.circular(2)),
      bgPaint,
    );

    if (duration.inMilliseconds <= 0) return;

    // Buffer range bars
    final bufPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final durationMs = duration.inMilliseconds.toDouble();
    for (final range in ranges) {
      final startFraction = (range.start.inMilliseconds / durationMs).clamp(0.0, 1.0);
      final endFraction = (range.end.inMilliseconds / durationMs).clamp(0.0, 1.0);
      if (endFraction <= startFraction) continue;

      final left = startFraction * size.width;
      final right = endFraction * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, y, right - left, trackHeight), const Radius.circular(2)),
        bufPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BufferRangePainter oldDelegate) {
    return oldDelegate.duration != duration || oldDelegate.ranges != ranges;
  }
}
