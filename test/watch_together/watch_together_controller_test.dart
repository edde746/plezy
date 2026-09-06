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

  void hostStartsMedia({String ratingKey = 'rk1', bool hasFirstFrame = false, Future<void>? startupHold}) {
    host.attachPlayer(
      hostPlayer,
      ratingKey: ratingKey,
      serverId: 'srv',
      mediaTitle: 'Ep',
      hasFirstFrame: hasFirstFrame,
      startupHold: startupHold,
    );
    host.setCurrentMedia(ratingKey: ratingKey, serverId: 'srv', mediaTitle: 'Ep');
    async.flushMicrotasks();
  }

  void guestJoinsMedia({String ratingKey = 'rk1', Future<void>? startupHold}) {
    guest.attachPlayer(guestPlayer, ratingKey: ratingKey, serverId: 'srv', startupHold: startupHold);
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

  group('host media reattachment', () {
    _Room playingRoom(FakeAsync async, {ControlMode controlMode = ControlMode.hostOnly}) {
      final room = _Room(async, controlMode: controlMode);
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      async.elapse(const Duration(seconds: 3));
      expect(room.hostPlayer.state.playing, isTrue);
      expect(room.guestPlayer.state.playing, isTrue);
      return room;
    }

    for (final hasFirstFrame in [false, true]) {
      test(
        hasFirstFrame
            ? 'a paused rollback stays paused without another first-frame event'
            : 'a paused same-key reload stays paused when replacement readiness arrives',
        () {
          fakeAsync((async) {
            final room = playingRoom(async);
            room.hostPlayer.emitPlaying(false);
            async.flushMicrotasks();
            expect(room.lastHostState().phase, PlaybackPhase.paused);
            expect(room.guestPlayer.state.playing, isFalse);
            room.hostPlayer.commandLog.clear();
            room.guestPlayer.commandLog.clear();
            final messagesBefore = room.hostService.outgoingLog.length;

            room.host.detachPlayer();
            async.flushMicrotasks();
            // Reload/rollback callers have no intent seed: the room, not the
            // rebound player's snapshot, owns whether playback should resume.
            room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk1', serverId: 'srv', hasFirstFrame: hasFirstFrame);
            async.flushMicrotasks();
            if (!hasFirstFrame) {
              async.elapse(const Duration(seconds: 2));
              expect(room.hostPlayer.state.playing, isFalse);
              room.hostPlayer.emitPlaybackRestart();
              async.flushMicrotasks();
            }
            async.elapse(const Duration(seconds: 6));

            expect(room.lastHostState().phase, PlaybackPhase.paused);
            expect(room.hostPlayer.state.playing, isFalse);
            expect(room.guestPlayer.state.playing, isFalse);
            expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
            expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);
            expect(
              room.hostService.outgoingLog
                  .skip(messagesBefore)
                  .where((m) => m.type == SyncMessageType.state && m.state!.phase == PlaybackPhase.playing),
              isEmpty,
            );
            room.dispose();
          });
        },
      );
    }

    test('a pause accepted while detached and loading survives reattachment', () {
      fakeAsync((async) {
        final room = _Room(async, controlMode: ControlMode.anyone);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.guestPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        expect(room.lastHostState().phase, PlaybackPhase.loading);

        room.host.detachPlayer();
        async.flushMicrotasks();
        room.guestService.sendTo(
          'host',
          SyncMessage.control(const ControlRequest(kind: ControlRequestKind.pause), peerId: 'guest'),
        );
        async.flushMicrotasks();
        // Loading is not a play-intent snapshot: the pause is latched without
        // publishing a playable anchor before the host has rendered.
        expect(room.host.phase, PlaybackPhase.loading);
        room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk1', serverId: 'srv');
        room.hostPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        expect(room.lastHostState().phase, PlaybackPhase.paused);
        expect(room.hostPlayer.state.playing, isFalse);
        expect(room.guestPlayer.state.playing, isFalse);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        room.dispose();
      });
    });

    test('a genuine play accepted during a paused detach gap resumes after readiness', () {
      fakeAsync((async) {
        final room = playingRoom(async, controlMode: ControlMode.anyone);
        room.hostPlayer.emitPlaying(false);
        async.flushMicrotasks();
        expect(room.lastHostState().phase, PlaybackPhase.paused);

        room.host.detachPlayer();
        async.flushMicrotasks();
        room.guestService.sendTo(
          'host',
          SyncMessage.control(const ControlRequest(kind: ControlRequestKind.play), peerId: 'guest'),
        );
        async.flushMicrotasks();
        expect(room.host.phase, PlaybackPhase.paused, reason: 'play waits for a meaningful local anchor');
        room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk1', serverId: 'srv');
        async.elapse(const Duration(seconds: 2));
        expect(room.hostPlayer.state.playing, isFalse);
        expect(room.guestPlayer.state.playing, isFalse);

        room.hostPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('a playing same-key reload resumes despite the internal detached pause', () {
      fakeAsync((async) {
        final room = playingRoom(async);
        room.host.detachPlayer();
        async.flushMicrotasks();
        room.hostPlayer.emitPlaying(false);
        async.flushMicrotasks();
        room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk1', serverId: 'srv');
        async.elapse(const Duration(seconds: 2));
        expect(room.hostPlayer.state.playing, isFalse);
        expect(room.guestPlayer.state.playing, isFalse);

        room.hostPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('opening a different item starts a previously paused room', () {
      fakeAsync((async) {
        final room = playingRoom(async);
        room.hostPlayer.emitPlaying(false);
        async.flushMicrotasks();
        expect(room.lastHostState().phase, PlaybackPhase.paused);

        room.host.detachPlayer();
        room.guest.detachPlayer();
        async.flushMicrotasks();
        room.host.setCurrentMedia(ratingKey: 'rk2', serverId: 'srv');
        room.host.attachPlayer(room.hostPlayer, ratingKey: 'rk2', serverId: 'srv');
        room.guestJoinsMedia(ratingKey: 'rk2');
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 3));

        expect(room.lastHostState().mediaKey, 'srv:rk2');
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
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

  test('rate reaches the room only when declared; a player rate event on the host is not a room change', () {
    fakeAsync((async) {
      final room = _Room(async, controlMode: ControlMode.anyone, guestControlMode: ControlMode.anyone);
      room.hostStartsMedia();
      room.guestJoinsMedia();
      room.bothBecomeReady();
      final delay = room.lastHostState().anchorHostTimeMs - room.nowMs();
      async.elapse(Duration(milliseconds: delay + 100));
      final statesBefore = room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state).length;

      // The host's player reports a rate change nobody asked the room for
      // (a default-speed apply, a late ack): the room rate must not move.
      room.hostPlayer.emitRate(1.25);
      async.flushMicrotasks();
      expect(room.hostService.outgoingLog.where((m) => m.type == SyncMessageType.state).length, statesBefore);
      expect(room.lastHostState().rate, 1.0);

      // The host's screen declares a rate: broadcast with attribution.
      room.host.onLocalRate(1.25);
      async.flushMicrotasks();
      expect(room.lastHostState().rate, 1.25);
      expect(room.lastHostState().actionHint, PlaybackActionHint.rate);
      expect(room.lastHostState().actorPeerId, 'host');
      expect(room.host.roomRate, 1.25);

      // The guest's screen declares one: a control request the host applies.
      room.guestPlayer.emitRate(1.5);
      async.flushMicrotasks();
      expect(room.guestService.outgoingLog.where((m) => m.type == SyncMessageType.control), isEmpty);
      room.guest.onLocalRate(1.5);
      async.flushMicrotasks();
      expect(room.hostPlayer.commandLog.last, 'rate:1.5');
      expect(room.lastHostState().rate, 1.5);
      expect(room.lastHostState().actorPeerId, 'guest');
      async.elapse(const Duration(seconds: 1));
      expect(room.guest.roomRate, 1.5);
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
    WatchSession sessionAs(SessionRole role, {String hostPeerId = 'guest'}) => WatchSession(
      sessionId: 'ROOM1',
      role: role,
      controlMode: ControlMode.hostOnly,
      state: SessionState.connected,
      hostPeerId: hostPeerId,
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

    test('promotion retains a pending startup hold after the first frame', () {
      fakeAsync((async) {
        final room = _Room(async);
        final hold = Completer<void>();
        room.hostStartsMedia();
        room.guestJoinsMedia(startupHold: hold.future);
        room.bothBecomeReady();

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        expect(room.guest.phase, PlaybackPhase.loading);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);

        // No second frame is emitted: the frame and the hold are independent
        // prerequisites belonging to the same surviving attachment.
        hold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.guest.phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('demotion does not advertise readiness from a frame while its startup hold is pending', () {
      fakeAsync((async) {
        final room = _Room(async);
        final hold = Completer<void>();
        room.hostStartsMedia(startupHold: hold.future);
        room.guestJoinsMedia();
        room.bothBecomeReady();
        final messagesBefore = room.hostService.outgoingLog.length;

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        final statuses = room.hostService.outgoingLog
            .skip(messagesBefore)
            .where((m) => m.type == SyncMessageType.status)
            .map((m) => m.status!);
        expect(statuses, isNotEmpty);
        expect(statuses.every((status) => !status.ready), isTrue);
        final waiting = room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;
        expect(waiting.phase, PlaybackPhase.waitingForPeers);
        expect(waiting.waitingOn, contains('host'));
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);

        hold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.hostService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.status).status!.ready, isTrue);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('promotion after hold completion still waits for the first frame', () {
      fakeAsync((async) {
        final room = _Room(async);
        final hold = Completer<void>();
        room.hostStartsMedia(hasFirstFrame: true);
        room.guestJoinsMedia(startupHold: hold.future);
        hold.complete();
        async.flushMicrotasks();

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.guest.phase, PlaybackPhase.loading);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);

        room.guestPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.guest.phase, PlaybackPhase.playing);
        expect(room.guestPlayer.state.playing, isTrue);
        expect(room.hostPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('demotion before either prerequisite still needs a frame after its hold completes', () {
      fakeAsync((async) {
        final room = _Room(async);
        final hold = Completer<void>();
        room.hostStartsMedia(startupHold: hold.future);
        room.guestJoinsMedia();
        room.guestPlayer.emitPlaybackRestart();
        async.flushMicrotasks();

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        hold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.hostService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.status).status!.ready, isFalse);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);

        room.hostPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('a pending attachment hold survives repeated promotion and demotion round trips', () {
      fakeAsync((async) {
        final room = _Room(async);
        final hold = Completer<void>();
        room.hostStartsMedia(hasFirstFrame: true);
        room.guestJoinsMedia(startupHold: hold.future);

        for (final (index, hostPeerId) in ['guest', 'host', 'guest', 'host'].indexed) {
          room.host.applyHostChange(
            sessionAs(hostPeerId == 'host' ? SessionRole.host : SessionRole.guest, hostPeerId: hostPeerId),
          );
          room.guest.applyHostChange(
            sessionAs(hostPeerId == 'guest' ? SessionRole.host : SessionRole.guest, hostPeerId: hostPeerId),
          );
          async.flushMicrotasks();
          // The first transfer precedes both prerequisites. Only that first
          // replacement gets a frame event; later replacements must retain it.
          if (index == 0) {
            room.guestPlayer.emitPlaybackRestart();
            async.flushMicrotasks();
          }
          async.elapse(const Duration(seconds: 2));
          expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);
          expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        }

        hold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });

    test('a replacement keeps its own startup hold when a stale pre-transfer hold completes', () {
      fakeAsync((async) {
        final room = _Room(async);
        final oldHold = Completer<void>();
        final replacementHold = Completer<void>();
        room.hostStartsMedia();
        room.guestJoinsMedia(startupHold: oldHold.future);
        room.bothBecomeReady();
        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();

        room.guest.detachPlayer();
        async.flushMicrotasks();
        final replacement = FakeSyncPlayer(position: const Duration(minutes: 2));
        room.guest.attachPlayer(
          replacement,
          ratingKey: 'rk1',
          serverId: 'srv',
          hasFirstFrame: true,
          startupHold: replacementHold.future,
        );
        async.flushMicrotasks();
        room.host.applyHostChange(sessionAs(SessionRole.host, hostPeerId: 'host'));
        room.guest.applyHostChange(sessionAs(SessionRole.guest, hostPeerId: 'host'));
        async.flushMicrotasks();

        oldHold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.status).status!.ready, isFalse);
        expect(replacement.commandLog.where((c) => c == 'play'), isEmpty);
        expect(room.hostPlayer.commandLog.where((c) => c == 'play'), isEmpty);

        replacementHold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(room.lastHostState().phase, PlaybackPhase.playing);
        expect(room.hostPlayer.state.playing, isTrue);
        expect(replacement.state.playing, isTrue);
        expect(room.guestPlayer.commandLog.where((c) => c == 'play'), isEmpty);
        room.dispose();
        unawaited(replacement.dispose());
        async.flushMicrotasks();
      });
    });

    test('a promoted guest adopts the room rate, not its own mid-correction player rate', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 3));

        // The room runs at 1.25; the guest's player momentarily reports
        // something else (a nudge, a stray event). The room rate is what the
        // new host must carry forward — not its player's snapshot.
        room.host.onLocalRate(1.25);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(room.lastHostState().rate, 1.25);
        room.guestPlayer.emitRate(1.3);
        async.flushMicrotasks();

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        final adopted = room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;
        expect(adopted.rate, 1.25);
        expect(room.guest.roomRate, 1.25);
        room.dispose();
      });
    });

    test('a promoted guest runs the room rate it never applied while the room was paused', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();
        room.bothBecomeReady();
        async.elapse(const Duration(seconds: 3));

        // A paused guest holds position, not rate: nothing applies the room's
        // speed to its player while the room is stopped.
        room.hostPlayer.emitPlaying(false);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(room.lastHostState().phase, PlaybackPhase.paused);
        room.host.onLocalRate(1.25);
        room.hostPlayer.emitRate(1.25);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(room.lastHostState().rate, 1.25);
        expect(room.guestPlayer.state.rate, 1.0, reason: 'the paused guest never ran the new rate');

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        // The host player is the room clock: a rate it advertises but does not
        // run is a permanent drift every guest keeps correcting against.
        expect(room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!.rate, 1.25);
        expect(room.guestPlayer.state.rate, 1.25);
        room.dispose();
      });
    });

    test('a promoted guest waits for the peers it already knows instead of starting alone', () {
      fakeAsync((async) {
        final room = _Room(async);
        room.hostStartsMedia();
        room.guestJoinsMedia();

        // Both existing peers have rendered; a third participant has not.
        final laggardService = room.hub.register('laggard');
        final laggard = WatchTogetherController(
          peerService: laggardService,
          session: WatchSession(
            sessionId: 'ROOM1',
            role: SessionRole.guest,
            controlMode: ControlMode.hostOnly,
            state: SessionState.connected,
            hostPeerId: 'host',
          ),
          nowMs: room.nowMs,
        );
        addTearDown(laggard.dispose);
        laggard.announceJoin('Laggard');
        final laggardPlayer = FakeSyncPlayer(position: Duration.zero);
        laggard.attachPlayer(laggardPlayer, ratingKey: 'rk1', serverId: 'srv');
        room.hostPlayer.emitPlaybackRestart();
        room.guestPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));

        room.host.applyHostChange(sessionAs(SessionRole.guest));
        room.guest.applyHostChange(sessionAs(SessionRole.host));
        laggard.applyHostChange(sessionAs(SessionRole.guest));
        async.flushMicrotasks();

        // The fresh epoch gates on the roster the new host already has, so the
        // still-loading participant is waited for rather than left behind.
        final adopted = room.guestService.outgoingLog.lastWhere((m) => m.type == SyncMessageType.state).state!;
        expect(adopted.phase, PlaybackPhase.waitingForPeers);
        expect(adopted.waitingOn, contains('laggard'));
        expect(room.guestPlayer.state.playing, isFalse);

        // Not a deadlock: the room starts once the laggard renders.
        laggardPlayer.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        expect(room.guestPlayer.state.playing, isTrue);
        room.dispose();
      });
    });
  });
}
