import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../models/plex_media_info.dart';
import '../../../mpv/models.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../utils/formatters.dart';
import '../painters/buffer_range_painter.dart';

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

  /// When true, show the preview thumbnail at the current playback position.
  /// Intended for sustained dpad/keyboard seeking where the decoder cannot
  /// keep up with accumulated seeks. Single presses should leave this false.
  final bool showKeyRepeatThumbnail;

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
    this.showKeyRepeatThumbnail = false,
  });

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  double? _mousePosition;
  double? _dragValue;
  bool _isFocused = false;

  // Must match the slider track inset: max(overlayRadius, thumbRadius)
  static const _sliderPadding = 0.0;

  static const _thumbWidth = 160.0;
  static const _thumbHeight = 90.0;

  Widget _buildTooltip(double sliderWidth, double pixelX, Duration time) {
    final thumbnailData = widget.thumbnailDataBuilder?.call(time);
    final hasThumbnail = thumbnailData != null;

    final tooltipWidth = hasThumbnail ? _thumbWidth : 64.0;
    final tooltipHeight = hasThumbnail ? _thumbHeight : 26.0;
    final tooltipTop = -(tooltipHeight + 2.0);

    // Center tooltip on cursor, clamped so it stays within the slider bounds
    final left = (pixelX - tooltipWidth / 2).clamp(0.0, (sliderWidth - tooltipWidth).clamp(0.0, double.infinity));

    final timeLabel = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
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
    );

    return Positioned(
      left: left,
      top: tooltipTop,
      child: IgnorePointer(
        child: hasThumbnail
            ? Container(
                width: _thumbWidth,
                height: _thumbHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      thumbnailData,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    Positioned(bottom: 4, left: 0, right: 0, child: Center(child: timeLabel)),
                  ],
                ),
              )
            : timeLabel,
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
          } else if (widget.showKeyRepeatThumbnail && widget.thumbnailDataBuilder != null) {
            // Preview thumbnail at the current playback position while the
            // user holds a dpad/keyboard direction. The decoder lags behind
            // rapid seeks, so the BIF thumbnail is the only live feedback.
            final fraction = (widget.position.inMilliseconds / durationMs).clamp(0.0, 1.0);
            final px = _sliderPadding + fraction * trackWidth;
            tooltip = _buildTooltip(sliderWidth, px, widget.position);
          }
        }

        Widget slider = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Buffer range + segmented background track (with chapter gaps)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _sliderPadding),
                  child: CustomPaint(
                    painter: BufferRangePainter(
                      ranges: widget.bufferRanges,
                      duration: widget.duration,
                      chapters: widget.chaptersLoaded ? widget.chapters : const [],
                    ),
                  ),
                ),
              ),
            ),
            // Slider - use IgnorePointer to block interaction while preserving visual style
            IgnorePointer(
              ignoring: !widget.enabled,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  trackGap: 0,
                  padding: EdgeInsets.zero,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  thumbSize: WidgetStatePropertyAll(
                    (!InputModeTracker.isKeyboardMode(context) || _isFocused) ? const Size(4, 20) : Size.zero,
                  ),
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
            ?tooltip,
          ],
        );

        // Wrap with FocusableWrapper when focusNode is provided
        if (widget.focusNode != null) {
          slider = FocusableWrapper(
            focusNode: widget.focusNode,
            onKeyEvent: widget.enabled ? widget.onKeyEvent : null,
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
              widget.onFocusChange?.call(hasFocus);
            },
            borderRadius: 8,
            autoScroll: false,
            disableScale: true,
            focusColor: Colors.transparent,
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
