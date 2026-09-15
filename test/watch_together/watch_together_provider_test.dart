import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/watch_together/services/watch_together_relay_endpoint.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';
import 'package:plezy/watch_together/services/relay_protocol.g.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/watch_together_fakes.dart';

class _FakeWatchTogetherPeerService extends WatchTogetherPeerService {
  _FakeWatchTogetherPeerService(
    this.sequence, {
    required bool hostInitiallyConnected,
    required this.rejectDisconnectedTargets,
    this.releaseError,
    this.releaseBarrier,
    this.admittedAsHost,
  }) : _hostConnected = hostInitiallyConnected;

  final int sequence;
  final bool rejectDisconnectedTargets;
  final Object? releaseError;
  final Future<void>? releaseBarrier;
  final bool? admittedAsHost;
  final _peerConnectedController = StreamController<String>.broadcast();
  final _peerDisconnectedController = StreamController<String>.broadcast();
  final _messageController = StreamController<SyncMessage>.broadcast();
  final _errorController = StreamController<PeerError>.broadcast();
  final _sessionEndedController = StreamController<void>.broadcast();
  final _hostChangedController = StreamController<String>.broadcast();
  final _hostTransferEligibilityController = StreamController<void>.broadcast();
  final Set<String> eligibleTransferTargets = {};
  final List<SyncMessage> broadcasts = [];
  final List<(String, SyncMessage)> directMessages = [];
  final List<String> transferRequests = [];

  /// Extra peers reported as connected on top of the modeled host link.
  final Set<String> connectedGuests = {};

  String? _sessionId;
  String? _myPeerId;
  String? _hostPeerId;
  bool _isHost = false;
  bool _disposed = false;
  bool _didDisconnect = false;
  int releaseCalls = 0;
  bool _hostConnected;

  @override
  Stream<String> get onPeerConnected => _peerConnectedController.stream;

  @override
  Stream<String> get onPeerDisconnected => _peerDisconnectedController.stream;

  @override
  Stream<SyncMessage> get onMessageReceived => _messageController.stream;

  @override
  Stream<PeerError> get onError => _errorController.stream;

  @override
  Stream<void> get onSessionEnded => _sessionEndedController.stream;

  @override
  Stream<String> get onHostChanged => _hostChangedController.stream;

  @override
  Stream<void> get onHostTransferEligibilityChanged => _hostTransferEligibilityController.stream;

  @override
  bool canTransferHostTo(String peerId) => eligibleTransferTargets.contains(peerId);

  void emitHostTransferEligibility(Iterable<String> targets) {
    eligibleTransferTargets
      ..clear()
      ..addAll(targets);
    _hostTransferEligibilityController.add(null);
  }

  @override
  String? get sessionId => _sessionId;

  @override
  String? get myPeerId => _myPeerId;

  @override
  String? get hostPeerId => _hostPeerId;

  @override
  bool get isHost => _isHost;

  @override
  List<String> get connectedPeers => [
    if (!_isHost && _sessionId != null && _hostConnected) 'wt-$_sessionId',
    ...connectedGuests,
  ];

  @override
  Future<String> createSession({String? sessionId}) {
    _sessionId = (sessionId ?? 'ROOM$sequence').toUpperCase();
    _myPeerId = 'wt-$_sessionId';
    _isHost = admittedAsHost ?? true;
    _hostPeerId = _isHost ? _myPeerId : 'resumed-host';
    return Future.value(_sessionId);
  }

  @override
  Future<void> joinSession(String sessionId) {
    _sessionId = sessionId.toUpperCase();
    _myPeerId = 'guest-$sequence';
    _isHost = admittedAsHost ?? false;
    _hostPeerId = _isHost ? _myPeerId : 'wt-$_sessionId';
    return Future.value();
  }

  @override
  void broadcast(SyncMessage message) {
    broadcasts.add(message);
  }

  @override
  void sendTo(String peerId, SyncMessage message) {
    if (rejectDisconnectedTargets && !connectedPeers.contains(peerId)) {
      _errorController.add(
        const PeerError(type: PeerErrorType.serverError, message: 'Peer is not in the room', serverCode: 'not_in_room'),
      );
      return;
    }
    directMessages.add((peerId, message));
  }

  @override
  void transferHost(String peerId) => transferRequests.add(peerId);

  void emitHostChanged(String newHostPeerId) {
    _hostPeerId = newHostPeerId;
    _isHost = newHostPeerId == _myPeerId;
    eligibleTransferTargets.clear();
    _hostChangedController.add(newHostPeerId);
  }

  void emitError(PeerError error) => _errorController.add(error);
  void emitPeerConnected(String peerId) {
    if (peerId == _hostPeerId) _hostConnected = true;
    _peerConnectedController.add(peerId);
  }

  void emitPeerDisconnected(String peerId) {
    if (peerId == _hostPeerId) _hostConnected = false;
    _peerDisconnectedController.add(peerId);
  }

  void emitSessionEnded() => _sessionEndedController.add(null);
  void emitMessage(SyncMessage message) => _messageController.add(message);

  bool get hasRelayListeners =>
      _peerConnectedController.hasListener ||
      _peerDisconnectedController.hasListener ||
      _messageController.hasListener ||
      _errorController.hasListener ||
      _sessionEndedController.hasListener ||
      _hostChangedController.hasListener ||
      _hostTransferEligibilityController.hasListener;

  bool get isDisposed => _disposed;
  bool get didDisconnect => _didDisconnect;

  @override
  Future<void> releaseSession() async {
    releaseCalls++;
    final barrier = releaseBarrier;
    if (barrier != null) await barrier;
    final error = releaseError;
    if (error != null) throw error;
  }

  void reconnect() => onReconnected?.call();
  @override
  Future<void> disconnect() {
    _didDisconnect = true;
    _sessionId = null;
    _myPeerId = null;
    _hostPeerId = null;
    _isHost = false;
    _hostConnected = false;
    return Future.value();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _peerConnectedController.close();
    _peerDisconnectedController.close();
    _messageController.close();
    _errorController.close();
    _sessionEndedController.close();
    _hostChangedController.close();
    _hostTransferEligibilityController.close();
    super.dispose();
  }
}

