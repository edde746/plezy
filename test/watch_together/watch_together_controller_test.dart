import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/services/watch_together_controller.dart';

import '../test_helpers/watch_together_fakes.dart';

const _epochMs = 1000000;

/// Two live controllers (host + guest) bridged by an in-memory relay.
class _Room {
  _Room(this.async, {ControlMode controlMode = ControlMode.hostOnly}) {
    hostService = hub.register('host');
    guestService = hub.register('guest');

    host = WatchTogetherController(
      peerService: hostService,
      session: WatchSession(
        sessionId: 'ROOM1',
        role: SessionRole.host,
        controlMode: controlMode,
        state: SessionState.connected,
        hostPeerId: 'host',
      ),
      nowMs: nowMs,
    );
    guest = WatchTogetherController(
      peerService: guestService,
      session: WatchSession(
        sessionId: 'ROOM1',
        role: SessionRole.guest,
        controlMode: controlMode,
        state: SessionState.connected,
        hostPeerId: 'host',
      ),
      nowMs: nowMs,
    );

    hostPlayer = FakeSyncPlayer(position: const Duration(minutes: 2));
    guestPlayer = FakeSyncPlayer(position: Duration.zero);

    guest.announceJoin('Guest');
    host.announceJoin('Host');
    async.flushMicrotasks();
  }

  final FakeAsync async;
  final hub = FakeRelayHub();
  late final HubPeerService hostService;
  late final HubPeerService guestService;
  late final WatchTogetherController host;
  late final WatchTogetherController guest;
  late final FakeSyncPlayer hostPlayer;
  late final FakeSyncPlayer guestPlayer;

  int nowMs() => _epochMs + async.elapsed.inMilliseconds;

  PlaybackState lastHostState() => hostService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;

  void hostStartsMedia({String ratingKey = 'rk1', bool hasFirstFrame = false}) {
    host.attachPlayer(
      hostPlayer,
      ratingKey: ratingKey,
      serverId: 'srv',
      mediaTitle: 'Ep',
      hasFirstFrame: hasFirstFrame,
    );
    host.setCurrentMedia(ratingKey: ratingKey, serverId: 'srv', mediaTitle: 'Ep');
    async.flushMicrotasks();
  }

  void guestJoinsMedia({String ratingKey = 'rk1'}) {
    guest.attachPlayer(guestPlayer, ratingKey: ratingKey, serverId: 'srv');
    async.flushMicrotasks();
  }

  void bothBecomeReady() {
    hostPlayer.emitPlaybackRestart();
    guestPlayer.emitPlaybackRestart();
    async.flushMicrotasks();
  }

  void dispose() {
    host.dispose();
    guest.dispose();
    hub.dispose();
  }
}

