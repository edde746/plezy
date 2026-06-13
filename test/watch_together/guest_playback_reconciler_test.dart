import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/watch_together/models/playback_state.dart';
import 'package:vibe_stream/watch_together/models/sync_message.dart';
import 'package:vibe_stream/watch_together/models/watch_session.dart';
import 'package:vibe_stream/watch_together/services/attached_player.dart';
import 'package:vibe_stream/watch_together/services/clock_sync.dart';
import 'package:vibe_stream/watch_together/services/guest_playback_reconciler.dart';

import '../test_helpers/watch_together_fakes.dart';

const _epochMs = 1000000;

class _Harness {
  _Harness(this.async, {GuestReconcilerCallbacks callbacks = const GuestReconcilerCallbacks()}) {
    player = FakeSyncPlayer(position: const Duration(minutes: 2));
    clock = ClockSync(sendPing: pings.add, nowMs: nowMs);
    reconciler = GuestPlaybackReconciler(
      myPeerId: 'guest',
      sendToHost: outgoing.add,
      clockSync: clock,
      callbacks: callbacks,
      nowMs: nowMs,
    );
    attached = AttachedPlayer(player: player, onLost: () {}, nowMs: nowMs);
  }

  final FakeAsync async;
  late final FakeSyncPlayer player;
  late final ClockSync clock;
  late final GuestPlaybackReconciler reconciler;
  late final AttachedPlayer attached;
  final List<SyncMessage> outgoing = [];
  final List<int> pings = [];
  int _seq = 0;

  int nowMs() => _epochMs + async.elapsed.inMilliseconds;

  void attachReady() {
    reconciler.attach(attached, ratingKey: 'rk1', serverId: 'srv', hasFirstFrame: true);
    async.flushMicrotasks();
  }

  PlaybackState state({
    PlaybackPhase phase = PlaybackPhase.playing,
    int? anchorPositionMs,
    int? anchorHostTimeMs,
    double rate = 1.0,
    ControlMode controlMode = ControlMode.hostOnly,
    List<String> waitingOn = const [],
    String ratingKey = 'rk1',
    String? actorPeerId,
    PlaybackActionHint? actionHint,
    int? seq,
  }) {
    return PlaybackState(
      seq: seq ?? ++_seq,
      ratingKey: ratingKey,
      serverId: 'srv',
      phase: phase,
      anchorPositionMs: anchorPositionMs ?? player.state.position.inMilliseconds,
      anchorHostTimeMs: anchorHostTimeMs ?? nowMs(),
      rate: rate,
      controlMode: controlMode,
      waitingOn: waitingOn,
      actorPeerId: actorPeerId,
      actionHint: actionHint,
    );
  }

  /// Delivers a state and runs one extra tick so the drift median has two
  /// samples (a single sample never triggers a correction).
  void deliverAndSettleDrift(PlaybackState s) {
    reconciler.onState(s);
    async.flushMicrotasks();
    async.elapse(const Duration(milliseconds: 500));
  }

  Iterable<String> get seekCommands => player.commandLog.where((c) => c.startsWith('seek:'));
  Iterable<PeerStatus> get statuses => outgoing.where((m) => m.type == SyncMessageType.status).map((m) => m.status!);
  Iterable<ControlRequest> get controls =>
      outgoing.where((m) => m.type == SyncMessageType.control).map((m) => m.control!);

  void dispose() {
    reconciler.dispose();
    attached.dispose();
  }
}

