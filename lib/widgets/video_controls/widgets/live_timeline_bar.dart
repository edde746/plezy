import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../models/livetv_capture_buffer.dart';
import '../../../mpv/mpv.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../utils/formatters.dart';
import '../../clickable_cursor.dart';
import '../helpers/eager_horizontal_drag_recognizer.dart';

/// Timeline bar for live TV time-shift.
///
/// Listens to the player's position stream and computes the absolute epoch
/// position from [streamStartEpoch] + player position. The slider range
/// covers the capture buffer's seekable window.
class LiveTimelineBar extends StatefulWidget {
  final Player player;
  final CaptureBuffer captureBuffer;
  final double streamStartEpoch;
  final bool isAtLiveEdge;
  final ValueChanged<int>? onSeekEnd;
  final bool horizontalLayout;
  final FocusNode? focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  final bool enabled;

  const LiveTimelineBar({
    super.key,
    required this.player,
    required this.captureBuffer,
    required this.streamStartEpoch,
    this.isAtLiveEdge = true,
    this.onSeekEnd,
    this.horizontalLayout = true,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.enabled = true,
  });

  @override
  State<LiveTimelineBar> createState() => _LiveTimelineBarState();
}

class _LiveTimelineBarState extends State<LiveTimelineBar> {
  bool _isDragging = false;
  int _dragPositionEpoch = 0;

  int get _rangeStart => widget.captureBuffer.seekableStartEpoch;
  int get _rangeEnd => widget.captureBuffer.seekableEndEpoch;

  int _currentEpoch(Duration playerPosition) => (widget.streamStartEpoch + playerPosition.inSeconds).round();

  int _displayPosition(Duration playerPosition) => _isDragging ? _dragPositionEpoch : _currentEpoch(playerPosition);

  String _formatEpochTime(BuildContext context, int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return formatClockTime(dt, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
  }

  double _epochToFraction(int epoch) {
    final range = _rangeEnd - _rangeStart;
    if (range <= 0) return 1.0; // No range yet → show at live edge (right)
    return ((epoch - _rangeStart) / range).clamp(0.0, 1.0);
  }

  int _fractionToEpoch(double fraction) {
    final range = _rangeEnd - _rangeStart;
    return (_rangeStart + (fraction * range).round()).clamp(_rangeStart, _rangeEnd);
  }

  double _widthOf(BuildContext context) {
    final renderObject = context.findRenderObject();
    return renderObject is RenderBox ? renderObject.size.width : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.streams.position,
      initialData: widget.player.state.position,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        final displayPos = _displayPosition(position);

        if (widget.horizontalLayout) {
          return _buildHorizontalLayout(displayPos);
        }
        return _buildVerticalLayout(displayPos);
      },
    );
  }

  Widget _buildHorizontalLayout(int displayPos) {
    return Row(
      children: [
        Text(
          _formatEpochTime(context, displayPos),
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildSlider(displayPos)),
      ],
    );
  }

  Widget _buildVerticalLayout(int displayPos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSlider(displayPos),
          const SizedBox(height: 4),
          Align(
            alignment: .centerLeft,
            child: Text(
              _formatEpochTime(context, displayPos),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(int displayPos) {
    final positionFraction = _epochToFraction(displayPos);

    return FocusableWrapper(
      focusNode: widget.focusNode,
      onKeyEvent: widget.enabled ? widget.onKeyEvent : null,
      onFocusChange: widget.onFocusChange,
      borderRadius: 8,
      autoScroll: false,
      useBackgroundFocus: true,
      disableScale: true,
      child: Builder(
        builder: (context) {
          return ClickableCursor(
            enabled: widget.enabled,
            // Eager claim: a touch that lands on the scrubber belongs to it
            // from pointer-down, so ancestor recognizers can't steal the drag
            // (#1302). A plain tap is onStart+onEnd, which seeks to the
            // tapped position.
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: widget.enabled
                  ? <Type, GestureRecognizerFactory>{
                      EagerHorizontalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<EagerHorizontalDragGestureRecognizer>(
                            () =>
                                EagerHorizontalDragGestureRecognizer(debugOwner: this)
                                  ..dragStartBehavior = DragStartBehavior.down,
                            (instance) {
                              instance.onStart = (details) => _onDragStart(details, _widthOf(context));
                              instance.onUpdate = (details) => _onDragUpdate(details, _widthOf(context));
                              instance.onEnd = (_) => _onDragEnd();
                              instance.onCancel = _onDragEnd;
                            },
                          ),
                    }
                  : const <Type, GestureRecognizerFactory>{},
              child: SizedBox(
                width: double.infinity,
                height: 24,
                child: CustomPaint(painter: _LiveTimelinePainter(positionFraction: positionFraction)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDragStart(DragStartDetails details, double width) {
    setState(() {
      _isDragging = true;
      _dragPositionEpoch = _currentEpoch(widget.player.state.position);
    });
    _applyDrag(details.localPosition.dx, width);
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging) return;
    _applyDrag(details.localPosition.dx, width);
  }

  void _applyDrag(double dx, double width) {
    if (width <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragPositionEpoch = _fractionToEpoch(fraction);
    });
  }

  /// Shared by onEnd and onCancel so an interrupted drag still finalizes.
  void _onDragEnd() {
    if (!_isDragging) return;
    final target = _dragPositionEpoch;
    setState(() => _isDragging = false);
    widget.onSeekEnd?.call(target);
  }
}

class _LiveTimelinePainter extends CustomPainter {
  final double positionFraction;

  _LiveTimelinePainter({required this.positionFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final trackY = size.height / 2;
    const trackHeight = 8.0;
    final trackRadius = Radius.circular(trackHeight / 2);
    final posX = positionFraction * w;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, trackY), width: w, height: trackHeight),
        trackRadius,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    if (posX > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, trackY - trackHeight / 2, posX, trackY + trackHeight / 2),
          trackRadius,
        ),
        Paint()..color = Colors.red,
      );
    }

    // Handle thumb (pill shape matching HandleThumbShape)
    const thumbWidth = 4.0;
    const thumbHeight = 20.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(posX, trackY), width: thumbWidth, height: thumbHeight),
        Radius.circular(thumbWidth / 2),
      ),
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveTimelinePainter oldDelegate) => positionFraction != oldDelegate.positionFraction;
}
