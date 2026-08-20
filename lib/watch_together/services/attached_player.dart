import 'dart:async';

import 'package:flutter/services.dart';

import '../../mpv/mpv.dart';
import '../../services/driver_distraction.dart';
import '../../utils/app_logger.dart';
import '../primitives.dart';

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
      _nowMs = nowMs ?? watchTogetherSystemNowMs {
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
  ///
  /// Refused while a vehicle requires distraction optimization: the sync layer
  /// mirrors whatever the room is doing, and a host that keeps playing must not
  /// restart video in a car that is driving (`DD-3`). The room's state is left
  /// alone, so the guest catches up once the car is parked.
  Future<bool> play() {
    if (!automotivePlaybackAllowedNow()) {
      appLogger.d('Watch Together play refused: the vehicle requires distraction optimization');
      return Future.value(false);
    }
    final expectation = _expect(_Expectation.playing(true, _nowMs() + _expectationTtlMs));
    return _guarded('play', (player) => player.play(), expectation);
  }

  Future<bool> pause() {
    // One acknowledgement per event: a pause issued while another is still unacknowledged would
    // leave the surplus in the ledger, and the user's next real pause would be consumed as its ack.
    if (_awaitingPlaying(false)) return pauseWithoutAck();
    final expectation = _expect(_Expectation.playing(false, _nowMs() + _expectationTtlMs));
    return _guarded('pause', (player) => player.pause(), expectation);
  }

  /// Pauses without recording an expectation, for a player that is not playing right now — a
  /// buffering one still intends to, so the command matters, but no `playing(false)` event is
  /// coming to acknowledge. Recording one anyway would leave it in the ledger for its whole
  /// lifetime and let it swallow the user's next real pause.
  Future<bool> pauseWithoutAck() => _guarded('pause', (player) => player.pause());

  Future<bool> setRate(double rate) {
    final expectation = _expect(_Expectation.rate(rate, _nowMs() + _expectationTtlMs));
    return _guarded('setRate', (player) => player.setRate(rate), expectation);
  }

  /// Seek issued by the sync layer. Routed through the screen's seek
  /// delegate when provided (Plex transcode restarts need the full path),
  /// falling back to a plain player seek.
  ///
  /// A seek can start playback without anyone calling [play] — mpv leaves `pause=false` at end of
  /// file, so seeking off it resumes — which would walk straight past the vehicle guard on [play].
  /// While the vehicle requires distraction optimization the seek is therefore followed by a pause.
  Future<bool> seek(Duration target) async {
    final seeked = await _guarded('seek', (player) async {
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
    if (seeked && !automotivePlaybackAllowedNow()) {
      // Decided after the seek, because that is when a player resumed by it reports itself playing
      // — and only then is there a transition to acknowledge. Acknowledging it keeps this peer's
      // enforced pause off the room, exactly like the one the restriction listener issues.
      await (playing ? pause() : pauseWithoutAck());
    }
    return seeked;
  }

  _Expectation _expect(_Expectation expectation) {
    _expectations.add(expectation);
    return expectation;
  }

  /// Whether an unconsumed acknowledgement for this playing value is already outstanding.
  ///
  /// Two commands in the same direction produce one event, so a second expectation would outlive
  /// it and consume the user's next real transition instead.
  bool _awaitingPlaying(bool value) {
    _pruneExpired();
    return _expectations.any((e) => e.kind == _ExpectationKind.playing && e.playingValue == value);
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
