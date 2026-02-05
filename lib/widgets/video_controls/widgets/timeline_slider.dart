import 'package:flutter/material.dart';
import '../../../models/plex_media_info.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../utils/formatters.dart';
import '../painters/chapter_marker_painter.dart';

/// Timeline slider with chapter markers for video playback
///
/// Displays a horizontal slider showing playback position and duration,
/// with optional chapter markers overlaid at their respective positions.
class TimelineSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;

  /// Optional FocusNode for D-pad/keyboard navigation.
  final FocusNode? focusNode;

  /// Custom key event handler for focus navigation.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the slider is enabled for interaction.
  final bool enabled;

  const TimelineSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.chapters,
    required this.chaptersLoaded,
    required this.onSeek,
    required this.onSeekEnd,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.enabled = true,
  });

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  double? _mousePosition;
  double? _dragValue;

  static const _sliderPadding = 24.0;

  Widget _buildTooltip(double sliderWidth, double pixelX, Duration time) {
    final tooltipWidth = 64.0;

    // Center tooltip on cursor, clamped so it stays within the slider bounds
    final left = (pixelX - tooltipWidth / 2).clamp(0.0, sliderWidth - tooltipWidth);
    return Positioned(
      left: left,
      top: -16,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
          child: Text(
            formatDurationTimestamp(time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        // Calculate the actual track width by subtracting the thumb padding on each side
        final trackWidth = sliderWidth - 2 * _sliderPadding;
        final durationMs = widget.duration.inMilliseconds;

        // Resolve tooltip position (drag takes priority over hover)
        Widget? tooltip;
        if (durationMs > 0) {
          if (_dragValue != null) {
            // Convert drag value (ms) to a 0..1 fraction, then map to pixel
            // position on the track (offset by padding to align with the slider)
            final fraction = (_dragValue! / durationMs).clamp(0.0, 1.0);
            final px = _sliderPadding + fraction * trackWidth;
            tooltip = _buildTooltip(sliderWidth, px, Duration(milliseconds: _dragValue!.toInt()));
          } else if (_mousePosition != null) {
            // Convert mouse pixel position to a 0..1 fraction of the track
            // (subtract padding to get position relative to track start),
            // then map that fraction to a time in milliseconds
            final fraction = ((_mousePosition! - _sliderPadding) / trackWidth).clamp(0.0, 1.0);
            final time = Duration(milliseconds: (fraction * durationMs).round());
            tooltip = _buildTooltip(sliderWidth, _mousePosition!, time);
          }
        }

        Widget slider = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Chapter markers layer
            if (widget.chaptersLoaded && widget.chapters.isNotEmpty && widget.duration.inMilliseconds > 0)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children:
                        widget.chapters.map((chapter) {
                          final chapterPosition = (chapter.startTimeOffset ?? 0) / widget.duration.inMilliseconds;
                          return Expanded(flex: (chapterPosition * 1000).toInt(), child: const SizedBox());
                        }).toList()..add(
                          Expanded(
                            flex:
                                1000 -
                                widget.chapters.fold<int>(
                                  0,
                                  (sum, chapter) =>
                                      sum +
                                      ((chapter.startTimeOffset ?? 0) / widget.duration.inMilliseconds * 1000).toInt(),
                                ),
                            child: const SizedBox(),
                          ),
                        ),
                  ),
                ),
              ),
            // Slider - use IgnorePointer to block interaction while preserving visual style
            IgnorePointer(
              ignoring: !widget.enabled,
              child: Semantics(
                label: t.videoControls.timelineSlider,
                slider: true,
                child: Slider(
                  value: widget.duration.inMilliseconds > 0 ? widget.position.inMilliseconds.toDouble() : 0.0,
                  min: 0.0,
                  max: widget.duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    setState(() => _dragValue = value);
                    widget.onSeek(Duration(milliseconds: value.toInt()));
                  },
                  onChangeEnd: (value) {
                    setState(() => _dragValue = null);
                    widget.onSeekEnd(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            // Chapter marker indicators
            if (widget.chaptersLoaded && widget.chapters.isNotEmpty && widget.duration.inMilliseconds > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomPaint(
                      painter: ChapterMarkerPainter(chapters: widget.chapters, duration: widget.duration),
                    ),
                  ),
                ),
              ),
            if (tooltip != null) tooltip,
          ],
        );

        // Wrap with FocusableWrapper when focusNode is provided
        if (widget.focusNode != null) {
          slider = FocusableWrapper(
            focusNode: widget.focusNode,
            onKeyEvent: widget.enabled ? widget.onKeyEvent : null,
            onFocusChange: widget.onFocusChange,
            borderRadius: 8,
            autoScroll: false,
            useBackgroundFocus: true,
            disableScale: true,
            semanticLabel: t.videoControls.timelineSlider,
            child: slider,
          );
        }

        return MouseRegion(
          // Handle mouse hover events
          onHover: (event) => setState(() => _mousePosition = event.localPosition.dx),
          onExit: (_) => setState(() => _mousePosition = null),
          child: slider,
        );
      },
    );
  }
}
