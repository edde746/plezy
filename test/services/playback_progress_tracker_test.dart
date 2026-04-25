import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_progress_tracker.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

import '../test_helpers/prefs.dart';

// NOTE on coverage scope:
// `PlaybackProgressTracker` periodically samples the player's position and
// reports it to either an online [PlexClient] or the offline queue. The
// periodic [Timer] is purely a wall-clock concern — instead of trying to
// virtualize it, we exercise the routing/threshold/scrobble logic directly
// through the public [PlaybackProgressTracker.sendProgress].
//
// Coverage:
//   - Constructor invariants (offline ↔ offlineWatchService, online ↔ client).
//   - Online routing: 'stopped' awaits, 'playing'/'paused' fire-and-forget.
//   - Threshold gating: scrobbles once when percent >= server threshold.
//   - Scrobble idempotency: a second sendProgress past threshold is a no-op.
//   - Offline routing: queues a progress update via the database.
//   - Offline progress with null serverId is a no-op (no queue write).
//   - 'stopped' event emits a WatchStateNotifier.notifyProgress.
//   - dispose() / stopTracking() are idempotent.
//
// What is NOT covered (by design):
//   - The periodic [Timer.periodic] tick itself — we'd need to either drive
//     real time (flaky) or inject a clock dependency (out of scope).
//   - The exponential-backoff state — observable only across multiple ticks
//     under wall time.

/// Fake Player whose state is mutable from the test.
class _FakePlayer implements Player {
  PlayerState _state;
  _FakePlayer({Duration position = Duration.zero, Duration duration = Duration.zero, bool playing = true})
    : _state = PlayerState(playing: playing, duration: duration, position: position);

  @override
  PlayerState get state => _state;

  set position(Duration value) {
    _state = _state.copyWith(position: value);
  }

  set duration(Duration value) {
    _state = _state.copyWith(duration: value);
  }

  set playing(bool value) {
    _state = _state.copyWith(playing: value);
  }