class _FakePeerServiceFactory {
  _FakePeerServiceFactory({
    this.hostInitiallyConnected = true,
    this.rejectDisconnectedTargets = false,
    this.releaseError,
    this.releaseBarrier,
    this.admittedAsHost,
  });

  final bool hostInitiallyConnected;
  final bool rejectDisconnectedTargets;
  final Object? releaseError;
  final Future<void>? releaseBarrier;
  final bool? admittedAsHost;
  final List<_FakeWatchTogetherPeerService> services = [];
  WatchTogetherPeerService call({WatchTogetherRelayEndpoint? endpoint}) {
    final service = _FakeWatchTogetherPeerService(
      services.length + 1,
      hostInitiallyConnected: hostInitiallyConnected,
      rejectDisconnectedTargets: rejectDisconnectedTargets,
      releaseError: releaseError,
      releaseBarrier: releaseBarrier,
      admittedAsHost: admittedAsHost,
    );
    services.add(service);
    return service;
  }
}

PeerError _transportError([String message = 'WebSocket error: connection reset']) {
  return PeerError(type: PeerErrorType.serverError, message: message, originalError: StateError('connection reset'));
}

Future<void> _flushProviderEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

const _providerHostId = 'relay-authoritative-host';

typedef _ProviderRelayHandler = void Function(WebSocket socket, Map<String, dynamic> message);

class _ProviderRelay {
  _ProviderRelay._(this._server);

  final HttpServer _server;
  final List<WebSocket> _sockets = [];
  final List<Map<String, dynamic>> messages = [];

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_ProviderRelay> start(_ProviderRelayHandler handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = _ProviderRelay._(server);
    server.listen((request) async {
      if (request.uri.path != '/relay') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      relay._sockets.add(socket);
      socket.listen((data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        relay.messages.add(message);
        handler(socket, message);
      });
    });
    return relay;
  }

  void send(WebSocket socket, Map<String, dynamic> message) => socket.add(jsonEncode(message));

  Future<void> close() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

void main() {
  test('generated relay versions match the protocol specification', () {
    final spec = (jsonDecode(File('relay_protocol.json').readAsStringSync()) as Map).cast<String, dynamic>();
    expect(RelayProtocol.protocolVersion, spec['protocolVersion']);
    expect(RelayProtocol.legacyProtocolVersion, spec['legacyProtocolVersion']);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The provider reads SettingsService.instanceOrNull?.read(...) when
    // creating/joining sessions; ensure prefs are reset between tests.
    resetSharedPreferencesForTest();
  });

  group('WatchTogetherProvider — initial state', () {
    test('starts disconnected with no session, peers, or sync state', () {
      final p = WatchTogetherProvider();
      expect(p.session, isNull);
      expect(p.sessionId, isNull);
      expect(p.isInSession, isFalse);
      expect(p.isHost, isFalse);
      expect(p.isConnected, isFalse);
      expect(p.isSyncing, isFalse);
      expect(p.isWaitingForPeers, isFalse);
      expect(p.waitingOnNames, isEmpty);
      expect(p.isWaitingForHostReconnect, isFalse);
      expect(p.participants, isEmpty);
      expect(p.participantCount, 0);
      // Default control mode falls back to hostOnly when there's no session.
      expect(p.controlMode, ControlMode.hostOnly);
      expect(p.hasAttachedPlayer, isFalse);
      p.dispose();
    });

    test('current media getters all return null on a fresh provider', () {
      final p = WatchTogetherProvider();
      expect(p.currentMediaRatingKey, isNull);
      expect(p.currentMediaServerId, isNull);
      expect(p.currentMediaTitle, isNull);
      expect(p.hasCurrentPlayback, isFalse);
      p.dispose();
    });

    test('participants list is unmodifiable', () {
      final p = WatchTogetherProvider();
      // Even when empty, the unmodifiable view must reject mutation so
      // callers can't smuggle peers in by mutating the returned list.
      expect(
        () => p.participants.add(const Participant(peerId: 'x', displayName: 'y', isHost: false)),
        throwsUnsupportedError,
      );
      p.dispose();
    });

    test('canControl returns true outside of a session (no gating)', () {
      final p = WatchTogetherProvider();
      expect(p.canControl(), isTrue);
      p.dispose();
    });
  });

  group('WatchTogetherProvider — session guards', () {
    test('selection is rejected outside a session', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      expect(
        p.selectMedia(
          ratingKey: 'rk1',
          serverId: ServerId('s1'),
          mediaTitle: 't1',
          position: Duration.zero,
          rate: 1,
          lease: null,
        ),
        isFalse,
      );
      expect(notified, 0);
      expect(p.currentMediaRatingKey, isNull);
      p.dispose();
    });

    test('setBackgrounded is null-safe without a sync controller', () {
      final p = WatchTogetherProvider();
      expect(() => p.setBackgrounded(true), returnsNormally);
      expect(() => p.setBackgrounded(false), returnsNormally);
      p.dispose();
    });
  });

