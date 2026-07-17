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
  final ClipSelection trimWindow;
  final ClipSelection selection;
  final bool enabled;
  final ScrubFrame? Function(Duration position)? thumbnailDataBuilder;
  final ValueChanged<_ClipTrimUpdate> onChanged;
  final ValueChanged<ClipSelection> onChangeEnd;

  const _ClipTrimSlider({
    required this.duration,
    required this.trimWindow,
    required this.selection,
    required this.enabled,
    required this.thumbnailDataBuilder,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<_ClipTrimSlider> createState() => _ClipTrimSliderState();
}

class _ClipTrimSliderState extends State<_ClipTrimSlider> {
  final LayerLink _tooltipLink = LayerLink();

  OverlayEntry? _tooltipOverlay;
  Duration? _hoverPosition;
  Duration? _dragPosition;
  Duration? _tooltipPosition;
  ScrubFrame? _tooltipFrame;
  Offset _tooltipOffset = Offset.zero;

  @override
  void didUpdateWidget(covariant _ClipTrimSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _removeTooltip();
    }
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  Duration _positionForDx(double dx, double width) {
    final minMs = widget.trimWindow.start.inMilliseconds;
    final maxMs = widget.trimWindow.end.inMilliseconds <= widget.trimWindow.start.inMilliseconds
        ? minMs + 1
        : widget.trimWindow.end.inMilliseconds;
    final fraction = width <= 0 ? 0.0 : (dx / width).clamp(0.0, 1.0);
    return Duration(milliseconds: (minMs + (maxMs - minMs) * fraction).round());
  }

  double _dxForPosition(Duration position, double width) {
    final minMs = widget.trimWindow.start.inMilliseconds;
    final maxMs = widget.trimWindow.end.inMilliseconds <= widget.trimWindow.start.inMilliseconds
        ? minMs + 1
        : widget.trimWindow.end.inMilliseconds;
    final fraction = ((position.inMilliseconds - minMs) / (maxMs - minMs)).clamp(0.0, 1.0);
    return fraction * width;
  }

  void _updateHover(Offset localPosition, double width) {
    final position = _positionForDx(localPosition.dx, width);
    if (_hoverPosition?.inSeconds == position.inSeconds) return;
    _hoverPosition = position;
    _showOrUpdateTooltip(position: position, dx: localPosition.dx);
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
    final tooltipWidth = _ClipTrimTooltip.widthFor(frame);
    final tooltipHeight = _ClipTrimTooltip.heightFor(frame);
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
            child: _ClipTrimTooltip(frame: _tooltipFrame, position: position),
          ),
        ),
      ),
    );
  }

  void _removeTooltip() {
    _tooltipPosition = null;
    _tooltipFrame = null;
    _tooltipOverlay?.remove();
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
              onHover: widget.enabled ? (event) => _updateHover(event.localPosition, constraints.maxWidth) : null,
              onExit: (_) => _clearHover(),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(rangeTrackShape: const RoundedRectRangeSliderTrackShape()),
                child: RangeSlider(
                  min: minMs,
                  max: maxMs,
                  values: RangeValues(startMs, endMs <= startMs ? (startMs + 1).clamp(minMs, maxMs).toDouble() : endMs),
                  labels: RangeLabels(
                    ClipExportService.formatClipTimestamp(widget.selection.start),
                    ClipExportService.formatClipTimestamp(widget.selection.end),
                  ),
                  onChanged: widget.enabled
                      ? (values) {
                          final previousStartMs = widget.selection.start.inMilliseconds.toDouble();
                          final previousEndMs = widget.selection.end.inMilliseconds.toDouble();
                          final next = ClipSelection(
                            start: Duration(milliseconds: values.start.round()),
                            end: Duration(milliseconds: values.end.round()),
                          ).clampedTo(widget.duration);
                          if (next.duration < clipMinimumDuration) return;
                          final handle = (values.end - previousEndMs).abs() >= (values.start - previousStartMs).abs()
                              ? _ClipPreviewHandle.end
                              : _ClipPreviewHandle.start;
                          final previewPosition = handle == _ClipPreviewHandle.end ? next.end : next.start;
                          _dragPosition = previewPosition;
                          _showOrUpdateTooltip(
                            position: previewPosition,
                            dx: _dxForPosition(previewPosition, constraints.maxWidth),
                          );
                          widget.onChanged(_ClipTrimUpdate(selection: next, handle: handle));
                        }
                      : null,
                  onChangeEnd: widget.enabled
                      ? (values) {
                          final next = ClipSelection(
                            start: Duration(milliseconds: values.start.round()),
                            end: Duration(milliseconds: values.end.round()),
                          ).clampedTo(widget.duration);
                          _dragPosition = null;
                          if (_hoverPosition == null) _removeTooltip();
                          widget.onChangeEnd(next);
                        }
                      : null,
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
  static double widthFor(ScrubFrame? frame) => frame == null ? 74.0 : 124.0;
  static double heightFor(ScrubFrame? frame) => frame == null ? 26.0 : 70.0;

  final ScrubFrame? frame;
  final Duration position;

  const _ClipTrimTooltip({required this.frame, required this.position});

  @override
  Widget build(BuildContext context) {
    final frame = this.frame;
    final width = widthFor(frame);
    final height = heightFor(frame);

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
                        child: Text(
                          ClipExportService.formatClipTimestamp(position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
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
