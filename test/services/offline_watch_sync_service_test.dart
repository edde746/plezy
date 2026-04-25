import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_mode_source.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';

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
  final mgr = MultiServerManager();
  final svc = OfflineWatchSyncService(database: db, serverManager: mgr);
  return (svc: svc, db: db, mgr: mgr);
}

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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '42');

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

      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '42');

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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '42');
      expect(await svc.getPendingSyncCount(), 1);

      // The DB layer's insertWatchAction deletes any prior entries for the
      // same globalKey before inserting — so flipping watched/unwatched keeps
      // a single row.
      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '42');
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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '2');
      await svc.queueMarkUnwatched(serverId: 'other', ratingKey: '1');

      expect(await svc.getPendingSyncCount(), 3);

      expect((await db.getLatestWatchAction('srv:1'))!.actionType, 'watched');
      expect((await db.getLatestWatchAction('srv:2'))!.actionType, 'watched');
      expect((await db.getLatestWatchAction('other:1'))!.actionType, 'unwatched');
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
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '42', viewOffset: 50, duration: 100);

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

      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '42', viewOffset: 95, duration: 100);

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

      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '42', viewOffset: 10, duration: 100);
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '42', viewOffset: 20, duration: 100);

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
      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      expect(await svc.getLocalWatchStatus('srv:1'), isTrue);
    });

    test('returns false for an "unwatched" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });
      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '1');
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
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '1', viewOffset: 50, duration: 100);
      expect(await svc.getLocalWatchStatus('srv:1'), isFalse);

      // Above threshold → shouldMarkWatched=true → status=true.
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '2', viewOffset: 99, duration: 100);
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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      expect(await svc.getLocalViewOffset('srv:1'), isNull);

      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '2');
      expect(await svc.getLocalViewOffset('srv:2'), isNull);
    });

    test('returns the stored offset for a "progress" action', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '1', viewOffset: 12345, duration: 60000);
      expect(await svc.getLocalViewOffset('srv:1'), 12345);
    });

    test('progress is replaced by a manual "watched" action — offset becomes null', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '1', viewOffset: 5000, duration: 10000);
      expect(await svc.getLocalViewOffset('srv:1'), 5000);

      // Manual "watched" wipes the progress row (insertWatchAction deletes
      // by globalKey first), so getLocalViewOffset reads the new row whose
      // actionType != 'progress' → null.
      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '2');
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '3', viewOffset: 50, duration: 100);
      expect(await svc.getPendingSyncCount(), 3);
    });

    test('progress upsert does NOT increment count', () async {
      final (svc: svc, db: db, mgr: mgr) = _makeService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '1', viewOffset: 10, duration: 100);
      await svc.queueProgressUpdate(serverId: 'srv', ratingKey: '1', viewOffset: 20, duration: 100);
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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '2');
      await svc.queueProgressUpdate(
        serverId: 'srv',
        ratingKey: '3',
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

      await svc.queueMarkWatched(serverId: 'srv', ratingKey: '1');
      await svc.queueMarkUnwatched(serverId: 'srv', ratingKey: '2');
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
