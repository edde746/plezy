import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/car_ux_restrictions_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/services/attached_player.dart';
import 'package:plezy/watch_together/services/host_playback_coordinator.dart';

import '../test_helpers/watch_together_fakes.dart';

const _epochMs = 1000000;

class _Harness {
  _Harness(
    FakeAsync async, {
    ControlMode controlMode = ControlMode.hostOnly,
    void Function(List<String>)? onResumedWithout,
    void Function(String, PlaybackActionHint)? onRemoteAction,
    Duration duration = const Duration(minutes: 45),
    bool seekable = true,
  }) {
    int nowMs() => _epochMs + async.elapsed.inMilliseconds;
    player = FakeSyncPlayer(position: const Duration(minutes: 2), duration: duration, seekable: seekable);
    coordinator = HostPlaybackCoordinator(
      myPeerId: 'host',
      controlMode: controlMode,
      sendState: (state, {toPeerId}) => sent.add((state, toPeerId)),
      onResumedWithout: onResumedWithout,
      onRemoteAction: onRemoteAction,
      nowMs: nowMs,
    );
    attached = AttachedPlayer(player: player, onLost: () {}, nowMs: nowMs);
  }

  late final FakeSyncPlayer player;
  late final HostPlaybackCoordinator coordinator;
  late final AttachedPlayer attached;
  final List<(PlaybackState, String?)> sent = [];

  /// Broadcast states only (no targeted sends).
  List<PlaybackState> get broadcasts => [
    for (final (state, to) in sent)
      if (to == null) state,
  ];

  PlaybackState get last => broadcasts.last;

  void attachForMedia(FakeAsync async, {bool hasFirstFrame = false}) {
    coordinator.attach(attached, ratingKey: 'rk1', serverId: 'srv', mediaTitle: 'Ep 1', hasFirstFrame: hasFirstFrame);
    async.flushMicrotasks();
  }

  void hostBecomesReady(FakeAsync async) {
    player.emitPlaybackRestart();
    async.flushMicrotasks();
  }

  void guestReports(
    FakeAsync async, {
    String peerId = 'guest',
    bool ready = true,
    bool buffering = false,
    String mediaKey = 'srv:rk1',
    int? rttMs,
  }) {
    coordinator.onPeerStatus(
      peerId,
      PeerStatus(mediaKey: mediaKey, ready: ready, buffering: buffering, positionMs: 0, rttMs: rttMs),
    );
    async.flushMicrotasks();
  }

  void dispose() {
    coordinator.dispose();
    attached.dispose();
  }
}