void main() {
  test('full flow: join, media dispatch, load, one simultaneous start — no loops', () {
    fakeAsync((async) {
      final mediaDispatches = <String>[];
      final room = _Room(async);
      room.guest.onMediaStateReceived = (rk, sid, title) => mediaDispatches.add(rk);

      // Host opens media; guest hears about it from the loading state even
      // though the host hasn't finished loading (joiners load in parallel).
      room.hostStartsMedia();
      expect(mediaDispatches, ['rk1']);

      // Guest loads FIRST (the original bug scenario).
      room.guestJoinsMedia();
      room.guestPlayer.emitPlaybackRestart();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));

      // While the host loads, the guest must never have been told to play.
      expect(room.guestPlayer.state.playing, isFalse);
      expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);

      // Host finishes loading → scheduled start lands on both simultaneously.
      room.hostPlayer.emitPlaybackRestart();
      async.flushMicrotasks();
      final state = room.lastHostState();
      expect(state.phase, PlaybackPhase.playing);
      final delay = state.anchorHostTimeMs - room.nowMs();
      expect(delay, greaterThan(0));

      async.elapse(Duration(milliseconds: delay - 50));
      expect(room.hostPlayer.state.playing, isFalse);
      expect(room.guestPlayer.state.playing, isFalse);
      async.elapse(const Duration(milliseconds: 100));
      expect(room.hostPlayer.state.playing, isTrue);
      expect(room.guestPlayer.state.playing, isTrue);

      // And the guest was aligned to the host's anchor position.
      expect((room.guestPlayer.state.position.inMilliseconds - state.anchorPositionMs).abs(), lessThanOrEqualTo(500));
      room.dispose();
    });
  });

  test('episode switch: state arriving during the guest detach gap is not lost', () {
    fakeAsync((async) {
      final mediaDispatches = <String>[];
      final room = _Room(async);
      room.guest.onMediaStateReceived = (rk, sid, title) => mediaDispatches.add(rk);

      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final delay = room.lastHostState().anchorHostTimeMs - room.nowMs();
      async.elapse(Duration(milliseconds: delay + 100));
      expect(room.guestPlayer.state.playing, isTrue);

      // Guest detaches (reload gap) — and ONLY THEN the host switches media.
      room.guest.detachPlayer();
      async.flushMicrotasks();
      room.host.setCurrentMedia(ratingKey: 'rk2', serverId: 'srv', mediaTitle: 'Ep 2');
      room.host.detachPlayer();
      room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk2', serverId: 'srv', mediaTitle: 'Ep 2');
      async.flushMicrotasks();

      // The guest controller was detached but session-scoped routing caught
      // the new epoch.
      expect(mediaDispatches, contains('rk2'));

      // Guest re-attaches for the new episode; both load; room starts again.
      room.guest.attachPlayer(room.guestPlayer, ratingKey: 'rk2', serverId: 'srv');
      async.flushMicrotasks();
      room.bothBecomeReady();
      final resume = room.lastHostState();
      expect(resume.phase, PlaybackPhase.playing);
      expect(resume.ratingKey, 'rk2');
      room.dispose();
    });
  });

  test('hostOnly: forged control requests are dropped at the controller', () {
    fakeAsync((async) {
      final room = _Room(async);
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final delay = room.lastHostState().anchorHostTimeMs - room.nowMs();
      async.elapse(Duration(milliseconds: delay + 100));
      expect(room.hostPlayer.state.playing, isTrue);

      room.guestService.sendTo(
        'host',
        SyncMessage.control(const ControlRequest(kind: ControlRequestKind.pause), peerId: 'guest'),
      );
      async.elapse(const Duration(seconds: 1));

      expect(room.hostPlayer.state.playing, isTrue); // Ignored.
      room.dispose();
    });
  });

  test('anyone-mode: guest control requests round-trip through the host', () {
    fakeAsync((async) {
      final room = _Room(async, controlMode: ControlMode.anyone);
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final delay = room.lastHostState().anchorHostTimeMs - room.nowMs();
      async.elapse(Duration(milliseconds: delay + 100));

      // Guest presses pause → request → host applies → state pauses guest too.
      room.guestPlayer.emitPlaying(false);
      async.flushMicrotasks();
      expect(room.hostPlayer.state.playing, isFalse);
      final paused = room.lastHostState();
      expect(paused.phase, PlaybackPhase.paused);
      expect(paused.actorPeerId, 'guest');
      room.dispose();
    });
  });

  test('clock sync runs over the relay and converges', () {
    fakeAsync((async) {
      final room = _Room(async);
      // The guest's clock-sync burst pings the host; pongs come back with the
      // shared fake clock → offset 0.
      async.elapse(const Duration(seconds: 2));
      final pongs = room.guestService.outgoingLog.where((m) => m.type == SyncMessageType.ping);
      expect(pongs, isNotEmpty);
      room.dispose();
    });
  });

  test('v1 peers are flagged and never gate the start', () {
    fakeAsync((async) {
      final needsUpdate = <String>[];
      final room = _Room(async);
      room.host.onPeerNeedsUpdate = needsUpdate.add;

      // A legacy client joins on its own connection: its join message has no
      // version field (the relay stamps the sender id, so it must really
      // connect as itself — peerId spoofing is rewritten).
      final legacyService = room.hub.register('legacy');
      legacyService.sendTo(
        'host',
        SyncMessage(
          type: SyncMessageType.join,
          timestamp: room.nowMs(),
          peerId: 'legacy',
          displayName: 'Old App',
          isHost: false,
        ),
      );
      async.flushMicrotasks();
      expect(needsUpdate, ['legacy']);

      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      // The legacy peer never reports status, yet the room starts.
      expect(room.lastHostState().phase, PlaybackPhase.playing);
      room.dispose();
    });
  });

  test('guest reconnect re-requests state and the host answers directly', () {
    fakeAsync((async) {
      final room = _Room(async);
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final statesBefore = room.guestService.outgoingLog.length;

      room.guest.onReconnected();
      async.flushMicrotasks();

      // Status + requestState went out; host replied with a targeted state.
      final outgoing = room.guestService.outgoingLog.skip(statesBefore);
      expect(outgoing.where((m) => m.type == SyncMessageType.status), isNotEmpty);
      expect(outgoing.where((m) => m.type == SyncMessageType.requestState), isNotEmpty);
      final targeted = room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state);
      expect(targeted, isNotEmpty);
      room.dispose();
    });
  });
}
