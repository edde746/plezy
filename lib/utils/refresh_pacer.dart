import 'dart:async';

import 'package:clock/clock.dart';

/// Paces push-triggered refreshes behind three windows: a trailing [debounce]
/// that merges event bursts, a [blockedRetry] loop that waits out a surface
/// the refresh would disturb, and a [cooldown] that bounds pass frequency
/// during sustained streams (bulk imports) while deferring the pending pass
/// to the window's trailing edge so the final change always lands.
///
/// The debounce arms once per burst and is never reset by later events, so a
/// sustained sub-[debounce] event stream (several servers scanning at once)
/// cannot starve the refresh — the pass runs at most [debounce] after the
/// burst's first event. Time is read through `package:clock`, so fake-async
/// and widget tests drive it deterministically, and a timer is pending only
/// while a pass is actually owed — an idle pacer holds none.
///
/// [runPass] returns whether a pass actually started; a dropped pass (owner
/// unmounted, surface hidden) does not spend the cooldown. [notePass]
/// credits an equivalent refresh committed outside the pacer (a pull pass) so
/// a push event landing just after it defers to the cooldown's trailing edge
/// instead of fanning out an identical load.
class RefreshPacer {
  RefreshPacer({
    required this.debounce,
    required this.cooldown,
    required this.blockedRetry,
    required bool Function() isBlocked,
    required bool Function() runPass,
    // A private field cannot be a named initializing formal callers can pass.
    // ignore: prefer_initializing_formals
  }) : _isBlocked = isBlocked,
       // ignore: prefer_initializing_formals
       _runPass = runPass;

  final Duration debounce;
  final Duration cooldown;
  final Duration blockedRetry;
  final bool Function() _isBlocked;
  final bool Function() _runPass;

  /// Debounce, blocked-retry, or trailing-edge timer; any of them means a
  /// pass is already owed, which is why [schedule] arms at most once.
  Timer? _timer;
  DateTime? _lastPassAt;
  bool _disposed = false;

  /// An event arrived. No-op while a pass is already scheduled.
  void schedule() {
    if (_disposed) return;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(debounce, _run);
  }

  /// An equivalent refresh committed outside the pacer: restart the cooldown
  /// window from now. A pass already owed defers to the new window's
  /// trailing edge rather than being dropped — the pull fetch may have
  /// raced the change it reported.
  void notePass() {
    if (_disposed) return;
    _lastPassAt = clock.now();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void _run() {
    if (_disposed) return;
    if (_isBlocked()) {
      _timer = Timer(blockedRetry, _run);
      return;
    }
    final last = _lastPassAt;
    if (last != null) {
      final remaining = cooldown - clock.now().difference(last);
      if (remaining > Duration.zero) {
        // Defer to the trailing edge; re-checks the window on fire in case a
        // [notePass] moved it meanwhile.
        _timer = Timer(remaining, _run);
        return;
      }
    }
    if (_runPass()) _lastPassAt = clock.now();
  }
}
