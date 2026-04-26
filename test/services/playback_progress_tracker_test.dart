import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
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
  final PlayerStreams _streams = const PlayerStreams(
    playing: Stream<bool>.empty(),
    completed: Stream<bool>.empty(),
    buffering: Stream<bool>.empty(),
    position: Stream<Duration>.empty(),
    duration: Stream<Duration>.empty(),
    seekable: Stream<bool>.empty(),
    buffer: Stream<Duration>.empty(),
    volume: Stream<double>.empty(),
    rate: Stream<double>.empty(),
    tracks: Stream<Tracks>.empty(),
    track: Stream<TrackSelection>.empty(),
    log: Stream<PlayerLog>.empty(),
    error: Stream<PlayerError>.empty(),
    audioDevice: Stream<AudioDevice>.empty(),
    audioDevices: Stream<List<AudioDevice>>.empty(),
    bufferRanges: Stream<List<BufferRange>>.empty(),
    playbackRestart: Stream<void>.empty(),
    backendSwitched: Stream<void>.empty(),
  );

  _FakePlayer({
    Duration position = Duration.zero,
    Duration duration = Duration.zero,
    bool playing = true,
    Tracks tracks = const Tracks(),
    TrackSelection track = const TrackSelection(),
  }) : _state = PlayerState(playing: playing, duration: duration, position: position, tracks: tracks, track: track);

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

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

  @override
  double get watchedThreshold => thresholdPercent / 100.0;

  /// (ratingKey, time, state, duration) tuples for every updateProgress call.
  final List<({String ratingKey, int time, String state, int? duration})> updateProgressCalls = [];

  /// Rating keys passed to markWatched.
  final List<String> markWatchedCalls = [];

  /// PlaySessionIds forwarded through the reportPlayback* methods.
  final List<String?> playbackSessionIds = [];

  final List<({String? mediaSourceId, int? audioStreamIndex, int? subtitleStreamIndex})> playbackStreamSelections = [];

  /// If non-null, the next reportPlayback*/markWatched call throws this.
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

  // The interface report* methods delegate to updateProgress so existing
  // assertions on `updateProgressCalls` keep working.
  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    playbackSessionIds.add(playSessionId);
    playbackStreamSelections.add((
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    ));
    return updateProgress(itemId, time: position.inMilliseconds, state: 'playing', duration: duration?.inMilliseconds);
  }

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    playbackSessionIds.add(playSessionId);
    playbackStreamSelections.add((
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    ));
    return updateProgress(
      itemId,
      time: position.inMilliseconds,
      state: isPaused ? 'paused' : 'playing',
      duration: duration.inMilliseconds,
    );
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) {
    playbackSessionIds.add(playSessionId);
    playbackStreamSelections.add((mediaSourceId: mediaSourceId, audioStreamIndex: null, subtitleStreamIndex: null));
    return updateProgress(itemId, time: position.inMilliseconds, state: 'stopped', duration: duration?.inMilliseconds);
  }

  @override
  Future<void> markWatched(MediaItem item) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    markWatchedCalls.add(item.id);
    WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
  }

  @override
  Future<void> markAsWatched(String ratingKey, {MediaItem? item}) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    markWatchedCalls.add(ratingKey);
    if (item != null) {
      WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedStartClient extends _FakePlexClient {
  final Completer<void> startCompleter = Completer<void>();

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    await startCompleter.future;
    await super.reportPlaybackStarted(
      itemId: itemId,
      position: position,
      duration: duration,
      playSessionId: playSessionId,
      playMethod: playMethod,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }
}

MediaItem _meta({String ratingKey = '42', String? serverId = 'srv', String? type = 'movie'}) => MediaItem(
  id: ratingKey,
  backend: MediaBackend.plex,
  kind: MediaKind.fromString(type),
  title: 'Test Item',
  serverId: serverId,
);

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

    test('forwards PlaySessionId to started, progress, and stopped reports', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        playSessionId: 'play-session-1',
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      await tracker.sendProgress('stopped');

      expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'playing', 'stopped']);
      expect(client.playbackSessionIds, ['play-session-1', 'play-session-1', 'play-session-1']);
    });

    test('coalesces concurrent start reports while the first start is in flight', () async {
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);

      client.startCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(client.updateProgressCalls.map((call) => call.state), ['playing']);
    });

    test('orders stopped after an in-flight start report', () async {
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);

      final stopFuture = tracker.sendProgress('stopped');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);

      client.startCompleter.complete();
      await stopFuture;

      expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'stopped']);
    });

    test('does not send queued progress after terminal stopped state', () async {
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);

      final stopFuture = tracker.sendProgress('stopped');
      client.startCompleter.complete();
      await stopFuture;

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);

      expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'stopped']);
    });

    test('coalesces concurrent stopped reports into one terminal stop', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      final events = <WatchStateEvent>[];
      final sub = WatchStateNotifier().forItem('42').listen(events.add);
      addTearDown(sub.cancel);

      await Future.wait([tracker.sendProgress('stopped'), tracker.sendProgress('stopped')]);
      await Future<void>.delayed(Duration.zero);

      expect(client.updateProgressCalls.map((call) => call.state), ['stopped']);
      expect(events.where((e) => e.changeType == WatchStateChangeType.progressUpdate), hasLength(1));
    });

    test('allows a later stopped report to retry after final stop fails', () async {
      final client = _FakePlexClient()..throwOnNextCall = Exception('network blip');
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      expect(client.updateProgressCalls, isEmpty);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);

      await tracker.sendProgress('stopped');
      expect(client.updateProgressCalls.map((call) => call.state), ['stopped']);
    });

    test('maps current player tracks to server stream indexes for progress reports', () async {
      final client = _FakePlexClient();
      const selectedAudio = AudioTrack(id: 'audio_1', language: 'jpn');
      const subtitlesOff = SubtitleTrack(id: 'no');
      final player = _FakePlayer(
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 100),
        tracks: const Tracks(
          audio: [
            AudioTrack(id: 'audio_0', language: 'eng'),
            selectedAudio,
          ],
          subtitle: [SubtitleTrack(id: 'text_0', language: 'eng')],
        ),
        track: const TrackSelection(audio: selectedAudio, subtitle: subtitlesOff),
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: '',
        audioTracks: [
          MediaAudioTrack(id: 1, languageCode: 'eng', selected: false),
          MediaAudioTrack(id: 2, languageCode: 'jpn', selected: true),
        ],
        subtitleTracks: [MediaSubtitleTrack(id: 3, languageCode: 'eng', selected: false, forced: false)],
        chapters: const [],
        mediaSourceId: 'source-1',
      );
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        mediaInfo: mediaInfo,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);

      final progressSelection = client.playbackStreamSelections[1];
      expect(progressSelection.mediaSourceId, 'source-1');
      expect(progressSelection.audioStreamIndex, 2);
      expect(progressSelection.subtitleStreamIndex, -1);
    });

    test('stopped reports only resolve media source and do not include selected streams', () async {
      final client = _FakePlexClient();
      const selectedAudio = AudioTrack(id: 'audio_1', language: 'jpn');
      final player = _FakePlayer(
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 100),
        tracks: const Tracks(
          audio: [selectedAudio],
          subtitle: [SubtitleTrack(id: 'text_0', language: 'eng')],
        ),
        track: const TrackSelection(
          audio: selectedAudio,
          subtitle: SubtitleTrack(id: 'text_0', language: 'eng'),
        ),
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: '',
        audioTracks: [MediaAudioTrack(id: 2, languageCode: 'jpn', selected: true)],
        subtitleTracks: [MediaSubtitleTrack(id: 3, languageCode: 'eng', selected: true, forced: false)],
        chapters: const [],
        mediaSourceId: 'source-1',
      );
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        mediaInfo: mediaInfo,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');

      expect(client.playbackStreamSelections, hasLength(1));
      expect(client.playbackStreamSelections.single.mediaSourceId, 'source-1');
      expect(client.playbackStreamSelections.single.audioStreamIndex, isNull);
      expect(client.playbackStreamSelections.single.subtitleStreamIndex, isNull);
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

      await tracker2.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      expect(precise.markWatchedAttempts, 1);

      // Retry — markAsWatched now succeeds.
      await tracker2.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
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
/// fail the scrobble (markWatched) without touching the progress signals.
class _ScrobblePreciseClient implements PlexClient {
  _ScrobblePreciseClient({this.thresholdPercent = 90, this.failScrobbleFirstTime = false});

  final int thresholdPercent;
  @override
  int get watchedThresholdPercent => thresholdPercent;

  @override
  double get watchedThreshold => thresholdPercent / 100.0;

  bool failScrobbleFirstTime;
  int markWatchedAttempts = 0;
  int markWatchedSuccesses = 0;

  @override
  Future<void> updateProgress(String ratingKey, {required int time, required String state, int? duration}) async {}

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {}

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {}

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) async {}

  @override
  Future<void> markWatched(MediaItem item) async {
    markWatchedAttempts++;
    if (failScrobbleFirstTime) {
      failScrobbleFirstTime = false;
      throw StateError('simulated scrobble failure');
    }
    markWatchedSuccesses++;
  }

  @override
  Future<void> markAsWatched(String ratingKey, {MediaItem? item}) async {
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
