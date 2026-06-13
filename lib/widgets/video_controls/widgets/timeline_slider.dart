import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import '../../../media/media_source_info.dart';
import '../../../mpv/models.dart';
import '../../../i18n/strings.g.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../services/scrub_preview_source.dart';
import '../../../utils/formatters.dart';
import '../helpers/eager_horizontal_drag_recognizer.dart';
import '../painters/buffer_range_painter.dart';

/// Timeline slider with chapter markers for video playback
///
/// Displays a horizontal slider showing playback position and duration,
/// with optional chapter markers overlaid at their respective positions.
class TimelineSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final List<BufferRange> bufferRanges;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final bool showChapterMarkersOnTimeline;
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

  /// Optional callback that returns a scrub-preview frame for a given timestamp.
  /// Plex returns [BytesScrubFrame] (BIF JPEG bytes); Jellyfin returns
  /// [SheetScrubFrame] (sprite-sheet URL + crop). The tooltip renders both.
  final ScrubFrame? Function(Duration time)? thumbnailDataBuilder;

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
    this.showChapterMarkersOnTimeline = true,
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
  int? _hoverTimeMs;
  int? _hoverLabelSecond;
  int? _hoverPixelBucket;
  ScrubFrame? _hoverFrame;
  Object? _hoverFrameKey;
  bool _isFocused = false;
  bool _scrubbing = false;

  // Must match the slider track inset: max(overlayRadius, thumbRadius)
  static const _sliderPadding = 0.0;

  static const _thumbWidth = 160.0;

  @override
  void didUpdateWidget(TimelineSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && _scrubbing) {
      // The gestures map is only registered while enabled, so the swap
      // disposes the recognizer without firing onCancel; finalize after this
      // frame so the parent isn't notified mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleScrubEnd();
      });
    }
  }

  void _handleScrubStart(DragStartDetails details, BuildContext sliderContext) {
    if (widget.duration.inMilliseconds <= 0) return;
    _scrubbing = true;
    _applyScrub(details.localPosition.dx, sliderContext);
  }

  void _handleScrubUpdate(DragUpdateDetails details, BuildContext sliderContext) {
    if (!_scrubbing) return;
    _applyScrub(details.localPosition.dx, sliderContext);
  }

  void _applyScrub(double dx, BuildContext sliderContext) {
    final durationMs = widget.duration.inMilliseconds;
    final trackWidth = _sliderWidthOf(sliderContext) - 2 * _sliderPadding;
    if (durationMs <= 0 || trackWidth <= 0) return;
    final fraction = ((dx - _sliderPadding) / trackWidth).clamp(0.0, 1.0);
    final value = fraction * durationMs;
    setState(() => _dragValue = value);
    widget.onSeek(Duration(milliseconds: value.round()));
  }

  /// Shared by onEnd and onCancel: a cancelled scrub still finalizes at the
  /// last position (Material Slider parity) so `_dragValue` is never stuck.
  void _handleScrubEnd() {
    if (!_scrubbing) return;
    _scrubbing = false;
    final value = _dragValue;
    setState(() => _dragValue = null);
    if (value != null) widget.onSeekEnd(Duration(milliseconds: value.round()));
  }

  /// Discrete a11y step (VoiceOver/TalkBack swipe): a complete seek.
  void _semanticSeekBy(Duration delta) {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) return;
    final base = _dragValue ?? widget.position.inMilliseconds.toDouble();
    final target = (base + delta.inMilliseconds).clamp(0.0, durationMs.toDouble());
    widget.onSeekEnd(Duration(milliseconds: target.round()));
  }

  // Keeps the visual Slider in its enabled style; real input goes through the
  // eager scrub recognizer above it.
  static void _noopSliderChanged(double _) {}

  Object? _scrubFrameKey(ScrubFrame? frame) {
    return switch (frame) {
      null => null,
      BytesScrubFrame(:final bytes) => bytes,
      SheetScrubFrame(:final sheet, :final tileColumn, :final tileRow, :final sheetColumns, :final sheetRows) =>
        Object.hash(sheet, tileColumn, tileRow, sheetColumns, sheetRows),
    };
  }

  void _clearHoverPosition() {
    if (_mousePosition == null && _hoverTimeMs == null && _hoverFrame == null) return;
    setState(() {
      _mousePosition = null;
      _hoverTimeMs = null;
      _hoverLabelSecond = null;
      _hoverPixelBucket = null;
      _hoverFrame = null;
      _hoverFrameKey = null;
    });
  }

  void _updateHoverPosition(double pixelX, double trackWidth, int durationMs) {
    if (durationMs <= 0 || trackWidth <= 0) {
      _clearHoverPosition();
      return;
    }

    final fraction = ((pixelX - _sliderPadding) / trackWidth).clamp(0.0, 1.0);
    final timeMs = (fraction * durationMs).round();
    final frame = widget.thumbnailDataBuilder?.call(Duration(milliseconds: timeMs));
    final frameKey = _scrubFrameKey(frame);
    final labelSecond = timeMs ~/ 1000;
    final pixelBucket = (pixelX / 4).round();

    if (_mousePosition != null &&
        _hoverLabelSecond == labelSecond &&
        _hoverPixelBucket == pixelBucket &&
        _hoverFrameKey == frameKey) {
      return;
    }

    setState(() {
      _mousePosition = pixelX;
      _hoverTimeMs = timeMs;
      _hoverLabelSecond = labelSecond;
      _hoverPixelBucket = pixelBucket;
      _hoverFrame = frame;
      _hoverFrameKey = frameKey;
    });
  }

  double _sliderWidthOf(BuildContext context) {
    final renderObject = context.findRenderObject();
    return renderObject is RenderBox ? renderObject.size.width : 0.0;
  }

  Widget? _buildActiveTooltip(double sliderWidth, int durationMs, double displayValue, Duration displayPosition) {
    if (durationMs <= 0 || sliderWidth <= 0) return null;

    final trackWidth = sliderWidth - 2 * _sliderPadding;
    if (_dragValue != null) {
      final fraction = (displayValue / durationMs).clamp(0.0, 1.0);
      final px = _sliderPadding + fraction * trackWidth;
      return _buildTooltip(sliderWidth, px, displayPosition);
    }

    if (_mousePosition != null) {
      final time = Duration(milliseconds: _hoverTimeMs ?? 0);
      return _buildTooltip(sliderWidth, _mousePosition!, time, frame: _hoverFrame);
    }

    if (widget.showKeyRepeatThumbnail && widget.thumbnailDataBuilder != null) {
      final fraction = (displayValue / durationMs).clamp(0.0, 1.0);
      final px = _sliderPadding + fraction * trackWidth;
      return _buildTooltip(sliderWidth, px, displayPosition);
    }

    return null;
  }

  Widget _buildTooltip(double sliderWidth, double pixelX, Duration time, {ScrubFrame? frame}) {
    final resolvedFrame = frame ?? widget.thumbnailDataBuilder?.call(time);
    final hasThumbnail = resolvedFrame != null;

    final tooltipWidth = hasThumbnail ? _thumbWidth : 64.0;
    final tooltipHeight = hasThumbnail ? _thumbWidth / resolvedFrame.aspectRatio : 26.0;
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
                width: tooltipWidth,
                height: tooltipHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ScrubFrameView(frame: resolvedFrame),
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
    final durationMs = widget.duration.inMilliseconds;
    final max = durationMs > 0 ? durationMs.toDouble() : 0.0;
    final displayValue = max > 0
        ? (_dragValue ?? widget.position.inMilliseconds.toDouble()).clamp(0.0, max).toDouble()
        : 0.0;
    final displayPosition = Duration(milliseconds: displayValue.toInt());
    final hasTooltip =
        durationMs > 0 &&
        (_dragValue != null ||
            _mousePosition != null ||
            (widget.showKeyRepeatThumbnail && widget.thumbnailDataBuilder != null));

    // The element tree below is structurally identical on every build: an
    // in-flight drag must never be disposed mid-gesture by a tree flip, and
    // the eager recognizer claims the arena at pointer-down so ancestor
    // recognizers (content-strip swipe, long-press 2x) can't steal a scrub
    // (#1302). The Material Slider is visual-only.
    Widget slider = Builder(
      builder: (sliderContext) => RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        gestures: widget.enabled
            ? <Type, GestureRecognizerFactory>{
                EagerHorizontalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<EagerHorizontalDragGestureRecognizer>(
                      () =>
                          EagerHorizontalDragGestureRecognizer(debugOwner: this)
                            ..dragStartBehavior = DragStartBehavior.down,
                      (instance) {
                        instance.onStart = (details) => _handleScrubStart(details, sliderContext);
                        instance.onUpdate = (details) => _handleScrubUpdate(details, sliderContext);
                        instance.onEnd = (_) => _handleScrubEnd();
                        instance.onCancel = _handleScrubEnd;
                      },
                    ),
              }
            : const <Type, GestureRecognizerFactory>{},
        child: Stack(
          clipBehavior: Clip.none,
          alignment: .center,
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
                      chapters: widget.chaptersLoaded && widget.showChapterMarkersOnTimeline
                          ? widget.chapters
                          : const [],
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              label: t.videoControls.timelineSlider,
              slider: true,
              value: formatDurationTimestamp(displayPosition),
              increasedValue: formatDurationTimestamp(
                Duration(milliseconds: (displayValue + 10000).clamp(0.0, max).round()),
              ),
              decreasedValue: formatDurationTimestamp(
                Duration(milliseconds: (displayValue - 10000).clamp(0.0, max).round()),
              ),
              enabled: widget.enabled,
              onIncrease: widget.enabled && durationMs > 0 ? () => _semanticSeekBy(const Duration(seconds: 10)) : null,
              onDecrease: widget.enabled && durationMs > 0 ? () => _semanticSeekBy(const Duration(seconds: -10)) : null,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 8,
                      trackGap: 0,
                      padding: .zero,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                      thumbSize: WidgetStatePropertyAll(
                        (!InputModeTracker.isKeyboardMode(context) || _isFocused) ? const Size(4, 20) : Size.zero,
                      ),
                    ),
                    child: Slider(
                      value: displayValue,
                      min: 0.0,
                      max: max,
                      onChanged: _noopSliderChanged,
                      activeColor: Colors.white,
                      inactiveColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            // Tooltip layer: a permanent child so showing/hiding the tooltip
            // never changes the structure around the slider.
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tooltip = hasTooltip
                        ? _buildActiveTooltip(constraints.maxWidth, durationMs, displayValue, displayPosition)
                        : null;
                    return Stack(clipBehavior: Clip.none, children: [?tooltip]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
        descendantsAreFocusable: false,
        child: slider,
      );
    }

    return Builder(
      builder: (context) => MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onHover: (event) {
          final trackWidth = _sliderWidthOf(context) - 2 * _sliderPadding;
          _updateHoverPosition(event.localPosition.dx, trackWidth, durationMs);
        },
        onExit: (_) => _clearHoverPosition(),
        child: slider,
      ),
    );
  }
}

