import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Live wall-clock label that follows the system 12/24-hour preference.
///
/// The displayed value comes from [formatClockTime] with
/// `MediaQuery.alwaysUse24HourFormatOf`, so it matches the format every other
/// time-of-day label in the app uses and flips as soon as the OS setting does.
///
/// Ticking is a one-shot timer re-armed onto each wall-clock minute boundary
/// rather than a one-second poll: one rebuild per minute, and the minute never
/// flips a fraction of a second late. A suspended process runs no timers, so
/// the clock also resynchronises on resume instead of waiting out the boundary
/// that elapsed while it was away.
class SystemClock extends StatefulWidget {
  const SystemClock({super.key, this.style, this.now = DateTime.now});

  /// Text style for the clock label. The two chrome surfaces that host it use
  /// different foregrounds, so the caller owns colour and size.
  final TextStyle? style;

  /// Wall-clock source. Overridden only by tests, which need the minute
  /// rollover to be deterministic.
  final DateTime Function() now;

  @override
  State<SystemClock> createState() => _SystemClockState();
}

class _SystemClockState extends State<SystemClock> with WidgetsBindingObserver {
  Timer? _tick;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now();
    _scheduleTick();
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tickNow();
  }

  void _scheduleTick() {
    final now = _now;
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute).add(const Duration(minutes: 1));
    _tick?.cancel();
    _tick = Timer(nextMinute.difference(now), _tickNow);
  }

  void _tickNow() {
    if (!mounted) return;
    setState(() => _now = widget.now());
    _scheduleTick();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClockTime(_now, is24Hour: MediaQuery.alwaysUse24HourFormatOf(context)),
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );
  }
}
