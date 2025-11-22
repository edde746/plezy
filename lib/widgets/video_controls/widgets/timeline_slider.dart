import 'package:flutter/material.dart';

import '../../../models/plex_media_info.dart';
import '../../../i18n/strings.g.dart';
import '../painters/chapter_marker_painter.dart';

/// Timeline slider with chapter markers for video playback
///
/// Displays a horizontal slider showing playback position and duration,
/// with optional chapter markers overlaid at their respective positions.
class TimelineSlider extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;

  const TimelineSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.chapters,
    required this.chaptersLoaded,
    required this.onSeek,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Chapter markers layer
        if (chaptersLoaded &&
            chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children:
                    chapters.map((chapter) {
                      final chapterPosition =
                          (chapter.startTimeOffset ?? 0) /
                          duration.inMilliseconds;
                      return Expanded(
                        flex: (chapterPosition * 1000).toInt(),
                        child: const SizedBox(),
                      );
                    }).toList()..add(
                      Expanded(
                        flex:
                            1000 -
                            chapters.fold<int>(
                              0,
                              (sum, chapter) =>
                                  sum +
                                  ((chapter.startTimeOffset ?? 0) /
                                          duration.inMilliseconds *
                                          1000)
                                      .toInt(),
                            ),
                        child: const SizedBox(),
                      ),
                    ),
              ),
            ),
          ),
        // Slider
        Semantics(
          label: t.videoControls.timelineSlider,
          slider: true,
          child: Slider(
            value: duration.inMilliseconds > 0
                ? position.inMilliseconds.toDouble()
                : 0.0,
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              onSeek(Duration(milliseconds: value.toInt()));
            },
            onChangeEnd: (value) {
              onSeekEnd(Duration(milliseconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        // Chapter marker indicators
        if (chaptersLoaded &&
            chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomPaint(
                  painter: ChapterMarkerPainter(
                    chapters: chapters,
                    duration: duration,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
