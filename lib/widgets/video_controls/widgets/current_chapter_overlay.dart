import 'package:flutter/material.dart';

import '../../../models/plex_media_info.dart';
import '../../../utils/formatters.dart';

/// An overlay widget that displays the current chapter name during video playback.
///
/// This widget listens to the current playback position and shows the
/// chapter name and remaining time in a semi-transparent overlay that
/// appears briefly when the chapter changes, then fades out.
class CurrentChapterOverlay extends StatefulWidget {
  /// List of chapters for the current video
  final List<PlexChapter> chapters;

  /// Current playback position in milliseconds
  final int currentPositionMs;

  /// Whether to show the overlay (typically tied to controls visibility)
  final bool isVisible;

  /// Duration in seconds before the overlay auto-hides (default 3 seconds)
  final int autoHideDuration;

  const CurrentChapterOverlay({
    super.key,
    required this.chapters,
    required this.currentPositionMs,
    this.isVisible = true,
    this.autoHideDuration = 3,
  });

  @override
  State<CurrentChapterOverlay> createState() => _CurrentChapterOverlayState();
}

class _CurrentChapterOverlayState extends State<CurrentChapterOverlay>
    with SingleTickerProviderStateMixin {
  int? _lastChapterIndex;
  bool _showChapterChange = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CurrentChapterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentChapter = _findCurrentChapter();
    if (currentChapter != null && currentChapter != _lastChapterIndex) {
      _lastChapterIndex = currentChapter;
      _showChapterChangeAnimation();
    }

    // Show/hide based on visibility
    if (widget.isVisible && !_showChapterChange) {
      _fadeController.forward();
    } else if (!widget.isVisible) {
      _fadeController.reverse();
    }
  }

  void _showChapterChangeAnimation() {
    setState(() {
      _showChapterChange = true;
    });
    _fadeController.forward();

    // Auto-hide after duration
    Future.delayed(Duration(seconds: widget.autoHideDuration), () {
      if (mounted && _showChapterChange) {
        _fadeController.reverse();
        setState(() {
          _showChapterChange = false;
        });
      }
    });
  }

  int? _findCurrentChapter() {
    if (widget.chapters.isEmpty) return null;

    for (int i = 0; i < widget.chapters.length; i++) {
      final chapter = widget.chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs = chapter.endTimeOffset ??
          (i < widget.chapters.length - 1
              ? widget.chapters[i + 1].startTimeOffset ?? 0
              : double.maxFinite.toInt());

      if (widget.currentPositionMs >= startMs &&
          widget.currentPositionMs < endMs) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentChapterIndex = _findCurrentChapter();
    if (currentChapterIndex == null || widget.chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    final chapter = widget.chapters[currentChapterIndex];
    final chapterEndMs = chapter.endTimeOffset ??
        (currentChapterIndex < widget.chapters.length - 1
            ? widget.chapters[currentChapterIndex + 1].startTimeOffset ?? 0
            : null);

    // Calculate remaining time in chapter
    String? remainingText;
    if (chapterEndMs != null) {
      final remainingMs = chapterEndMs - widget.currentPositionMs;
      if (remainingMs > 0) {
        final remainingDuration = Duration(milliseconds: remainingMs);
        remainingText = '${formatDurationTimestamp(remainingDuration)} remaining';
      }
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter number and name
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Chapter ${currentChapterIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chapter.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Remaining time
            if (remainingText != null) ...[
              const SizedBox(height: 4),
              Text(
                remainingText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A minimal chapter indicator that shows just the current chapter number
/// and can be used inline with other controls.
class ChapterIndicator extends StatelessWidget {
  /// List of chapters for the current video
  final List<PlexChapter> chapters;

  /// Current playback position in milliseconds
  final int currentPositionMs;

  /// Callback when the indicator is tapped (to show chapter list)
  final VoidCallback? onTap;

  const ChapterIndicator({
    super.key,
    required this.chapters,
    required this.currentPositionMs,
    this.onTap,
  });

  int? _findCurrentChapter() {
    if (chapters.isEmpty) return null;

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs = chapter.endTimeOffset ??
          (i < chapters.length - 1
              ? chapters[i + 1].startTimeOffset ?? 0
              : double.maxFinite.toInt());

      if (currentPositionMs >= startMs && currentPositionMs < endMs) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentChapterIndex = _findCurrentChapter();
    if (currentChapterIndex == null || chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_rounded,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${currentChapterIndex + 1}/${chapters.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
