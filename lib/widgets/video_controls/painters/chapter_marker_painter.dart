import 'package:flutter/material.dart';
import '../../../models/plex_media_info.dart';

/// Custom painter for drawing chapter markers on the video timeline slider
class ChapterMarkerPainter extends CustomPainter {
  final List<PlexChapter> chapters;
  final Duration duration;

  ChapterMarkerPainter({required this.chapters, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (final chapter in chapters) {
      final startMs = chapter.startTimeOffset ?? 0;
      if (startMs == 0) continue; // Skip first chapter marker at 0:00

      final x = (startMs / duration.inMilliseconds) * size.width;
      canvas.drawCircle(Offset(x, size.height / 2), 3, paint);
    }
  }

  @override
  bool shouldRepaint(ChapterMarkerPainter oldDelegate) {
    return oldDelegate.chapters != chapters || oldDelegate.duration != duration;
  }
}
