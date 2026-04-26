import 'package:flutter/material.dart';
import '../../../media/media_source_info.dart';
import '../../../mpv/models.dart';

/// Custom painter that draws a segmented background track (split at chapter
/// boundaries) and buffered range bars on the video timeline slider.
class BufferRangePainter extends CustomPainter {
  final List<BufferRange> ranges;
  final Duration duration;
  final List<MediaChapter> chapters;

  BufferRangePainter({required this.ranges, required this.duration, this.chapters = const []});

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 8.0;
    const gapWidth = 4.0;
    final radius = trackHeight / 2;
    final y = (size.height - trackHeight) / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final durationMs = duration.inMilliseconds.toDouble();

    // Collect chapter split fractions excluding 0 and 1
    final splits = <double>[];
    if (durationMs > 0) {
      for (final chapter in chapters) {
        final ms = chapter.startTimeOffset ?? 0;
        if (ms <= 0) continue;
        final f = (ms / durationMs).clamp(0.0, 1.0);
        if (f > 0 && f < 1) splits.add(f);
      }
    }

    // Build segment pixel ranges [left, right] with gaps at chapter boundaries
    final segmentEdges = <double>[0, ...splits, 1];
    final segments = <(double, double)>[];
    for (int i = 0; i < segmentEdges.length - 1; i++) {
      final left = segmentEdges[i] * size.width + (i > 0 ? gapWidth / 2 : 0);
      final right = segmentEdges[i + 1] * size.width - (i < segmentEdges.length - 2 ? gapWidth / 2 : 0);
      if (right > left) segments.add((left, right));
    }

    // Draw background segments
    for (final (left, right) in segments) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, y, right - left, trackHeight), Radius.circular(radius)),
        bgPaint,
      );
    }

    if (durationMs <= 0) return;

    // Draw buffer ranges clipped to segments
    final bufPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (final range in ranges) {
      final bufLeft = (range.start.inMilliseconds / durationMs).clamp(0.0, 1.0) * size.width;
      final bufRight = (range.end.inMilliseconds / durationMs).clamp(0.0, 1.0) * size.width;
      if (bufRight <= bufLeft) continue;

      // Clip buffer to each segment it overlaps
      for (final (segLeft, segRight) in segments) {
        final clippedLeft = bufLeft.clamp(segLeft, segRight);
        final clippedRight = bufRight.clamp(segLeft, segRight);
        if (clippedRight <= clippedLeft) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(clippedLeft, y, clippedRight - clippedLeft, trackHeight),
            Radius.circular(radius),
          ),
          bufPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BufferRangePainter oldDelegate) {
    return oldDelegate.duration != duration || oldDelegate.ranges != ranges || oldDelegate.chapters != chapters;
  }
}
