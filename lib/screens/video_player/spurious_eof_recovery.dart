import 'dart:async';

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import 'completion_latch.dart';
import 'media_reload_outcome.dart';
import 'playback_transition_gate.dart';
import 'wakelock_controller.dart';

/// Recovery from spurious EOFs — a network stream dying mid-file that libmpv
/// reports as a clean end-of-file (#1520).
///
/// Owns the bounded automatic-recovery budget, the progress baseline that
/// refills it, and the parked latch playback sits on once the budget is
/// spent. Exits from a park: user play/seek (always allowed, never consume
/// the budget) or the server-status monitor seeing the server come back
/// online. Plain State-owned helper in the established player pattern.
class SpuriousEofRecovery {
  SpuriousEofRecovery({
    required this.isLive,
    required this._isOffline,
    required this._isTranscoding,
    required this._transitionGate,
    required this._player,
    required this._metadata,
    required this._transportFaultSeen,
    required this._reload,
    required this._wakelock,
  });

  static const int maxAttempts = 2;
  static const int progressResetMs = 30000;

  /// mpv `file-format` values whose byte stream is a manifest, not the
  /// media: segment fetches happen inside the lavf demuxer, whose failures
  /// log under `ffmpeg/demuxer` or not at all, and the manifest's own size
  /// says nothing about the stream. Reachable on direct play through a
  /// `.strm` pointing at a playlist.
  static const Set<String> manifestFormats = {'hls', 'dash'};

  final bool isLive;
  final bool Function() _isOffline;
  final bool Function() _isTranscoding;
  final PlaybackTransitionGate _transitionGate;
  final Player? Function() _player;
  final MediaItem Function() _metadata;

  /// Whether the transport layer has logged a warning or error (see
  /// [isTransportFaultLog]) since the current file opened. A latch, not a
  /// window: ffmpeg's reconnect loop logs each attempt *before* its backoff
  /// sleep and gives up silently, and mpv's forward cache can keep playback
  /// going for minutes after the demuxer hit the dead socket, so the fault
  /// that explains an EOF may be many minutes older than the EOF.
  final bool Function() _transportFaultSeen;
  final Future<MediaReloadOutcome> Function({required Duration resumePosition, required String reason}) _reload;
  final WakelockController _wakelock;

  int _attempts = 0;
  int? _baselineMs;
  bool _parked = false;

  /// Whether a player log line is the transport layer reporting a fault.
  ///
  /// libav protocol messages (`https:`, `tls:`, `tcp:`) reach mpv's log under
  /// the bare `ffmpeg` prefix; decoders and lavf demuxers get `ffmpeg/video`,
  /// `ffmpeg/audio`, `ffmpeg/demuxer`, whose warnings are routine mid-file.
  static bool isTransportFaultLog(PlayerLog log) {
    return log.prefix == 'ffmpeg' &&
        (log.level == PlayerLogLevel.warn || log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal);
  }

  /// Playback is parked mid-file on a dead stream: automatic recovery failed
  /// or its budget is spent.
  bool get parked => _parked;

  /// Any freshly opened stream ends a dead-stream park (#1520).
  void clearPark() {
    _parked = false;
  }

  /// An item change starts a fresh automatic-recovery budget (loop guard).
  void resetBudget() {
    _attempts = 0;
    _baselineMs = null;
  }

  /// Sustained progress past the recovery baseline proves the rebuilt stream
  /// is healthy; refill the automatic budget for the next stream death.
  void onPositionAdvanced(int positionMs) {
    final baselineMs = _baselineMs;
    if (baselineMs != null && positionMs >= baselineMs + progressResetMs) {
      _attempts = 0;
      _baselineMs = null;
    }
  }

