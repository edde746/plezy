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
  const TrackerSessionMonitor({super.key, required this.enabled, required this.child, this.intervalMinutes = 5})
    : assert(intervalMinutes >= 1 && intervalMinutes <= 60);

  final bool enabled;
  final int intervalMinutes;
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
    if (oldWidget.enabled != widget.enabled || oldWidget.intervalMinutes != widget.intervalMinutes) _schedule();
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
    // Use the chosen interval with up to 20% jitter to avoid synchronized
    // requests. Account checks never rotate tokens unnecessarily.
    final seconds = widget.intervalMinutes * 60;
    final variation = seconds ~/ 5;
    _timer = Timer(Duration(seconds: seconds - variation + _random.nextInt(2 * variation + 1)), () {
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
