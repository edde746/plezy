import 'package:flutter/material.dart';
import '../../../models/plex_media_info.dart';

/// Custom painter for drawing chapter markers on the video timeline slider.
///
/// Markers are displayed as prominent vertical lines with optional
/// diamond indicators at chapter positions. The current chapter's marker
/// can be highlighted differently.
class ChapterMarkerPainter extends CustomPainter {
  final List<PlexChapter> chapters;
  final Duration duration;

  /// Current playback position for highlighting the active chapter
  final Duration? currentPosition;

  /// Whether to use enhanced (more visible) markers
  final bool enhanced;

  /// Color for regular markers
  final Color markerColor;

  /// Color for the active chapter marker
  final Color activeMarkerColor;

  ChapterMarkerPainter({
    required this.chapters,
    required this.duration,
    this.currentPosition,
    this.enhanced = true,
    this.markerColor = const Color(0xB3FFFFFF), // White with 70% opacity
    this.activeMarkerColor = const Color(0xFF2196F3), // Material Blue
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0 || chapters.isEmpty) return;

    final currentMs = currentPosition?.inMilliseconds ?? 0;

    // Find current chapter index
    int? currentChapterIndex;
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs = chapter.endTimeOffset ??
          (i < chapters.length - 1
              ? chapters[i + 1].startTimeOffset ?? 0
              : duration.inMilliseconds);

      if (currentMs >= startMs && currentMs < endMs) {
        currentChapterIndex = i;
        break;
      }
    }

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      if (startMs == 0) continue; // Skip first chapter marker at 0:00

      final position = (startMs / duration.inMilliseconds) * size.width;
      final isActiveTransition = currentChapterIndex == i;

      if (enhanced) {
        _drawEnhancedMarker(
          canvas,
          size,
          position,
          isActiveTransition,
        );
      } else {
        _drawSimpleMarker(canvas, size, position, isActiveTransition);
      }
    }
  }

  /// Draws a simple vertical line marker
  void _drawSimpleMarker(
    Canvas canvas,
    Size size,
    double position,
    bool isActive,
  ) {
    final paint = Paint()
      ..color = isActive ? activeMarkerColor : markerColor
      ..strokeWidth = isActive ? 3 : 2
      ..strokeCap = StrokeCap.round;

    // Draw vertical line (centered on slider track)
    canvas.drawLine(
      Offset(position, size.height * 0.35),
      Offset(position, size.height * 0.65),
      paint,
    );
  }

  /// Draws an enhanced marker with a diamond indicator
  void _drawEnhancedMarker(
    Canvas canvas,
    Size size,
    double position,
    bool isActive,
  ) {
    final color = isActive ? activeMarkerColor : markerColor;

    // Draw vertical line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 3 : 2
      ..strokeCap = StrokeCap.round;

    // Taller line for enhanced markers
    canvas.drawLine(
      Offset(position, size.height * 0.2),
      Offset(position, size.height * 0.8),
      linePaint,
    );

    // Draw diamond indicator at the top
    final diamondSize = isActive ? 6.0 : 4.0;
    final diamondPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final diamondPath = Path()
      ..moveTo(position, size.height * 0.1) // Top point
      ..lineTo(position + diamondSize, size.height * 0.2) // Right point
      ..lineTo(position, size.height * 0.3) // Bottom point
      ..lineTo(position - diamondSize, size.height * 0.2) // Left point
      ..close();

    canvas.drawPath(diamondPath, diamondPaint);

    // Add glow effect for active marker
    if (isActive) {
      final glowPaint = Paint()
        ..color = activeMarkerColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(
        Offset(position, size.height * 0.2),
        Offset(position, size.height * 0.8),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ChapterMarkerPainter oldDelegate) {
    return oldDelegate.chapters != chapters ||
        oldDelegate.duration != duration ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.enhanced != enhanced;
  }
}

/// A compact chapter marker painter that uses colored segments
/// to show chapter boundaries on the progress bar.
class ChapterSegmentPainter extends CustomPainter {
  final List<PlexChapter> chapters;
  final Duration duration;
  final Duration? currentPosition;

  ChapterSegmentPainter({
    required this.chapters,
    required this.duration,
    this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0 || chapters.isEmpty) return;

    final currentMs = currentPosition?.inMilliseconds ?? 0;

    // Draw alternating colored segments for chapters
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs = chapter.endTimeOffset ??
          (i < chapters.length - 1
              ? chapters[i + 1].startTimeOffset ?? 0
              : duration.inMilliseconds);

      final startX = (startMs / duration.inMilliseconds) * size.width;
      final endX = (endMs / duration.inMilliseconds) * size.width;

      final isCurrentChapter = currentMs >= startMs && currentMs < endMs;

      // Use alternating colors for visual distinction
      final baseColor = i.isEven
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.05);

      final paint = Paint()
        ..color = isCurrentChapter
            ? Colors.blue.withOpacity(0.2)
            : baseColor
        ..style = PaintingStyle.fill;

      // Draw segment background
      canvas.drawRect(
        Rect.fromLTWH(startX, 0, endX - startX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ChapterSegmentPainter oldDelegate) {
    return oldDelegate.chapters != chapters ||
        oldDelegate.duration != duration ||
        oldDelegate.currentPosition != currentPosition;
  }
}
