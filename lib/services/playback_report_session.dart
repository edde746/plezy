import 'dart:async';

import '../media/media_server_client.dart';

enum _PlaybackReportState { idle, starting, started, stopping, stopFailed, stopped }

class _PendingProgressReport {
  _PendingProgressReport(this.snapshot);

  final PlaybackReportSnapshot snapshot;
  final Completer<bool> completer = Completer<bool>();

  void complete(bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!completer.isCompleted) completer.completeError(error, stackTrace);
  }
}

class PlaybackStreamSelection {
  final String? mediaSourceId;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;

  const PlaybackStreamSelection({this.mediaSourceId, this.audioStreamIndex, this.subtitleStreamIndex});

  static const none = PlaybackStreamSelection();
}

typedef PlaybackStreamSelectionResolver = FutureOr<PlaybackStreamSelection> Function();

class PlaybackReportSnapshot {
  final String state;
  final Duration position;
  final Duration duration;
  final PlaybackStreamSelectionResolver resolveStreamSelection;

  const PlaybackReportSnapshot({
    required this.state,
    required this.position,
    required this.duration,
    this.resolveStreamSelection = _noStreamSelection,
  });

  bool get isStopped => state == 'stopped';

  static PlaybackStreamSelection _noStreamSelection() => PlaybackStreamSelection.none;
}

/// Serializes backend playback-report calls for one media item.
///
/// This class owns the start/progress/stop lifecycle invariants. Callers may
/// fire reports concurrently, but state changes are recorded synchronously
/// before any async work such as settings lookup, track mapping, or HTTP calls.
class PlaybackReportSession {
  PlaybackReportSession({required this.client, required this.itemId, this.playSessionId, this.playMethod});

  final MediaServerClient client;
  final String itemId;
  final String? playSessionId;
  final String? playMethod;

  _PlaybackReportState _state = _PlaybackReportState.idle;
  PlaybackReportSnapshot? _startSnapshot;
  _PendingProgressReport? _pendingProgress;
  Future<void>? _pumpFuture;
  Future<void>? _stopFuture;

  bool get isIdle => _state == _PlaybackReportState.idle;

  bool get _isStoppingOrTerminal =>
      _state == _PlaybackReportState.stopping ||
      _state == _PlaybackReportState.stopFailed ||
      _state == _PlaybackReportState.stopped;

  Future<bool> report(PlaybackReportSnapshot snapshot) {
    return snapshot.isStopped ? _reportStopped(snapshot) : _reportProgress(snapshot);
  }

  Future<bool> _reportProgress(PlaybackReportSnapshot snapshot) {
    if (_isStoppingOrTerminal) {
      return Future.value(false);
    }

    switch (_state) {
      case _PlaybackReportState.idle:
        _state = _PlaybackReportState.starting;
        _startSnapshot = snapshot;
        return _ensurePump().then((_) => true);
      case _PlaybackReportState.starting:
        // A duplicate playing heartbeat during startup does not need an
        // immediate progress ping; a state change (playing -> paused) does.
        if (_startSnapshot?.state != snapshot.state) {
          return _setPendingProgress(snapshot);
        }
        final pump = _pumpFuture;
        return (pump ?? Future<void>.value()).then((_) => true);
      case _PlaybackReportState.started:
        final pending = _setPendingProgress(snapshot);
        _ensurePump();
        return pending;
      case _PlaybackReportState.stopping:
      case _PlaybackReportState.stopFailed:
      case _PlaybackReportState.stopped:
        return Future.value(false);
    }
  }

  Future<bool> _reportStopped(PlaybackReportSnapshot snapshot) {
    if (_state == _PlaybackReportState.stopped) {
      return Future.value(false);
    }
    if (_state == _PlaybackReportState.stopping) {
      final pending = _stopFuture;
      return (pending ?? Future<void>.value()).then((_) => false);
    }

    _state = _PlaybackReportState.stopping;
    _discardPendingProgress();
    final stopFuture = _runStop(snapshot);
    _stopFuture = stopFuture;
    return stopFuture.then((_) => true);
  }

