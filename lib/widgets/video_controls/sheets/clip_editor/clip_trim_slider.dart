part of '../clip_editor_sheet.dart';

class _ClipTrimBoundsHeader extends StatelessWidget {
  final ClipSelection selection;

  const _ClipTrimBoundsHeader({required this.selection});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        Text(
          ClipExportService.formatClipTimestamp(selection.start),
          key: const ValueKey('clip_trim_start_label'),
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Text(
          ClipExportService.formatClipTimestamp(selection.end),
          key: const ValueKey('clip_trim_end_label'),
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ClipTrimSlider extends StatefulWidget {
  final Duration duration;
  final double? frameRate;
  final ClipSelection trimWindow;
  final ClipSelection selection;
  final bool enabled;
  final ScrubFrame? Function(Duration position)? thumbnailDataBuilder;
  final ValueChanged<_ClipTrimUpdate> onChanged;

  const _ClipTrimSlider({
    required this.duration,
    required this.frameRate,
    required this.trimWindow,
    required this.selection,
    required this.enabled,
    required this.thumbnailDataBuilder,
    required this.onChanged,
  });

  @override
  State<_ClipTrimSlider> createState() => _ClipTrimSliderState();
}

class _ClipTrimSliderState extends State<_ClipTrimSlider> with WidgetsBindingObserver {
  final LayerLink _tooltipLink = LayerLink();

  OverlayEntry? _tooltipOverlay;
  Duration? _hoverPosition;
  Duration? _dragPosition;
  Duration? _tooltipPosition;
  ScrubFrame? _tooltipFrame;
  Offset _tooltipOffset = Offset.zero;

  static const _dwellDuration = Duration(milliseconds: 400);
  static const _dwellTolerance = 3.0;
  static const _fineSensitivity = 0.1;

  RenderBox? _trackBox;
  Rect _track = Rect.zero;
  Offset _startCenter = Offset.zero;
  Offset _endCenter = Offset.zero;
  Size _hitSize = Size.zero;
  double _thumbInset = 0;
  int? _pointer;
  _ClipPreviewHandle? _handle;
  ClipSelection? _accepted;
  Offset _lastPointer = Offset.zero;
  Offset _dwellAnchor = Offset.zero;
  double _endpointMs = 0;
  Timer? _dwellTimer;
  bool _fine = false;
  double? _fineFrameRate;
  int? _fineFrame;
  // Keep stock gesture ownership separate from raw pointer lifetime: either
  // pointer-up or RangeSlider.onChangeEnd may arrive first.
  bool _mouseHandleSequence = false;
  bool _stockMouseGesture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _ClipTrimSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pointer == null) _accepted = widget.selection;
    if (!widget.enabled ||
        widget.duration != oldWidget.duration ||
        widget.trimWindow.start != oldWidget.trimWindow.start ||
        widget.trimWindow.end != oldWidget.trimWindow.end) {
      _cancelMouseGesture();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancelMouseGesture();
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    if (event.viewId == View.of(context).viewId && event.state == ViewFocusState.unfocused) {
      _cancelMouseGesture();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _finishMouseGesture();
    super.dispose();
  }

  bool get _validTrack =>
      _trackBox?.attached == true &&
      _track.width.isFinite &&
      _track.width > 0 &&
      widget.trimWindow.duration > Duration.zero &&
      widget.duration > Duration.zero;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  ClipSelection get _selection => _accepted ?? widget.selection;

  Duration _positionForDx(double dx) {
    var fraction = ((dx - _track.left) / _track.width).clamp(0.0, 1.0);
    if (_rtl) fraction = 1 - fraction;
    return Duration(
      milliseconds: (widget.trimWindow.start.inMilliseconds + widget.trimWindow.duration.inMilliseconds * fraction)
          .round(),
    );
  }

  double _dxForPosition(Duration position) {
    var fraction = ((position - widget.trimWindow.start).inMicroseconds / widget.trimWindow.duration.inMicroseconds)
        .clamp(0.0, 1.0);
    if (_rtl) fraction = 1 - fraction;
    // Flutter clips the handle centers at rounded track ends. Keep the tooltip
    // on the painted handle there, while retaining its value-track scale.
    return (_track.left + fraction * _track.width).clamp(_track.left + _thumbInset, _track.right - _thumbInset);
  }

  double _tooltipDx(double trackDx) {
    final target = context.findRenderObject() as RenderBox;
    return target.globalToLocal(_trackBox!.localToGlobal(Offset(trackDx, 0))).dx;
  }

  void _showEndpoint() {
    if (!_validTrack || _handle == null) return;
    final position = _handle == _ClipPreviewHandle.start ? _selection.start : _selection.end;
    _dragPosition = position;
    _showOrUpdateTooltip(position: position, dx: _tooltipDx(_dxForPosition(position)));
  }

  void _restartDwell() {
    _dwellTimer?.cancel();
    _dwellAnchor = _lastPointer;
    _dwellTimer = Timer(_dwellDuration, () {
      _dwellTimer = null;
      if (_pointer == null || !widget.enabled || !_validTrack) return;
      _fine = true;
      // Start from the accepted value, not displacement since mouse-down.
      _endpointMs = (_handle == _ClipPreviewHandle.start ? _selection.start : _selection.end).inMicroseconds / 1000;
      final rate = widget.frameRate;
      _fineFrameRate = rate != null && rate.isFinite && rate > 0 ? rate : null;
      _fineFrame = _fineFrameRate == null ? null : (_endpointMs * _fineFrameRate! / 1000).round();
      _showEndpoint();
    });
  }

  void _pointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _mouseHandleSequence = false;
    _accepted = widget.selection;
    if (!widget.enabled ||
        event.kind != PointerDeviceKind.mouse ||
        event.buttons != kPrimaryMouseButton ||
        !_validTrack) {
      return;
    }
    final local = _trackBox!.globalToLocal(event.position);
    final startDistance = (local - _startCenter).distance;
    final endDistance = (local - _endCenter).distance;
    bool hits(Offset center) =>
        Rect.fromCenter(center: center, width: _hitSize.width, height: _hitSize.height).contains(local);
    if (!hits(_startCenter) && !hits(_endCenter)) return;
    _handle = startDistance <= endDistance ? _ClipPreviewHandle.start : _ClipPreviewHandle.end;
    _mouseHandleSequence = true;
    _pointer = event.pointer;
    _lastPointer = local;
    _endpointMs = (_handle == _ClipPreviewHandle.start ? _selection.start : _selection.end).inMicroseconds / 1000;
    _hoverPosition = null;
    _restartDwell();
    _showEndpoint();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if (event.buttons & kPrimaryMouseButton == 0 || !_validTrack) {
      _cancelMouseGesture();
      return;
    }
    final local = _trackBox!.globalToLocal(event.position);
    final delta = local.dx - _lastPointer.dx;
    _lastPointer = local;
    if (!_fine && (local - _dwellAnchor).distance > _dwellTolerance) _restartDwell();
    if (delta == 0) return;
    final selection = _selection;
    final windowStart = widget.trimWindow.start.inMilliseconds.clamp(0, widget.duration.inMilliseconds);
    final windowEnd = widget.trimWindow.end.inMilliseconds.clamp(windowStart, widget.duration.inMilliseconds);
    final minimum = clipMinimumDuration.inMilliseconds;
    final lower = _handle == _ClipPreviewHandle.start ? windowStart : selection.start.inMicroseconds / 1000 + minimum;
    final upper = _handle == _ClipPreviewHandle.start ? selection.end.inMicroseconds / 1000 - minimum : windowEnd;
    if (lower > upper) return;
    // Clamp the accumulator itself, discarding outward overshoot while retaining
    // sub-millisecond motion everywhere else.
    _endpointMs =
        (_endpointMs +
                delta *
                    (_rtl ? -1 : 1) *
                    widget.trimWindow.duration.inMilliseconds /
                    _track.width *
                    (_fine ? _fineSensitivity : 1))
            .clamp(lower.toDouble(), upper.toDouble());
    final rate = _fineFrameRate;
    Duration endpoint;
    if (_fine && rate != null) {
      // Quantize by frame index, never by a rounded millisecond frame length.
      // The half-microsecond allowance matches Duration's final rounding at
      // boundaries (e.g. a 24 fps frame is 41666.666... microseconds long).
      final firstFrame = ((lower * 1000 - 0.5) * rate / Duration.microsecondsPerSecond).ceil();
      final lastFrame = ((upper * 1000 + 0.5) * rate / Duration.microsecondsPerSecond).floor();
      if (firstFrame > lastFrame) return;
      _endpointMs = _endpointMs.clamp(firstFrame * 1000 / rate, lastFrame * 1000 / rate);
      final frame = (_endpointMs * rate / 1000).round().clamp(firstFrame, lastFrame);
      // A stationary hold (or tiny jitter) must not snap the initial value.
      if (frame == _fineFrame) return;
      _fineFrame = frame;
      endpoint = Duration(microseconds: (frame * Duration.microsecondsPerSecond / rate).round());
    } else {
      endpoint = Duration(milliseconds: _endpointMs.round());
    }
    _accept(
      ClipSelection(
        start: _handle == _ClipPreviewHandle.start ? endpoint : selection.start,
        end: _handle == _ClipPreviewHandle.end ? endpoint : selection.end,
      ),
      _handle!,
    );
    _showEndpoint();
  }

  bool _isValid(ClipSelection next) =>
      next.start >= Duration.zero &&
      next.start >= widget.trimWindow.start &&
      next.end <= widget.trimWindow.end &&
      next.end <= widget.duration &&
      next.duration >= clipMinimumDuration;

  void _accept(ClipSelection next, _ClipPreviewHandle handle) {
    if (!_isValid(next) || (next.start == _selection.start && next.end == _selection.end)) return;
    _accepted = next;
    widget.onChanged(_ClipTrimUpdate(selection: next, handle: handle));
  }

  void _cancelMouseGesture() {
    final pointer = _pointer;
    _finishMouseGesture();
    // End Flutter's stock recognizers too: a window losing focus may never
    // receive the physical button-up. This does not affect the system cursor.
    if (pointer != null) WidgetsBinding.instance.cancelPointer(pointer);
  }

  void _finishMouseGesture() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    _pointer = null;
    _handle = null;
    _fine = false;
    _fineFrameRate = null;
    _fineFrame = null;
    _hoverPosition = null;
    _dragPosition = null;
    // Every accepted change was already emitted. Finalizing must neither seek
    // again nor resurrect RangeSlider's absolute cursor value.
    _removeTooltip();
  }

  void _updateHover(Offset globalPosition) {
    if (_pointer != null || !_validTrack) return;
    final local = _trackBox!.globalToLocal(globalPosition);
    final position = _positionForDx(local.dx);
    if (_hoverPosition?.inSeconds == position.inSeconds) return;
    _hoverPosition = position;
    _showOrUpdateTooltip(position: position, dx: _tooltipDx(_dxForPosition(position)));
  }

  void _clearHover() {
    if (_hoverPosition == null) return;
    _hoverPosition = null;
    if (_dragPosition == null) _removeTooltip();
  }

  void _showOrUpdateTooltip({required Duration position, required double dx}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;
    if (overlay == null || overlayBox == null || targetBox == null || !targetBox.hasSize) return;

    final frame = widget.thumbnailDataBuilder?.call(position);
    final tooltipSize = _ClipTrimTooltip.sizeFor(context, frame, position, _fine);
    final tooltipWidth = tooltipSize.width;
    final tooltipHeight = tooltipSize.height;
    final targetTopLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final overlaySize = overlayBox.size;
    final maxLeft = (overlaySize.width - tooltipWidth - 8).clamp(8.0, double.infinity).toDouble();
    final maxTop = (overlaySize.height - tooltipHeight - 8).clamp(8.0, double.infinity).toDouble();
    final left = (targetTopLeft.dx + dx - tooltipWidth / 2).clamp(8.0, maxLeft).toDouble();
    final top = (targetTopLeft.dy - tooltipHeight - 6).clamp(8.0, maxTop).toDouble();

    _tooltipPosition = position;
    _tooltipFrame = frame;
    _tooltipOffset = Offset(left - targetTopLeft.dx, top - targetTopLeft.dy);

    final existing = _tooltipOverlay;
    if (existing == null) {
      _tooltipOverlay = OverlayEntry(builder: _buildTooltipOverlay);
      overlay.insert(_tooltipOverlay!);
    } else {
      existing.markNeedsBuild();
    }
  }

  Widget _buildTooltipOverlay(BuildContext context) {
    final position = _tooltipPosition;
    if (position == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CompositedTransformFollower(
          link: _tooltipLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.topLeft,
          offset: _tooltipOffset,
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: _ClipTrimTooltip(frame: _tooltipFrame, position: position, fine: _fine),
          ),
        ),
      ),
    );
  }

  void _removeTooltip() {
    _tooltipPosition = null;
    _tooltipFrame = null;
    _tooltipOverlay?.remove();
    _tooltipOverlay?.dispose();
    _tooltipOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final minMs = widget.trimWindow.start.inMilliseconds.toDouble();
    final maxMs = widget.trimWindow.end.inMilliseconds <= widget.trimWindow.start.inMilliseconds
        ? minMs + 1
        : widget.trimWindow.end.inMilliseconds.toDouble();
    final startMs = widget.selection.start.inMilliseconds.clamp(minMs.toInt(), maxMs.toInt()).toDouble();
    final endMs = widget.selection.end.inMilliseconds.clamp(minMs.toInt(), maxMs.toInt()).toDouble();
    return CompositedTransformTarget(
      link: _tooltipLink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            key: const ValueKey('clip_trim_slider'),
            height: 48,
            child: MouseRegion(
              cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
              onHover: widget.enabled ? (event) => _updateHover(event.position) : null,
              onExit: (_) => _clearHover(),
              child: Listener(
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: (event) {
                  if (event.pointer == _pointer) _finishMouseGesture();
                },
                onPointerCancel: (event) {
                  if (event.pointer == _pointer) _finishMouseGesture();
                },
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    rangeTrackShape: _ClipTrimTrackShape((box, track, start, end, hitSize, thumbInset) {
                      _trackBox = box;
                      _track = track;
                      _startCenter = start;
                      _endCenter = end;
                      _hitSize = hitSize;
                      _thumbInset = thumbInset;
                    }),
                  ),
                  child: RangeSlider(
                    min: minMs,
                    max: maxMs,
                    values: RangeValues(
                      startMs,
                      endMs <= startMs ? (startMs + 1).clamp(minMs, maxMs).toDouble() : endMs,
                    ),
                    labels: RangeLabels(
                      ClipExportService.formatClipTimestamp(widget.selection.start),
                      ClipExportService.formatClipTimestamp(widget.selection.end),
                    ),
                    onChangeStart: (_) {
                      _stockMouseGesture = _mouseHandleSequence;
                      if (!_stockMouseGesture) _accepted = widget.selection;
                    },
                    onChanged: widget.enabled
                        ? (values) {
                            if (_pointer != null || _stockMouseGesture) return;
                            final previous = _selection;
                            final next = ClipSelection(
                              start: Duration(milliseconds: values.start.round()),
                              end: Duration(milliseconds: values.end.round()),
                            );
                            if (!_isValid(next)) return;
                            final handle =
                                (values.end - previous.end.inMilliseconds).abs() >=
                                    (values.start - previous.start.inMilliseconds).abs()
                                ? _ClipPreviewHandle.end
                                : _ClipPreviewHandle.start;
                            _accept(next, handle);
                            final position = handle == _ClipPreviewHandle.start ? next.start : next.end;
                            _dragPosition = position;
                            if (_validTrack) {
                              _showOrUpdateTooltip(position: position, dx: _tooltipDx(_dxForPosition(position)));
                            }
                          }
                        : null,
                    onChangeEnd: (_) {
                      final owned = _stockMouseGesture;
                      _stockMouseGesture = false;
                      if (owned || _pointer != null) return;
                      _dragPosition = null;
                      if (_hoverPosition == null) _removeTooltip();
                      // onChanged has already emitted the last valid selection.
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClipTrimTooltip extends StatelessWidget {
  static const _timestampStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const _modeStyle = TextStyle(color: Colors.white70, fontSize: 10, height: 1);

  static String _timestamp(Duration position, bool fine) {
    final normal = ClipExportService.formatClipTimestamp(position);
    return fine
        ? '${normal.substring(0, normal.length - 1)}.${(position.inMilliseconds % 1000).toString().padLeft(3, '0')}s'
        : normal;
  }

  static Size sizeFor(BuildContext context, ScrubFrame? frame, Duration position, bool fine) {
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final timestampWidth = measure(_timestamp(position, fine), _timestampStyle);
    final labelWidth = fine ? measure(t.videoControls.clip.fineAdjust, _modeStyle) : 0.0;
    final width = (timestampWidth > labelWidth ? timestampWidth : labelWidth) + 16;
    final baseWidth = frame == null ? 74.0 : 124.0;
    final textHeight =
        MediaQuery.textScalerOf(context).scale(12) + (fine ? MediaQuery.textScalerOf(context).scale(10) + 4 : 0);
    return Size(width > baseWidth ? width : baseWidth, (frame == null ? 14 : 58) + textHeight);
  }

  final ScrubFrame? frame;
  final Duration position;
  final bool fine;

  const _ClipTrimTooltip({required this.frame, required this.position, required this.fine});

  @override
  Widget build(BuildContext context) {
    final frame = this.frame;
    final size = sizeFor(context, frame, position, fine);
    final width = size.width;
    final height = size.height;

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (frame != null) ScrubFrameView(frame: frame),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_timestamp(position, fine), style: _timestampStyle),
                            if (fine) ...[
                              const SizedBox(height: 4),
                              Text(t.videoControls.clip.fineAdjust, style: _modeStyle),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Observe the existing painter's geometry, including theme padding and animated
// thumb positions. Painting remains entirely delegated to Flutter.
class _ClipTrimTrackShape extends RoundedRectRangeSliderTrackShape {
  final void Function(RenderBox, Rect, Offset, Offset, Size, double) onPaint;
  const _ClipTrimTrackShape(this.onPaint);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    final track = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final thumb = sliderTheme.rangeThumbShape!.getPreferredSize(isEnabled, isDiscrete);
    final overlay = sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete);
    onPaint(
      parentBox,
      track,
      startThumbCenter - offset,
      endThumbCenter - offset,
      Size(
        thumb.width > overlay.width ? thumb.width : overlay.width,
        thumb.height > overlay.height ? thumb.height : overlay.height,
      ),
      track.height > thumb.width ? (track.height / 2).clamp(0, track.width / 2) : 0,
    );
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      startThumbCenter: startThumbCenter,
      endThumbCenter: endThumbCenter,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
      textDirection: textDirection,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
  }
}