  /// The player reports a clean EOF when a network stream dies mid-file
  /// (#1520) — no libmpv signal distinguishes it from the real end, so
  /// position vs best-known duration is the first discriminator (see
  /// [classifyEofSignal]). An EOF that lands short of the duration is then
  /// checked against the transport: for a direct-play source of known size,
  /// ffmpeg's HTTP layer cannot end early silently — a connection that closes
  /// short of `Content-Length` logs "Stream ends prematurely", and the
  /// reconnect loop network VOD opens with (`stream-lavf-o` in
  /// `_applyNetworkStreamTuning`) logs its first attempt before any backoff
  /// — so a demuxer EOF with no transport fault anywhere behind it in this
  /// file is the container's own end (a remux that lost the last minute of
  /// its primary video and audio while the dub tracks run on) and runs the
  /// normal completion flow. Returns true when the signal was spurious and
  /// handled here (recovery started, or playback stays parked); false lets
  /// the caller run the normal completion flow.
  Future<bool> interceptEof(Player currentPlayer) async {
    // Live EOFs have their own handling, an offline file can't lose its
    // stream, and in-flight transitions already produce expected EOFs that
    // the completion flow ignores — all fall through untouched.
    if (isLive || _isOffline()) return false;
    if (_transitionGate.transition != PlaybackTransition.idle) return false;
    // Already parked: swallow duplicate EOF signals without burning budget
    // or re-toasting.
    if (_parked) return true;

    final positionMs = currentPlayer.state.position.inMilliseconds;
    final playerDurationMs = currentPlayer.state.duration.inMilliseconds;
    final metadataDurationMs = _metadata().durationMs;
    final signal = classifyEofSignal(
      positionMs: positionMs,
      playerDurationMs: playerDurationMs,
      metadataDurationMs: metadataDurationMs,
    );
    if (signal != EofSignalClass.spurious) return false;

    // Only a fault-free direct-play EOF pays the channel round trips; a
    // transcode's playlist and a chunked proxy have no size for the transport
    // to hold the stream to, so the duration rule stays in charge there.
    _SourceShape? source;
    if (!_transportFaultSeen() && !_isTranscoding()) {
      source = await _readSourceShape(currentPlayer);
      // The reads yielded: a transition or a park may have landed meanwhile,
      // the player may no longer be the screen's, and mpv delivers property
      // changes ahead of queued log lines, so the fault behind this very EOF
      // may only now have reached the log tap.
      if (_transitionGate.transition != PlaybackTransition.idle || _player() != currentPlayer) return false;
      if (_parked) return true;
      if (_transportFaultSeen()) source = null;
    }
    if (source != null && source.isByteAddressedMedia) {
      appLogger.i(
        'EOF at ${positionMs}ms short of the duration (playerDuration=${playerDurationMs}ms, '
        'metadataDuration=${metadataDurationMs}ms) with no transport fault on a ${source.bytes}-byte '
        '${source.format} source: the container ends here; treating as complete',
      );
      return false;
    }

    appLogger.w(
      'Spurious EOF at ${positionMs}ms (playerDuration=${playerDurationMs}ms, '
      'metadataDuration=${metadataDurationMs}ms, '
      'cacheEnd=${currentPlayer.state.buffer.inMilliseconds}ms, '
      'transportFault=${_transportFaultSeen()}, transcoding=${_isTranscoding()}, '
      'source=${source == null ? 'unread' : '${source.bytes ?? 'unsized'} ${source.format ?? 'unknown'}'}), '
      'recovery attempt ${_attempts + 1}/$maxAttempts',
    );

    if (_attempts >= maxAttempts) {
      _park();
      return true;
    }
    _attempts++;
    _baselineMs = positionMs;
    unawaited(_recover(currentPlayer));
    return true;
  }

  /// mpv's `file-size` (the byte size the transport holds the stream to;
  /// unknown for chunked transfer and non-mpv backends) and `file-format`.
  static Future<_SourceShape> _readSourceShape(Player currentPlayer) async {
    try {
      final bytes = int.tryParse(await currentPlayer.getProperty('file-size') ?? '');
      final format = await currentPlayer.getProperty('file-format');
      return _SourceShape(bytes: bytes, format: format);
    } catch (error, stackTrace) {
      appLogger.d('EOF classification: source properties unavailable', error: error, stackTrace: stackTrace);
      return const _SourceShape(bytes: null, format: null);
    }
  }

  /// Leave playback parked on the dead stream: no auto-exit — the user keeps
  /// their place and the snackbar names the actions that actually rebuild the
  /// stream (play/seek route to [retry] while parked).
  void _park() {
    _parked = true;
    unawaited(_wakelock.setEnabled(false));
    showGlobalErrorSnackBar(t.messages.streamInterrupted);
  }

  /// Recover from a spurious EOF by re-running the full playback decision in
  /// place — the same path as the TV background suspend restore, because the
  /// failure is the same: the server-side stream is gone and only a fresh
  /// resolve replaces it (a seek-in-place lands inside the dead cache, and a
  /// same-session transcode seek can hit the reaped session).
  Future<void> _recover(Player currentPlayer) async {
    final outcome = await _reload(resumePosition: currentPlayer.state.position, reason: 'spurious EOF recovery');
    if (outcome == MediaReloadOutcome.failed) _park();
    // rejected/superseded: another flow owns the player and will commit
    // fresh media (clearing any park). opened: recovered — the budget
    // resets via 30s of progress or an item change.
  }

  /// Rebuild the dead stream after playback parked on a spurious EOF.
  /// User actions and the server-online monitor land here; these retries are
  /// always allowed and never consume the automatic budget.
  Future<void> retry({required String reason, Duration? resumePosition}) async {
    final currentPlayer = _player();
    if (currentPlayer == null || _transitionGate.transition != PlaybackTransition.idle) return;
    appLogger.i('Retrying dead-stream recovery ($reason)');
    _parked = false;
    final outcome = await _reload(
      resumePosition: resumePosition ?? currentPlayer.state.position,
      reason: 'stream recovery ($reason)',
    );
    if (outcome == MediaReloadOutcome.failed) _park();
  }
}

/// What mpv knows about the byte stream behind the current file.
class _SourceShape {
  const _SourceShape({required this.bytes, required this.format});

  final int? bytes;
  final String? format;

  /// The transport holds a byte stream of known size and that stream is the
  /// media itself, so ffmpeg's HTTP layer would have logged an early end.
  bool get isByteAddressedMedia {
    final bytes = this.bytes;
    final format = this.format;
    if (bytes == null || bytes <= 0 || format == null) return false;
    // `file-format` is lavf's comma-separated demuxer name list ("hls",
    // "matroska,webm", "mov,mp4,m4a,3gp,3g2,mj2").
    return !format.split(',').any(SpuriousEofRecovery.manifestFormats.contains);
  }
}
