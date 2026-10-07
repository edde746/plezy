import 'dart:async';

import '../../media/live_tv_support.dart';

/// Sends one live-TV timeline report and commits what it learned only while
/// the dispatching session and scheduling generation still own the screen.
Future<void> runLiveTimelineReport({
  required LiveTvPlaybackSession requestSession,
  required int requestGeneration,
  required String state,
  required int positionMs,
  required LiveTvPlaybackSession? Function() currentSession,
  required int Function() currentGeneration,
  required bool Function() isMounted,
  required void Function(LiveTimelineUpdate update) commit,
}) async {
  final update = await requestSession.reportTimeline(
    state: state,
    positionMs: positionMs,
    durationMs: requestSession.program.durationMs ?? 0,
  );
  if (update == null ||
      state == 'stopped' ||
      !isMounted() ||
      currentGeneration() != requestGeneration ||
      !identical(currentSession(), requestSession)) {
    return;
  }
  commit(update);
}

/// Orders reports for one tuned session. Closing the queue synchronously
/// rejects new heartbeats, while the terminal report waits for older HTTP
/// requests so a late playing report cannot resurrect the backend session.
///
/// A heartbeat that arrives while an earlier report is still pending is
/// skipped rather than queued: the next tick carries a fresher position, and
/// queueing every tick behind a server that stopped answering would build a
/// backlog of stale positions to replay once it recovers.
class LiveTimelineReportQueue {
  Future<void>? _pending;
  Future<void>? _stopped;

  Future<void> send({required bool stopped, required Future<void> Function() report}) {
    final terminal = _stopped;
    if (terminal != null) return terminal;
    final previous = _pending;
    if (!stopped && previous != null) return Future<void>.value();
    final completer = Completer<void>();
    final operation = completer.future;
    _pending = operation;
    if (stopped) _stopped = operation;
    unawaited(() async {
      try {
        if (previous != null) {
          try {
            await previous;
          } catch (_) {
            // A failed heartbeat must not prevent the final stop attempt.
          }
        }
        await report();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_pending, operation)) _pending = null;
      }
    }());
    return operation;
  }
}
