import 'dart:async';

import 'package:flutter/services.dart';

import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';

enum _ExpectationKind { playing, rate }

class _Expectation {
  final _ExpectationKind kind;
  final bool? playingValue;
  final double? rateValue;
  final int deadlineMs;

  _Expectation.playing(bool value, this.deadlineMs)
    : kind = _ExpectationKind.playing,
      playingValue = value,
      rateValue = null;

  _Expectation.rate(double value, this.deadlineMs)
    : kind = _ExpectationKind.rate,
      playingValue = null,
      rateValue = value;
}

/// One player attachment to a Watch Together session.
///
/// Wraps the screen's [Player] with:
/// - **Guarded commands** that survive player teardown races: recoverable
///   failures ([StateError], `COMMAND_FAILED`/`NOT_INITIALIZED`
///   [PlatformException]s) report `false` and fire [AttachedPlayer.new]'s
///   `onLost` once instead of throwing.
/// - An **expected-state ledger** separating command acks from user intents
///   on the playing/rate streams. Property events arrive *after* the command
///   future resolves, so a boolean "remote action in progress" flag misses
///   them; the ledger matches observed transitions against outstanding
///   expectations instead.
/// - Fresh snapshot reads for sync math ([position] uses
///   [Player.currentPosition], not the throttled state).
///
/// The session controller creates one instance per attachment and disposes
/// it on detach — instance lifecycle *is* the staleness guard.
class AttachedPlayer {
  AttachedPlayer({required Player player, required this._onLost, this._remoteSeek, int Function()? nowMs})
    : _player = player,
      _nowMs = nowMs ?? _systemNowMs {
    _lastPlaying = player.state.playing;
    _lastBuffering = player.state.buffering;
    _lastRate = player.state.rate;

    _subscriptions.add(player.streams.playing.listen(_onPlayingEvent));
    _subscriptions.add(player.streams.buffering.listen(_onBufferingEvent));
    _subscriptions.add(player.streams.rate.listen(_onRateEvent));
    _subscriptions.add(
      player.streams.playbackRestart.listen((_) {
        if (!_disposed) _loadedSignalsController.add(null);
      }),
    );
  }

  static int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

  /// How long an issued command may wait for its property event before the
  /// expectation is considered dead (covers silently-swallowed commands).
  static const int _expectationTtlMs = 3000;

  final Player _player;
  final void Function() _onLost;
  final Future<void> Function(Duration target)? _remoteSeek;
  final int Function() _nowMs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<_Expectation> _expectations = [];

  final _playingIntentsController = StreamController<bool>.broadcast();
  final _rateIntentsController = StreamController<double>.broadcast();
  final _bufferingChangesController = StreamController<bool>.broadcast();
  final _loadedSignalsController = StreamController<void>.broadcast();

  late bool _lastPlaying;
  late bool _lastBuffering;
  late double _lastRate;
  bool _disposed = false;
  bool _lostFired = false;

  /// User-initiated play/pause transitions (command acks are filtered out).
  Stream<bool> get playingIntents => _playingIntentsController.stream;

  /// User-initiated rate changes (command acks are filtered out).
  Stream<double> get rateIntents => _rateIntentsController.stream;

  /// Raw buffering transitions (`paused-for-cache`).
  Stream<bool> get bufferingChanges => _bufferingChangesController.stream;

  /// `playback-restart` events: first frame rendered after load and after
  /// every seek.
  Stream<void> get loadedSignals => _loadedSignalsController.stream;

  bool get usable => !_disposed && !_player.disposed;

  // Fresh snapshots.
  Duration get position => _player.currentPosition;
  bool get playing => _player.state.playing;
  bool get buffering => _player.state.buffering;
  bool get completed => _player.state.completed;
  bool get seekable => _player.state.seekable;
  Duration get duration => _player.state.duration;
  double get rate => _player.state.rate;
  bool get passthroughActive => _player.audioPassthroughActive;

  /// Demuxer cache ahead of the playhead, or null when the backend hasn't
  /// reported a cache position.
  Duration? get bufferAhead {
    final buffer = _player.state.buffer;
    if (buffer == Duration.zero) return null;
    final ahead = buffer - position;
    return ahead.isNegative ? Duration.zero : ahead;
  }