  set completed(bool value) {
    _state = _state.copyWith(completed: value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Recording fake [PlexClient] that captures every progress / scrobble call
/// without touching the network.
class _FakePlexClient implements PlexClient {
  _FakePlexClient({this.thresholdPercent = 90});

  /// Watched-threshold percentage to report. Defaults to 90 (matches
  /// production fallback).
  final int thresholdPercent;

  /// Override [PlexClient.watchedThresholdPercent] without going through
  /// `_serverPrefs`.
  @override
  int get watchedThresholdPercent => thresholdPercent;

  /// (ratingKey, time, state, duration) tuples for every updateProgress call.
  final List<({String ratingKey, int time, String state, int? duration})> updateProgressCalls = [];

  /// Rating keys passed to markAsWatched.
  final List<String> markWatchedCalls = [];

  /// If non-null, [updateProgress] / [markAsWatched] throw this on the next call.
  Object? throwOnNextCall;

  @override
  Future<void> updateProgress(String ratingKey, {required int time, required String state, int? duration}) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    updateProgressCalls.add((ratingKey: ratingKey, time: time, state: state, duration: duration));
  }

  @override
  Future<void> markAsWatched(String ratingKey, {PlexMetadata? metadata}) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    markWatchedCalls.add(ratingKey);
    // Production fires a WatchStateNotifier event from markAsWatched. Mirror
    // that so tests can observe it through the singleton.
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: true);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlexMetadata _meta({String ratingKey = '42', String? serverId = 'srv', String? type = 'movie'}) =>
    PlexMetadata(ratingKey: ratingKey, type: type, title: 'Test Item', serverId: serverId);

void main() {
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // Constructor assertions
  // ============================================================

  group('constructor assertions', () {
    test('offline=true requires offlineWatchService', () {
      expect(
        () => PlaybackProgressTracker(client: null, metadata: _meta(), player: _FakePlayer(), isOffline: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('offline=false requires client', () {
      expect(
        () => PlaybackProgressTracker(client: null, metadata: _meta(), player: _FakePlayer(), isOffline: false),
        throwsA(isA<AssertionError>()),
      );
    });

    test('valid online construction succeeds', () {
      final tracker = PlaybackProgressTracker(
        client: _FakePlexClient(),
        metadata: _meta(),
        player: _FakePlayer(),
        isOffline: false,
      );
      addTearDown(tracker.dispose);
      // No assertion — the constructor returned cleanly.
      expect(tracker, isNotNull);
    });
  });

  // ============================================================
  // sendProgress: short-circuit on duration=0
  // ============================================================

  group('sendProgress: duration guard', () {
    test('does NOT send progress when duration is zero (player not yet ready)', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(); // duration = Duration.zero
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      expect(client.updateProgressCalls, isEmpty);
      expect(client.markWatchedCalls, isEmpty);
    });
  });

  // ============================================================
  // sendProgress: online routing
  // ============================================================

  group('sendProgress: online', () {
    test('"stopped" awaits the underlying call and reports correct args', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 30), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');

      // updateProgress is awaited synchronously when state == 'stopped'.
      expect(client.updateProgressCalls, hasLength(1));
      final call = client.updateProgressCalls.single;
      expect(call.ratingKey, '42');
      expect(call.time, 30000); // 30s in ms
      expect(call.state, 'stopped');
      expect(call.duration, 100000); // 100s in ms
    });

    test('"playing" fires-and-forgets but eventually invokes updateProgress', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      // The unawaited Future may not have settled yet — drain microtasks.
      await Future<void>.delayed(Duration.zero);

      expect(client.updateProgressCalls, hasLength(1));
      expect(client.updateProgressCalls.single.state, 'playing');
    });
  });

  // ============================================================
  // Threshold gating + scrobble
  // ============================================================

  group('threshold gating', () {
    test('does NOT scrobble when percent < watchedThresholdPercent', () async {
      // 89% < 90% threshold.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 89), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      expect(client.markWatchedCalls, isEmpty);
    });

    test('scrobbles when percent >= watchedThresholdPercent', () async {
      // 95% >= 90% threshold.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');

      expect(client.markWatchedCalls, ['42']);
    });

    test('respects a custom server threshold (e.g. 80%)', () async {
      // 81% >= 80%, but < 90% default.
      final client = _FakePlexClient(thresholdPercent: 80);
      final player = _FakePlayer(position: const Duration(seconds: 81), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      expect(client.markWatchedCalls, ['42']);
    });

    test('scrobble is idempotent across multiple progress calls', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      await tracker.sendProgress('stopped');
      await tracker.sendProgress('stopped');

      // markAsWatched fired exactly once — _scrobbled stays true.
      expect(client.markWatchedCalls, hasLength(1));
    });

    test('a failed scrobble is retried on the next call (resets _scrobbled)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      // First call: updateProgress succeeds, then markAsWatched throws.
      // To make the *second* method (markAsWatched) throw, we need a flag that
      // only triggers on the 2nd call. The fake's `throwOnNextCall` consumes
      // on the first call, which is updateProgress. Workaround: arm the throw
      // immediately before sendProgress, so updateProgress fails. The catch
      // branch in PlaybackProgressTracker still bumps the failure counter for
      // online stopped calls (and skips scrobble). Then arm again — updateProgress
      // succeeds (because the throw was consumed) — and assert markAsWatched
      // succeeds and scrobbles.
      //
      // To target ONLY markAsWatched, we instead use a custom client.
      final precise = _ScrobblePreciseClient(thresholdPercent: 90, failScrobbleFirstTime: true);
      final tracker2 = PlaybackProgressTracker(
        client: precise,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker2.dispose);

      await tracker2.sendProgress('stopped');
      expect(precise.markWatchedAttempts, 1);

      // Retry — markAsWatched now succeeds.
      await tracker2.sendProgress('stopped');
      expect(precise.markWatchedAttempts, 2);
      expect(precise.markWatchedSuccesses, 1);
    });
  });

  // ============================================================
  // Offline routing
  // ============================================================

  group('sendProgress: offline', () {
    Future<({OfflineWatchSyncService svc, AppDatabase db, MultiServerManager mgr})> makeOfflineService() async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final mgr = MultiServerManager();
      final svc = OfflineWatchSyncService(database: db, serverManager: mgr);
      return (svc: svc, db: db, mgr: mgr);
    }

    test('queues a progress update via the offline service', () async {
      final (svc: svc, db: db, mgr: mgr) = await makeOfflineService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final player = _FakePlayer(position: const Duration(seconds: 12), duration: const Duration(seconds: 60));
      final tracker = PlaybackProgressTracker(
        client: null,
        metadata: _meta(ratingKey: '42', serverId: 'srv'),
        player: player,
        isOffline: true,
        offlineWatchService: svc,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');

      // Local DB now has a progress row for srv:42.
      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.actionType, 'progress');
      expect(action.viewOffset, 12000); // 12s in ms
      expect(action.duration, 60000);
    });

    test('offline + null serverId is a no-op (does NOT throw, does NOT queue)', () async {
      final (svc: svc, db: db, mgr: mgr) = await makeOfflineService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 60));
      final tracker = PlaybackProgressTracker(
        client: null,
        metadata: _meta(ratingKey: '42', serverId: null), // <— no serverId
        player: player,
        isOffline: true,
        offlineWatchService: svc,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      expect(await svc.getPendingSyncCount(), 0);
    });
  });

  // ============================================================
  // WatchStateNotifier emission on 'stopped'
  // ============================================================

  group('WatchStateNotifier event on "stopped"', () {
    test('emits a progress-update event when stopped past position 0', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 30), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42', serverId: 'srv'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      // Subscribe before triggering the event.
      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().forItem('42').listen(events.add);
      addTearDown(sub.cancel);

      await tracker.sendProgress('stopped');
      // Stream is broadcast — give it a microtask.
      await Future<void>.delayed(Duration.zero);

      // We expect at least one progressUpdate event for ratingKey=42.
      final progressEvents = events.where((e) => e.changeType == WatchStateChangeType.progressUpdate).toList();
      expect(progressEvents, isNotEmpty);
      expect(progressEvents.first.viewOffset, 30000);
    });

    test('does NOT emit on "stopped" if position is 0 (no real watch)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: Duration.zero, duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: 'no-watch', serverId: 'srv'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().forItem('no-watch').listen(events.add);
      addTearDown(sub.cancel);

      await tracker.sendProgress('stopped');
      await Future<void>.delayed(Duration.zero);

      // No progressUpdate event.
      expect(events.where((e) => e.changeType == WatchStateChangeType.progressUpdate), isEmpty);
    });

    test('does NOT emit a progress event when scrobble already fired', () async {
      // 95% triggers a scrobble (markAsWatched → notifyWatched). The progress
      // event must be suppressed by the `_scrobbled` flag.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: 'scrobbler', serverId: 'srv'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().forItem('scrobbler').listen(events.add);
      addTearDown(sub.cancel);

      await tracker.sendProgress('stopped');
      await Future<void>.delayed(Duration.zero);

      // Watched event from markAsWatched fires; progressUpdate is suppressed.
      final watched = events.where((e) => e.changeType == WatchStateChangeType.watched).toList();
      final progress = events.where((e) => e.changeType == WatchStateChangeType.progressUpdate).toList();
      expect(watched, hasLength(1));
      expect(progress, isEmpty);
    });
  });

  // ============================================================
  // startTracking / stopTracking / dispose lifecycle
  // ============================================================

  group('lifecycle', () {
    test('startTracking + stopTracking is a clean no-op for an inactive player', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(playing: false); // not active
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      tracker.startTracking();
      tracker.stopTracking();

      // No initial 'playing' progress was sent because the player wasn't active.
      // Drain anyway in case the unawaited future raced.
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);
    });

    test('startTracking is idempotent: a second call logs a warning and no-ops', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(playing: false); // skip the immediate fire
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: player,
        isOffline: false,
        updateInterval: const Duration(hours: 1), // long enough that no tick fires in the test window
      );
      addTearDown(tracker.dispose);

      tracker.startTracking();
      tracker.startTracking(); // second call should warn and bail
      tracker.stopTracking();
      // No exception is the contract.
    });

    test('dispose is idempotent', () {
      final client = _FakePlexClient();
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: _FakePlayer(playing: false),
        isOffline: false,
      );
      tracker.dispose();
      // Calling dispose again must not throw.
      expect(tracker.dispose, returnsNormally);
    });
  });
}

/// A more precise fake than [_FakePlexClient]: lets the test independently
/// fail markAsWatched without touching updateProgress.
class _ScrobblePreciseClient implements PlexClient {
  _ScrobblePreciseClient({this.thresholdPercent = 90, this.failScrobbleFirstTime = false});

  final int thresholdPercent;
  @override
  int get watchedThresholdPercent => thresholdPercent;

  bool failScrobbleFirstTime;
  int markWatchedAttempts = 0;
  int markWatchedSuccesses = 0;

  @override
  Future<void> updateProgress(String ratingKey, {required int time, required String state, int? duration}) async {}

  @override
  Future<void> markAsWatched(String ratingKey, {PlexMetadata? metadata}) async {
    markWatchedAttempts++;
    if (failScrobbleFirstTime) {
      failScrobbleFirstTime = false;
      throw StateError('simulated scrobble failure');
    }
    markWatchedSuccesses++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
