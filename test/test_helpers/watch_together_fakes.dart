import 'dart:async';

import 'package:plezy/mpv/mpv.dart';

/// Rich fake [Player] for player and Watch Together tests.
///
/// Commands mutate state and emit the corresponding property events on a
/// microtask (mirroring the real command-ack-then-property-event ordering);
/// drive externally-caused transitions with the `emit*` helpers. Designed to
/// run under `fakeAsync` — nothing here uses wall-clock time.
class FakeSyncPlayer implements Player {
  FakeSyncPlayer({
    bool playing = false,
    bool buffering = false,
    Duration position = Duration.zero,
    Duration duration = const Duration(minutes: 45),
    bool seekable = true,
    double rate = 1.0,
    bool hasRenderedFrame = false,
  }) : _state = PlayerState(
         playing: playing,
         buffering: buffering,
         position: position,
         duration: duration,
         seekable: seekable,
         rate: rate,
         hasRenderedFrame: hasRenderedFrame,
       );

  PlayerState _state;
  bool _disposed = false;

  /// When set, the next command throws this and clears the field.
  Object? nextCommandError;

  /// When set, the next command waits for this future and clears the field.
  Future<void>? nextCommandFuture;

  /// Simulates bitstream audio ignoring rate changes: setRate succeeds but
  /// neither state nor the rate stream reflect it.
  bool ignoreRateChanges = false;

  /// Whether seeks emit a playback-restart event (first frame after seek).
  bool emitRestartOnSeek = true;

  @override
  bool audioPassthroughActive = false;

  final commandLog = <String>[];

  final _playingController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  final _playbackRestartController = StreamController<void>.broadcast();
  final _fileStartedController = StreamController<void>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  @override
  PlayerState get state => _state;

  @override
  Duration get currentPosition => _state.position;

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: _playingController.stream,
    completed: const Stream<bool>.empty(),
    buffering: _bufferingController.stream,
    position: const Stream<Duration>.empty(),
    duration: _durationController.stream,
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: const Stream<double>.empty(),
    rate: _rateController.stream,
    tracks: const Stream<Tracks>.empty(),
    track: const Stream<TrackSelection>.empty(),
    log: const Stream<PlayerLog>.empty(),
    error: const Stream<PlayerError>.empty(),
    audioDevice: const Stream<AudioDevice>.empty(),
    audioDevices: const Stream<List<AudioDevice>>.empty(),
    bufferRanges: const Stream<List<BufferRange>>.empty(),
    playbackRestart: _playbackRestartController.stream,
    fileStarted: _fileStartedController.stream,
    backendSwitched: const Stream<void>.empty(),
  );

  void _maybeThrow() {
    final error = nextCommandError;
    if (error != null) {
      nextCommandError = null;
      throw error;
    }
  }

  @override
  Future<void> play() async {
    commandLog.add('play');
    _maybeThrow();
    final pending = nextCommandFuture;
    nextCommandFuture = null;
    if (pending != null) await pending;
    if (_state.playing) return;
    _state = _state.copyWith(playing: true);
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    commandLog.add('pause');
    _maybeThrow();
    final pending = nextCommandFuture;
    nextCommandFuture = null;
    if (pending != null) await pending;
    if (!_state.playing) return;
    _state = _state.copyWith(playing: false);
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    commandLog.add('seek:${position.inMilliseconds}');
    _maybeThrow();
    final pending = nextCommandFuture;
    nextCommandFuture = null;
    if (pending != null) await pending;
    _state = _state.copyWith(position: position);
    if (emitRestartOnSeek) emitPlaybackRestart();
  }

  @override
  Future<void> setRate(double rate) async {
    commandLog.add('rate:$rate');
    _maybeThrow();
    final pending = nextCommandFuture;
    nextCommandFuture = null;
    if (pending != null) await pending;
    if (ignoreRateChanges || _state.rate == rate) return;
    _state = _state.copyWith(rate: rate);
    _rateController.add(rate);
  }

  /// Defaults to mpv so host-side cache tuning is exercised. Property writes
  /// are recorded in [properties] rather than [commandLog], which is for
  /// transport.
  @override
  String playerType = 'mpv';

  final properties = <String, String>{};

  @override
  Future<void> setProperty(String name, String value) async {
    _maybeThrow();
    properties[name] = value;
  }

  /// Externally-caused playing transition (e.g. user pressed a media key).
  void emitPlaying(bool value) {
    if (_state.playing == value) return;
    _state = _state.copyWith(playing: value);
    _playingController.add(value);
  }

  /// Externally-caused buffering transition (paused-for-cache).
  void emitBuffering(bool value) {
    if (_state.buffering == value) return;
    _state = _state.copyWith(buffering: value);
    _bufferingController.add(value);
  }

  /// Externally-caused rate transition.
  void emitRate(double value) {
    _state = _state.copyWith(rate: value);
    _rateController.add(value);
  }

  /// The screen asked the backend to open a replacement source and `open()`
  /// resolved. Like the real player, the per-file facts reset here — before
  /// the backend's `start-file` or anything else from the new file arrives.
  void beginOpen() {
    _state = _state.copyWith(completed: false, hasRenderedFrame: false);
  }

  /// The backend started a load (mpv `start-file`). Every real backend sends
  /// this before the load's first frame, and the open outcome delimits an
  /// attempt's signals by it; a fake `open` emits it before its restart.
  /// Like the real player, the new file has rendered nothing yet.
  void emitFileStarted() {
    _state = _state.copyWith(hasRenderedFrame: false);
    _fileStartedController.add(null);
  }

  /// First frame rendered (after load and after every seek). Like the real
  /// player, the state records the fact before the event goes out.
  void emitPlaybackRestart() {
    _state = _state.copyWith(hasRenderedFrame: true);
    _playbackRestartController.add(null);
  }

  void emitDuration(Duration value) {
    _state = _state.copyWith(duration: value);
    _durationController.add(value);
  }

  void setPosition(Duration position) {
    _state = _state.copyWith(position: position);
  }

  /// Seed the physical "current file rendered a frame" fact without an event,
  /// for a binding made after the frame.
  void setHasRenderedFrame(bool value) {
    _state = _state.copyWith(hasRenderedFrame: value);
  }

  /// Advance the playhead as if [elapsed] of playback happened.
  void advanceBy(Duration elapsed) {
    if (!_state.playing || _state.buffering) return;
    setPosition(_state.position + elapsed * _state.rate);
  }

  void setBuffer(Duration bufferEnd) {
    _state = _state.copyWith(buffer: bufferEnd);
  }

  void setCompleted(bool completed) {
    _state = _state.copyWith(completed: completed);
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (_disposed) return;
    _disposed = true;
    await _playingController.close();
    await _bufferingController.close();
    await _rateController.close();
    await _playbackRestartController.close();
    await _fileStartedController.close();
    await _durationController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
