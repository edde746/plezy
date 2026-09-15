import 'dart:async';

import 'package:flutter/services.dart';

import '../../mpv/mpv.dart';
import '../../services/driver_distraction.dart';
import '../../utils/app_logger.dart';
import '../primitives.dart';

/// An outstanding acknowledgement for a `playing` transition this attachment
/// commanded. Only play/pause is inferred from the player's event stream;
/// rate changes are declared explicitly by the screen
/// ([WatchTogetherController.onLocalRate]) because every deliberate rate
/// change already passes through one UI seam, whereas play/pause has many.
class _Expectation {
  final bool playingValue;
  final int deadlineMs;

  _Expectation.playing(this.playingValue, this.deadlineMs);
}

/// One player attachment to a Watch Together session.
///
/// Wraps the screen's [Player] with:
/// - **Guarded commands** that survive player teardown races: recoverable
///   failures ([StateError], `COMMAND_FAILED`/`NOT_INITIALIZED`
///   [PlatformException]s) report `false` and fire [AttachedPlayer.new]'s
///   `onLost` once instead of throwing.
/// - An **expected-state ledger** separating command acks from user intents
///   on the playing stream. Property events arrive *after* the command
///   future resolves, so a boolean "remote action in progress" flag misses
///   them; the ledger matches observed transitions against outstanding
///   expectations instead.
/// - Fresh snapshot reads for sync math ([position] uses
///   [Player.currentPosition], not the throttled state).
///
/// The session controller retains this physical-player ledger across role
/// swaps and source-open gaps. Source observations are reset by [observeBinding],
/// while late play/pause acknowledgements still reach the current role engine.
class AttachedPlayer {
  AttachedPlayer({required Player player, required this._onLost, this._remoteSeek, int Function()? nowMs})
    : _player = player,
      _nowMs = nowMs ?? watchTogetherSystemNowMs {
    _lastPlaying = player.state.playing;
    _lastBuffering = player.state.buffering;

    _subscriptions.add(player.streams.playing.listen(_onPlayingEvent));
    _subscriptions.add(player.streams.buffering.listen(_onBufferingEvent));
    _subscriptions.add(
      player.streams.playbackRestart.listen((_) {
        if (!_disposed) {
          firstFrameSeen = true;
          _loadedSignalsController.add(null);
        }
      }),
    );
  }

  /// How long an issued command may wait for its property event before the
  /// expectation is considered dead (covers silently-swallowed commands).
  static const int _expectationTtlMs = 3000;

  final Player _player;
  final void Function() _onLost;
  Future<void> Function(Duration target)? _remoteSeek;
  final int Function() _nowMs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<_Expectation> _expectations = [];

  final _playingIntentsController = StreamController<bool>.broadcast();
  final _playingAcksController = StreamController<bool>.broadcast();
  final _bufferingChangesController = StreamController<bool>.broadcast();
  final _loadedSignalsController = StreamController<void>.broadcast();

  late bool _lastPlaying;
  late bool _lastBuffering;
  bool _disposed = false;
  bool _lostFired = false;
  int _bindingGeneration = 0;
  String? ratingKey;
  String? serverId;
  String? mediaTitle;
  bool firstFrameSeen = false;
  Future<void>? startupHold;

  bool wraps(Player player) => identical(_player, player);

  /// A new source open resets observations, but not physical command acknowledgements.
  void observeBinding({
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    required bool hasFirstFrame,
    Future<void>? startupHold,
    Future<void> Function(Duration target)? remoteSeek,
  }) {
    _bindingGeneration++;
    this.ratingKey = ratingKey;
    this.serverId = serverId;
    this.mediaTitle = mediaTitle;
    firstFrameSeen = hasFirstFrame;
    this.startupHold = startupHold;
    _remoteSeek = remoteSeek;
  }

  /// Revokes source-local continuations without discarding the physical ledger.
  void unbind() {
    _bindingGeneration++;
    _remoteSeek = null;
  }

  /// User-initiated play/pause transitions (command acks are filtered out).
  Stream<bool> get playingIntents => _playingIntentsController.stream;

  /// Playing transitions consumed as command acknowledgements — including
  /// acks for commands issued by a previous role engine on this attachment.
  Stream<bool> get playingAcks => _playingAcksController.stream;

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

  /// Rate changes are never inferred back into intents, so no expectation
  /// is recorded: the player's rate event is display-only.
  int _pendingRates = 0;
  Completer<void>? _rateDrain;
  Future<void> get pendingRateCommands => _rateDrain?.future ?? Future<void>.value();

  Future<bool> setRate(double rate) async {
    if (_pendingRates++ == 0) _rateDrain = Completer<void>();
    try {
      return await _guarded('setRate', (player) => player.setRate(rate));
    } finally {
      if (--_pendingRates == 0) {
        _rateDrain!.complete();
        _rateDrain = null;
      }
    }
  }

  /// How much cache mpv must refill before it leaves `paused-for-cache` on
  /// its own. A room host raises this from mpv's 1 s default: resuming with a
  /// second of data on a starved link means stalling again a second later,
  /// and every such cycle is a pause and a group restart for every guest.
  /// No-op on cores without the property (ExoPlayer manages its own buffer).
  Future<bool> setCachePauseWait(Duration wait) {
    if (_player.playerType != 'mpv') return Future.value(true);
    return _guarded('setCachePauseWait', (player) => player.setProperty('cache-pause-wait', '${wait.inSeconds}'));
  }

  /// Sync seek through the screen's source-aware delegate, or native seek when
  /// no delegate exists. Delegate failure is not permission to seek a newer source.
  /// A seek can start playback without anyone calling [play] — mpv leaves `pause=false` at end of
  /// file, so seeking off it resumes — which would walk straight past the vehicle guard on [play].
  /// While the vehicle requires distraction optimization the seek is therefore followed by a pause.
  Future<bool> seek(Duration target) async {
    final seeked = await _guarded('seek', (player) async {
      final delegate = _remoteSeek;
      if (delegate != null) {
        await delegate(target);
        return;
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
    return _expectations.any((e) => e.playingValue == value);
  }

  Future<bool> _guarded(
    String actionName,
    Future<void> Function(Player player) command, [
    _Expectation? expectation,
  ]) async {
    final bindingGeneration = _bindingGeneration;
    if (!usable) {
      _expectations.remove(expectation);
      _handleLost(actionName, StateError('Player became unavailable'));
      return false;
    }

    try {
      await command(_player);
    } on StateError catch (e) {
      if (bindingGeneration != _bindingGeneration) return false;
      _expectations.remove(expectation);
      _handleLost(actionName, e);
      return false;
    } on PlatformException catch (e) {
      if (bindingGeneration != _bindingGeneration) return false;
      _expectations.remove(expectation);
      if (e.code == 'COMMAND_FAILED' || e.code == 'NOT_INITIALIZED') {
        _handleLost(actionName, e);
        return false;
      }
      rethrow;
    }

    if (bindingGeneration != _bindingGeneration) return false;
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
    final index = _expectations.indexWhere((e) => e.playingValue == value);
    if (index < 0) return false;
    _expectations.removeAt(index);
    return true;
  }

  void _onPlayingEvent(bool value) {
    if (_disposed || value == _lastPlaying) return;
    _lastPlaying = value;
    if (_consumePlayingExpectation(value)) {
      _playingAcksController.add(value);
      return;
    }
    _playingIntentsController.add(value);
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
    await _playingAcksController.close();
    await _bufferingChangesController.close();
    await _loadedSignalsController.close();
  }
}
