import 'dart:async';

/// The in-place media-source transitions a player screen can run.
/// They are mutually exclusive by construction — entry points bail while a
/// transition is in flight.
enum PlaybackTransition { idle, switchingSource, reloadingMedia, switchingChannel }

/// Identity token for one owner of the in-place playback transition lock.
///
/// The enum describes what the current owner is doing; it is not itself an
/// ownership token because a superseded async flow can outlive a newer flow
/// that has since acquired the same enum value.
final class PlaybackTransitionLease {
  PlaybackTransitionLease._();

  bool _wasSuperseded = false;

  bool get wasSuperseded => _wasSuperseded;
}

/// The player screen's transition lock and playback generation counter.
///
/// Owns the mutually-exclusive transition state, the lease identity that
/// guards it, the idle completer that [waitForIdle] callers block on, and the
/// monotonically increasing generation that stamps every playback attempt.
/// Plain State-owned object; writers were already centralized in the screen
/// core before extraction.
class PlaybackTransitionGate {
  PlaybackTransition _transition = PlaybackTransition.idle;
  PlaybackTransitionLease? _lease;
  Completer<void>? _idleCompleter;
  int _generation = 0;

  PlaybackTransition get transition => _transition;

  /// The current playback generation; bumped by [beginGeneration] and
  /// [bumpGeneration]. Async continuations compare a captured value against
  /// this to detect supersession.
  int get generation => _generation;

  /// Start a new playback generation. A full (non-reload) attempt also
  /// force-idles the transition lock: whatever owned it is superseded.
  int beginGeneration({bool isMediaReload = false}) {
    if (!isMediaReload) forceIdle();
    return ++_generation;
  }

  /// Invalidate in-flight continuations without touching the transition lock
  /// — the failed-initialization teardown path.
  void bumpGeneration() {
    _generation++;
  }

  PlaybackTransitionLease? tryAcquire(PlaybackTransition transition) {
    assert(transition != PlaybackTransition.idle);
    if (_transition != PlaybackTransition.idle) return null;
    final lease = PlaybackTransitionLease._();
    _lease = lease;
    _change(transition);
    return lease;
  }

  bool owns(PlaybackTransitionLease lease, {PlaybackTransition? expected}) {
    return identical(_lease, lease) && (expected == null || _transition == expected);
  }

  bool advance(PlaybackTransitionLease lease, PlaybackTransition transition, {PlaybackTransition? expected}) {
    assert(transition != PlaybackTransition.idle);
    if (!owns(lease, expected: expected)) return false;
    _change(transition);
    return true;
  }

  void release(PlaybackTransitionLease lease) {
    if (!identical(_lease, lease)) return;
    _lease = null;
    _change(PlaybackTransition.idle);
  }

  void forceIdle() {
    _lease?._wasSuperseded = true;
    _lease = null;
    _change(PlaybackTransition.idle);
  }

  void _change(PlaybackTransition transition) {
    if (_transition == transition) return;
    _transition = transition;
    if (transition == PlaybackTransition.idle) {
      final completer = _idleCompleter;
      _idleCompleter = null;
      if (completer != null && !completer.isCompleted) completer.complete();
    } else {
      _idleCompleter ??= Completer<void>();
    }
  }

  /// Wait until the lock is idle. [shouldWait] is re-checked after every
  /// wake-up so a disposed screen stops waiting.
  Future<void> waitForIdle(bool Function() shouldWait) async {
    while (shouldWait() && _transition != PlaybackTransition.idle) {
      _idleCompleter ??= Completer<void>();
      await _idleCompleter!.future;
    }
  }

  /// Complete any idle waiters during screen dispose so they cannot leak.
  void completeIdleWaiters() {
    final completer = _idleCompleter;
    _idleCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }
}