  Future<void> _ensurePump() {
    final existing = _pumpFuture;
    if (existing != null) return existing;

    final future = _runPump();
    _pumpFuture = future;
    future.then(
      (_) {
        if (identical(_pumpFuture, future)) _pumpFuture = null;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_pumpFuture, future)) _pumpFuture = null;
      },
    );
    return future;
  }

  Future<void> _runPump() async {
    try {
      final start = _startSnapshot;
      if (start != null) {
        await _sendStarted(start);
        _startSnapshot = null;
        if (_state == _PlaybackReportState.starting) {
          _state = _PlaybackReportState.started;
        }
      }

      while (_state == _PlaybackReportState.started) {
        final progress = _pendingProgress;
        if (progress == null) break;
        _pendingProgress = null;
        try {
          progress.complete(await _sendProgress(progress.snapshot));
        } catch (e, st) {
          progress.completeError(e, st);
          rethrow;
        }
      }
    } catch (_) {
      if (_state == _PlaybackReportState.starting) {
        _state = _PlaybackReportState.idle;
        _startSnapshot = null;
      }
      _discardPendingProgress();
      rethrow;
    }
  }

  Future<void> _runStop(PlaybackReportSnapshot snapshot) async {
    var stopSucceeded = false;
    try {
      final pump = _pumpFuture;
      if (pump != null) {
        try {
          await pump;
        } catch (_) {
          // Stop is terminal and best-effort. A failed start/progress report
          // must not prevent the final stopped position from being reported.
        }
      }
      await _sendStopped(snapshot);
      stopSucceeded = true;
    } finally {
      _stopFuture = null;
      _discardPendingProgress();
      _pumpFuture = null;
      _state = stopSucceeded ? _PlaybackReportState.stopped : _PlaybackReportState.stopFailed;
    }
  }

  Future<bool> _setPendingProgress(PlaybackReportSnapshot snapshot) {
    _discardPendingProgress();
    final pending = _PendingProgressReport(snapshot);
    _pendingProgress = pending;
    return pending.completer.future;
  }

  void _discardPendingProgress() {
    final pending = _pendingProgress;
    if (pending == null) return;
    _pendingProgress = null;
    pending.complete(false);
  }

  Future<void> _sendStarted(PlaybackReportSnapshot snapshot) async {
    final selection = await snapshot.resolveStreamSelection();
    await client.reportPlaybackStarted(
      itemId: itemId,
      position: snapshot.position,
      duration: snapshot.duration,
      playSessionId: playSessionId,
      playMethod: playMethod,
      mediaSourceId: selection.mediaSourceId,
      audioStreamIndex: selection.audioStreamIndex,
      subtitleStreamIndex: selection.subtitleStreamIndex,
    );
  }

  Future<bool> _sendProgress(PlaybackReportSnapshot snapshot) async {
    final selection = await snapshot.resolveStreamSelection();
    if (_state != _PlaybackReportState.started) return false;
    await client.reportPlaybackProgress(
      itemId: itemId,
      position: snapshot.position,
      duration: snapshot.duration,
      isPaused: snapshot.state == 'paused',
      playSessionId: playSessionId,
      playMethod: playMethod,
      mediaSourceId: selection.mediaSourceId,
      audioStreamIndex: selection.audioStreamIndex,
      subtitleStreamIndex: selection.subtitleStreamIndex,
    );
    return true;
  }

  Future<void> _sendStopped(PlaybackReportSnapshot snapshot) async {
    final selection = await snapshot.resolveStreamSelection();
    await client.reportPlaybackStopped(
      itemId: itemId,
      position: snapshot.position,
      duration: snapshot.duration,
      playSessionId: playSessionId,
      mediaSourceId: selection.mediaSourceId,
    );
  }
}
