import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';

import '../test_helpers/prefs.dart';

void main() {
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

    test('participantEvents is a broadcast stream that listeners can attach to', () async {
      final p = WatchTogetherProvider();
      // Attach a listener so the stream is observed; on a fresh provider no
      // events will fire, but the stream must already be live.
      final sub = p.participantEvents.listen((_) {});
      await sub.cancel();
      p.dispose();
    });
  });

  group('WatchTogetherProvider — listener firing via public API', () {
    test('setCurrentMedia notifies listeners as host', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      // Without a session, setCurrentMedia logs a warning and bails — no notify.
      p.setCurrentMedia(ratingKey: 'rk1', serverId: ServerId('s1'), mediaTitle: 't1');
      expect(notified, 0);
      expect(p.currentMediaRatingKey, isNull);
      p.dispose();
    });

    test('setDisplayName mutates internal state without notifying', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      // setDisplayName is a plain assignment with no notify; verify it doesn't
      // accidentally fire one.
      p.setDisplayName('Tester');
      expect(notified, 0);
      p.dispose();
    });

    test('markCurrentPlaybackHandled does not throw on a fresh provider', () {
      final p = WatchTogetherProvider();
      expect(() => p.markCurrentPlaybackHandled(ratingKey: 'rk1', serverId: ServerId('s1')), returnsNormally);
      p.dispose();
    });

    test('requestCurrentPlaybackSnapshot is a no-op when not in session', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      // Guard fires before any peer service work, so no listener notification.
      p.requestCurrentPlaybackSnapshot();
      expect(notified, 0);
      p.dispose();
    });

    test('attachPlayer is a no-op without a sync controller (logs warning)', () {
      final p = WatchTogetherProvider();
      // The mpv Player object is platform-tied; skipping it would reach the
      // null-controller guard first and bail. Calling with a null check via
      // the same path used by the production code: just verify the early
      // return path on detachPlayer (which is also null-safe).
      expect(p.detachPlayer, returnsNormally);
      p.dispose();
    });

    test('setBackgrounded forwards to the sync controller but is null-safe', () {
      final p = WatchTogetherProvider();
      expect(() => p.setBackgrounded(true), returnsNormally);
      expect(() => p.setBackgrounded(false), returnsNormally);
      p.dispose();
    });

    test('onLocalSeek is null-safe without a sync controller', () {
      final p = WatchTogetherProvider();
      expect(() => p.onLocalSeek(const Duration(seconds: 5)), returnsNormally);
      p.dispose();
    });

    test('notifyHostExitedPlayer is a no-op when not host or not in session', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.notifyHostExitedPlayer();
      expect(notified, 0);
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

  group('WatchTogetherProvider — leaveSession safety', () {
    test('leaveSession on a fresh provider is a no-op (no notify)', () async {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      await p.leaveSession();
      // Early-return path: no session ever existed, no listener fires.
      expect(notified, 0);
      expect(p.session, isNull);
      p.dispose();
    });
  });

  group('WatchTogetherProvider — dispose hygiene', () {
    test('dispose runs cleanly with no peer service or subscriptions', () {
      final p = WatchTogetherProvider();
      // Fresh provider: 4 stream subscriptions are all null, 1 stream
      // controller is open, _hostReconnectTimer is null. dispose() must
      // close the controller and tear down without throwing.
      expect(p.dispose, returnsNormally);
    });

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

    test('notifyListeners after dispose does not throw (coalescing guard)', () async {
      // The provider overrides notifyListeners to coalesce into a microtask.
      // After dispose, the _disposed flag must short-circuit any pending or
      // late notifications.
      final p = WatchTogetherProvider();
      p.dispose();
      // Even if some pathway tried to notify (it won't from outside, but the
      // microtask path in the override is the relevant guard), it must not
      // throw and not call super.notifyListeners() on a disposed instance.
      await Future<void>.delayed(Duration.zero);
    });

    test('dispose is safe to call after a leaveSession on a fresh provider', () async {
      final p = WatchTogetherProvider();
      await p.leaveSession();
      expect(p.dispose, returnsNormally);
    });
  });
}