void main() {
  test('stale sequence numbers are dropped', () {
    fakeAsync((async) {
      final h = _Harness(async);
      h.attachReady();
      h.player.emitPlaying(true);
      async.flushMicrotasks();

      h.reconciler.onState(h.state(phase: PlaybackPhase.paused, seq: 10));
      async.flushMicrotasks();
      expect(h.player.state.playing, isFalse);

      // An older state saying "playing" must not apply.
      h.reconciler.onState(h.state(phase: PlaybackPhase.playing, seq: 9));
      async.flushMicrotasks();
      expect(h.player.state.playing, isFalse);
      expect(h.reconciler.latestState!.seq, 10);
      h.dispose();
    });
  });

  group('drift pipeline', () {
    test('within the deadband nothing happens', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        // Anchor implies we should be 200ms ahead of where we are — inside
        // the deadband.
        final pos = h.player.state.position.inMilliseconds;
        h.deliverAndSettleDrift(h.state(anchorPositionMs: pos + 200));

        expect(h.seekCommands, isEmpty);
        expect(h.player.commandLog.where((c) => c.startsWith('rate:')), isEmpty);
        h.dispose();
      });
    });

    test('moderate drift nudges the rate and restores it on convergence', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        // We are 1s behind the room → speed up by 4%.
        final pos = h.player.state.position.inMilliseconds;
        final s = h.state(anchorPositionMs: pos + 1000);
        h.deliverAndSettleDrift(s);
        expect(h.player.state.rate, closeTo(1.04, 0.0001));
        expect(h.seekCommands, isEmpty);

        // Converged: hold the player ~50ms off target across several ticks
        // (median smoothing needs the old samples to wash out) → restored.
        for (var i = 0; i < 3; i++) {
          h.player.setPosition(Duration(milliseconds: s.targetPositionMs(h.nowMs() + 500) + 50));
          async.elapse(const Duration(milliseconds: 500));
        }
        expect(h.player.state.rate, closeTo(1.0, 0.0001));
        h.dispose();
      });
    });

    test('audio passthrough suppresses nudging (tolerated up to the seek band)', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        h.player.audioPassthroughActive = true;
        async.flushMicrotasks();

        final pos = h.player.state.position.inMilliseconds;
        h.deliverAndSettleDrift(h.state(anchorPositionMs: pos + 1000));

        expect(h.player.commandLog.where((c) => c.startsWith('rate:')), isEmpty);
        expect(h.seekCommands, isEmpty);
        h.dispose();
      });
    });

    test('rate nudges that do not take effect disable nudging for the session', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        h.player.ignoreRateChanges = true;
        async.flushMicrotasks();

        final pos = h.player.state.position.inMilliseconds;
        h.deliverAndSettleDrift(h.state(anchorPositionMs: pos + 1000));
        expect(h.player.commandLog.where((c) => c.startsWith('rate:')), isNotEmpty);

        async.elapse(const Duration(milliseconds: 600)); // Confirm window.
        final rateCommandsAfterLatch = h.player.commandLog.where((c) => c.startsWith('rate:')).length;

        // Further drift no longer attempts nudges.
        h.deliverAndSettleDrift(h.state(anchorPositionMs: h.player.state.position.inMilliseconds + 1500));
        async.elapse(const Duration(seconds: 2));
        expect(h.player.commandLog.where((c) => c.startsWith('rate:')).length, rateCommandsAfterLatch);
        h.dispose();
      });
    });

    test('large drift hard-seeks with lead, settle window, and cooldown', () {
      fakeAsync((async) {
        final correcting = <bool>[];
        final h = _Harness(async, callbacks: GuestReconcilerCallbacks(onCorrectingChanged: correcting.add));
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        final pos = h.player.state.position.inMilliseconds;
        final target = pos + 10000;
        h.deliverAndSettleDrift(h.state(anchorPositionMs: target));

        // Seeked to (extrapolated) target + 250ms lead.
        expect(h.seekCommands, hasLength(1));
        final seekTarget = int.parse(h.seekCommands.single.substring('seek:'.length));
        expect(seekTarget, greaterThanOrEqualTo(target + 250));
        expect(seekTarget, lessThan(target + 250 + 1500));
        expect(correcting, [true]);

        // Settle: playback-restart fired on seek; +250ms ends the window.
        async.elapse(const Duration(milliseconds: 300));
        expect(correcting, [true, false]);

        // Within the cooldown a fresh large drift does not seek again.
        h.player.setPosition(Duration(milliseconds: seekTarget - 8000));
        async.elapse(const Duration(milliseconds: 1000));
        expect(h.seekCommands, hasLength(1));

        // After the cooldown it does.
        async.elapse(const Duration(milliseconds: 1500));
        expect(h.seekCommands.length, greaterThan(1));
        h.dispose();
      });
    });

    test('settle falls back to the timeout when no playback-restart arrives', () {
      fakeAsync((async) {
        final correcting = <bool>[];
        final h = _Harness(async, callbacks: GuestReconcilerCallbacks(onCorrectingChanged: correcting.add));
        h.player.emitRestartOnSeek = false;
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        h.deliverAndSettleDrift(h.state(anchorPositionMs: h.player.state.position.inMilliseconds + 10000));
        expect(correcting, [true]);

        async.elapse(const Duration(milliseconds: 1600));
        expect(correcting, [true, false]);
        h.dispose();
      });
    });
  });

  group('phases', () {
    test('paused phase aligns to the anchor and pauses the player', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        h.reconciler.onState(h.state(phase: PlaybackPhase.paused, anchorPositionMs: 600000));
        async.flushMicrotasks();

        expect(h.player.state.playing, isFalse);
        expect(h.seekCommands, hasLength(1));
        expect(h.player.state.position, const Duration(minutes: 10));
        h.dispose();
      });
    });

    test('host loading phase holds paused without chasing the meaningless anchor', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();

        h.reconciler.onState(h.state(phase: PlaybackPhase.loading, anchorPositionMs: 0));
        async.elapse(const Duration(seconds: 3));

        expect(h.player.state.playing, isFalse);
        expect(h.seekCommands, isEmpty); // Never seeks to the host's stale 0.
        h.dispose();
      });
    });

    test('hostOnly: a local pause snaps back to the room state', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();

        h.reconciler.onState(h.state(phase: PlaybackPhase.playing));
        async.flushMicrotasks();
        expect(h.player.state.playing, isTrue);

        h.player.emitPlaying(false); // User pause.
        async.flushMicrotasks();
        expect(h.player.state.playing, isTrue); // Snapped back.
        expect(h.controls, isEmpty); // No request in hostOnly.
        h.dispose();
      });
    });

    test('scheduled group start fires at the host moment, clock-adjusted', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();

        // Establish a clock offset of +5000ms (host ahead) via one exchange.
        h.clock.start();
        final ping = h.pings.single;
        async.elapse(const Duration(milliseconds: 100));
        h.clock.onPong(ping, ping + 50 + 5000);
        expect(h.clock.offsetMs, 5000);
        h.clock.stop();

        // Host schedules the start 1s into ITS future.
        final startAtHost = h.clock.hostNowMs() + 1000;
        final anchor = h.player.state.position.inMilliseconds;
        h.reconciler.onState(h.state(anchorHostTimeMs: startAtHost, anchorPositionMs: anchor));
        async.flushMicrotasks();
        expect(h.player.state.playing, isFalse); // Holding.

        async.elapse(const Duration(milliseconds: 950));
        expect(h.player.state.playing, isFalse);
        async.elapse(const Duration(milliseconds: 100));
        expect(h.player.state.playing, isTrue); // Fired on the dot.
        h.dispose();
      });
    });

    test('a newer pause cancels a pending scheduled start', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();

        h.reconciler.onState(h.state(anchorHostTimeMs: h.nowMs() + 1000));
        async.flushMicrotasks();
        h.reconciler.onState(h.state(phase: PlaybackPhase.paused));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 2));
        expect(h.player.state.playing, isFalse); // Start never fired.
        h.dispose();
      });
    });
  });

  group('media and status', () {
    test('epoch mismatch hands off to the media-switch flow and stops correcting', () {
      fakeAsync((async) {
        final switches = <(String, String, String?)>[];
        final h = _Harness(
          async,
          callbacks: GuestReconcilerCallbacks(onMediaSwitchNeeded: (rk, sid, title) => switches.add((rk, sid, title))),
        );
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();
        final commandsBefore = h.player.commandLog.length;

        h.reconciler.onState(h.state(ratingKey: 'rk2', phase: PlaybackPhase.loading));
        async.elapse(const Duration(seconds: 2));

        expect(switches, [('rk2', 'srv', null)]);
        expect(h.player.commandLog.length, commandsBefore); // No commands for foreign media.
        h.dispose();
      });
    });

    test('attach reconciles to the latest state received while detached', () {
      fakeAsync((async) {
        final h = _Harness(async);

        // State arrives during an episode-switch gap (no player attached).
        h.reconciler.onState(h.state(phase: PlaybackPhase.paused, anchorPositionMs: 300000));
        async.flushMicrotasks();

        h.attachReady();
        expect(h.player.state.position, const Duration(minutes: 5));
        h.dispose();
      });
    });

    test('readiness is announced on first frame and revoked on detach', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.reconciler.attach(h.attached, ratingKey: 'rk1', serverId: 'srv');
        async.flushMicrotasks();

        expect(h.statuses.last.ready, isFalse);

        h.player.emitPlaybackRestart();
        async.flushMicrotasks();
        expect(h.statuses.last.ready, isTrue);

        h.reconciler.detachPlayer();
        expect(h.statuses.last.ready, isFalse);
        h.dispose();
      });
    });

    test('self-heals when the host wrongly lists us in waitingOn', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        final readyStatuses = h.statuses.where((s) => s.ready).length;

        h.reconciler.onState(h.state(phase: PlaybackPhase.waitingForPeers, waitingOn: ['guest']));
        async.flushMicrotasks();

        expect(h.statuses.where((s) => s.ready).length, readyStatuses + 1);
        h.dispose();
      });
    });

    test('buffering changes refresh the status while stalled', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.reconciler.onState(h.state());
        async.flushMicrotasks();

        h.player.emitBuffering(true);
        async.flushMicrotasks();
        expect(h.statuses.last.buffering, isTrue);

        async.elapse(const Duration(seconds: 6));
        expect(h.statuses.where((s) => s.buffering).length, greaterThan(1)); // 5s refresh.

        h.player.emitBuffering(false);
        async.flushMicrotasks();
        expect(h.statuses.last.buffering, isFalse);
        h.dispose();
      });
    });
  });

  group('anyone-mode control', () {
    test('guest seek sends a request and in-flight heartbeats do not undo it', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.reconciler.onState(h.state(controlMode: ControlMode.anyone));
        async.flushMicrotasks();

        // User seeks locally; screen already moved the player.
        h.player.setPosition(const Duration(minutes: 20));
        h.reconciler.onLocalSeekIntent(const Duration(minutes: 20));
        async.flushMicrotasks();
        expect(h.controls.single.kind, ControlRequestKind.seek);
        expect(h.controls.single.positionMs, const Duration(minutes: 20).inMilliseconds);

        // A heartbeat that left the host before our request arrives with the
        // old anchor — inside the optimistic window it must not yank us back.
        h.reconciler.onState(h.state(controlMode: ControlMode.anyone, anchorPositionMs: 120000));
        async.elapse(const Duration(milliseconds: 600));
        expect(h.seekCommands, isEmpty);

        // The host's confirming transition (actor = us) closes the window.
        h.reconciler.onState(
          h.state(
            controlMode: ControlMode.anyone,
            anchorPositionMs: const Duration(minutes: 20).inMilliseconds,
            actorPeerId: 'guest',
            actionHint: PlaybackActionHint.seek,
          ),
        );
        async.elapse(const Duration(milliseconds: 600));
        expect(h.seekCommands, isEmpty); // Already in place — converged.
        h.dispose();
      });
    });

    test('guest play/pause intents become control requests', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.reconciler.onState(h.state(controlMode: ControlMode.anyone));
        async.flushMicrotasks();
        expect(h.player.state.playing, isTrue);

        h.player.emitPlaying(false); // User pause.
        async.flushMicrotasks();
        expect(h.controls.last.kind, ControlRequestKind.pause);
        // Optimistic: not snapped back immediately.
        expect(h.player.state.playing, isFalse);
        h.dispose();
      });
    });
  });

  group('edge cases', () {
    test('EOF clamp: both at the credits → no fighting', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        final durationMs = h.player.state.duration.inMilliseconds;
        h.player.setPosition(Duration(milliseconds: durationMs));
        h.player.setCompleted(true);

        h.deliverAndSettleDrift(h.state(anchorPositionMs: durationMs - 400));
        expect(h.seekCommands, isEmpty);
        h.dispose();
      });
    });

    test('guest at EOF while the room plays on rejoins via seek + play', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        final durationMs = h.player.state.duration.inMilliseconds;
        h.player.setPosition(Duration(milliseconds: durationMs));
        h.player.setCompleted(true);

        h.reconciler.onState(h.state(anchorPositionMs: durationMs - 600000));
        async.flushMicrotasks();
        expect(h.seekCommands, hasLength(1));
        h.dispose();
      });
    });

    test('live (!seekable) limits corrections to play/pause/rate', () {
      fakeAsync((async) {
        final h = _Harness(async);
        final livePlayer = FakeSyncPlayer(seekable: false, position: const Duration(minutes: 2));
        final attached = AttachedPlayer(player: livePlayer, onLost: () {}, nowMs: h.nowMs);
        h.reconciler.attach(attached, ratingKey: 'rk1', serverId: 'srv', hasFirstFrame: true);
        async.flushMicrotasks();

        h.deliverAndSettleDrift(h.state(anchorPositionMs: livePlayer.state.position.inMilliseconds + 60000));
        expect(livePlayer.state.playing, isTrue); // Play enforced.
        expect(livePlayer.commandLog.where((c) => c.startsWith('seek:')), isEmpty); // Never seeks live.
        h.reconciler.dispose();
        attached.dispose();
        h.attached.dispose();
      });
    });

    test('backgrounded guests freewheel without corrections', () {
      fakeAsync((async) {
        final h = _Harness(async);
        h.attachReady();
        h.player.emitPlaying(true);
        async.flushMicrotasks();
        h.reconciler.setBackgrounded(true);

        h.deliverAndSettleDrift(h.state(anchorPositionMs: h.player.state.position.inMilliseconds + 30000));
        expect(h.seekCommands, isEmpty);

        h.reconciler.setBackgrounded(false);
        async.elapse(const Duration(milliseconds: 600));
        expect(h.seekCommands, isNotEmpty); // Catches up once foregrounded.
        h.dispose();
      });
    });
  });
}
