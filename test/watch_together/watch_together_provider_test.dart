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
  });

  group('WatchTogetherProvider — session guards', () {
    test('setCurrentMedia is rejected outside a session', () {
      final p = WatchTogetherProvider();
      var notified = 0;
      p.addListener(() => notified++);
      // Without a session, setCurrentMedia logs a warning and bails — no notify.
      p.setCurrentMedia(ratingKey: 'rk1', serverId: ServerId('s1'), mediaTitle: 't1');
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
  });
}
