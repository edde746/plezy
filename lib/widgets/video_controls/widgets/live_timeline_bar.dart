import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/livetv_capture_buffer.dart';
import '../../../mpv/mpv.dart';
import '../../../focus/focusable_wrapper.dart';

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

  int _currentEpoch(Duration playerPosition) =>
      (widget.streamStartEpoch + playerPosition.inSeconds).round();

  int _displayPosition(Duration playerPosition) =>
      _isDragging ? _dragPositionEpoch : _currentEpoch(playerPosition);

  String _formatEpochTime(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return DateFormat.jm().format(dt);
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
          _formatEpochTime(displayPos),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
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
            alignment: Alignment.centerLeft,
            child: Text(
              _formatEpochTime(displayPos),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
      onKeyEvent: widget.onKeyEvent,
      onFocusChange: widget.onFocusChange,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragStart: widget.enabled ? _onDragStart : null,
            onHorizontalDragUpdate: widget.enabled
                ? (details) => _onDragUpdate(details, width)
                : null,
            onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
            onTapUp: widget.enabled ? (details) => _onTap(details, width) : null,
            child: SizedBox(
              height: 24,
              child: CustomPaint(
                size: Size(width, 24),
                painter: _LiveTimelinePainter(
                  positionFraction: positionFraction,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPositionEpoch = _currentEpoch(widget.player.state.position);
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (width <= 0) return;
    final fraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragPositionEpoch = _fractionToEpoch(fraction);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final target = _dragPositionEpoch;
    setState(() => _isDragging = false);
    widget.onSeekEnd?.call(target);
  }

  void _onTap(TapUpDetails details, double width) {
    if (width <= 0) return;
    final fraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final target = _fractionToEpoch(fraction);
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
    const trackHeight = 4.0;
    const thumbRadius = 6.0;
    final posX = positionFraction * w;

    // Background track (unplayed)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, trackY), width: w, height: trackHeight),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // Played region
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, trackY - trackHeight / 2, posX, trackY + trackHeight / 2),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.red,
    );

    // Thumb
    canvas.drawCircle(Offset(posX, trackY), thumbRadius, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant _LiveTimelinePainter oldDelegate) =>
      positionFraction != oldDelegate.positionFraction;
}
