import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../models/plex_media_info.dart';
import '../../../mpv/models.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../utils/formatters.dart';
import '../painters/buffer_range_painter.dart';
import '../painters/chapter_marker_painter.dart';

/// Timeline slider with chapter markers for video playback
///
/// Displays a horizontal slider showing playback position and duration,
/// with optional chapter markers overlaid at their respective positions.
class TimelineSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final List<BufferRange> bufferRanges;
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

  /// Optional callback that returns thumbnail image bytes for a given timestamp.
  final Uint8List? Function(Duration time)? thumbnailDataBuilder;

  const TimelineSlider({
    super.key,
    required this.position,
    required this.duration,
    this.bufferRanges = const [],
    required this.chapters,
    required this.chaptersLoaded,
    required this.onSeek,
    required this.onSeekEnd,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.enabled = true,
    this.thumbnailDataBuilder,
  });

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  double? _mousePosition;
  double? _dragValue;
  bool _showKeySeekThumbnail = false;
  Timer? _keySeekTimer;

  // Must match the slider track inset: max(overlayRadius, thumbRadius)
  static const _sliderPadding = 12.0;

  static const _thumbWidth = 160.0;
  static const _thumbHeight = 90.0;
  static const _keySeekThumbnailTimeout = Duration(milliseconds: 800);

  @override
  void didUpdateWidget(TimelineSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect user-initiated seeks. A normal playback will advance the timeline
    // a very short amount. But a bigger jump indicates that the user changed position.
    // For now we will check half a second, but this can probably be made higher.
    if (widget.thumbnailDataBuilder != null && _dragValue == null) {
      final delta = (widget.position.inMilliseconds - oldWidget.position.inMilliseconds).abs();
      if (delta > 500) {
        _showKeySeekThumbnail = true;
        _resetKeySeekTimer();
      }
    }
  }

  @override
  void dispose() {
    _keySeekTimer?.cancel();
    super.dispose();
  }

  void _resetKeySeekTimer() {
    _keySeekTimer?.cancel();
    _keySeekTimer = Timer(_keySeekThumbnailTimeout, () {
      if (mounted) setState(() => _showKeySeekThumbnail = false);
    });
  }

  Widget _buildTooltip(double sliderWidth, double pixelX, Duration time) {
    final thumbnailData = widget.thumbnailDataBuilder?.call(time);
    final hasThumbnail = thumbnailData != null;

    final tooltipWidth = hasThumbnail ? _thumbWidth : 64.0;
    final timestampOffset = 16.0;
    final tooltipTop = hasThumbnail ? -(_thumbHeight + timestampOffset) : -timestampOffset;

    // Center tooltip on cursor, clamped so it stays within the slider bounds
    final left = (pixelX - tooltipWidth / 2).clamp(0.0, sliderWidth - tooltipWidth);
    return Positioned(
      left: left,
      top: tooltipTop,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasThumbnail)
              Container(
                width: _thumbWidth,
                height: _thumbHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  thumbnailData,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (hasThumbnail) const SizedBox(height: 4),
            Container(
              width: 64.0,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
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
          ],
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
          } else if (_showKeySeekThumbnail && widget.thumbnailDataBuilder != null) {
            // Show tooltip at current playback position when user is actively seeking via d-pad/keyboard
            // Note that this has the lowest priority, so if the user hovers, that will show instead
            final fraction = (widget.position.inMilliseconds / durationMs).clamp(0.0, 1.0);
            final px = _sliderPadding + fraction * trackWidth;
            tooltip = _buildTooltip(sliderWidth, px, widget.position);
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
                  padding: const EdgeInsets.symmetric(horizontal: _sliderPadding),
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
            // Buffer range + background track painter
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _sliderPadding),
                  child: CustomPaint(
                    painter: BufferRangePainter(ranges: widget.bufferRanges, duration: widget.duration),
                  ),
                ),
              ),
            ),
            // Slider - use IgnorePointer to block interaction while preserving visual style
            IgnorePointer(
              ignoring: !widget.enabled,
              child: SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
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
                    inactiveColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Chapter marker indicators
            if (widget.chaptersLoaded && widget.chapters.isNotEmpty && widget.duration.inMilliseconds > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sliderPadding),
                    child: CustomPaint(
                      painter: ChapterMarkerPainter(chapters: widget.chapters, duration: widget.duration),
                    ),
                  ),
                ),
              ),
            ?tooltip,
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