class _ScrubFrameView extends StatelessWidget {
  final ScrubFrame frame;
  const _ScrubFrameView({required this.frame});

  int? _cacheDimension(double logicalSize, double devicePixelRatio) {
    if (!logicalSize.isFinite || logicalSize <= 0) return null;
    return (logicalSize * devicePixelRatio).round().clamp(1, 8192).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final f = frame;
    switch (f) {
      case BytesScrubFrame():
        return LayoutBuilder(
          builder: (context, constraints) {
            final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
            return Image.memory(
              f.bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: _cacheDimension(constraints.maxWidth, devicePixelRatio),
              cacheHeight: _cacheDimension(constraints.maxHeight, devicePixelRatio),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            );
          },
        );
      case SheetScrubFrame():
        // The parent tooltip box matches the source tile aspect (see
        // `tooltipHeight = tooltipWidth / frame.aspectRatio` above), so each
        // source tile maps 1:1 to the box without distortion or cropping.
        return LayoutBuilder(
          builder: (context, constraints) {
            final tileW = constraints.maxWidth;
            final tileH = constraints.maxHeight;
            final sheetW = tileW * f.sheetColumns;
            final sheetH = tileH * f.sheetRows;
            final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
            final sheet = ResizeImage.resizeIfNeeded(
              _cacheDimension(sheetW, devicePixelRatio),
              _cacheDimension(sheetH, devicePixelRatio),
              f.sheet,
            );
            return ClipRect(
              child: OverflowBox(
                maxWidth: sheetW,
                maxHeight: sheetH,
                alignment: .topLeft,
                child: Transform.translate(
                  offset: Offset(-f.tileColumn * tileW, -f.tileRow * tileH),
                  child: Image(
                    image: sheet,
                    width: sheetW,
                    height: sheetH,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}
