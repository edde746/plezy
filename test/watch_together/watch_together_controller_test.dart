import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/services/watch_together_controller.dart';

import '../test_helpers/watch_together_fakes.dart';

const _epochMs = 1000000;

/// Two live controllers (host + guest) bridged by an in-memory relay.
///
/// The guest session is seeded with the production default
/// ([ControlMode.hostOnly], see [WatchSession.joinAsGuest]) unless
/// [guestControlMode] says otherwise — guests only learn the room's real
/// mode over the wire.
class _Room {
  _Room(this.async, {ControlMode controlMode = ControlMode.hostOnly, ControlMode? guestControlMode}) {
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
        controlMode: guestControlMode ?? ControlMode.hostOnly,
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

  test('anyone-mode: invalid controls are rejected and the queue continues', () {
    fakeAsync((async) {
      final room = _Room(async, controlMode: ControlMode.anyone);
      final actions = <(String, PlaybackActionHint)>[];
      room.host.onRemoteAction = (peer, hint) => actions.add((peer, hint));
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final delay = room.lastHostState().anchorHostTimeMs - room.nowMs();
      async.elapse(Duration(milliseconds: delay + 100));
      room.hostPlayer.commandLog.clear();
      final statesBefore = room.hostService.outgoingLog
          .where((message) => message.type == SyncMessageType.state)
          .length;
      final stateBefore = room.lastHostState();

      SyncMessage wireControl(ControlRequest request) {
        return SyncMessage.fromJson(SyncMessage.control(request, peerId: 'forged-peer').toJson());
      }

      room.guestService.sendTo(
        'host',
        wireControl(
          ControlRequest(kind: ControlRequestKind.seek, positionMs: room.hostPlayer.state.duration.inMilliseconds + 1),
        ),
      );
      room.guestService.sendTo(
        'host',
        wireControl(const ControlRequest(kind: ControlRequestKind.rate, rate: 8.000001)),
      );
      async.flushMicrotasks();

      expect(room.hostPlayer.commandLog, isEmpty);
      expect(actions, isEmpty);
      expect(
        room.hostService.outgoingLog.where((message) => message.type == SyncMessageType.state),
        hasLength(statesBefore),
      );
      expect(room.lastHostState().seq, stateBefore.seq);
      expect(room.lastHostState().anchorPositionMs, stateBefore.anchorPositionMs);
      expect(room.lastHostState().rate, stateBefore.rate);

      room.guestService.sendTo(
        'host',
        wireControl(const ControlRequest(kind: ControlRequestKind.seek, positionMs: 600000)),
      );
      async.flushMicrotasks();
      room.guestService.sendTo('host', wireControl(const ControlRequest(kind: ControlRequestKind.rate, rate: 0.25)));
      async.flushMicrotasks();

      expect(room.hostPlayer.commandLog, ['seek:600000', 'rate:0.25']);
      expect(actions, [('guest', PlaybackActionHint.seek), ('guest', PlaybackActionHint.rate)]);
      final acceptedStates = room.hostService.outgoingLog
          .where((message) => message.type == SyncMessageType.state)
          .skip(statesBefore)
          .map((message) => message.state!)
          .toList();
      expect(acceptedStates, hasLength(2));
      expect(acceptedStates[0].anchorPositionMs, 600000);
      expect(acceptedStates[0].actionHint, PlaybackActionHint.seek);
      expect(acceptedStates[0].actorPeerId, 'guest');
      expect(acceptedStates[1].rate, 0.25);
      expect(acceptedStates[1].actionHint, PlaybackActionHint.rate);
      expect(acceptedStates[1].actorPeerId, 'guest');
      room.dispose();
    });
  });

  test('guest controller starts clock-sync pings automatically', () {
    fakeAsync((async) {
      final room = _Room(async);
      // The guest's clock-sync burst starts immediately and sends pings
      // through its relay-backed peer service.
      async.elapse(const Duration(seconds: 2));
      final pings = room.guestService.outgoingLog.where((m) => m.type == SyncMessageType.ping);
      expect(pings, isNotEmpty);
      room.dispose();
    });
  });

  test('v2 peers are flagged and never gate the start', () {
    fakeAsync((async) {
      final needsUpdate = <String>[];
      final room = _Room(async);
      room.host.onPeerNeedsUpdate = needsUpdate.add;

      // A sync-protocol-2 client joins on its own connection. The relay
      // stamps the sender ID, so it must really connect as itself.
      final legacyService = room.hub.register('legacy');
      legacyService.sendTo(
        'host',
        SyncMessage(
          type: SyncMessageType.join,
          timestamp: room.nowMs(),
          peerId: 'legacy',
          displayName: 'Old App',
          isHost: false,
          version: 2,
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

  test('versionless legacy peers are flagged and never gate the start', () {
    fakeAsync((async) {
      final needsUpdate = <String>[];
      final room = _Room(async);
      room.host.onPeerNeedsUpdate = needsUpdate.add;

      final versionlessService = room.hub.register('versionless');
      versionlessService.sendTo(
        'host',
        SyncMessage(
          type: SyncMessageType.join,
          timestamp: room.nowMs(),
          peerId: 'versionless',
          displayName: 'Old App',
          isHost: false,
        ),
      );
      async.flushMicrotasks();
      expect(needsUpdate, ['versionless']);

      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      expect(room.lastHostState().phase, PlaybackPhase.playing);
      room.dispose();
    });
  });

  group('lobby control mode propagation', () {
    test('a host join delivers the control mode to an idle-room guest', () {
      fakeAsync((async) {
        final room = _Room(async, controlMode: ControlMode.anyone);
        final modes = <ControlMode>[];
        room.guest.onControlModeReceived = modes.add;

        // The room is idle: no media epoch, so no PlaybackState can carry
        // the mode (issue #1950). The host's (re-)announce must.
        room.host.announceJoin('Host');
        async.flushMicrotasks();

        expect(modes, [ControlMode.anyone]);
        expect(room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state), isEmpty);
        room.dispose();
      });
    });

    test('a control mode claimed by a non-host join is ignored', () {
      fakeAsync((async) {
        final room = _Room(async);
        final modes = <ControlMode>[];
        room.guest.onControlModeReceived = modes.add;

        // The relay stamps the real sender ID, so the forged isHost flag is
        // the only claim — and it must not be believed.
        final intruder = room.hub.register('intruder');
        intruder.sendTo(
          'guest',
          SyncMessage.join(peerId: 'intruder', displayName: 'Intruder', isHost: true, controlMode: ControlMode.anyone),
        );
        async.flushMicrotasks();

        expect(modes, isEmpty);
        room.dispose();
      });
    });

    test('a host join without a control mode (older client) changes nothing', () {
      fakeAsync((async) {
        final room = _Room(async, controlMode: ControlMode.anyone);
        final modes = <ControlMode>[];
        room.guest.onControlModeReceived = modes.add;

        // A 2.13.0 host's join carries no cm key — parse the exact legacy
        // wire shape.
        room.hostService.sendTo(
          'guest',
          SyncMessage.fromJson(
            SyncMessage(
              type: SyncMessageType.join,
              timestamp: room.nowMs(),
              peerId: 'host',
              displayName: 'Host',
              isHost: true,
              version: SyncMessage.protocolVersion,
            ).toJson(),
          ),
        );
        async.flushMicrotasks();

        expect(modes, isEmpty);
        room.dispose();
      });
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

  test('only relay-stamped state from the declared host reaches guest reconciliation', () {
    fakeAsync((async) {
      final room = _Room(async);
      final mediaDispatches = <String>[];
      room.guest.onMediaStateReceived = (ratingKey, serverId, title) => mediaDispatches.add(ratingKey);
      const state = PlaybackState(
        seq: 10,
        ratingKey: 'relay-authority',
        serverId: 'srv',
        mediaTitle: 'Authorized',
        phase: PlaybackPhase.loading,
        anchorPositionMs: 0,
        anchorHostTimeMs: _epochMs,
        rate: 1,
        controlMode: ControlMode.hostOnly,
      );
      final unprivileged = room.hub.register('unprivileged');

      // The fake relay overwrites the payload claim with the connection's
      // routing ID, just like the production relay envelope parser.
      unprivileged.broadcast(SyncMessage.state(state, peerId: 'host'));
      async.flushMicrotasks();
      expect(mediaDispatches, isEmpty);

      room.hostService.broadcast(SyncMessage.state(state, peerId: 'host'));
      async.flushMicrotasks();
      expect(mediaDispatches, ['relay-authority']);
      room.dispose();
    });
  });

  test('fake relay rejects duplicate routing IDs instead of replacing authority', () async {
    final hub = FakeRelayHub();
    hub.register('reserved');

    expect(() => hub.register('reserved'), throwsStateError);

    await hub.dispose();
  });

  group('hostExitedPlayer routing', () {
    test('rides the ordered queue: never overtakes states sent before it', () {
      fakeAsync((async) {
        final room = _Room(async);
        final log = <String>[];
        room.guest.onMediaStateReceived = (rk, sid, title) => log.add('state:$rk');
        room.guest.onHostExitedPlayer = () => log.add('hostExit');

        // Host starts media, then exits the player — wire order matters.
        room.hostStartsMedia();
        room.hostService.broadcast(SyncMessage.hostExitedPlayer(peerId: 'host'));
        async.flushMicrotasks();

        expect(log, isNotEmpty);
        expect(log.first, 'state:rk1');
        expect(log.last, 'hostExit');
        room.dispose();
      });
    });

    test('is ignored when forged by a non-host peer', () {
      fakeAsync((async) {
        final room = _Room(async);
        var hostExits = 0;
        room.guest.onHostExitedPlayer = () => hostExits++;

        final evil = room.hub.register('evil');
        evil.broadcast(SyncMessage.hostExitedPlayer(peerId: 'evil'));
        async.flushMicrotasks();

        expect(hostExits, 0);
        room.dispose();
      });
    });

    test('the host itself never reacts to a hostExitedPlayer echo', () {
      fakeAsync((async) {
        final room = _Room(async);
        var hostExits = 0;
        room.host.onHostExitedPlayer = () => hostExits++;

        // A confused/malicious guest sends the message; the host must not
        // tear down its own epoch.
        room.guestService.broadcast(SyncMessage.hostExitedPlayer(peerId: 'guest'));
        async.flushMicrotasks();

        expect(hostExits, 0);
        room.dispose();
      });
    });
  });

  group('a vehicle forcing a pause on one peer', () {
    test('a guest stops locally and the room keeps playing', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 2));
        expect(room.guestPlayer.state.playing, isTrue);

        bool? handled;
        unawaited(room.guest.pauseLocallyForSystem().then((value) => handled = value));
        async.flushMicrotasks();

        expect(handled, isTrue);
        expect(room.guestPlayer.state.playing, isFalse, reason: 'the car this guest is in must go quiet');
        async.elapse(const Duration(seconds: 2));
        expect(room.hostPlayer.state.playing, isTrue, reason: 'one guest driving must not stop the room');
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        room.dispose();
      });
    });

    test('a host is refused, because the room cannot outrun its own clock', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 2));

        bool? handled;
        unawaited(room.host.pauseLocallyForSystem().then((value) => handled = value));
        async.flushMicrotasks();

        // Refused, so the caller pauses the ordinary way and the room follows: a host that keeps
        // broadcasting a playing anchor from a frozen player would stall every guest.
        expect(handled, isFalse);
        expect(room.hostPlayer.state.playing, isTrue, reason: 'nothing local happened');
        room.dispose();
      });
    });
  });