void main() {
  group('initial start coordination', () {
    test('guest loads first: nothing but loading-phase states until the host is ready (the loop bug)', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);

        // Guest is ready long before the host.
        h.guestReports(async);
        async.elapse(const Duration(seconds: 5));

        // Every state so far must be loading — never "playing at a frozen
        // position", which is what caused guests to loop.
        expect(h.broadcasts, isNotEmpty);
        expect(h.broadcasts.every((s) => s.phase == PlaybackPhase.loading), isTrue);
        expect(h.player.commandLog.where((c) => c == 'play'), isEmpty);

        // Host becomes ready: waitingForPeers resolves instantly into a
        // scheduled start because the guest is already ready.
        h.hostBecomesReady(async);
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorHostTimeMs, greaterThan(_epochMs + async.elapsed.inMilliseconds));

        // The host's own player starts exactly at the scheduled moment.
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        expect(delay, greaterThanOrEqualTo(HostPlaybackCoordinator.startDelayMinMs));
        expect(h.player.state.playing, isFalse);
        async.elapse(Duration(milliseconds: delay));
        expect(h.player.state.playing, isTrue);

        h.dispose();
      });
    });

    test('host loads first: waits for the guest, then schedules the start', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);

        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        expect(h.last.waitingOn, ['guest']);
        expect(h.player.state.playing, isFalse);

        async.elapse(const Duration(seconds: 3));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        h.guestReports(async, rttMs: 200);
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds), 750);

        h.dispose();
      });
    });

    test('start delay scales with the worst peer RTT, capped', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.coordinator.onPeerJoined('guest2', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        h.guestReports(async, rttMs: 100);
        h.guestReports(async, peerId: 'guest2', rttMs: 900);

        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds), 1350);

        h.dispose();
      });
    });

    test('host alone starts immediately with no artificial delay', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async);
        h.hostBecomesReady(async);

        expect(h.last.phase, PlaybackPhase.playing);
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        expect(h.player.state.playing, isTrue);

        h.dispose();
      });
    });

    test('attaching to an already-rendering player counts as ready', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async, hasFirstFrame: true);
        expect(h.broadcasts.map((s) => s.phase), contains(PlaybackPhase.playing));
        h.dispose();
      });
    });

    test('readiness waits for the startup hold (frame-rate gate)', () {
      fakeAsync((async) {
        final h = _Harness(async);
        final hold = Completer<void>();

        h.coordinator.attach(h.attached, ratingKey: 'rk1', serverId: 'srv', startupHold: hold.future);
        async.flushMicrotasks();
        h.player.emitPlaybackRestart();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        expect(h.broadcasts.every((s) => s.phase == PlaybackPhase.loading), isTrue);
        expect(h.player.commandLog.where((c) => c == 'play'), isEmpty);

        hold.complete();
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.player.state.playing, isTrue);

        h.dispose();
      });
    });

    test('a stale hold cannot release a replacement attachment of the same player', () {
      fakeAsync((async) {
        final h = _Harness(async);
        final oldHold = Completer<void>();
        final replacementHold = Completer<void>();
        h.coordinator.attach(
          h.attached,
          ratingKey: 'rk1',
          serverId: 'srv',
          hasFirstFrame: true,
          startupHold: oldHold.future,
        );
        async.flushMicrotasks();

        h.coordinator.detachPlayer();
        unawaited(h.attached.dispose());
        async.flushMicrotasks();
        final replacement = AttachedPlayer(
          player: h.player,
          onLost: () {},
          nowMs: () => _epochMs + async.elapsed.inMilliseconds,
        );
        h.coordinator.attach(
          replacement,
          ratingKey: 'rk1',
          serverId: 'srv',
          hasFirstFrame: true,
          startupHold: replacementHold.future,
        );
        async.flushMicrotasks();

        oldHold.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(h.last.phase, PlaybackPhase.loading);
        expect(h.player.commandLog.where((c) => c == 'play'), isEmpty);

        replacementHold.complete();
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.player.state.playing, isTrue);
        h.coordinator.dispose();
        unawaited(replacement.dispose());
        async.flushMicrotasks();
      });
    });
  });

  group('stalls and group wait', () {
    _Harness playingRoom(FakeAsync async) {
      final h = _Harness(async);
      h.coordinator.onPeerJoined('guest', compatible: true);
      h.attachForMedia(async);
      h.guestReports(async);
      h.hostBecomesReady(async);
      final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
      async.elapse(Duration(milliseconds: delay));
      expect(h.player.state.playing, isTrue);
      return h;
    }

    test('host stall: brief blips are absorbed by the grace window', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        final statesBefore = h.broadcasts.length;

        h.player.emitBuffering(true);
        async.elapse(const Duration(milliseconds: 300));
        h.player.emitBuffering(false);
        async.elapse(const Duration(seconds: 1));

        expect(h.broadcasts.skip(statesBefore).where((s) => s.phase == PlaybackPhase.waitingForPeers), isEmpty);
        h.dispose();
      });
    });

    test('host stall: sustained buffering pauses the room and the host player at the stall anchor', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        expect(h.player.properties['cache-pause-wait'], '4'); // Set on attach.
        h.player.setPosition(const Duration(minutes: 5));

        h.player.emitBuffering(true);
        async.elapse(const Duration(milliseconds: 600));

        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        expect(h.last.waitingOn, ['host']);
        expect(h.last.anchorPositionMs, const Duration(minutes: 5).inMilliseconds);
        // The host player is the room clock: it stops where the room stops,
        // so mpv's own cache-pause cannot walk the anchor ahead of everyone.
        expect(h.player.state.playing, isFalse);

        // A 4s stall demands 12s of headroom. With no cache position from
        // the backend the hold is time-based, measured from the stall's end.
        async.elapse(const Duration(milliseconds: 3400));
        h.player.emitBuffering(false);
        async.elapse(const Duration(seconds: 11));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        async.elapse(const Duration(milliseconds: 1500));
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorPositionMs, const Duration(minutes: 5).inMilliseconds);
        expect(h.last.anchorHostTimeMs, greaterThan(_epochMs + async.elapsed.inMilliseconds));
        h.dispose();
      });
    });

    test('host stall: a known cache position releases the hold as soon as headroom is buffered', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        h.player.setPosition(const Duration(minutes: 5));

        h.player.emitBuffering(true);
        async.elapse(const Duration(seconds: 2)); // 2s stall → 6s of headroom needed.
        h.player.setBuffer(const Duration(minutes: 5, seconds: 3));
        h.player.emitBuffering(false);
        async.elapse(const Duration(seconds: 1));
        expect(h.last.phase, PlaybackPhase.waitingForPeers); // 3s ahead is not enough.

        h.player.setBuffer(const Duration(minutes: 5, seconds: 7));
        async.elapse(const Duration(milliseconds: 600)); // Next 500ms re-check.
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('host stall near the end: headroom is capped by the media left, not held for what cannot arrive', () {
      fakeAsync((async) {
        final h = _Harness(async, duration: const Duration(seconds: 310));
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.guestReports(async);
        h.hostBecomesReady(async);
        async.elapse(Duration(milliseconds: h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds)));
        h.player.setPosition(const Duration(seconds: 300));

        h.player.emitBuffering(true);
        async.elapse(const Duration(seconds: 4)); // 4s stall → 12s wanted, but only 10s of media remain.
        h.player.setBuffer(const Duration(seconds: 310)); // Everything left is buffered.
        h.player.emitBuffering(false);
        async.elapse(const Duration(milliseconds: 1500));

        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('host stall: a cache that never grows releases the room at the wait deadline', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        h.player.setPosition(const Duration(minutes: 5));

        h.player.emitBuffering(true);
        async.elapse(const Duration(seconds: 4));
        h.player.setBuffer(const Duration(minutes: 5, seconds: 3)); // 3s ahead, 12s wanted, and it stays there.
        h.player.emitBuffering(false);
        async.elapse(Duration(milliseconds: HostPlaybackCoordinator.selfRecoveryMaxWaitMs - 500));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        async.elapse(const Duration(seconds: 1));
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('host stall: a heartbeat during a sub-grace blip keeps extrapolating the last anchor', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        final anchor = h.last;
        final statesBefore = h.broadcasts.length;
        // Heartbeats tick 2s from the scheduled-start broadcast, which the
        // room made startDelayMinMs before the start moment playingRoom
        // elapsed to. Straddle the next tick with a blip shorter than grace.
        final untilTickMs = HostPlaybackCoordinator.heartbeatPlayingMs - HostPlaybackCoordinator.startDelayMinMs;
        async.elapse(Duration(milliseconds: untilTickMs - 200));

        // Player position freezes while buffering; the heartbeat must not
        // re-anchor on the frozen position (that moves every guest back).
        h.player.emitBuffering(true);
        async.elapse(const Duration(milliseconds: 300));
        expect(h.broadcasts.length, statesBefore + 1); // The tick fired.
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorPositionMs, anchor.anchorPositionMs);
        expect(h.last.anchorHostTimeMs, anchor.anchorHostTimeMs);

        h.player.emitBuffering(false);
        h.player.setPosition(const Duration(minutes: 2, seconds: 4));
        async.elapse(const Duration(milliseconds: 2000));
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorPositionMs, const Duration(minutes: 2, seconds: 4).inMilliseconds);
        expect(h.last.anchorHostTimeMs, greaterThan(anchor.anchorHostTimeMs));
        h.dispose();
      });
    });

    test('guest stall: room pauses, safety timeout excuses them, resume fires', () {
      fakeAsync((async) {
        final resumedWithout = <List<String>>[];
        final h = _Harness(async, onResumedWithout: resumedWithout.add);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.guestReports(async);
        h.hostBecomesReady(async);
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        async.elapse(Duration(milliseconds: delay));

        h.guestReports(async, buffering: true);
        async.elapse(const Duration(milliseconds: 600));

        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        expect(h.last.waitingOn, ['guest']);
        expect(h.player.state.playing, isFalse); // Host pauses for a peer stall.

        // Guest never recovers — safety excuses them and the room resumes
        // immediately (no other gating peers left).
        async.elapse(const Duration(seconds: 15));
        expect(resumedWithout, [
          ['guest'],
        ]);
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.player.state.playing, isTrue);

        // A healthy report un-excuses the guest: its next stall gates again.
        h.guestReports(async);
        h.guestReports(async, buffering: true);
        async.elapse(const Duration(milliseconds: 600));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        h.dispose();
      });
    });

    test('guest recovery resumes the room with a fresh scheduled start', () {
      fakeAsync((async) {
        final h = playingRoom(async);

        h.guestReports(async, buffering: true);
        async.elapse(const Duration(milliseconds: 600));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        final anchorDuringWait = h.last.anchorPositionMs;

        h.guestReports(async, buffering: false);
        async.elapse(const Duration(milliseconds: 450));
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorPositionMs, anchorDuringWait);
        h.dispose();
      });
    });

    test('late joiner never pauses a playing room', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        final statesBefore = h.broadcasts.length;

        h.coordinator.onPeerJoined('late', compatible: true);
        async.flushMicrotasks();
        // Targeted state so the joiner can catch up.
        expect(h.sent.where((entry) => entry.$2 == 'late'), isNotEmpty);

        // Their loading status does not gate the room.
        h.guestReports(async, peerId: 'late', ready: false);
        async.elapse(const Duration(seconds: 2));
        expect(h.broadcasts.skip(statesBefore).where((s) => s.phase == PlaybackPhase.waitingForPeers), isEmpty);
        h.dispose();
      });
    });

    test('a stalled peer leaving unblocks the room', () {
      fakeAsync((async) {
        final h = playingRoom(async);
        h.guestReports(async, buffering: true);
        async.elapse(const Duration(milliseconds: 600));
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        h.coordinator.onPeerLeft('guest');
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });
  });

  group('intents and control', () {
    test('play presses while waiting are held back; the room starts at all-ready', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        // User mashes play while the room waits on the guest — held back.
        h.player.emitPlaying(true);
        async.flushMicrotasks();
        expect(h.player.state.playing, isFalse);
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        h.guestReports(async);
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('a pause control request during the wait lands the room paused at all-ready', () {
      fakeAsync((async) {
        final h = _Harness(async, controlMode: ControlMode.anyone);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.coordinator.onPeerJoined('guest2', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        h.guestReports(async, peerId: 'guest2');
        expect(h.last.phase, PlaybackPhase.waitingForPeers);

        h.coordinator.onControlRequest('guest2', const ControlRequest(kind: ControlRequestKind.pause));
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.paused);

        // The remaining guest becoming ready must NOT auto-play.
        h.guestReports(async);
        expect(h.last.phase, PlaybackPhase.paused);
        expect(h.player.state.playing, isFalse);
        h.dispose();
      });
    });

    test('user play with everyone ready schedules a synchronized resume', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        h.guestReports(async);
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        async.elapse(Duration(milliseconds: delay));

        h.player.emitPlaying(false); // User pauses.
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.paused);

        h.player.emitPlaying(true); // User resumes.
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.playing);
        expect(h.last.anchorHostTimeMs, greaterThan(_epochMs + async.elapsed.inMilliseconds));
        // Host was paused back until the scheduled moment.
        expect(h.player.state.playing, isFalse);
        async.elapse(Duration(milliseconds: h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds)));
        expect(h.player.state.playing, isTrue);
        h.dispose();
      });
    });

    test('control requests apply to the host player with actor attribution', () {
      fakeAsync((async) {
        final actions = <(String, PlaybackActionHint)>[];
        final h = _Harness(
          async,
          controlMode: ControlMode.anyone,
          onRemoteAction: (peer, hint) => actions.add((peer, hint)),
        );
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.guestReports(async);
        h.hostBecomesReady(async);
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        async.elapse(Duration(milliseconds: delay));

        h.coordinator.onControlRequest('guest', const ControlRequest(kind: ControlRequestKind.pause));
        async.flushMicrotasks();
        expect(h.player.state.playing, isFalse);
        expect(h.last.phase, PlaybackPhase.paused);
        expect(h.last.actorPeerId, 'guest');
        expect(actions, contains(('guest', PlaybackActionHint.pause)));

        h.coordinator.onControlRequest(
          'guest',
          const ControlRequest(kind: ControlRequestKind.seek, positionMs: 600000),
        );
        async.flushMicrotasks();
        expect(h.player.state.position, const Duration(minutes: 10));
        expect(h.last.anchorPositionMs, 600000);
        expect(h.last.actionHint, PlaybackActionHint.seek);

        h.coordinator.onControlRequest('guest', const ControlRequest(kind: ControlRequestKind.play));
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('invalid remote seeks and rates are rejected without side effects', () {
      fakeAsync((async) {
        final actions = <(String, PlaybackActionHint)>[];
        final h = _Harness(
          async,
          controlMode: ControlMode.anyone,
          onRemoteAction: (peer, hint) => actions.add((peer, hint)),
        );
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        final durationMs = h.player.state.duration.inMilliseconds;
        final broadcastsBefore = h.broadcasts.length;
        final seqBefore = h.last.seq;
        final anchorBefore = h.last.anchorPositionMs;
        final rateBefore = h.last.rate;
        h.player.commandLog.clear();

        for (final targetMs in [-1, durationMs + 1]) {
          h.coordinator.onControlRequest('guest', ControlRequest(kind: ControlRequestKind.seek, positionMs: targetMs));
        }
        for (final rate in [0.25 - 0.000001, 8.0 + 0.000001, double.nan, double.infinity, double.negativeInfinity]) {
          h.coordinator.onControlRequest('guest', ControlRequest(kind: ControlRequestKind.rate, rate: rate));
        }
        async.flushMicrotasks();

        expect(h.player.commandLog, isEmpty);
        expect(actions, isEmpty);
        expect(h.broadcasts, hasLength(broadcastsBefore));
        expect(h.last.seq, seqBefore);
        expect(h.last.anchorPositionMs, anchorBefore);
        expect(h.last.rate, rateBefore);
        h.dispose();
      });
    });

    test('inclusive remote seek and rate boundaries are applied exactly', () {
      fakeAsync((async) {
        final actions = <(String, PlaybackActionHint)>[];
        final h = _Harness(
          async,
          controlMode: ControlMode.anyone,
          onRemoteAction: (peer, hint) => actions.add((peer, hint)),
        );
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        final durationMs = h.player.state.duration.inMilliseconds;
        final seqBefore = h.last.seq;
        h.player.commandLog.clear();

        for (final targetMs in [0, durationMs]) {
          h.coordinator.onControlRequest('guest', ControlRequest(kind: ControlRequestKind.seek, positionMs: targetMs));
          async.flushMicrotasks();
          expect(h.last.anchorPositionMs, targetMs);
          expect(h.last.actorPeerId, 'guest');
          expect(h.last.actionHint, PlaybackActionHint.seek);
        }
        for (final rate in [0.25, 8.0]) {
          h.coordinator.onControlRequest('guest', ControlRequest(kind: ControlRequestKind.rate, rate: rate));
          async.flushMicrotasks();
          expect(h.last.rate, rate);
          expect(h.last.actorPeerId, 'guest');
          expect(h.last.actionHint, PlaybackActionHint.rate);
        }

        expect(h.player.commandLog, ['seek:0', 'seek:$durationMs', 'rate:0.25', 'rate:8.0']);
        expect(h.last.seq, seqBefore + 4);
        expect(actions, [
          ('guest', PlaybackActionHint.seek),
          ('guest', PlaybackActionHint.seek),
          ('guest', PlaybackActionHint.rate),
          ('guest', PlaybackActionHint.rate),
        ]);
        h.dispose();
      });
    });

    test('remote seeks require seekability and a positive known duration', () {
      fakeAsync((async) {
        for (final config in [
          (seekable: false, duration: const Duration(minutes: 45)),
          (seekable: true, duration: Duration.zero),
        ]) {
          final actions = <(String, PlaybackActionHint)>[];
          final h = _Harness(
            async,
            controlMode: ControlMode.anyone,
            duration: config.duration,
            seekable: config.seekable,
            onRemoteAction: (peer, hint) => actions.add((peer, hint)),
          );
          h.attachForMedia(async);
          h.hostBecomesReady(async);
          async.elapse(Duration(milliseconds: h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds)));
          h.player.commandLog.clear();
          actions.clear();
          final broadcastsBefore = h.broadcasts.length;
          final seqBefore = h.last.seq;

          h.coordinator.onControlRequest(
            'guest',
            const ControlRequest(kind: ControlRequestKind.seek, positionMs: 1000),
          );
          async.flushMicrotasks();

          expect(h.player.commandLog, isEmpty);
          expect(actions, isEmpty);
          expect(h.broadcasts, hasLength(broadcastsBefore));
          expect(h.last.seq, seqBefore);

          h.coordinator.onControlRequest('guest', const ControlRequest(kind: ControlRequestKind.rate, rate: 0.25));
          h.coordinator.onControlRequest('guest', const ControlRequest(kind: ControlRequestKind.pause));
          h.coordinator.onControlRequest('guest', const ControlRequest(kind: ControlRequestKind.play));
          async.flushMicrotasks();
          async.elapse(Duration(milliseconds: h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds)));

          expect(h.player.commandLog, ['rate:0.25', 'pause', 'play']);
          // The rate action is reported once the player has committed it (so
          // listeners reading the room rate see the new value); play/pause
          // report on request.
          expect(actions, [
            ('guest', PlaybackActionHint.pause),
            ('guest', PlaybackActionHint.play),
            ('guest', PlaybackActionHint.rate),
          ]);
          h.dispose();
        }
      });
    });

    test('local seeks debounce into a single re-anchor broadcast', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        async.elapse(const Duration(milliseconds: 100));
        final statesBefore = h.broadcasts.length;

        h.coordinator.onLocalSeekIntent(const Duration(minutes: 10));
        async.elapse(const Duration(milliseconds: 100));
        h.coordinator.onLocalSeekIntent(const Duration(minutes: 11));
        async.elapse(const Duration(milliseconds: 100));
        h.coordinator.onLocalSeekIntent(const Duration(minutes: 12));
        async.elapse(const Duration(milliseconds: 250));

        final seekStates = h.broadcasts.skip(statesBefore).where((s) => s.actionHint == PlaybackActionHint.seek);
        expect(seekStates, hasLength(1));
        expect(seekStates.single.anchorPositionMs, const Duration(minutes: 12).inMilliseconds);
        h.dispose();
      });
    });
  });

  group('heartbeats and epochs', () {
    test('heartbeats are 2s while playing, 5s otherwise, suppressed in background', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        async.elapse(Duration.zero);
        expect(h.player.state.playing, isTrue);

        final before = h.broadcasts.length;
        async.elapse(const Duration(seconds: 6));
        expect(h.broadcasts.length - before, 3); // 2s cadence.

        h.coordinator.setBackgrounded(true);
        final backgrounded = h.broadcasts.length;
        async.elapse(const Duration(seconds: 10));
        expect(h.broadcasts.length, backgrounded);

        h.coordinator.setBackgrounded(false); // Immediate fresh heartbeat.
        expect(h.broadcasts.length, backgrounded + 1);
        h.dispose();
      });
    });

    test('heartbeat detects implicit jumps and flags them as seeks', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        async.elapse(Duration.zero);

        // Simulate playback advancing normally between heartbeats…
        async.elapse(const Duration(seconds: 2));
        // …then something seeks the player behind our back.
        h.player.setPosition(const Duration(minutes: 30));
        async.elapse(const Duration(seconds: 2));

        expect(h.broadcasts.last.actionHint, PlaybackActionHint.seek);
        h.dispose();
      });
    });

    test('sequence numbers strictly increase across every send', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        h.guestReports(async);
        async.elapse(const Duration(seconds: 10));

        final seqs = [for (final (state, _) in h.sent) state.seq];
        for (var i = 1; i < seqs.length; i++) {
          expect(seqs[i], greaterThan(seqs[i - 1]));
        }
        h.dispose();
      });
    });

    test('epoch switch resets gating and broadcasts loading with a mediaSwitch hint', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);
        h.guestReports(async);
        h.hostBecomesReady(async);
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        async.elapse(Duration(milliseconds: delay));
        expect(h.last.phase, PlaybackPhase.playing);

        h.coordinator.setLocalMedia(ratingKey: 'rk2', serverId: 'srv', mediaTitle: 'Ep 2');
        async.flushMicrotasks();
        expect(h.last.phase, PlaybackPhase.loading);
        expect(h.last.actionHint, PlaybackActionHint.mediaSwitch);
        expect(h.last.ratingKey, 'rk2');

        // Old-epoch readiness no longer counts: after the host reloads and
        // becomes ready for rk2, the guest (still on rk1) gates the start.
        h.coordinator.detachPlayer();
        h.coordinator.attach(h.attached, ratingKey: 'rk2', serverId: 'srv', mediaTitle: 'Ep 2');
        async.flushMicrotasks();
        h.hostBecomesReady(async);
        expect(h.last.phase, PlaybackPhase.waitingForPeers);
        expect(h.last.waitingOn, ['guest']);

        // The guest reports ready on the new epoch — start schedules.
        h.guestReports(async, mediaKey: 'srv:rk2');
        expect(h.last.phase, PlaybackPhase.playing);
        h.dispose();
      });
    });

    test('incompatible peers never gate and get no targeted state', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('legacy', compatible: false);
        h.attachForMedia(async);
        h.hostBecomesReady(async);

        expect(h.last.phase, PlaybackPhase.playing); // Did not wait for them.
        expect(h.sent.where((entry) => entry.$2 == 'legacy'), isEmpty);
        h.dispose();
      });
    });

    test('requestState answers during loading so joiners can start loading media', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.coordinator.onPeerJoined('guest', compatible: true);
        h.attachForMedia(async);

        h.coordinator.onStateRequested('guest');
        final targeted = h.sent.where((entry) => entry.$2 == 'guest').map((entry) => entry.$1);
        expect(targeted.where((s) => s.phase == PlaybackPhase.loading && s.ratingKey == 'rk1'), isNotEmpty);
        h.dispose();
      });
    });

    test('the reply-on-demand paths hold the anchor while the player is detached', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async, hasFirstFrame: true);
        h.hostBecomesReady(async);
        final anchored = h.last.anchorPositionMs;
        expect(anchored, const Duration(minutes: 2).inMilliseconds);

        // The state every in-place source reload passes through. Heartbeats
        // suppress themselves here; the on-demand replies do not, so they are
        // the paths that would otherwise publish a position of 0.
        h.coordinator.detachPlayer();
        async.flushMicrotasks();

        h.coordinator.onStateRequested('guest');
        h.coordinator.onPeerJoined('guest2', compatible: true);
        h.coordinator.onReconnected();
        async.flushMicrotasks();

        for (final (state, toPeerId) in h.sent.skip(h.sent.length - 3)) {
          expect(
            state.anchorPositionMs,
            anchored,
            reason: 'reply to ${toPeerId ?? 'the room'} must hold the anchor, not collapse it to 0',
          );
        }
        h.dispose();
      });
    });
  });

  group('driver distraction', () {
    tearDown(() {
      TvDetectionService.debugReset();
      CarUxRestrictionsService.debugSetOverride(null);
    });

    test('a start the vehicle refuses puts the room back to paused', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachForMedia(async);
        h.hostBecomesReady(async);
        expect(h.last.phase, PlaybackPhase.playing);

        // The car starts moving during the scheduled-start delay, so the play the
        // host had already announced is refused.
        TvDetectionService.debugSetAutomotiveOverride(true);
        CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
        final delay = h.last.anchorHostTimeMs - (_epochMs + async.elapsed.inMilliseconds);
        async.elapse(Duration(milliseconds: delay));
        async.flushMicrotasks();

        expect(h.player.state.playing, isFalse, reason: 'DD-3: driving must not start video');
        expect(h.last.phase, PlaybackPhase.paused, reason: 'the room must not be told the host is playing');
        h.dispose();
      });
    });
  });
}
