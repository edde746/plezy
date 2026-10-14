import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/trackers_provider.dart';
import '../utils/app_logger.dart';

/// Mounted with the main screen, which stays alive underneath playback routes.
/// Only foreground, online sessions poll. Jitter spreads account requests from
/// clients that started together; the provider coalesces overlapping checks.
class TrackerSessionMonitor extends StatefulWidget {
  const TrackerSessionMonitor({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<TrackerSessionMonitor> createState() => _TrackerSessionMonitorState();
}

class _TrackerSessionMonitorState extends State<TrackerSessionMonitor> with WidgetsBindingObserver {
  final _random = Random();
  Timer? _timer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void didUpdateWidget(TrackerSessionMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!widget.enabled || !_foreground) return;
    // One small account request per connected tracker every 4–6 minutes,
    // including during playback. This never rotates tokens unnecessarily.
    _timer = Timer(Duration(seconds: 240 + _random.nextInt(121)), () {
      _timer = null;
      if (!mounted || !widget.enabled || !_foreground) return;
      appLogger.d('Checking tracker sessions (periodic)');
      unawaited(context.read<TrackersProvider>().validateSessions());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
