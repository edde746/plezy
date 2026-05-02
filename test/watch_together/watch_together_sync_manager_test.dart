import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';
import 'package:plezy/watch_together/services/watch_together_sync_manager.dart';

void main() {
  group('WatchTogetherSyncManager deferred play', () {
    test('does not re-enter initial load gate after attaching an already-playing player', () async {
      final peerService = _FakeWatchTogetherPeerService(peerId: 'host');
      final player = _FakePlayer(playing: true, position: const Duration(minutes: 3));
      final manager = _hostManager(peerService);
      final deferredStates = <bool>[];
      manager.onDeferredPlayChanged = deferredStates.add;

      manager.initializeParticipants(['host', 'guest']);
      manager.attachPlayer(player);

      await player.emitPlaying(false);
      await player.emitPlaying(true);

      expect(deferredStates, isNot(contains(true)));
      expect(player.state.playing, isTrue);

      manager.dispose();
      await player.dispose();
      await peerService.close();
    });

    test('remote play completion prevents a later local resume from using the initial load gate', () async {
      final peerService = _FakeWatchTogetherPeerService(peerId: 'guest');
      final player = _FakePlayer(playing: false, position: const Duration(seconds: 10));
      final manager = _guestManager(peerService, controlMode: ControlMode.anyone);
      final deferredStates = <bool>[];
      manager.onDeferredPlayChanged = deferredStates.add;

      manager.initializeParticipants(['guest', 'host', 'other']);
      manager.attachPlayer(player);

      peerService.emit(SyncMessage.playerReady(peerId: 'other', ready: false));
      await _settle();

      peerService.emit(SyncMessage.play(peerId: 'host', position: const Duration(seconds: 20)));
      await _settle();
      expect(player.state.playing, isTrue);

      await player.emitPlaying(false);
      await player.emitPlaying(true);

      expect(deferredStates, isNot(contains(true)));
      expect(player.state.playing, isTrue);

      manager.dispose();
      await player.dispose();
      await peerService.close();
    });

    test('removing a disconnected not-ready peer resumes deferred play', () async {
      final peerService = _FakeWatchTogetherPeerService(peerId: 'host');
      final player = _FakePlayer(playing: false, position: const Duration(minutes: 5));
      final manager = _hostManager(peerService);
      final deferredStates = <bool>[];
      manager.onDeferredPlayChanged = deferredStates.add;

      manager.initializeParticipants(['host', 'guest']);
      manager.attachPlayer(player);

      await player.emitPlaying(true);

      expect(deferredStates, contains(true));
      expect(player.state.playing, isFalse);

      await manager.handlePeerDisconnected('guest');

      expect(deferredStates, containsAllInOrder([true, false]));
      expect(player.state.playing, isTrue);
      expect(peerService.broadcasts.where((m) => m.type == SyncMessageType.play), isNotEmpty);

      manager.dispose();
      await player.dispose();
      await peerService.close();
    });
  });
}

WatchTogetherSyncManager _hostManager(_FakeWatchTogetherPeerService peerService) {
  return WatchTogetherSyncManager(
    peerService: peerService,
    session: const WatchSession(
      sessionId: 'ROOM1',
      role: SessionRole.host,
      controlMode: ControlMode.hostOnly,
      state: SessionState.connected,
      hostPeerId: 'host',
    ),
    displayName: 'Host',
  );
}

WatchTogetherSyncManager _guestManager(_FakeWatchTogetherPeerService peerService, {required ControlMode controlMode}) {
  return WatchTogetherSyncManager(
    peerService: peerService,
    session: WatchSession(
      sessionId: 'ROOM1',
      role: SessionRole.guest,
      controlMode: controlMode,
      state: SessionState.connected,
      hostPeerId: 'host',
    ),
    displayName: 'Guest',
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeWatchTogetherPeerService extends WatchTogetherPeerService {
  _FakeWatchTogetherPeerService({required this.peerId}) : super(customBaseUrl: 'http://localhost');

  final String peerId;
  final StreamController<SyncMessage> _messages = StreamController<SyncMessage>.broadcast();
  final List<SyncMessage> broadcasts = [];
  final Map<String, List<SyncMessage>> sentMessages = {};

  @override
  String? get myPeerId => peerId;

  @override
  Stream<SyncMessage> get onMessageReceived => _messages.stream;

  @override
  void broadcast(SyncMessage message) {
    broadcasts.add(message);
  }

  @override
  void sendTo(String peerId, SyncMessage message) {
    sentMessages.putIfAbsent(peerId, () => []).add(message);
  }

  void emit(SyncMessage message) {
    _messages.add(message);
  }

  Future<void> close() => _messages.close();
}

class _FakePlayer implements Player {
  _FakePlayer({bool playing = false, Duration position = Duration.zero})
    : _state = PlayerState(playing: playing, buffering: false, position: position);

  PlayerState _state;
  bool _disposed = false;

  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<bool> _bufferingController = StreamController<bool>.broadcast();
  final StreamController<double> _rateController = StreamController<double>.broadcast();

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: _playingController.stream,
    completed: const Stream<bool>.empty(),
    buffering: _bufferingController.stream,
    position: const Stream<Duration>.empty(),
    duration: const Stream<Duration>.empty(),
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
    playbackRestart: const Stream<void>.empty(),
    backendSwitched: const Stream<void>.empty(),
  );

  Future<void> emitPlaying(bool value) async {
    _state = _state.copyWith(playing: value);
    _playingController.add(value);
    await _settle();
  }

  @override
  Future<void> play() async {
    _state = _state.copyWith(playing: true);
  }

  @override
  Future<void> pause() async {
    _state = _state.copyWith(playing: false);
  }

  @override
  Future<void> seek(Duration position) async {
    _state = _state.copyWith(position: position);
  }

  @override
  Future<void> setRate(double rate) async {
    _state = _state.copyWith(rate: rate);
    _rateController.add(rate);
  }

  @override
  bool get disposed => _disposed;

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _playingController.close();
    await _bufferingController.close();
    await _rateController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
