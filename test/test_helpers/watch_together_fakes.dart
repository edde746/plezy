import 'dart:async';

import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';

/// Rich fake [Player] for Watch Together sync tests.
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
  }) : _state = PlayerState(
         playing: playing,
         buffering: buffering,
         position: position,
         duration: duration,
         seekable: seekable,
         rate: rate,
       );

  PlayerState _state;
  bool _disposed = false;

  /// When set, the next command throws this and clears the field.
  Object? nextCommandError;

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
    if (_state.playing) return;
    _state = _state.copyWith(playing: true);
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    commandLog.add('pause');
    _maybeThrow();
    if (!_state.playing) return;
    _state = _state.copyWith(playing: false);
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    commandLog.add('seek:${position.inMilliseconds}');
    _maybeThrow();
    _state = _state.copyWith(position: position);
    if (emitRestartOnSeek) _playbackRestartController.add(null);
  }

  @override
  Future<void> setRate(double rate) async {
    commandLog.add('rate:$rate');
    _maybeThrow();
    if (ignoreRateChanges || _state.rate == rate) return;
    _state = _state.copyWith(rate: rate);
    _rateController.add(rate);
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

  /// First frame rendered (after load).
  void emitPlaybackRestart() => _playbackRestartController.add(null);

  void emitDuration(Duration value) {
    _state = _state.copyWith(duration: value);
    _durationController.add(value);
  }

  void setPosition(Duration position) {
    _state = _state.copyWith(position: position);
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
    await _durationController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Standalone recording fake peer service (no relay behind it).
class FakeWatchTogetherPeerService extends WatchTogetherPeerService {
  FakeWatchTogetherPeerService({required this.peerId}) : super(customBaseUrl: 'http://localhost');

  final String peerId;
  final _messages = StreamController<SyncMessage>.broadcast();
  final _peerConnected = StreamController<String>.broadcast();
  final _peerDisconnected = StreamController<String>.broadcast();

  final List<SyncMessage> broadcasts = [];
  final Map<String, List<SyncMessage>> sent = {};

  @override
  String? get myPeerId => peerId;

  @override
  Stream<SyncMessage> get onMessageReceived => _messages.stream;

  @override
  Stream<String> get onPeerConnected => _peerConnected.stream;

  @override
  Stream<String> get onPeerDisconnected => _peerDisconnected.stream;

  @override
  void broadcast(SyncMessage message) {
    broadcasts.add(message);
  }

  @override
  void sendTo(String peerId, SyncMessage message) {
    sent.putIfAbsent(peerId, () => []).add(message);
  }

  /// All recorded outgoing messages of [type], broadcast and targeted.
  Iterable<SyncMessage> outgoing(SyncMessageType type) =>
      [...broadcasts, ...sent.values.expand((m) => m)].where((m) => m.type == type);

  void emit(SyncMessage message) => _messages.add(message);

  void emitPeerConnected(String peerId) => _peerConnected.add(peerId);

  void emitPeerDisconnected(String peerId) => _peerDisconnected.add(peerId);

  Future<void> close() async {
    await _messages.close();
    await _peerConnected.close();
    await _peerDisconnected.close();
  }
}

/// In-memory relay linking [HubPeerService]s for duplex end-to-end tests.
///
/// Mirrors the real relay's contract: broadcasts fan out to every other
/// peer, sendTo targets one, the sender id is stamped server-side
/// ([SyncMessage.copyWith]), and registration/disconnection emit
/// peerJoined/peerLeft events to the others.
class FakeRelayHub {
  final Map<String, HubPeerService> _peers = {};

  HubPeerService register(String peerId) {
    final service = HubPeerService._(peerId, this);
    for (final existing in _peers.values) {
      existing._peerConnected.add(peerId);
      service._peerConnected.add(existing.peerId);
    }
    _peers[peerId] = service;
    return service;
  }

  void disconnect(String peerId) {
    if (_peers.remove(peerId) == null) return;
    for (final other in _peers.values) {
      other._peerDisconnected.add(peerId);
    }
  }

  void _broadcast(String from, SyncMessage message) {
    final stamped = message.peerId == from ? message : message.copyWith(peerId: from);
    for (final entry in _peers.entries) {
      if (entry.key == from) continue;
      entry.value._messages.add(stamped);
    }
  }

  void _sendTo(String from, String to, SyncMessage message) {
    final stamped = message.peerId == from ? message : message.copyWith(peerId: from);
    _peers[to]?._messages.add(stamped);
  }

  Future<void> dispose() async {
    final peers = _peers.values.toList();
    _peers.clear();
    for (final peer in peers) {
      await peer.closeHub();
    }
  }
}

class HubPeerService extends WatchTogetherPeerService {
  HubPeerService._(this.peerId, this._hub) : super(customBaseUrl: 'http://localhost');

  final String peerId;
  final FakeRelayHub _hub;
  final _messages = StreamController<SyncMessage>.broadcast();
  final _peerConnected = StreamController<String>.broadcast();
  final _peerDisconnected = StreamController<String>.broadcast();

  /// Outgoing log (in addition to hub routing), for assertions.
  final List<SyncMessage> outgoingLog = [];

  @override
  String? get myPeerId => peerId;

  @override
  Stream<SyncMessage> get onMessageReceived => _messages.stream;

  @override
  Stream<String> get onPeerConnected => _peerConnected.stream;

  @override
  Stream<String> get onPeerDisconnected => _peerDisconnected.stream;

  @override
  void broadcast(SyncMessage message) {
    outgoingLog.add(message);
    _hub._broadcast(peerId, message);
  }

  @override
  void sendTo(String peerId, SyncMessage message) {
    outgoingLog.add(message);
    _hub._sendTo(this.peerId, peerId, message);
  }

  Future<void> closeHub() async {
    await _messages.close();
    await _peerConnected.close();
    await _peerDisconnected.close();
  }
}
