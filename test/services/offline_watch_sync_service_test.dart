import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_mode_source.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

import '../test_helpers/prefs.dart';

// NOTE on coverage scope:
// The actual sync-to-server path (`syncPendingItems`, `syncWatchStatesFromServer`,
// `_performBidirectionalSync`) all reach into a real `PlexClient` via the
// injected `MultiServerManager`. Per the task brief we do NOT exercise those
// paths here — they require either a fake `PlexClient` factory or live HTTP.
//
// What IS covered:
//   - Initial state on a fresh service.
//   - `queueMarkWatched` / `queueMarkUnwatched` — local DB persistence.
//   - `getLocalWatchStatus` / `getLocalViewOffset` — local resolution.
//   - `getPendingSyncCount` — DB-side count.
//   - `clearAll` — local wipe.
//   - `dispose` — listener cleanup on the offline-mode source.
//   - Connectivity listener attachment via `startConnectivityMonitoring`.
//
// What is NOT covered (would need a fake PlexClient factory):
//   - `_performBidirectionalSync` (online path)
//   - `syncPendingItems` outcome map
//   - `syncWatchStatesFromServer` cache-write logic
//   - `getWatchedThreshold`'s "online client preference" branch — only the
//     SettingsService cached + default branches are testable here.

/// Minimal [OfflineModeSource] that lets tests flip the offline flag and
/// observe `addListener`/`removeListener` traffic via the protected
/// [ChangeNotifier.hasListeners] flag.
class _FakeOfflineModeSource extends ChangeNotifier implements OfflineModeSource {
  bool _isOffline;
  _FakeOfflineModeSource({bool initial = false}) : _isOffline = initial;

  @override
  bool get isOffline => _isOffline;

  void setOffline(bool value) {
    if (_isOffline == value) return;
    _isOffline = value;
    notifyListeners();
  }

  // ChangeNotifier.hasListeners is `@protected` — re-export for tests.
  @override
  // ignore: unnecessary_overrides
  bool get hasListeners => super.hasListeners;
}

/// Build a service against an in-memory database and a bare-metal
/// [MultiServerManager] (no servers added).
({OfflineWatchSyncService svc, AppDatabase db, MultiServerManager mgr}) _makeService() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  JellyfinApiCache.initialize(db);
  final mgr = MultiServerManager();
  final svc = OfflineWatchSyncService(database: db, serverManager: mgr);
  return (svc: svc, db: db, mgr: mgr);
}

