import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';

import '../test_helpers/prefs.dart';

final _malStore = trackerAccountStore(TrackerService.mal);
final _anilistStore = trackerAccountStore(TrackerService.anilist);
final _simklStore = trackerAccountStore(TrackerService.simkl);

TrackerSession _mal({String? username}) => TrackerSession(
  accessToken: 'mal-at',
  refreshToken: 'mal-rt',
  expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

TrackerSession _anilist({String? username}) => TrackerSession(
  accessToken: 'anilist-at',
  expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

TrackerSession _simkl({String? username}) => TrackerSession(
  accessToken: 'simkl-at',
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    _resetTrackerBindings();
  });
  tearDown(_resetTrackerBindings);

  group('TrackersProvider', () {
    test('starts with all trackers disconnected', () {
      final p = TrackersProvider();
      expect(p.mal, isNull);
      expect(p.anilist, isNull);
      expect(p.simkl, isNull);
      expect(p.isMalConnected, isFalse);
      expect(p.isAnilistConnected, isFalse);
      expect(p.isSimklConnected, isFalse);
      expect(p.malUsername, isNull);
      expect(p.anilistUsername, isNull);
      expect(p.simklUsername, isNull);
      expect(p.isConnecting(TrackerService.mal), isFalse);
      expect(p.isConnecting(TrackerService.anilist), isFalse);
      expect(p.isConnecting(TrackerService.simkl), isFalse);
      p.dispose();
    });

    test('onActiveProfileChanged loads sessions from per-profile stores', () async {
      const uuid = 'profile-1';
      await _malStore.save(uuid, _mal(username: 'alice'));
      await _anilistStore.save(uuid, _anilist(username: 'bob'));
      await _simklStore.save(uuid, _simkl(username: 'carol'));

      // Reset cached singletons so the provider reads fresh prefs state.
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);
      expect(p.isAnilistConnected, isTrue);
      expect(p.isSimklConnected, isTrue);
      expect(p.malUsername, 'alice');
      expect(p.anilistUsername, 'bob');
      expect(p.simklUsername, 'carol');
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('onActiveProfileChanged switching to empty profile clears all sessions', () async {
      const uuid = 'profile-1';
      await _malStore.save(uuid, _mal(username: 'alice'));
      await _anilistStore.save(uuid, _anilist(username: 'bob'));
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);

      await p.onActiveProfileChanged('other-profile');
      expect(p.isMalConnected, isFalse);
      expect(p.isAnilistConnected, isFalse);
      expect(p.isSimklConnected, isFalse);

      p.dispose();
    });

    test('onActiveProfileChanged loads only the populated stores', () async {
      const uuid = 'profile-2';
      // Only AniList is set up — MAL and Simkl remain absent.
      await _anilistStore.save(uuid, _anilist(username: 'bob'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isAnilistConnected, isTrue);
      expect(p.anilistUsername, 'bob');
      expect(p.isMalConnected, isFalse);
      expect(p.isSimklConnected, isFalse);
      p.dispose();
    });

    test('disconnectMal clears stored session and notifies', () async {
      const uuid = 'profile-3';
      await _malStore.save(uuid, _mal(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);

      var notified = 0;
      p.addListener(() => notified++);

      await p.disconnectMal();
      expect(p.isMalConnected, isFalse);
      expect(p.mal, isNull);
      // _clearAndRebind notifies once.
      expect(notified, 1);

      // Persistence is cleared too.
      expect(await _malStore.load(uuid), isNull);

      p.dispose();
    });

    test('disconnectAnilist clears anilist while leaving MAL intact', () async {
      const uuid = 'profile-4';
      await _malStore.save(uuid, _mal(username: 'alice'));
      await _anilistStore.save(uuid, _anilist(username: 'bob'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);

      await p.disconnectAnilist();
      expect(p.isAnilistConnected, isFalse);
      expect(p.isMalConnected, isTrue);
      expect(p.malUsername, 'alice');

      p.dispose();
    });

    test('disconnect during an in-flight profile load keeps the other trackers loaded', () async {
      const uuid = 'profile-race';
      await _malStore.save(uuid, _mal(username: 'alice'));
      await _anilistStore.save(uuid, _anilist(username: 'bob'));
      await _simklStore.save(uuid, _simkl(username: 'carol'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      // Start the load, then disconnect MAL before it resolves.
      final load = p.onActiveProfileChanged(uuid);
      await p.disconnectMal();
      await load;

      // MAL stays disconnected (and cleared) — the racing load must not
      // resurrect it — but it also must not drop AniList/Simkl.
      expect(p.isMalConnected, isFalse);
      expect(await _malStore.load(uuid), isNull);
      expect(p.isAnilistConnected, isTrue);
      expect(p.anilistUsername, 'bob');
      expect(p.isSimklConnected, isTrue);
      expect(p.simklUsername, 'carol');

      p.dispose();
    });

    test('disconnectSimkl on a profile with no session is safe', () async {
      final p = TrackersProvider();
      // No `onActiveProfileChanged` — uuid is empty (global slot).
      // disconnectSimkl just clears the (already absent) entry and rebinds.
      await p.disconnectSimkl();
      expect(p.isSimklConnected, isFalse);
      p.dispose();
    });

    test('cancelConnect is a no-op when not connecting', () {
      final p = TrackersProvider();
      expect(() => p.cancelConnect(), returnsNormally);
      expect(p.isConnecting(TrackerService.mal), isFalse);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = TrackersProvider();
      p.dispose();
      // Post-dispose rebind should not throw.
      await p.onActiveProfileChanged('any-uuid');
    });
    for (final service in [TrackerService.mal, TrackerService.anilist, TrackerService.simkl]) {
      test('$service stale connect cannot save or replace a newer binding after dispose', () async {
        const oldUuid = 'profile-old';
        const newUuid = 'profile-new';
        final oldSession = _session(service, 'old');
        final newSession = _session(service, 'new');
        await _store(service).save(newUuid, newSession);
        BaseSharedPreferencesService.resetForTesting();

        final pipeline = _ControlledConnectPipeline(oldSession);
        final oldProvider = TrackersProvider.forTesting(connectPipeline: pipeline.call);
        await oldProvider.onActiveProfileChanged(oldUuid);
        final connect = _connect(oldProvider, service);
        await pipeline.beforeSave.future;

        oldProvider.dispose();
        final newProvider = TrackersProvider();
        await newProvider.onActiveProfileChanged(newUuid);
        final newBinding = _boundClient(service);
        expect(newBinding, isNotNull);
        expect(_providerSession(newProvider, service)?.accessToken, newSession.accessToken);

        pipeline.releaseBeforeSave.complete();
        expect(await connect, isFalse);
        expect(await _store(service).load(oldUuid), isNull);
        expect((await _store(service).load(newUuid))?.accessToken, newSession.accessToken);
        expect(_boundClient(service), same(newBinding));
        expect(_boundSession(service)?.accessToken, newSession.accessToken);
        expect(_providerSession(oldProvider, service), isNull);

        newProvider.dispose();
      });
    }

    test('cancel invalidates a connect after authorization and before save', () async {
      const uuid = 'profile-cancel';
      final pipeline = _ControlledConnectPipeline(_session(TrackerService.mal, 'cancelled'));
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await p.onActiveProfileChanged(uuid);

      final connect = _connect(p, TrackerService.mal);
      await pipeline.beforeSave.future;
      p.cancelConnect();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(p.isConnecting(TrackerService.mal), isFalse);
      expect(p.mal, isNull);
      expect(await _malStore.load(uuid), isNull);
      expect(MalTracker.instance.client, isNull);
      p.dispose();
    });

    test('profile change invalidates the old connect and preserves the new binding', () async {
      const oldUuid = 'profile-change-old';
      const newUuid = 'profile-change-new';
      final oldSession = _session(TrackerService.anilist, 'old');
      final newSession = _session(TrackerService.anilist, 'new');
      await _anilistStore.save(newUuid, newSession);
      BaseSharedPreferencesService.resetForTesting();

      final pipeline = _ControlledConnectPipeline(oldSession);
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await p.onActiveProfileChanged(oldUuid);
      final connect = _connect(p, TrackerService.anilist);
      await pipeline.beforeSave.future;

      await p.onActiveProfileChanged(newUuid);
      final newBinding = AnilistTracker.instance.client;
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(await _anilistStore.load(oldUuid), isNull);
      expect((await _anilistStore.load(newUuid))?.accessToken, newSession.accessToken);
      expect(p.anilist?.accessToken, newSession.accessToken);
      expect(AnilistTracker.instance.client, same(newBinding));
      expect(AnilistTracker.instance.client?.session.accessToken, newSession.accessToken);
      p.dispose();
    });

    test('same-service disconnect invalidates an in-flight connect', () async {
      const uuid = 'profile-same-disconnect';
      final pipeline = _ControlledConnectPipeline(_session(TrackerService.simkl, 'late'));
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await p.onActiveProfileChanged(uuid);
      final connect = _connect(p, TrackerService.simkl);
      await pipeline.beforeSave.future;

      await p.disconnectSimkl();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isFalse);
      expect(p.simkl, isNull);
      expect(await _simklStore.load(uuid), isNull);
      expect(SimklTracker.instance.client, isNull);
      p.dispose();
    });

    test('unrelated disconnect leaves an allowed connect current', () async {
      const uuid = 'profile-unrelated-disconnect';
      final linkedAnilist = _session(TrackerService.anilist, 'linked');
      final connectedMal = _session(TrackerService.mal, 'connected');
      await _anilistStore.save(uuid, linkedAnilist);
      BaseSharedPreferencesService.resetForTesting();

      final pipeline = _ControlledConnectPipeline(connectedMal);
      final p = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await p.onActiveProfileChanged(uuid);
      final connect = _connect(p, TrackerService.mal);
      await pipeline.beforeSave.future;

      await p.disconnectAnilist();
      pipeline.releaseBeforeSave.complete();

      expect(await connect, isTrue);
      expect(p.anilist, isNull);
      expect(p.mal?.accessToken, connectedMal.accessToken);
      expect((await _malStore.load(uuid))?.accessToken, connectedMal.accessToken);
      expect(MalTracker.instance.client?.session.accessToken, connectedMal.accessToken);
      p.dispose();
    });

    test('dispose after save cannot assign or erase a newer same-profile binding', () async {
      const uuid = 'profile-save-race';
      final staleSession = _session(TrackerService.mal, 'stale');
      final freshSession = _session(TrackerService.mal, 'fresh');
      final pipeline = _ControlledConnectPipeline(staleSession, pauseAfterSave: true);
      final staleProvider = TrackersProvider.forTesting(connectPipeline: pipeline.call);
      await staleProvider.onActiveProfileChanged(uuid);
      final connect = _connect(staleProvider, TrackerService.mal);
      await pipeline.beforeSave.future;
      pipeline.releaseBeforeSave.complete();
      await pipeline.afterSave.future;

      staleProvider.dispose();
      await _malStore.save(uuid, freshSession);
      BaseSharedPreferencesService.resetForTesting();
      final freshProvider = TrackersProvider();
      await freshProvider.onActiveProfileChanged(uuid);
      final freshBinding = MalTracker.instance.client;
      pipeline.releaseAfterSave.complete();

      expect(await connect, isFalse);
      expect((await _malStore.load(uuid))?.accessToken, freshSession.accessToken);
      expect(MalTracker.instance.client, same(freshBinding));
      expect(MalTracker.instance.client?.session.accessToken, freshSession.accessToken);
      expect(staleProvider.mal, isNull);
      freshProvider.dispose();
    });
  });
}

void _resetTrackerBindings() {
  MalTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  AnilistTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  SimklTracker.instance.rebindSession(null, onSessionInvalidated: () {});
}

TrackerAccountStore _store(TrackerService service) => switch (service) {
  TrackerService.mal => _malStore,
  TrackerService.anilist => _anilistStore,
  TrackerService.simkl => _simklStore,
  _ => throw ArgumentError.value(service),
};

TrackerSession _session(TrackerService service, String owner) => switch (service) {
  TrackerService.mal => TrackerSession(
    accessToken: '$owner-mal-at',
    refreshToken: '$owner-mal-rt',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
  TrackerService.anilist => TrackerSession(
    accessToken: '$owner-anilist-at',
    expiresAt: 2000000000,
    createdAt: 1900000000,
    username: owner,
  ),
  TrackerService.simkl => TrackerSession(accessToken: '$owner-simkl-at', createdAt: 1900000000, username: owner),
  _ => throw ArgumentError.value(service),
};

Future<bool> _connect(TrackersProvider provider, TrackerService service) => switch (service) {
  TrackerService.mal => provider.connectMal(onCodeReady: (_) {}),
  TrackerService.anilist => provider.connectAnilist(onCodeReady: (_) {}),
  TrackerService.simkl => provider.connectSimkl(onCodeReady: (_) {}),
  _ => throw ArgumentError.value(service),
};

TrackerSession? _providerSession(TrackersProvider provider, TrackerService service) => switch (service) {
  TrackerService.mal => provider.mal,
  TrackerService.anilist => provider.anilist,
  TrackerService.simkl => provider.simkl,
  _ => throw ArgumentError.value(service),
};

Object? _boundClient(TrackerService service) => switch (service) {
  TrackerService.mal => MalTracker.instance.client,
  TrackerService.anilist => AnilistTracker.instance.client,
  TrackerService.simkl => SimklTracker.instance.client,
  _ => throw ArgumentError.value(service),
};

TrackerSession? _boundSession(TrackerService service) => switch (service) {
  TrackerService.mal => MalTracker.instance.client?.session,
  TrackerService.anilist => AnilistTracker.instance.client?.session,
  TrackerService.simkl => SimklTracker.instance.client?.session,
  _ => throw ArgumentError.value(service),
};

class _ControlledConnectPipeline {
  _ControlledConnectPipeline(this.session, {this.pauseAfterSave = false});

  final TrackerSession session;
  final bool pauseAfterSave;
  final beforeSave = Completer<void>();
  final releaseBeforeSave = Completer<void>();
  final afterSave = Completer<void>();
  final releaseAfterSave = Completer<void>();

  Future<bool> call({
    required String logLabel,
    required Future<TrackerSession?> Function() authorize,
    required Future<TrackerSession> Function(TrackerSession raw) enrich,
    required Future<void> Function(TrackerSession enriched) save,
    required void Function(TrackerSession enriched) assign,
  }) async {
    beforeSave.complete();
    await releaseBeforeSave.future;
    await save(session);
    afterSave.complete();
    if (pauseAfterSave) await releaseAfterSave.future;
    assign(session);
    return true;
  }
}