  group('host transfer', () {
    WatchSession sessionAs(SessionRole role) => WatchSession(
      sessionId: 'ROOM1',
      role: role,
      controlMode: ControlMode.hostOnly,
      state: SessionState.connected,
      hostPeerId: 'guest',
    );

    test('mid-playback: the promoted guest re-anchors the room and the demoted host follows', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 3));
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        final originalKey = room.lastHostState().mediaKey;
        final statesBefore = room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state).length;

        // The relay reassigned authority: each side applies its own hostChanged.
        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();

        // The demoted host falls in line: it asks the new authority for state.
        expect(room.hostService.outgoingLog.any((m) => m.type == SyncMessageType.requestState), isTrue);

        // The promoted guest re-runs the epoch gate and both players resume.
        async.elapse(const Duration(seconds: 5));
        final adopted = room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;
        expect(adopted.phase, PlaybackPhase.playing);
        expect(adopted.mediaKey, originalKey);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);

        // The old host's coordinator is gone — it authors no further states.
        expect(room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state).length, statesBefore);
        room.dispose();
      });
    });

    test('a paused room stays paused across the handoff', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 3));
        expect(room.hostPlayer.state.playing, isTrue);

        // The host pauses the room before handing it over.
        room.hostPlayer.emitPlaying(false);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(room.lastHostState().phase, PlaybackPhase.paused);
        expect(room.guestPlayer.state.playing, isFalse);
        final guestPlays = room.guestPlayer.commandLog.where((c) => c == 'play').length;
        final hostPlays = room.hostPlayer.commandLog.where((c) => c == 'play').length;

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        final adopted = room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;
        expect(adopted.phase, PlaybackPhase.paused, reason: 'a host change is not a play intent');
        expect(room.hostPlayer.state.playing, isFalse);
        expect(room.guestPlayer.state.playing, isFalse);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play').length, guestPlays);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play').length, hostPlays);
        room.dispose();
      });
    });
  });
}