  group('WatchTogetherProvider — media switch dispatch', () {
    test('dispatches once with typed args and suppresses the key after success', () async {
      final p = WatchTogetherProvider();
      final calls = <(String, String, String)>[];
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls.add((ratingKey, serverId, mediaTitle));
        return true;
      };

      p.debugHandleMediaState('rk1', 's1', 'Ep 1');
      await Future<void>.delayed(Duration.zero);
      expect(calls, [('rk1', 's1', 'Ep 1')]);

      // Heartbeat repeat of the handled key: no re-dispatch.
      p.debugHandleMediaState('rk1', 's1', 'Ep 1');
      await Future<void>.delayed(Duration.zero);
      expect(calls.length, 1);
      p.dispose();
    });

    test('a false result is retried on the next heartbeat state', () async {
      final p = WatchTogetherProvider();
      var calls = 0;
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls++;
        return calls > 1; // Fail once, then succeed.
      };

      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);

      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2); // Second attempt succeeded; key now handled.
      p.dispose();
    });

    test('a throwing callback is contained and retried', () async {
      final p = WatchTogetherProvider();
      var calls = 0;
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls++;
        throw StateError('network down');
      };

      expect(() => p.debugHandleMediaState('rk1', 's1', null), returnsNormally);
      await Future<void>.delayed(Duration.zero);
      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      p.dispose();
    });

    test('no double dispatch while a switch is pending, even for another key', () async {
      final p = WatchTogetherProvider();
      final pending = Completer<bool>();
      final calls = <String>[];
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) {
        calls.add(ratingKey);
        return pending.future;
      };

      p.debugHandleMediaState('rk1', 's1', null);
      p.debugHandleMediaState('rk1', 's1', null);
      p.debugHandleMediaState('rk2', 's1', null); // Serialized behind rk1.
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['rk1']);

      pending.complete(false);
      await Future<void>.delayed(Duration.zero);
      // The slot is free again; the next heartbeat re-dispatches.
      p.debugHandleMediaState('rk2', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['rk1', 'rk2']);
      p.dispose();
    });

    test('onPlayerMediaSwitched takes priority over onMediaSwitched', () async {
      final p = WatchTogetherProvider();
      final calls = <String>[];
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls.add('main');
        return true;
      };
      p.onPlayerMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls.add('player');
        return true;
      };

      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['player']);
      p.dispose();
    });

    test('markCurrentPlaybackHandled suppresses the marked key', () async {
      final p = WatchTogetherProvider();
      var calls = 0;
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls++;
        return true;
      };

      p.markCurrentPlaybackHandled(ratingKey: 'rk1', serverId: ServerId('s1'));
      p.debugHandleMediaState('rk1', 's1', null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
      p.dispose();
    });

    test('a blank serverId is ignored without throwing', () {
      final p = WatchTogetherProvider();
      var calls = 0;
      p.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        calls++;
        return true;
      };

      expect(() => p.debugHandleMediaState('rk1', '', null), returnsNormally);
      expect(calls, 0);
      p.dispose();
    });
  });

  group('WatchTogetherProvider — reconnect recovery', () {
    test('restores only the matching host transport error and preserves session fields', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      final observedStates = <SessionState?>[];
      provider.addListener(() => observedStates.add(provider.session?.state));

      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'room1',
        mediaRatingKey: 'rating-1',
        mediaServerId: 'server-1',
        mediaTitle: 'Episode 1',
      );
      await _flushProviderEvents();
      final established = provider.session!;
      final service = factory.services.single;
      observedStates.clear();
      service.broadcasts.clear();

      service.emitError(_transportError());
      await _flushProviderEvents();
      expect(provider.session?.state, SessionState.error);
      expect(provider.isConnected, isFalse);

      service.reconnect();
      await _flushProviderEvents();

      expect(observedStates, [SessionState.error, SessionState.connected]);
      expect(provider.isConnected, isTrue);
      expect(provider.session?.errorMessage, isNull);
      expect(provider.session?.sessionId, established.sessionId);
      expect(provider.session?.role, established.role);
      expect(provider.session?.controlMode, established.controlMode);
      expect(provider.session?.mediaRatingKey, established.mediaRatingKey);
      expect(provider.session?.mediaServerId, established.mediaServerId);
      expect(provider.session?.mediaTitle, established.mediaTitle);
      expect(service.broadcasts.where((message) => message.type == SyncMessageType.join), hasLength(1));

      await provider.leaveSession();
      provider.dispose();
    });

    test('guest waits for a reconnecting declared host before requesting state', () async {
      final factory = _FakePeerServiceFactory(hostInitiallyConnected: false, rejectDisconnectedTargets: true);
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);

      await provider.joinSession(
        'late1',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      await _flushProviderEvents();
      final service = factory.services.single;
      final hostPeerId = provider.session!.hostPeerId!;

      expect(provider.session?.state, SessionState.connected);
      expect(service.connectedPeers, isEmpty);
      expect(service.directMessages.where((entry) => entry.$2.type == SyncMessageType.requestState), isEmpty);

      service.emitPeerConnected(hostPeerId);
      await _flushProviderEvents();

      expect(service.connectedPeers, [hostPeerId]);
      expect(
        service.directMessages.where(
          (entry) => entry.$1 == hostPeerId && entry.$2.type == SyncMessageType.requestState,
        ),
        hasLength(1),
      );
      expect(provider.session?.state, SessionState.connected);

      await provider.leaveSession();
      provider.dispose();
    });

    test('guest recovery re-announces and re-requests authoritative state once', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      await provider.joinSession(
        'room2',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      await _flushProviderEvents();
      final service = factory.services.single;
      service.broadcasts.clear();
      service.directMessages.clear();

      service.emitError(_transportError());
      await _flushProviderEvents();
      service.reconnect();
      await _flushProviderEvents();

      expect(provider.session?.state, SessionState.connected);
      expect(service.broadcasts.where((message) => message.type == SyncMessageType.join), hasLength(1));
      expect(service.directMessages.where((entry) => entry.$2.type == SyncMessageType.requestState), hasLength(1));

      await provider.leaveSession();
      provider.dispose();
    });

    test('relay errors remain terminal when the current service reconnects', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      final observedStates = <SessionState?>[];
      provider.addListener(() => observedStates.add(provider.session?.state));
      await provider.createSession(
        controlMode: ControlMode.hostOnly,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        sessionId: 'room3',
      );
      await _flushProviderEvents();
      final service = factory.services.single;
      observedStates.clear();

      service.emitError(
        const PeerError(type: PeerErrorType.serverError, message: 'Room was rejected', serverCode: 'room_rejected'),
      );
      await _flushProviderEvents();
      service.reconnect();
      await _flushProviderEvents();

      expect(observedStates, [SessionState.error]);
      expect(provider.session?.state, SessionState.error);
      expect(provider.session?.errorMessage, 'Room was rejected');
      expect(provider.isConnected, isFalse);

      await provider.leaveSession();
      provider.dispose();
    });

    test('host-loss expiry supersedes a recoverable guest transport error', () {
      fakeAsync((async) {
        final factory = _FakePeerServiceFactory();
        final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
        var joined = false;
        unawaited(
          provider
              .joinSession('room4', relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint, displayName: 'Guest')
              .then((_) => joined = true),
        );
        async.flushMicrotasks();
        expect(joined, isTrue);
        final service = factory.services.single;
        final hostPeerId = provider.session!.hostPeerId!;

        service.emitError(_transportError());
        async.flushMicrotasks();
        expect(provider.session?.state, SessionState.error);

        service.emitPeerDisconnected(hostPeerId);
        async.flushMicrotasks();
        expect(provider.isWaitingForHostReconnect, isTrue);
        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();
        expect(provider.session?.errorMessage, 'Host left the session');

        service.reconnect();
        async.flushMicrotasks();
        expect(provider.session?.state, SessionState.error);
        expect(provider.session?.errorMessage, 'Host left the session');

        unawaited(provider.leaveSession());
        async.flushMicrotasks();
        provider.dispose();
        async.flushMicrotasks();
      });
    });

    test('stale service callback cannot mutate or resync a replacement session', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.createSession(
        controlMode: ControlMode.hostOnly,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        sessionId: 'old1',
      );
      await _flushProviderEvents();
      final oldService = factory.services.single;
      final staleReconnect = oldService.onReconnected!;
      oldService.emitError(_transportError('old transport error'));
      await _flushProviderEvents();

      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        sessionId: 'new1',
      );
      await _flushProviderEvents();
      final currentService = factory.services.last;
      currentService.broadcasts.clear();
      notifications = 0;
      final replacement = provider.session;

      staleReconnect();
      await _flushProviderEvents();
      expect(provider.session, replacement);
      expect(notifications, 0);
      expect(currentService.broadcasts, isEmpty);

      currentService.emitError(_transportError('current transport error'));
      await _flushProviderEvents();
      currentService.reconnect();
      await _flushProviderEvents();
      expect(provider.session?.state, SessionState.connected);
      expect(provider.session?.errorMessage, isNull);
      expect(currentService.broadcasts.where((message) => message.type == SyncMessageType.join), hasLength(1));

      await provider.leaveSession();
      provider.dispose();
    });
  });

  group('WatchTogetherProvider — lobby control mode', () {
    test('guest adopts the mode from the host join before any playback state', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      await provider.joinSession(
        'lobby1',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      await _flushProviderEvents();
      final service = factory.services.single;
      final hostPeerId = provider.session!.hostPeerId!;

      // Production guest default until the room's real mode arrives.
      expect(provider.controlMode, ControlMode.hostOnly);
      expect(provider.canControl(), isFalse);

      // A non-host peer claiming a mode must not be believed (the relay
      // stamps sender IDs, so hostPeerId is the only authority).
      service.emitMessage(
        SyncMessage.join(peerId: 'other-guest', displayName: 'Liar', isHost: true, controlMode: ControlMode.anyone),
      );
      await _flushProviderEvents();
      expect(provider.controlMode, ControlMode.hostOnly);

      // The host's join reply carries the room's mode — the only carrier in
      // an idle lobby, where no PlaybackState exists yet (issue #1950).
      service.emitMessage(
        SyncMessage.join(peerId: hostPeerId, displayName: 'Host', isHost: true, controlMode: ControlMode.anyone),
      );
      await _flushProviderEvents();
      expect(provider.controlMode, ControlMode.anyone);
      expect(provider.canControl(), isTrue);

      await provider.leaveSession();
      provider.dispose();
    });

    test('host replies to a new guest join with the room control mode', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'lobby2',
      );
      await _flushProviderEvents();
      final service = factory.services.single;

      service.emitMessage(SyncMessage.join(peerId: 'guest-9', displayName: 'Guest', isHost: false));
      await _flushProviderEvents();

      final reply = service.directMessages.singleWhere(
        (entry) => entry.$1 == 'guest-9' && entry.$2.type == SyncMessageType.join,
      );
      expect(reply.$2.controlMode, ControlMode.anyone);

      await provider.leaveSession();
      provider.dispose();
    });
  });

  group('WatchTogetherProvider — release cleanup', () {
    test('release failure is surfaced after local session teardown completes', () async {
      final releaseFailure = StateError('relay release failed');
      final factory = _FakePeerServiceFactory(releaseError: releaseFailure);
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);

      await provider.createSession(
        controlMode: ControlMode.hostOnly,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        sessionId: 'fail1',
      );
      final service = factory.services.single;

      await expectLater(provider.leaveSession(), throwsA(same(releaseFailure)));

      expect(service.releaseCalls, 1);
      expect(service.didDisconnect, isTrue);
      expect(service.isDisposed, isTrue);
      expect(provider.session, isNull);
      expect(provider.isInSession, isFalse);
      expect(provider.participants, isEmpty);
    });
  });

  group('WatchTogetherProvider — relay authority', () {
    // These drive a real loopback relay; the widget binding's mock HttpClient
    // (400 for everything) must not intercept the per-attempt upgrade client.
    setUp(() {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
    });

    test('an occupied room is joined as a guest without creating', () async {
      late final _ProviderRelay relay;
      relay = await _ProviderRelay.start((socket, message) {
        if (message['type'] == 'join') {
          relay.send(socket, {
            'type': 'joined',
            'sessionId': message['sessionId'],
            'hostPeerId': _providerHostId,
            'reconnectToken': message['reconnectToken'],
            'protocolVersion': 2,
            'peers': [_providerHostId],
          });
        } else if (message['type'] == 'leave') {
          relay.send(socket, {
            'type': 'left',
            'sessionId': message['sessionId'],
            'peerId': message['peerId'],
            'protocolVersion': 2,
          });
        }
      });
      addTearDown(relay.close);
      final endpoint = WatchTogetherRelayEndpoint.resolve(relay.baseUrl);
      final provider = WatchTogetherProvider();
      addTearDown(() async {
        await provider.leaveSession();
        provider.dispose();
      });

      await provider.enterRoom('busy01', relayEndpoint: endpoint, displayName: 'Guest');

      expect(provider.isHost, isFalse);
      expect(provider.session?.hostPeerId, _providerHostId);
      final joins = relay.messages.where((message) => message['type'] == 'join').toList();
      expect(joins, hasLength(2));
      for (final join in joins) {
        expect(join['protocolVersion'], 2);
        expect(join['reconnectToken'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      }
      final leave = relay.messages.singleWhere((message) => message['type'] == 'leave');
      expect(leave['peerId'], joins.first['peerId']);
      expect(leave['reconnectToken'], joins.first['reconnectToken']);
      expect(leave['protocolVersion'], RelayProtocol.protocolVersion);
      expect(joins.last['peerId'], isNot(joins.first['peerId']));
      expect(relay.messages.map((message) => message['type']).take(3), ['join', 'leave', 'join']);
      expect(relay.messages.where((message) => message['type'] == 'create'), isEmpty);
    });

    test('an abandoned room with no peers is hosted instead of joined', () async {
      late final _ProviderRelay relay;
      relay = await _ProviderRelay.start((socket, message) {
        switch (message['type']) {
          case 'join':
            relay.send(socket, {
              'type': 'joined',
              'sessionId': message['sessionId'],
              'hostPeerId': _providerHostId,
              'reconnectToken': message['reconnectToken'],
              'protocolVersion': 2,
            });
          case 'leave':
            relay.send(socket, {
              'type': 'left',
              'sessionId': message['sessionId'],
              'peerId': message['peerId'],
              'protocolVersion': 2,
            });
          case 'create':
            relay.send(socket, {
              'type': 'created',
              'sessionId': message['sessionId'],
              'hostPeerId': message['peerId'],
              'reconnectToken': message['reconnectToken'],
              'protocolVersion': 2,
            });
          case 'endSession':
            relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
        }
      });
      addTearDown(relay.close);
      final endpoint = WatchTogetherRelayEndpoint.resolve(relay.baseUrl);
      final provider = WatchTogetherProvider();
      addTearDown(() async {
        await provider.leaveSession();
        provider.dispose();
      });

      await provider.enterRoom('empty1', relayEndpoint: endpoint, displayName: 'Host');

      expect(provider.isHost, isTrue);
      // The probe identity is released before the code is taken over, so the
      // relay sees an empty room when the create lands.
      expect(relay.messages.map((message) => message['type']).take(3), ['join', 'leave', 'create']);
      final create = relay.messages.singleWhere((message) => message['type'] == 'create');
      expect(create['sessionId'], 'EMPTY1');
      expect(provider.session?.hostPeerId, create['peerId']);
      final probeJoin = relay.messages.firstWhere((message) => message['type'] == 'join');
      expect(create['peerId'], isNot(probeJoin['peerId']));
      expect(provider.session?.hostPeerId, isNot(_providerHostId));
    });

    test('a room-not-found probe creates with relay-declared host authority', () async {
      late final _ProviderRelay relay;
      relay = await _ProviderRelay.start((socket, message) {
        if (message['type'] == 'join') {
          relay.send(socket, {'type': 'error', 'code': 'room_not_found', 'message': 'Room not found'});
        } else if (message['type'] == 'create') {
          relay.send(socket, {
            'type': 'created',
            'sessionId': message['sessionId'],
            'hostPeerId': message['peerId'],
            'reconnectToken': message['reconnectToken'],
            'protocolVersion': 2,
          });
        } else if (message['type'] == 'endSession') {
          relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
        }
      });
      addTearDown(relay.close);
      final endpoint = WatchTogetherRelayEndpoint.resolve(relay.baseUrl);
      final provider = WatchTogetherProvider();
      addTearDown(() async {
        await provider.leaveSession();
        provider.dispose();
      });

      await provider.enterRoom('new01', relayEndpoint: endpoint, displayName: 'Host');

      expect(provider.isHost, isTrue);
      final create = relay.messages.singleWhere((message) => message['type'] == 'create');
      expect(provider.session?.hostPeerId, create['peerId']);
      expect(create['peerId'], isNot('wt-NEW01'));
      expect(create['protocolVersion'], 2);
      expect(create['reconnectToken'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    });
  });

  test('create and join use the final admitted role, not the initiating verb', () async {
    for (final create in [true, false]) {
      final factory = _FakePeerServiceFactory(admittedAsHost: !create);
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      if (create) {
        await provider.createSession(
          controlMode: ControlMode.anyone,
          relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        );
      } else {
        await provider.joinSession('promoted', relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint);
      }
      expect(provider.isHost, !create);
      expect(provider.participants.single.isHost, !create);
      expect(provider.session!.hostPeerId, factory.services.single.hostPeerId);
      await provider.leaveSession();
      provider.dispose();
    }
  });

  test('terminal membership loss also detaches the host and revokes old screen work', () async {
    final factory = _FakePeerServiceFactory();
    final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
    final player = FakeSyncPlayer();
    var exits = 0;
    provider.onHostExitedPlayer = () => exits++;
    await provider.createSession(
      controlMode: ControlMode.anyone,
      relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
    );
    final oldLease = provider.capturePlaybackLease(selection: true)!;
    provider.selectMedia(
      ratingKey: 'A',
      serverId: ServerId('srv'),
      mediaTitle: 'A',
      position: const Duration(seconds: 121),
      rate: 1,
      lease: oldLease,
    );
    final oldBinding = provider.bindPlayer(player, ratingKey: 'A', serverId: 'srv', lease: oldLease)!;
    provider.unbindPlayer(expectedBinding: oldBinding);
    factory.services.single.emitSessionEnded();
    await _flushProviderEvents();
    expect(exits, 1);
    expect(provider.isInSession, isFalse);
    expect(provider.hasCurrentPlayback, isFalse);
    await provider.createSession(
      controlMode: ControlMode.anyone,
      relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
    );
    expect(provider.bindPlayer(player, ratingKey: 'A', serverId: 'srv', lease: oldLease), isNull);
    expect(
      provider.selectMedia(
        ratingKey: 'A',
        serverId: ServerId('srv'),
        mediaTitle: 'A',
        position: Duration.zero,
        rate: 1,
        lease: oldLease,
      ),
      isFalse,
    );
    provider.endMedia(expectedBinding: oldBinding);
    expect(provider.hasCurrentPlayback, isFalse);
    await provider.leaveSession();
    provider.dispose();
    await player.dispose();
  });

  group('WatchTogetherProvider — terminal room lifecycle', () {
    test('relay ended notification exits immediately without release or reconnect grace', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      var hostExitCalls = 0;
      provider.onHostExitedPlayer = () => hostExitCalls++;

      await provider.joinSession(
        'ended1',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      final service = factory.services.single;
      service.emitPeerDisconnected(provider.session!.hostPeerId!);
      await _flushProviderEvents();
      expect(provider.isWaitingForHostReconnect, isTrue);

      service.emitSessionEnded();
      await _flushProviderEvents();

      expect(hostExitCalls, 1);
      expect(provider.session, isNull);
      expect(provider.isWaitingForHostReconnect, isFalse);
      expect(service.releaseCalls, 0);
      expect(service.didDisconnect, isTrue);
      expect(service.isDisposed, isTrue);
      provider.dispose();
    });

    test('best-effort host-leave cleanup observes release failures', () async {
      final releaseFailure = StateError('relay release failed');
      final factory = _FakePeerServiceFactory(releaseError: releaseFailure);
      final uncaught = <Object>[];

      await runZonedGuarded(() async {
        final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
        await provider.joinSession(
          'leave2',
          relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
          displayName: 'Guest',
        );
        final service = factory.services.single;
        service.emitMessage(SyncMessage.leave(peerId: provider.session!.hostPeerId!));
        await _flushProviderEvents();
        expect(provider.session, isNull);
        expect(service.releaseCalls, 1);
        provider.dispose();
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
    });
  });

  group('WatchTogetherProvider — dispose hygiene', () {
    test('participantEvents stream is closed after dispose', () async {
      final p = WatchTogetherProvider();
      // Attach a listener; capture done via the stream's done future.
      final events = <ParticipantEvent>[];
      var streamDone = false;
      final sub = p.participantEvents.listen(events.add, onDone: () => streamDone = true);
      p.dispose();
      // Yield so the broadcast controller's close microtask runs.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(streamDone, isTrue);
    });

    test('dispose detaches local listeners before relay release completes', () async {
      final releaseCompleter = Completer<void>();
      final factory = _FakePeerServiceFactory(releaseBarrier: releaseCompleter.future);
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      await provider.joinSession(
        'dispose1',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      final service = factory.services.single;
      expect(service.hasRelayListeners, isTrue);

      provider.dispose();

      expect(provider.session, isNull);
      expect(provider.participants, isEmpty);
      expect(provider.isWaitingForHostReconnect, isFalse);
      expect(service.hasRelayListeners, isFalse);
      expect(service.releaseCalls, 1);
      expect(service.didDisconnect, isFalse);

      service.emitPeerConnected('late-peer');
      service.emitMessage(SyncMessage.join(peerId: 'late-peer', displayName: 'Late', isHost: false));
      await _flushProviderEvents();
      expect(provider.participants, isEmpty);

      releaseCompleter.complete();
      await _flushProviderEvents();
      expect(service.didDisconnect, isTrue);
      expect(service.isDisposed, isTrue);
    });
  });

  group('WatchTogetherProvider — host transfer', () {
    test('guest A, host B, guest A reloads the mounted player and converges', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      final player = FakeSyncPlayer();
      addTearDown(player.dispose);
      await provider.joinSession('roundtrip', relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint);
      final service = factory.services.single;
      final originalHost = service.hostPeerId!;
      final reloads = <String>[];
      var lobbyPushes = 0;
      provider.onMediaSwitched = (_, _, _) async {
        lobbyPushes++;
        return true;
      };
      provider.onPlayerMediaSwitched = (key, server, _) async {
        reloads.add(key);
        provider.bindPlayer(
          player,
          ratingKey: key,
          serverId: server,
          hasFirstFrame: true,
          lease: provider.capturePlaybackLease()!,
        );
        return true;
      };
      void publishA(int seq) => service.emitMessage(
        SyncMessage.state(
          PlaybackState(
            seq: seq,
            ratingKey: 'A',
            serverId: 'srv',
            phase: PlaybackPhase.paused,
            anchorPositionMs: 30000,
            anchorHostTimeMs: 0,
            rate: 1,
            controlMode: ControlMode.anyone,
          ),
          peerId: originalHost,
        ),
      );

      publishA(1);
      await _flushProviderEvents();
      expect(reloads, ['A']);
      expect(player.state.position, const Duration(seconds: 30));
      service.emitHostChanged(service.myPeerId!);
      await _flushProviderEvents();
      provider.selectMedia(
        ratingKey: 'B',
        serverId: ServerId('srv'),
        mediaTitle: 'B',
        position: Duration.zero,
        rate: 1,
        lease: provider.capturePlaybackLease(selection: true),
      );
      provider.unbindPlayer();
      player.setPosition(Duration.zero);
      provider.bindPlayer(player, ratingKey: 'B', serverId: 'srv', lease: provider.capturePlaybackLease()!);
      service.emitHostChanged(originalHost);
      await _flushProviderEvents();

      publishA(1); // A new authority resets sequence numbering as well.
      await _flushProviderEvents();
      publishA(2);
      await _flushProviderEvents();
      expect(reloads, ['A', 'A']);
      expect(player.state.position, const Duration(seconds: 30));
      expect(player.state.playing, isFalse);
      expect(lobbyPushes, 0);
    });

    test('demotion invalidates pending guest completion as well as handled history', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      await provider.joinSession('pending', relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint);
      final service = factory.services.single;
      final originalHost = service.hostPeerId!;
      final oldSwitch = Completer<bool>();
      var attempts = 0;
      provider.onPlayerMediaSwitched = (_, _, _) {
        attempts++;
        return attempts == 1 ? oldSwitch.future : Future.value(attempts > 2);
      };
      provider.debugHandleMediaState('A', 'srv', 'A');
      await _flushProviderEvents();
      service.emitHostChanged(service.myPeerId!);
      await _flushProviderEvents();
      provider.selectMedia(
        ratingKey: 'B',
        serverId: ServerId('srv'),
        mediaTitle: 'B',
        position: Duration.zero,
        rate: 1,
        lease: provider.capturePlaybackLease(selection: true),
      );
      service.emitHostChanged(originalHost);
      await _flushProviderEvents();
      provider.debugHandleMediaState('A', 'srv', 'A');
      await _flushProviderEvents();
      expect(attempts, 2);
      oldSwitch.complete(true);
      await _flushProviderEvents();
      // The failed current-generation switch must still retry, regardless
      // of the old generation's late success.
      provider.debugHandleMediaState('A', 'srv', 'A');
      await _flushProviderEvents();
      expect(attempts, 3);
      provider.debugHandleMediaState('A', 'srv', 'A');
      await _flushProviderEvents();
      expect(attempts, 3);
    });

    test('host-started player remains the media owner after demotion and reloads', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      final player = FakeSyncPlayer();
      addTearDown(player.dispose);
      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        sessionId: 'owner',
      );
      final service = factory.services.single;
      var currentKey = 'A';
      final reloads = <String>[];
      var lobbyPushes = 0;
      provider.onMediaSwitched = (_, _, _) async {
        lobbyPushes++;
        return true;
      };
      provider.onPlayerMediaSwitched = (key, server, _) async {
        provider.unbindPlayer();
        currentKey = key;
        reloads.add(key);
        provider.bindPlayer(
          player,
          ratingKey: key,
          serverId: server,
          hasFirstFrame: true,
          lease: provider.capturePlaybackLease()!,
        );
        return true;
      };
      provider.selectMedia(
        ratingKey: currentKey,
        serverId: ServerId('srv'),
        mediaTitle: currentKey,
        position: Duration.zero,
        rate: 1,
        lease: provider.capturePlaybackLease(selection: true),
      );
      provider.bindPlayer(
        player,
        ratingKey: currentKey,
        serverId: 'srv',
        hasFirstFrame: true,
        lease: provider.capturePlaybackLease()!,
      );
      service.emitHostChanged('other-host');
      await _flushProviderEvents();
      for (final (seq, key) in [(1, 'B'), (2, 'C')]) {
        service.emitMessage(
          SyncMessage.state(
            PlaybackState(
              seq: seq,
              ratingKey: key,
              serverId: 'srv',
              phase: PlaybackPhase.paused,
              anchorPositionMs: 0,
              anchorHostTimeMs: 0,
              rate: 1,
              controlMode: ControlMode.anyone,
            ),
            peerId: 'other-host',
          ),
        );
        await _flushProviderEvents();
      }
      expect(currentKey, 'C');
      expect(reloads, ['B', 'C']);
      expect(lobbyPushes, 0);
      var exits = 0;
      provider.onHostExitedPlayer = () {
        exits++;
        provider.endMedia();
      };
      service.emitMessage(SyncMessage.hostExitedPlayer(peerId: 'other-host'));
      await _flushProviderEvents();
      expect(exits, 1);
      expect(provider.onPlayerMediaSwitched, isNull);
      expect(provider.hasCurrentPlayback, isFalse);
    });

    test('hostChanged demotes the host, updates participants, and toasts the new host', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      final events = <ParticipantEvent>[];
      final subscription = provider.participantEvents.listen(events.add);
      addTearDown(subscription.cancel);

      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'xfer1',
      );
      final service = factory.services.single;
      service.connectedGuests.add('guest-a');
      service.emitMessage(SyncMessage.join(peerId: 'guest-a', displayName: 'Guest A', isHost: false));
      service.emitHostTransferEligibility(['guest-a']);
      await _flushProviderEvents();

      final guest = provider.participants.singleWhere((p) => p.peerId == 'guest-a');
      expect(provider.canTransferHostTo(guest), isTrue);
      provider.transferHost(guest);
      expect(service.transferRequests, ['guest-a']);

      // Roles only flip when the relay's broadcast lands.
      expect(provider.isHost, isTrue);
      service.emitHostChanged('guest-a');
      await _flushProviderEvents();

      expect(provider.isHost, isFalse);
      expect(provider.session?.hostPeerId, 'guest-a');
      expect(provider.session?.state, SessionState.connected);
      expect(provider.participants.singleWhere((p) => p.peerId == 'guest-a').isHost, isTrue);
      expect(provider.participants.singleWhere((p) => p.peerId != 'guest-a').isHost, isFalse);
      final event = events.singleWhere((e) => e.type == ParticipantEventType.hostChanged);
      expect(event.displayName, 'Guest A');
    });

    test('hostChanged promotion re-announces the room control mode as host', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      final events = <ParticipantEvent>[];
      final subscription = provider.participantEvents.listen(events.add);
      addTearDown(subscription.cancel);

      await provider.joinSession(
        'xfer2',
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Guest',
      );
      final service = factory.services.single;
      // The host's join teaches guests the room's real control mode.
      service.emitMessage(
        SyncMessage.join(peerId: 'wt-XFER2', displayName: 'Host', isHost: true, controlMode: ControlMode.anyone),
      );
      await _flushProviderEvents();
      expect(provider.controlMode, ControlMode.anyone);

      service.emitHostChanged(service.myPeerId!);
      await _flushProviderEvents();

      expect(provider.isHost, isTrue);
      expect(provider.session?.role, SessionRole.host);
      expect(provider.session?.hostPeerId, service.myPeerId);
      expect(provider.participants.singleWhere((p) => p.peerId == service.myPeerId).isHost, isTrue);
      expect(provider.participants.singleWhere((p) => p.peerId == 'wt-XFER2').isHost, isFalse);
      expect(events.map((e) => e.type), contains(ParticipantEventType.becameHost));
      // The promoted host re-broadcasts a join carrying the inherited mode.
      final announced = service.broadcasts.lastWhere((m) => m.type == SyncMessageType.join);
      expect(announced.isHost, isTrue);
      expect(announced.controlMode, ControlMode.anyone);
      // Reverse state: the demoted-side wiring is exercised by the demotion
      // test above; a promoted host can end the session (host-only path).
      expect(provider.canControl(), isTrue);
    });

    test('a rejected transfer keeps the session connected and toasts the failure', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      final events = <ParticipantEvent>[];
      final subscription = provider.participantEvents.listen(events.add);
      addTearDown(subscription.cancel);

      await provider.createSession(
        controlMode: ControlMode.hostOnly,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'xfer3',
      );
      final service = factory.services.single;
      service.connectedGuests.add('guest-b');
      service.emitMessage(SyncMessage.join(peerId: 'guest-b', displayName: 'Guest B', isHost: false));
      service.emitHostTransferEligibility(['guest-b']);
      await _flushProviderEvents();

      provider.transferHost(provider.participants.singleWhere((p) => p.peerId == 'guest-b'));
      service.emitError(
        const PeerError(
          type: PeerErrorType.serverError,
          message: 'Host transfer unavailable',
          serverCode: RelayProtocol.hostTransferUnavailableCode,
        ),
      );
      await _flushProviderEvents();

      expect(provider.session?.state, SessionState.connected);
      expect(provider.isHost, isTrue);
      final event = events.singleWhere((e) => e.type == ParticipantEventType.hostTransferFailed);
      expect(event.displayName, 'Guest B');
    });

    test('transfer requires host role, a connected target, and relay authorization', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);

      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'xfer4',
      );
      final service = factory.services.single;
      service.connectedGuests.add('guest-new');
      service.emitMessage(SyncMessage.join(peerId: 'guest-new', displayName: 'New', isHost: false));
      // An old-protocol guest (version below the current sync protocol).
      service.connectedGuests.add('guest-old');
      service.emitMessage(
        SyncMessage.fromJson('{"t":"join","ts":0,"pid":"guest-old","name":"Old","host":false,"v":2}'),
      );
      // A guest the relay no longer reports as connected.
      service.emitMessage(SyncMessage.join(peerId: 'guest-gone', displayName: 'Gone', isHost: false));
      service.emitHostTransferEligibility(['guest-new', 'guest-gone']);
      await _flushProviderEvents();

      Participant byId(String id) => provider.participants.singleWhere((p) => p.peerId == id);
      expect(provider.canTransferHostTo(byId('guest-new')), isTrue);
      expect(provider.canTransferHostTo(byId('guest-old')), isFalse);
      expect(provider.canTransferHostTo(byId('guest-gone')), isFalse);
      expect(provider.canTransferHostTo(byId(service.myPeerId!)), isFalse);

      // Ineligible targets never reach the relay.
      provider.transferHost(byId('guest-old'));
      expect(service.transferRequests, isEmpty);

      // A guest can never initiate a transfer.
      service.emitHostChanged('guest-new');
      await _flushProviderEvents();
      expect(provider.isHost, isFalse);
      expect(provider.canTransferHostTo(byId('guest-old')), isFalse);
    });

    test('relay eligibility updates block transfer before a bystander announces sync join', () async {
      final factory = _FakePeerServiceFactory();
      final provider = WatchTogetherProvider(peerServiceFactory: factory.call);
      addTearDown(provider.dispose);
      await provider.createSession(
        controlMode: ControlMode.anyone,
        relayEndpoint: WatchTogetherRelayEndpoint.defaultEndpoint,
        displayName: 'Host',
        sessionId: 'xfer5',
      );
      final service = factory.services.single;
      service.connectedGuests.add('guest-new');
      service.emitMessage(SyncMessage.join(peerId: 'guest-new', displayName: 'New', isHost: false));
      service.emitHostTransferEligibility(['guest-new']);
      await _flushProviderEvents();
      final target = provider.participants.singleWhere((p) => p.peerId == 'guest-new');
      expect(provider.canTransferHostTo(target), isTrue);

      final availability = <bool>[];
      provider.addListener(() => availability.add(provider.canTransferHostTo(target)));
      // Admission blocks transfer without waiting for B's sync join or even
      // the peerJoined event to reach this client.
      service.emitHostTransferEligibility([]);
      await _flushProviderEvents();
      expect(availability.last, isFalse);
      provider.transferHost(target);
      expect(service.transferRequests, isEmpty);

      service.connectedGuests.add('guest-218');
      service.emitMessage(
        SyncMessage.fromJson(
          '{"t":"join","ts":0,"pid":"guest-218","name":"Old","host":false,"v":3,"cap":["hostTransfer"]}',
        ),
      );
      await _flushProviderEvents();
      expect(provider.canTransferHostTo(target), isFalse, reason: 'sync payload cannot authorize transfer');
      service.connectedGuests.remove('guest-218');
      service.emitPeerDisconnected('guest-218');
      service.emitHostTransferEligibility(['guest-new']);
      await _flushProviderEvents();
      expect(availability.last, isTrue);
      provider.transferHost(target);
      expect(service.transferRequests, ['guest-new']);
    });
  });
}
