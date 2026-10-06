import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../mpv/mpv.dart';

/// Builds with the wall-clock minute at which playback would end if it ran
/// from now — `now + (duration - position) / rate`, truncated to the minute —
/// or null once nothing remains.
///
/// While the playhead advances, that estimate holds still, so player events
/// drive it: duration, rate, and play-state changes, plus each change in the
/// whole minutes left. While paused or buffering the playhead stops and the
/// estimate moves with the wall clock instead (#2580), so a one-shot timer is
/// re-armed onto each minute boundary the estimate crosses, and every position
/// event — only a seek moves a stopped playhead — is re-read. A suspended
/// process runs no timers, so the estimate also resynchronises on resume.
///
/// [builder] runs when the displayed minute changes or the parent rebuilds.
class FinishTimeBuilder extends StatefulWidget {
  const FinishTimeBuilder({super.key, required this.player, required this.builder, this.now = DateTime.now});

  final Player player;

  final Widget Function(BuildContext context, DateTime? finishTime) builder;

  /// Wall-clock source. Overridden only by tests, which need minute rollovers
  /// to be deterministic.
  final DateTime Function() now;

  @override
  State<FinishTimeBuilder> createState() => _FinishTimeBuilderState();
}

class _FinishTimeBuilderState extends State<FinishTimeBuilder> with WidgetsBindingObserver {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _tick;

  /// The displayed finish time, truncated to its minute.
  DateTime? _finishMinute;

  /// Whole minutes left as of the last sync; null once nothing remains.
  int? _minutesLeft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
    _finishMinute = _sync();
  }

  @override
  void didUpdateWidget(FinishTimeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == widget.player) return;
    _unsubscribe();
    _subscribe();
    _finishMinute = _sync();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _unsubscribe();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _subscribe() {
    final streams = widget.player.streams;
    _subscriptions.addAll([
      streams.position.listen(_onPosition),
      streams.duration.listen((_) => _refresh()),
      streams.rate.listen((_) => _refresh()),
      streams.playing.listen((_) => _refresh()),
      streams.buffering.listen((_) => _refresh()),
    ]);
  }

  void _unsubscribe() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _onPosition(Duration _) {
    final state = widget.player.state;
    // Playback ticks at ~4 Hz but leaves the estimate where it was; re-reading
    // each one would only let tick jitter flip a boundary minute back and forth.
    if (_isAdvancing(state) && _wholeMinutesLeft(state) == _minutesLeft) return;
    _refresh();
  }

  void _refresh() {
    final finishMinute = _sync();
    if (finishMinute != _finishMinute) setState(() => _finishMinute = finishMinute);
  }

  /// Re-reads the player and the wall clock, re-arms the stopped-playhead tick,
  /// and returns the finish minute to display.
  DateTime? _sync() {
    _tick?.cancel();
    _tick = null;
    final state = widget.player.state;
    _minutesLeft = _wholeMinutesLeft(state);
    if (_minutesLeft == null) return null;

    final finishTime = widget.now().add((state.duration - state.position) * (1 / state.rate));
    final finishMinute = DateTime(
      finishTime.year,
      finishTime.month,
      finishTime.day,
      finishTime.hour,
      finishTime.minute,
    );
    if (!_isAdvancing(state)) {
      _tick = Timer(finishMinute.add(const Duration(minutes: 1)).difference(finishTime), _refresh);
    }
    return finishMinute;
  }

  static bool _isAdvancing(PlayerState state) => state.playing && !state.buffering;

  static int? _wholeMinutesLeft(PlayerState state) {
    final remaining = state.duration - state.position;
    return remaining.inSeconds > 0 ? remaining.inMinutes : null;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _finishMinute);
}