  /// Start or resume playback. Records a ledger expectation so the resulting
  /// playing event is consumed as an ack.
  Future<bool> play() {
    final expectation = _expect(_Expectation.playing(true, _nowMs() + _expectationTtlMs));
    return _guarded('play', (player) => player.play(), expectation);
  }

  Future<bool> pause() {
    final expectation = _expect(_Expectation.playing(false, _nowMs() + _expectationTtlMs));
    return _guarded('pause', (player) => player.pause(), expectation);
  }

  Future<bool> setRate(double rate) {
    final expectation = _expect(_Expectation.rate(rate, _nowMs() + _expectationTtlMs));
    return _guarded('setRate', (player) => player.setRate(rate), expectation);
  }

  /// Seek issued by the sync layer. Routed through the screen's seek
  /// delegate when provided (Plex transcode restarts need the full path),
  /// falling back to a plain player seek.
  Future<bool> seek(Duration target) {
    return _guarded('seek', (player) async {
      final delegate = _remoteSeek;
      if (delegate != null) {
        try {
          await delegate(target);
          return;
        } catch (e) {
          appLogger.w('AttachedPlayer: seek delegate failed, falling back to player.seek', error: e);
        }
      }
      await player.seek(target);
    });
  }

  _Expectation _expect(_Expectation expectation) {
    _expectations.add(expectation);
    return expectation;
  }

  Future<bool> _guarded(
    String actionName,
    Future<void> Function(Player player) command, [
    _Expectation? expectation,
  ]) async {
    if (!usable) {
      _expectations.remove(expectation);
      _handleLost(actionName, StateError('Player became unavailable'));
      return false;
    }

    try {
      await command(_player);
    } on StateError catch (e) {
      _expectations.remove(expectation);
      _handleLost(actionName, e);
      return false;
    } on PlatformException catch (e) {
      _expectations.remove(expectation);
      if (e.code == 'COMMAND_FAILED' || e.code == 'NOT_INITIALIZED') {
        _handleLost(actionName, e);
        return false;
      }
      rethrow;
    }

    if (!usable) {
      _expectations.remove(expectation);
      if (!_disposed) _handleLost(actionName, StateError('Player became unavailable'));
      return false;
    }
    return true;
  }

  void _handleLost(String actionName, Object error) {
    if (_disposed || _lostFired) return;
    _lostFired = true;
    appLogger.w('AttachedPlayer: $actionName failed because the player became unavailable', error: error);
    _onLost();
  }

  void _pruneExpired() {
    final now = _nowMs();
    _expectations.removeWhere((e) => now > e.deadlineMs);
  }

  bool _consumePlayingExpectation(bool value) {
    _pruneExpired();
    final index = _expectations.indexWhere((e) => e.kind == _ExpectationKind.playing && e.playingValue == value);
    if (index < 0) return false;
    _expectations.removeAt(index);
    return true;
  }

  bool _consumeRateExpectation(double value) {
    _pruneExpired();
    final index = _expectations.indexWhere(
      (e) => e.kind == _ExpectationKind.rate && (e.rateValue! - value).abs() < 0.001,
    );
    if (index < 0) return false;
    _expectations.removeAt(index);
    return true;
  }

  void _onPlayingEvent(bool value) {
    if (_disposed || value == _lastPlaying) return;
    _lastPlaying = value;
    if (_consumePlayingExpectation(value)) return;
    _playingIntentsController.add(value);
  }

  void _onRateEvent(double value) {
    if (_disposed || value == _lastRate) return;
    _lastRate = value;
    if (_consumeRateExpectation(value)) return;
    _rateIntentsController.add(value);
  }

  void _onBufferingEvent(bool value) {
    if (_disposed || value == _lastBuffering) return;
    _lastBuffering = value;
    _bufferingChangesController.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _expectations.clear();
    final subscriptions = List<StreamSubscription<dynamic>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    await _playingIntentsController.close();
    await _rateIntentsController.close();
    await _bufferingChangesController.close();
    await _loadedSignalsController.close();
  }
}
