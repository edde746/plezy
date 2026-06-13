import 'dart:async';

import '../../utils/app_logger.dart';

/// NTP-style clock-offset estimation against the session host (guest side).
///
/// Sends pings through [sendPing] (the controller wraps them into sync
/// messages addressed to the host) and consumes pongs via [onPong]. Keeps a
/// rolling window of samples and reports the offset of the lowest-RTT sample
/// — a single clean exchange beats an average polluted by jittery ones.
///
/// All time reads go through the injected [nowMs] so tests can virtualize
/// time alongside `fakeAsync`.
class ClockSync {
  ClockSync({required this._sendPing, int Function()? nowMs}) : _nowMs = nowMs ?? _systemNowMs;

  static int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

  static const int _windowSize = 8;
  static const int _maxAcceptedRttMs = 1000;
  static const Duration _interval = Duration(seconds: 5);
  static const Duration _burstSpacing = Duration(milliseconds: 500);
  static const int _burstCount = 3;
  static const int _pendingExpiryMs = 10000;

  final void Function(int pingId) _sendPing;
  final int Function() _nowMs;

  /// In-flight pings: pingId -> local send time. Multiple may be pending.
  final Map<int, int> _pending = {};

  /// Accepted samples, oldest first.
  final List<({int offsetMs, int rttMs})> _samples = [];

  Timer? _timer;
  Timer? _burstTimer;
  bool _started = false;

  /// How far ahead the host's clock is vs ours, or null before any sample.
  int? get offsetMs => _best?.offsetMs;

  /// Lowest RTT to the host in the sample window, or null before any sample.
  int? get minRttMs => _best?.rttMs;

  ({int offsetMs, int rttMs})? get _best {
    if (_samples.isEmpty) return null;
    var best = _samples.first;
    for (final sample in _samples.skip(1)) {
      if (sample.rttMs < best.rttMs) best = sample;
    }
    return best;
  }

  /// Local time translated into the host's clock (identity until a sample
  /// arrives — callers needing a guarantee should check [offsetMs]).
  int hostNowMs() => _nowMs() + (offsetMs ?? 0);

  /// Begin measuring: a short convergence burst, then a steady interval.
  void start() {
    if (_started) return;
    _started = true;

    var sent = 0;
    _ping();
    sent++;
    _burstTimer = Timer.periodic(_burstSpacing, (timer) {
      if (sent >= _burstCount) {
        timer.cancel();
        return;
      }
      _ping();
      sent++;
    });

    _timer = Timer.periodic(_interval, (_) => _ping());
  }

  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
    _burstTimer?.cancel();
    _burstTimer = null;
    _pending.clear();
  }

  void _ping() {
    final now = _nowMs();
    _pending.removeWhere((_, sentAt) => now - sentAt > _pendingExpiryMs);
    // The ping id doubles as the send timestamp; nudge to keep ids unique
    // when two pings land on the same millisecond.
    var pingId = now;
    while (_pending.containsKey(pingId)) {
      pingId++;
    }
    _pending[pingId] = now;
    _sendPing(pingId);
  }

  /// Feed a pong from the host. [remoteTimestampMs] is the host's clock when
  /// it created the pong.
  void onPong(int pingId, int remoteTimestampMs) {
    final sentAt = _pending.remove(pingId);
    if (sentAt == null) return; // Not ours or already expired.

    final now = _nowMs();
    final rtt = now - sentAt;
    if (rtt < 0 || rtt > _maxAcceptedRttMs) {
      appLogger.d('ClockSync: discarding sample with RTT=${rtt}ms');
      return;
    }

    final offset = remoteTimestampMs - sentAt - (rtt ~/ 2);
    _samples.add((offsetMs: offset, rttMs: rtt));
    if (_samples.length > _windowSize) {
      _samples.removeAt(0);
    }
  }
}
