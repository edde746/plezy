import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The shared pull-to-refresh behavior for app scroll views.
///
/// [RefreshIndicator] handles touch drags and simple trackpad scrollables.
/// Nested or competing scrollables can consume macOS trackpad pan events
/// before the indicator receives drag details, so this also triggers the same
/// indicator from a vertical trackpad pull that begins at the top.
class AppRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({super.key, required this.onRefresh, required this.child});

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  static const double _trackpadTriggerDistance = 80;

  final GlobalKey<RefreshIndicatorState> _indicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isAtTop = false;
  bool _canTriggerFromTrackpad = false;
  bool _trackpadTriggered = false;

  bool _handleMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _isAtTop = notification.metrics.extentBefore <= 1;
    }
    return false;
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _isAtTop = notification.metrics.extentBefore <= 1;
    }
    return false;
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _canTriggerFromTrackpad = _isAtTop;
    _trackpadTriggered = false;
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (!_canTriggerFromTrackpad || _trackpadTriggered) return;
    final pan = event.localPan;
    if (pan.dy < _trackpadTriggerDistance || pan.dy.abs() < pan.dx.abs()) return;

    _trackpadTriggered = true;
    final refresh = _indicatorKey.currentState?.show();
    if (refresh != null) unawaited(refresh);
  }

  void _handlePanZoomEnd(PointerPanZoomEndEvent event) {
    _canTriggerFromTrackpad = false;
    _trackpadTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerPanZoomStart: _handlePanZoomStart,
          onPointerPanZoomUpdate: _handlePanZoomUpdate,
          onPointerPanZoomEnd: _handlePanZoomEnd,
          child: RefreshIndicator(key: _indicatorKey, onRefresh: widget.onRefresh, child: widget.child),
        ),
      ),
    );
  }
}