JellyfinConnection _jellyfinConnection(String userId) => JellyfinConnection(
  id: 'jf-machine/$userId',
  baseUrl: 'https://jf.example.com',
  serverName: 'Shared JF',
  serverMachineId: 'jf-machine',
  userId: userId,
  userName: userId,
  accessToken: 'token-$userId',
  deviceId: 'device',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // Initial state
  // ============================================================

  group('initial state', () {
    test('a freshly constructed service is not syncing and has no pending count', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      expect(svc.isSyncing, isFalse);
      expect(await svc.getPendingSyncCount(), 0);
      expect(await svc.getLocalWatchStatus('srv:nonexistent'), isNull);
      expect(await svc.getLocalViewOffset('srv:nonexistent'), isNull);
    });

    test('isWatchedByProgress: pure math (no DB / network)', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      // duration=0 short-circuits to false (avoids divide-by-zero).
      expect(svc.isWatchedByProgress(0, 0), isFalse);
      expect(svc.isWatchedByProgress(1000, 0), isFalse);

      // No serverId → uses 0.9 default threshold.
      expect(svc.isWatchedByProgress(89, 100), isFalse);
      expect(svc.isWatchedByProgress(90, 100), isTrue);
      expect(svc.isWatchedByProgress(95, 100), isTrue);
      expect(svc.isWatchedByProgress(100, 100), isTrue);
    });

    test('getWatchedThreshold falls back to default 0.9 when no client + no settings', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      // No SettingsService initialized, no client registered → default 90/100.
      expect(svc.getWatchedThreshold('unknown-server'), 0.9);
    });
  });

  // ============================================================
  // queueMarkWatched / queueMarkUnwatched
  // ============================================================

  group('queueMarkWatched / queueMarkUnwatched', () {
    test('queueMarkWatched persists a "watched" action and bumps pending count', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      var notifications = 0;
      svc.addListener(() => notifications++);

      await svc.queueMarkWatched(serverId: 'srv', itemId: '42');

      expect(await svc.getPendingSyncCount(), 1);
      // ChangeNotifier emission was synchronous in the queue helper.
      expect(notifications, 1);

      // Latest action has actionType='watched'.
      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.actionType, 'watched');
      expect(action.serverId, 'srv');
      expect(action.ratingKey, '42');
    });

    test('queueMarkUnwatched persists an "unwatched" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '42');

      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.actionType, 'unwatched');
    });

    test('queueing the opposite action replaces the prior action (single row)', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '42');
      expect(await svc.getPendingSyncCount(), 1);

      // The DB layer's insertWatchAction deletes any prior entries for the
      // same globalKey before inserting — so flipping watched/unwatched keeps
      // a single row.
      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '42');
      expect(await svc.getPendingSyncCount(), 1);

      final action = await db.getLatestWatchAction('srv:42');
      expect(action!.actionType, 'unwatched');
    });

    test('different ratingKeys persist independently', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      await svc.queueMarkWatched(serverId: 'srv', itemId: '2');
      await svc.queueMarkUnwatched(serverId: 'other', itemId: '1');

      expect(await svc.getPendingSyncCount(), 3);

      expect((await db.getLatestWatchAction('srv:1'))!.actionType, 'watched');
      expect((await db.getLatestWatchAction('srv:2'))!.actionType, 'watched');
      expect((await db.getLatestWatchAction('other:1'))!.actionType, 'unwatched');
    });
  });

  group('syncPendingItems retry preservation', () {
    test('server unavailable keeps queued action without consuming attempts', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '42');

      await svc.syncPendingItems();

      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.syncAttempts, 0);
      expect(action.lastError, isNull);
    });

    test('max-attempt action is retained for explicit cleanup instead of deleted', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '42');
      var action = await db.getLatestWatchAction('srv:42');
      for (var i = 0; i < OfflineWatchSyncService.maxSyncAttempts; i++) {
        await db.updateSyncAttempt(action!.id, 'server error');
        action = await db.getLatestWatchAction('srv:42');
      }

      await svc.syncPendingItems();

      final retained = await db.getLatestWatchAction('srv:42');
      expect(retained, isNotNull);
      expect(retained!.syncAttempts, OfflineWatchSyncService.maxSyncAttempts);
      expect(retained.lastError, 'server error');
    });
  });

  // ============================================================
  // queueProgressUpdate (also exercised so we can test the progress branches
  // of getLocalWatchStatus / getLocalViewOffset).
  // ============================================================

  group('queueProgressUpdate', () {
    test('persists a progress row with shouldMarkWatched=false below threshold', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      // 50% progress → below default 0.9 threshold.
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '42', viewOffset: 50, duration: 100);

      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.actionType, 'progress');
      expect(action.viewOffset, 50);
      expect(action.duration, 100);
      expect(action.shouldMarkWatched, isFalse);
    });

    test('persists shouldMarkWatched=true at/above the default 0.9 threshold', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', itemId: '42', viewOffset: 95, duration: 100);

      final action = await db.getLatestWatchAction('srv:42');
      expect(action!.shouldMarkWatched, isTrue);
    });

    test('repeated progress updates merge into the same row', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', itemId: '42', viewOffset: 10, duration: 100);
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '42', viewOffset: 20, duration: 100);

      // upsertProgressAction merges by globalKey — only ONE row.
      expect(await svc.getPendingSyncCount(), 1);
      final action = await db.getLatestWatchAction('srv:42');
      expect(action!.viewOffset, 20);
    });
  });

  // ============================================================
  // getLocalWatchStatus
  // ============================================================

  group('getLocalWatchStatus', () {
    test('returns null when no local action exists', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      expect(await svc.getLocalWatchStatus('srv:none'), isNull);
    });

    test('returns true for a "watched" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      expect(await svc.getLocalWatchStatus('srv:1'), isTrue);
    });

    test('returns false for an "unwatched" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '1');
      expect(await svc.getLocalWatchStatus('srv:1'), isFalse);
    });

    test('returns shouldMarkWatched for a "progress" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      // Below threshold → shouldMarkWatched=false → status=false.
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '1', viewOffset: 50, duration: 100);
      expect(await svc.getLocalWatchStatus('srv:1'), isFalse);

      // Above threshold → shouldMarkWatched=true → status=true.
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '2', viewOffset: 99, duration: 100);
      expect(await svc.getLocalWatchStatus('srv:2'), isTrue);
    });
  });

  // ============================================================
  // getLocalViewOffset
  // ============================================================

  group('getLocalViewOffset', () {
    test('returns null when no local action exists', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      expect(await svc.getLocalViewOffset('srv:none'), isNull);
    });

    test('returns null for a "watched" or "unwatched" action (no offset)', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      expect(await svc.getLocalViewOffset('srv:1'), isNull);

      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '2');
      expect(await svc.getLocalViewOffset('srv:2'), isNull);
    });

    test('returns the stored offset for a "progress" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', itemId: '1', viewOffset: 12345, duration: 60000);
      expect(await svc.getLocalViewOffset('srv:1'), 12345);
    });

    test('progress is replaced by a manual "watched" action — offset becomes null', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', itemId: '1', viewOffset: 5000, duration: 10000);
      expect(await svc.getLocalViewOffset('srv:1'), 5000);

      // Manual "watched" wipes the progress row (insertWatchAction deletes
      // by globalKey first), so getLocalViewOffset reads the new row whose
      // actionType != 'progress' → null.
      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      expect(await svc.getLocalViewOffset('srv:1'), isNull);
    });
  });

  // ============================================================
  // getPendingSyncCount
  // ============================================================

  group('getPendingSyncCount', () {
    test('counts every queued action (manual + progress)', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      expect(await svc.getPendingSyncCount(), 0);

      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '2');
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '3', viewOffset: 50, duration: 100);
      expect(await svc.getPendingSyncCount(), 3);
    });

    test('progress upsert does NOT increment count', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', itemId: '1', viewOffset: 10, duration: 100);
      await svc.queueProgressUpdate(serverId: 'srv', itemId: '1', viewOffset: 20, duration: 100);
      expect(await svc.getPendingSyncCount(), 1);
    });
  });

  // ============================================================
  // getLocalWatchStatusesBatched
  // ============================================================

  group('getLocalWatchStatusesBatched', () {
    test('empty input returns empty map without touching the DB', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      expect(await svc.getLocalWatchStatusesBatched({}), isEmpty);
    });

    test('returns null for missing keys, statuses for queued items', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '2');
      await svc.queueProgressUpdate(
        serverId: 'srv',
        itemId: '3',
        viewOffset: 99,
        duration: 100, // above threshold
      );

      final result = await svc.getLocalWatchStatusesBatched({'srv:1', 'srv:2', 'srv:3', 'srv:missing'});
      expect(result['srv:1'], isTrue);
      expect(result['srv:2'], isFalse);
      expect(result['srv:3'], isTrue);
      expect(result['srv:missing'], isNull);
      // The map MUST contain every requested key, even when null.
      expect(result.keys.toSet(), {'srv:1', 'srv:2', 'srv:3', 'srv:missing'});
    });

    test('filters batched local statuses by active Jellyfin scope', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final activeUserB = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(activeUserB.close);
      mgr.debugRegisterJellyfinClientForTesting(activeUserB);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.insertWatchAction(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        actionType: OfflineActionType.unwatched.id,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.insertWatchAction(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'item-1',
        actionType: OfflineActionType.watched.id,
      );

      final result = await svc.getLocalWatchStatusesBatched({'jf-machine:item-1'});
      expect(result['jf-machine:item-1'], isTrue);
    });

    test('local watch actions are isolated by active profile', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      svc.setActiveProfileId('profile-a');
      await svc.queueMarkWatched(serverId: 'plex-machine', itemId: 'item-1');
      expect(await svc.getLocalWatchStatus('plex-machine:item-1'), isTrue);
      expect(await svc.getPendingSyncCount(), 1);

      svc.setActiveProfileId('profile-b');
      expect(await svc.getLocalWatchStatus('plex-machine:item-1'), isNull);
      expect(await svc.getPendingSyncCount(), 0);
      await svc.queueMarkUnwatched(serverId: 'plex-machine', itemId: 'item-1');
      expect(await svc.getLocalWatchStatus('plex-machine:item-1'), isFalse);
      expect(await svc.getPendingSyncCount(), 1);

      svc.setActiveProfileId('profile-a');
      expect(await svc.getLocalWatchStatus('plex-machine:item-1'), isTrue);
      expect(await svc.getPendingSyncCount(), 1);
    });
  });

  group('Jellyfin scoped sync', () {
    test('queues with downloaded Jellyfin source scope when no active client is registered', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );

      await svc.queueMarkWatched(serverId: 'jf-machine', itemId: 'item-1');

      final queued = await db.getPendingWatchActions();
      expect(queued.single.clientScopeId, 'jf-machine/user-a');
    });

    test('local status and resume offset use active scope over downloaded source scope', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final activeUserB = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(activeUserB.close);
      mgr.debugRegisterJellyfinClientForTesting(activeUserB);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.upsertProgressAction(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        viewOffset: 5000,
        duration: 100000,
        shouldMarkWatched: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.upsertProgressAction(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'item-1',
        viewOffset: 90000,
        duration: 100000,
        shouldMarkWatched: true,
      );

      expect(await svc.getLocalWatchStatus('jf-machine:item-1'), isTrue);
      expect(await svc.getLocalViewOffset('jf-machine:item-1'), 90000);
      expect(await svc.getLocalWatchStatus('jf-machine:item-1', clientScopeId: 'jf-machine/user-a'), isFalse);
      expect(await svc.getLocalViewOffset('jf-machine:item-1', clientScopeId: 'jf-machine/user-a'), 5000);
    });

    test('queues with active Jellyfin user instead of downloaded source scope', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );

      final activeUserB = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(activeUserB.close);
      mgr.debugRegisterJellyfinClientForTesting(activeUserB);

      final returnedScope = await svc.queueMarkWatched(serverId: 'jf-machine', itemId: 'item-1');

      final queued = await db.getPendingWatchActions();
      expect(returnedScope, 'jf-machine/user-b');
      expect(queued.single.clientScopeId, 'jf-machine/user-b');
    });

    test('replays through the queued Jellyfin user after active user changes', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final pathsByUser = <String, List<String>>{'user-a': [], 'user-b': []};

      JellyfinClient clientFor(String userId) {
        return JellyfinClient.forTesting(
          connection: _jellyfinConnection(userId),
          httpClient: MockClient((request) async {
            pathsByUser[userId]!.add('${request.method} ${request.url.path}?${request.url.query}');
            if (request.method == 'GET' && request.url.path == '/Users/$userId/Items/item-1') {
              return http.Response('{"Id":"item-1","Type":"Movie","Name":"Movie $userId"}', 200);
            }
            if (request.method == 'POST' && request.url.path == '/UserPlayedItems/item-1') {
              return http.Response('', 204);
            }
            return http.Response('not found', 404);
          }),
        );
      }

      final userA = clientFor('user-a');
      final userB = clientFor('user-b');
      addTearDown(userA.close);
      addTearDown(userB.close);

      mgr.debugRegisterJellyfinClientForTesting(userA);
      await svc.queueMarkWatched(serverId: 'jf-machine', itemId: 'item-1');
      final queued = await db.getPendingWatchActions();
      expect(queued.single.clientScopeId, 'jf-machine/user-a');

      // User B becomes the active machine client. The queued action must
      // still resolve the specific user A client from clientScopeId.
      mgr.debugRegisterJellyfinClientForTesting(userB, online: false);
      await svc.syncPendingItems();

      expect(await svc.getPendingSyncCount(), 0);
      expect(pathsByUser['user-a'], contains('POST /UserPlayedItems/item-1?userId=user-a'));
      expect(pathsByUser['user-b'], isEmpty);
    });

    test('legacy Jellyfin rows without clientScopeId are not synced through the active server client', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final paths = <String>[];
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((request) async {
          paths.add('${request.method} ${request.url.path}?${request.url.query}');
          if (request.method == 'GET' && request.url.path == '/Users/user-b/Items/item-1') {
            return http.Response('{"Id":"item-1","Type":"Movie","Name":"Movie"}', 200);
          }
          if (request.method == 'POST' && request.url.path == '/UserPlayedItems/item-1') {
            return http.Response('', 204);
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(client.close);

      mgr.debugRegisterJellyfinClientForTesting(client);
      await db.insertWatchAction(serverId: 'jf-machine', ratingKey: 'item-1', actionType: OfflineActionType.watched.id);

      await svc.syncPendingItems();

      expect(await svc.getPendingSyncCount(), 1);
      expect(paths, isEmpty);
    });

    test('legacy Jellyfin rows without clientScopeId do not borrow downloaded source scope during replay', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final pathsByUser = <String, List<String>>{'user-a': [], 'user-b': []};

      JellyfinClient clientFor(String userId) {
        return JellyfinClient.forTesting(
          connection: _jellyfinConnection(userId),
          httpClient: MockClient((request) async {
            pathsByUser[userId]!.add('${request.method} ${request.url.path}?${request.url.query}');
            if (request.method == 'GET' && request.url.path == '/Users/$userId/Items/item-1') {
              return http.Response('{"Id":"item-1","Type":"Movie","Name":"Movie $userId"}', 200);
            }
            if (request.method == 'POST' && request.url.path == '/UserPlayedItems/item-1') {
              return http.Response('', 204);
            }
            return http.Response('not found', 404);
          }),
        );
      }

      final userA = clientFor('user-a');
      final userB = clientFor('user-b');
      addTearDown(userA.close);
      addTearDown(userB.close);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.insertWatchAction(serverId: 'jf-machine', ratingKey: 'item-1', actionType: OfflineActionType.watched.id);

      mgr.debugRegisterJellyfinClientForTesting(userA);
      mgr.debugRegisterJellyfinClientForTesting(userB);
      await svc.syncPendingItems();

      expect(await svc.getPendingSyncCount(), 1);
      expect(pathsByUser['user-a'], isEmpty);
      expect(pathsByUser['user-b'], isEmpty);
    });

    test('watch-state pull uses active scope for shared movie downloads', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final pathsByUser = <String, List<String>>{'user-a': [], 'user-b': []};

      JellyfinClient clientFor(String userId) {
        return JellyfinClient.forTesting(
          connection: _jellyfinConnection(userId),
          httpClient: MockClient((request) async {
            pathsByUser[userId]!.add('${request.method} ${request.url.path}?${request.url.query}');
            if (request.method == 'GET' && request.url.path == '/Users/$userId/Items/item-1') {
              return http.Response(
                '{"Id":"item-1","Type":"Movie","Name":"Movie $userId","UserData":{"PlayCount":1,"Played":true}}',
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('not found', 404);
          }),
        );
      }

      final userA = clientFor('user-a');
      final userB = clientFor('user-b');
      addTearDown(userA.close);
      addTearDown(userB.close);
      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().stream.listen(events.add);
      addTearDown(sub.cancel);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:item-1');
      svc.setActiveProfileId('profile-b');

      mgr.debugRegisterJellyfinClientForTesting(userA);
      mgr.debugRegisterJellyfinClientForTesting(userB);
      await svc.syncWatchStatesFromServer();
      await Future<void>.delayed(Duration.zero);

      expect(pathsByUser['user-a'], isEmpty);
      expect(pathsByUser['user-b']!.where((p) => p.startsWith('GET /Users/user-b/Items/item-1?')), isNotEmpty);
      expect(events.single.cacheServerId, 'jf-machine/user-b');
    });

    test('watch-state pull does not treat Jellyfin PlayCount alone as watched', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final paths = <String>[];
      final userB = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((request) async {
          paths.add('${request.method} ${request.url.path}?${request.url.query}');
          if (request.method == 'GET' && request.url.path == '/Users/user-b/Items/item-1') {
            return http.Response(
              '{"Id":"item-1","Type":"Movie","Name":"Started Movie","UserData":{"PlayCount":1,"Played":false}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
      addTearDown(userB.close);
      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().stream.listen(events.add);
      addTearDown(sub.cancel);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:item-1');
      svc.setActiveProfileId('profile-b');

      mgr.debugRegisterJellyfinClientForTesting(userB);
      await svc.syncWatchStatesFromServer();
      await Future<void>.delayed(Duration.zero);

      expect(paths.where((p) => p.startsWith('GET /Users/user-b/Items/item-1?')), isNotEmpty);
      expect(events, isEmpty);
    });

    test('watch-state pull uses active scope for shared episode season batches', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final pathsByUser = <String, List<String>>{'user-a': [], 'user-b': []};

      JellyfinClient clientFor(String userId) {
        return JellyfinClient.forTesting(
          connection: _jellyfinConnection(userId),
          httpClient: MockClient((request) async {
            pathsByUser[userId]!.add('${request.method} ${request.url.path}?${request.url.query}');
            if (request.method == 'GET' && request.url.path == '/Shows/season-1/Seasons') {
              return http.Response('not found', 404);
            }
            if (request.method == 'GET' && request.url.path == '/Items') {
              return http.Response(
                '{"Items":[{"Id":"ep-1","Type":"Episode","Name":"Episode $userId","UserData":{"PlayCount":1,"Played":true}}]}',
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.method == 'GET' && request.url.path == '/Users/$userId/Items/ep-1') {
              return http.Response(
                '{"Id":"ep-1","Type":"Episode","Name":"Episode $userId","UserData":{"PlayCount":1,"Played":true}}',
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('not found', 404);
          }),
        );
      }

      final userA = clientFor('user-a');
      final userB = clientFor('user-b');
      addTearDown(userA.close);
      addTearDown(userB.close);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'ep-1',
        globalKey: 'jf-machine:ep-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        status: 3,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:ep-1');
      svc.setActiveProfileId('profile-b');

      mgr.debugRegisterJellyfinClientForTesting(userA);
      mgr.debugRegisterJellyfinClientForTesting(userB);
      await svc.syncWatchStatesFromServer();

      expect(pathsByUser['user-a'], isEmpty);
      expect(pathsByUser['user-b']!.where((p) => p.startsWith('GET /Items?')), isNotEmpty);
    });

    test('watch-state pull ignores physical downloads not owned by active profile', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final paths = <String>[];
      final userB = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-b'),
        httpClient: MockClient((request) async {
          paths.add('${request.method} ${request.url.path}?${request.url.query}');
          return http.Response('not found', 404);
        }),
      );
      addTearDown(userB.close);

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: 3,
      );
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'jf-machine:item-1');
      svc.setActiveProfileId('profile-b');

      mgr.debugRegisterJellyfinClientForTesting(userB);
      await svc.syncWatchStatesFromServer();

      expect(paths, isEmpty);
    });
  });

  // ============================================================
  // clearAll
  // ============================================================

  group('clearAll', () {
    test('removes every queued action and notifies listeners', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueMarkWatched(serverId: 'srv', itemId: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', itemId: '2');
      expect(await svc.getPendingSyncCount(), 2);

      var notifications = 0;
      svc.addListener(() => notifications++);

      await svc.clearAll();
      expect(await svc.getPendingSyncCount(), 0);
      expect(notifications, 1);
    });
  });

  // ============================================================
  // startConnectivityMonitoring + dispose
  // ============================================================

  group('startConnectivityMonitoring + dispose', () {
    test('attaches a listener to the source', () {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        mgr.dispose();
        await db.close();
      });

      final source = _FakeOfflineModeSource();
      expect(source.hasListeners, isFalse);

      svc.startConnectivityMonitoring(source);
      expect(source.hasListeners, isTrue);

      svc.dispose();
      // After dispose, the listener is removed.
      expect(source.hasListeners, isFalse);
    });

    test('replacing the source detaches the prior listener', () {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final first = _FakeOfflineModeSource();
      final second = _FakeOfflineModeSource();

      svc.startConnectivityMonitoring(first);
      expect(first.hasListeners, isTrue);
      expect(second.hasListeners, isFalse);

      svc.startConnectivityMonitoring(second);
      // First's listener was removed; second now has one.
      expect(first.hasListeners, isFalse);
      expect(second.hasListeners, isTrue);
    });

    test('dispose() before startConnectivityMonitoring is safe', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        mgr.dispose();
        await db.close();
      });

      // Never called startConnectivityMonitoring → both fields are null.
      expect(svc.dispose, returnsNormally);
    });
  });
}
