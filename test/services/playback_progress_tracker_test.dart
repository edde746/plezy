import 'dart:async';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/playback_report_metadata.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/playback_progress_tracker.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/utils/active_client_scope.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/playback_report_fakes.dart';

// Periodic behavior is virtualized with fake_async and the tracker's existing
// updateInterval seam. Routing, threshold, scrobble, cadence, coalescing,
// backoff, resume, and disposal are asserted through observable calls.

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
class _FakePlexClient with PlaybackReportRecorder implements PlexClient {
  _FakePlexClient({this.thresholdPercent = 90});

  /// Watched-threshold percentage to report. Defaults to 90 (matches
  /// production fallback).
  final int thresholdPercent;

  /// Override [PlexClient.watchedThresholdPercent] without going through
  /// `_serverPrefs`.
  @override
  int get watchedThresholdPercent => thresholdPercent;

  /// markWatchedFromPlaybackStop resolves the event's cacheServerId from
  /// [serverId] after the transport call.
  @override
  ServerId get serverId => ServerId('scrobbler');
  @override
  PlexProfileScopeId profileScopeId = buildPlexProfileScopeId(serverId: ServerId('scrobbler'), profileId: 'profile-a');

  @override
  String get scopedServerId => profileScopeId;

  @override
  double get watchedThreshold => thresholdPercent / 100.0;

  /// Plex relies on the explicit markWatched call (no auto-mark from the stop
  /// report), so the scrobble path hits [markWatched].
  @override
  bool get marksWatchedOnPlaybackStopped => false;

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
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state,
    int? duration,
    String? sessionIdentifier,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
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
  Future<void> onPlaybackReport(PlaybackReportCall call) {
    playbackSessionIds.add(call.playSessionId);
    playbackStreamSelections.add((
      mediaSourceId: call.mediaSourceId,
      audioStreamIndex: call.audioStreamIndex,
      subtitleStreamIndex: call.subtitleStreamIndex,
    ));
    return updateProgress(
      call.itemId,
      time: call.position.inMilliseconds,
      state: switch (call.kind) {
        PlaybackReportKind.started => 'playing',
        PlaybackReportKind.progress => call.isPaused ? 'paused' : 'playing',
        PlaybackReportKind.stopped => 'stopped',
      },
      duration: call.duration?.inMilliseconds,
    );
  }

  // Transport-only, like production: the single watch event for the stop
  // flow is emitted by markWatchedFromPlaybackStop after this returns.
  @override
  Future<void> markWatched(MediaItem item) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    markWatchedCalls.add(item.id);
  }

  @override
  Future<void> markAsWatched(String ratingKey) async {
    if (throwOnNextCall != null) {
      final err = throwOnNextCall!;
      throwOnNextCall = null;
      throw err;
    }
    markWatchedCalls.add(ratingKey);
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
    String? liveStreamId,
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
      liveStreamId: liveStreamId,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }
}

class _DelayedProgressClient extends _FakePlexClient {
  final List<int> progressAttempts = [];
  final List<Completer<void>> progressGates = [];

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    progressAttempts.add(position.inMilliseconds);
    final gate = Completer<void>();
    progressGates.add(gate);
    await gate.future;
    await super.reportPlaybackProgress(
      itemId: itemId,
      position: position,
      duration: duration,
      isPaused: isPaused,
      playSessionId: playSessionId,
      playMethod: playMethod,
      liveStreamId: liveStreamId,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }
}

class _FailingProgressClient extends _FakePlexClient {
  _FailingProgressClient({required this.failuresRemaining});

  int failuresRemaining;
  int progressAttempts = 0;

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    progressAttempts++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('planned progress failure');
    }
    await super.reportPlaybackProgress(
      itemId: itemId,
      position: position,
      duration: duration,
      isPaused: isPaused,
      playSessionId: playSessionId,
      playMethod: playMethod,
      liveStreamId: liveStreamId,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }
}

/// Jellyfin-style backend: the playback-stopped report marks the item played
/// server-side, so the in-player scrobble path must emit only the local watch
/// event and skip the explicit server mark (#1287).
class _StopMarksWatchedClient extends _FakePlexClient {
  @override
  bool get marksWatchedOnPlaybackStopped => true;

  @override
  ServerId get serverId => ServerId('srv');
}

const Object _defaultServerId = Object();

MediaItem _meta({
  String ratingKey = '42',
  Object? serverId = _defaultServerId,
  String? type = 'movie',
  int? viewOffsetMs,
}) => testMediaItem(
  id: ratingKey,
  backend: MediaBackend.plex,
  kind: MediaKind.fromString(type),
  title: 'Test Item',
  serverId: identical(serverId, _defaultServerId) ? ServerId('srv') : serverId as ServerId?,
  viewOffsetMs: viewOffsetMs,
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

  group('sendProgress: playback readiness', () {
    test('blocks non-terminal reports until playback output is ready', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
      var ready = false;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: player,
        isOffline: false,
        canReportPlayback: () => ready,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);
      await tracker.sendProgress('paused');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls, isEmpty);

      ready = true;
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      expect(client.updateProgressCalls.map((call) => call.state), ['playing']);
    });

    test('stopped before rendered output terminates at known progress without scrobbling', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 99), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(viewOffsetMs: 12000),
        player: player,
        isOffline: false,
        canReportPlayback: () => false,
        hasRenderedPlayback: () => false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped', positionOverride: player.state.duration);

      expect(client.updateProgressCalls, hasLength(1));
      expect(client.updateProgressCalls.single.state, 'stopped');
      expect(client.updateProgressCalls.single.time, 12000);
      expect(client.markWatchedCalls, isEmpty);
    });

    test('fatal stop uses the last reportable position instead of the advancing native clock', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      var canReport = true;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: player,
        isOffline: false,
        canReportPlayback: () => canReport,
        hasRenderedPlayback: () => true,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      canReport = false;
      player.position = const Duration(seconds: 95);
      await tracker.sendProgress('stopped');

      expect(client.updateProgressCalls.map((call) => (call.time, call.state)), [
        (50000, 'playing'),
        (50000, 'stopped'),
      ]);
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

    test('"stopped" can override stale player position for completion', () async {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 12), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped', positionOverride: const Duration(seconds: 100));

      expect(client.updateProgressCalls.single.time, 100000);
      expect(client.markWatchedCalls, ['42']);
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

    test('Jellyfin progress reports selected source audio when player exposes a single output track', () async {
      final client = _FakePlexClient();
      const outputAudio = AudioTrack(id: 'audio_0', language: 'jpn');
      const subtitlesOff = SubtitleTrack(id: 'no');
      final player = _FakePlayer(
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 100),
        tracks: const Tracks(
          audio: [outputAudio],
          subtitle: [SubtitleTrack(id: 'text_0', language: 'eng')],
        ),
        track: const TrackSelection(audio: outputAudio, subtitle: subtitlesOff),
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: '',
        audioTracks: [
          MediaAudioTrack(id: 1, languageCode: 'eng', selected: false),
          MediaAudioTrack(id: 4, languageCode: 'jpn', selected: true, external: true),
        ],
        subtitleTracks: [MediaSubtitleTrack(id: 3, languageCode: 'eng', selected: false, forced: false)],
        chapters: const [],
        mediaSourceId: 'source-1',
      );
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: testMediaItem(id: '42', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv'),
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
      expect(progressSelection.audioStreamIndex, 4);
      expect(progressSelection.subtitleStreamIndex, -1);
    });

    test('an off that fell out of a declined carry is not persisted as -1 (#1785)', () async {
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
        subtitleOffIsDeliberate: () => false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);
      await tracker.sendProgress('playing');
      await Future<void>.delayed(Duration.zero);

      final progressSelection = client.playbackStreamSelections[1];
      // Withheld, so the server keeps whatever it knew — an explicit -1
      // would come back as this item's default and latch the fallout.
      expect(progressSelection.subtitleStreamIndex, isNull);
      // The audio selection is still reported normally.
      expect(progressSelection.audioStreamIndex, 2);
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

    test('a session with no observable crossing still issues the explicit mark', () async {
      // A lone stopped report at 95%: Plex never held a sub-threshold offset
      // for this session, so it will not mark the item itself (#1740).
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

    test('backend that marks watched on stop skips the explicit server mark (#1287)', () async {
      // Jellyfin: /Sessions/Playing/Stopped marks the item played server-side,
      // so an explicit markWatched here would double-scrobble via the Trakt
      // plugin. The local watch event must still fire (UI + Plezy's own Trakt
      // sync, which key on `watched` events, not progress).
      final client = _StopMarksWatchedClient();
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final watched = <WatchStateEvent>[];
      final sub = WatchStateNotifier()
          .forItem('42')
          .where((e) => e.changeType == WatchStateChangeType.watched)
          .listen(watched.add);
      addTearDown(sub.cancel);

      await tracker.sendProgress('stopped');
      await Future<void>.delayed(Duration.zero);

      expect(client.markWatchedCalls, isEmpty);
      expect(watched, hasLength(1));
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

    test('a failed explicit mark is retried on the next session end', () async {
      // The mark is only attempted once a session ends with no crossing the
      // backend could see. A failure must leave it unsettled so the next
      // terminal report tries again.
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final precise = _ScrobblePreciseClient(thresholdPercent: 90, failScrobbleFirstTime: true);
      final tracker = PlaybackProgressTracker(
        client: precise,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(precise.markWatchedAttempts, 1);
      expect(precise.markWatchedSuccesses, 0);

      tracker.resumeAfterStoppedReport();
      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(precise.markWatchedAttempts, 2);
      expect(precise.markWatchedSuccesses, 1);
    });

    test('onScrobbled fires once after a successful scrobble (#1500)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        onScrobbled: () async => hookCalls++,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      await tracker.sendProgress('stopped');

      expect(client.markWatchedCalls, ['42']);
      expect(hookCalls, 1);
    });

    test('onScrobbled is not invoked below threshold', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 89), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: player,
        isOffline: false,
        onScrobbled: () async => hookCalls++,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      expect(hookCalls, 0);
    });

    test('onScrobbled waits for the explicit mark and never runs ahead of it (#1500)', () async {
      // The hook marks same-file siblings with real server writes, so it must
      // not run while this item's own mark is still pending: a hard kill in
      // between would leave the siblings watched and the episode actually
      // played unwatched.
      final precise = _ScrobblePreciseClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: precise,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        onScrobbled: () async => hookCalls++,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      expect(precise.markWatchedAttempts, 0, reason: 'the mark waits for the session to end');
      expect(hookCalls, 0, reason: 'and the siblings wait for the mark');

      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(precise.markWatchedSuccesses, 1);
      expect(hookCalls, 1);
    });

    test('onScrobbled does not run when the explicit mark fails, and runs on the retry', () async {
      // The exact inconsistency to avoid: siblings marked watched while the
      // primary episode is still unmarked on the server.
      final precise = _ScrobblePreciseClient(thresholdPercent: 90, failScrobbleFirstTime: true);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: precise,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        onScrobbled: () async => hookCalls++,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(precise.markWatchedAttempts, 1);
      expect(precise.markWatchedSuccesses, 0);
      expect(hookCalls, 0, reason: 'siblings must not be marked while the primary is not');

      tracker.resumeAfterStoppedReport();
      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(precise.markWatchedSuccesses, 1);
      expect(hookCalls, 1);
    });

    test('a throwing onScrobbled does not reset the scrobble latch', () async {
      // A sibling-mark failure must not re-scrobble the primary item — that
      // would inflate its view count on the next progress tick.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        onScrobbled: () async {
          hookCalls++;
          throw Exception('sibling mark failed');
        },
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, hasLength(1));
      expect(hookCalls, 1);
    });

    // ----------------------------------------------------------
    // Server-side crossing detection (#1740)
    //
    // Both backends mark an item played from a watched-threshold crossing they
    // observe inside one reporting session: a report below the threshold
    // followed by one at or above it. Verified against PMS 1.43 — consecutive
    // above-threshold reports mark nothing, and a resume point from an earlier
    // session does not arm a new one. The explicit mark must therefore be sent
    // only when the backend had no crossing to observe.
    // ----------------------------------------------------------

    test('a delivered crossing marks watched locally and never issues the explicit mark (#1740)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final watched = <WatchStateEvent>[];
      final sub = WatchStateNotifier()
          .forItem('42')
          .where((e) => e.changeType == WatchStateChangeType.watched)
          .listen(watched.add);
      addTearDown(sub.cancel);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 95);
      await tracker.sendProgress('playing');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty, reason: 'the server saw the crossing and marked it itself');
      expect(watched, hasLength(1), reason: 'local watched state still flips exactly once');
    });

    test('a session that begins past the threshold marks explicitly, but only once it ends', () async {
      // Resume at 95%: the server never holds a sub-threshold offset for this
      // session, so no crossing is observable and it will not mark the item.
      // The mark still waits for the stop — until then the session could seek
      // back and create a crossing of its own.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      expect(client.markWatchedCalls, isEmpty, reason: 'still live — a rewind could yet create a crossing');

      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, ['42']);
    });

    test('the explicit mark completes with the stopped report future', () async {
      // The mark is resolved at session end, so it must ride the terminal
      // report rather than race teardown: callers await the stop and then
      // dispose the tracker.
      final client = _ScrobblePreciseClient(thresholdPercent: 90)..markGate = Completer<void>();
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();

      var stopDone = false;
      final stop = tracker.sendStoppedProgressOnce().then((_) => stopDone = true);
      await pumpEventQueue();
      expect(client.markWatchedAttempts, 1);
      expect(stopDone, isFalse, reason: 'the stopped future must wait for the mark it triggered');

      client.markGate!.complete();
      await stop;
      expect(client.markWatchedSuccesses, 1);
    });

    test('a session that begins past the threshold then rewinds and re-crosses never marks explicitly', () async {
      // Verified against PMS 1.43: an explicit mark followed by an in-session
      // crossing leaves viewCount at 2 with a Play History row. Marking eagerly
      // at the start of a resumed-past-threshold session would recreate #1740
      // for anyone who rewinds and watches the end again.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 50);
      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 92);
      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty, reason: 'the server observed the 50% -> 92% crossing itself');
    });

    test('a crossing landing on the stopped report suppresses the explicit mark', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty);
    });

    test('a crossing landing on a paused report suppresses the explicit mark', () async {
      // The shape in the issue log: the threshold is crossed on a paused
      // heartbeat, ~2 minutes before playback actually ends.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 92);
      await tracker.sendProgress('paused');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty);
    });

    test('onScrobbled still fires when the explicit mark is suppressed (#1500)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      var hookCalls = 0;
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
        onScrobbled: () async => hookCalls++,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 95);
      await tracker.sendProgress('playing');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty);
      expect(hookCalls, 1, reason: 'same-file siblings are still marked');
    });

    test('resumeAfterStoppedReport clears the crossing state for the next session', () async {
      // Session 1 only ever reports below the threshold. If its sub-threshold
      // offset leaked into session 2, the first above-threshold report there
      // would look like a crossing and the explicit mark would be skipped —
      // but the server treats them as separate sessions and marks nothing.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 40), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(client.markWatchedCalls, isEmpty, reason: 'never crossed the threshold');

      tracker.resumeAfterStoppedReport();
      player.position = const Duration(seconds: 95);
      await tracker.sendProgress('playing');
      await pumpEventQueue();
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, ['42']);
    });

    test('a below-threshold report dropped during startup does not arm the crossing', () async {
      // The start report (95%) is in flight; a same-state 50% heartbeat arriving
      // meanwhile is coalesced away by PlaybackReportSession even though its
      // future resolves true. The server only ever saw 95%, so there is no
      // crossing and the explicit mark must still go out.
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 95), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final crossing = tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 50);
      final dropped = tracker.sendProgress('playing');
      await pumpEventQueue();

      client.startCompleter.complete();
      await Future.wait([crossing, dropped]);
      await pumpEventQueue();

      expect(client.updateProgressCalls.map((c) => c.time), [95000], reason: 'the 50% snapshot was never sent');

      await tracker.sendProgress('stopped');
      await pumpEventQueue();
      expect(client.markWatchedCalls, ['42']);
    });

    test('a dropped crossing followed by a seek back below the threshold marks explicitly', () async {
      // The crossing snapshot is coalesced away, so the server never sees an
      // at-or-above report; playback then seeks back and the terminal stop
      // carries a sub-threshold position. Deciding at the crossing would have
      // lost this watch entirely.
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final below = tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 95);
      final dropped = tracker.sendProgress('playing');
      await pumpEventQueue();

      client.startCompleter.complete();
      await Future.wait([below, dropped]);
      await pumpEventQueue();

      expect(client.updateProgressCalls.map((c) => c.time), [50000], reason: 'the crossing snapshot was dropped');
      expect(client.markWatchedCalls, isEmpty, reason: 'the decision is deferred, not made');

      player.position = const Duration(seconds: 50);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, ['42'], reason: 'the session ended with no crossing the server could see');
    });

    test('a dropped crossing settles as server-marked once a later report is delivered', () async {
      final client = _DelayedStartClient();
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      final below = tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 95);
      final dropped = tracker.sendProgress('playing');
      await pumpEventQueue();

      client.startCompleter.complete();
      await Future.wait([below, dropped]);
      await pumpEventQueue();
      expect(client.markWatchedCalls, isEmpty);

      player.position = const Duration(seconds: 96);
      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty, reason: 'the later delivery completed the crossing server-side');
    });

    test('a report at position zero does not arm the crossing', () async {
      // Verified against PMS 1.43: a session reporting time=0 and then the full
      // duration is NOT marked played, while the same session starting at
      // time=1000 is. Plex treats zero as session initialisation, so it has
      // nothing to cross from. Short music tracks hit this — the initial report
      // fires at 0 and the next one is the terminal stop at duration.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: Duration.zero, duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, ['42']);
    });

    test('a report one second in does arm the crossing', () async {
      // The boundary is strictly positive, not some larger minimum: PMS marks
      // a 1s -> 100% session played even though it persists no resume point.
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: const Duration(seconds: 1), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42'),
        player: player,
        isOffline: false,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      await pumpEventQueue();
      player.position = const Duration(seconds: 100);
      await tracker.sendProgress('stopped');
      await pumpEventQueue();

      expect(client.markWatchedCalls, isEmpty);
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
        metadata: _meta(ratingKey: '42', serverId: ServerId('srv')),
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

    test('does not queue offline playing progress before playback output is ready', () async {
      final (svc: svc, db: db, mgr: mgr) = await makeOfflineService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final player = _FakePlayer(position: const Duration(seconds: 12), duration: const Duration(seconds: 60));
      var ready = false;
      final tracker = PlaybackProgressTracker(
        client: null,
        metadata: _meta(ratingKey: '42', serverId: ServerId('srv')),
        player: player,
        isOffline: true,
        offlineWatchService: svc,
        canReportPlayback: () => ready,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('playing');
      expect(await db.getLatestWatchAction('srv:42'), isNull);

      ready = true;
      await tracker.sendProgress('playing');
      expect(await db.getLatestWatchAction('srv:42'), isNotNull);
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

    test('online local playback queues fallback progress when reporting fails', () async {
      final (svc: svc, db: db, mgr: mgr) = await makeOfflineService();
      addTearDown(() async {
        svc.dispose();
        mgr.dispose();
        await db.close();
      });

      final client = _FakePlexClient()..throwOnNextCall = StateError('offline');
      final player = _FakePlayer(position: const Duration(seconds: 10), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: '42', serverId: ServerId('srv')),
        player: player,
        isOffline: false,
        offlineWatchService: svc,
        queueOnOnlineFailure: true,
      );
      addTearDown(tracker.dispose);

      await tracker.sendProgress('stopped', positionOverride: const Duration(seconds: 100));

      final action = await db.getLatestWatchAction('srv:42');
      expect(action, isNotNull);
      expect(action!.viewOffset, 100000);
      expect(action.shouldMarkWatched, isTrue);
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
        metadata: _meta(ratingKey: '42', serverId: ServerId('srv')),
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
      expect(progressEvents.first.cacheServerId, client.profileScopeId);
    });

    test('does NOT emit on "stopped" if position is 0 (no real watch)', () async {
      final client = _FakePlexClient(thresholdPercent: 90);
      final player = _FakePlayer(position: Duration.zero, duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(ratingKey: 'no-watch', serverId: ServerId('srv')),
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
        metadata: _meta(ratingKey: 'scrobbler', serverId: ServerId('srv')),
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

  group('periodic tracking', () {
    test('reports immediately, follows cadence, and resumes playing after pause', () {
      fakeAsync((async) {
        final client = _FakePlexClient();
        final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
        var pausedKeepalives = 0;
        final tracker = PlaybackProgressTracker(
          client: client,
          metadata: _meta(),
          player: player,
          isOffline: false,
          updateInterval: const Duration(seconds: 1),
          onPausedKeepalive: () async => pausedKeepalives++,
        );

        tracker.startTracking();
        async.flushMicrotasks();
        expect(client.updateProgressCalls.map((call) => call.state), ['playing']);

        async.elapse(const Duration(milliseconds: 999));
        async.flushMicrotasks();
        expect(client.updateProgressCalls, hasLength(1));

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'playing']);

        player.playing = false;
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'playing', 'paused']);
        expect(pausedKeepalives, 1);

        player.playing = true;
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'playing', 'paused', 'playing']);
        expect(pausedKeepalives, 1);

        tracker.dispose();
      });
    });

    test('coalesces timer ticks while a progress report is in flight', () {
      fakeAsync((async) {
        final client = _DelayedProgressClient();
        final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
        final tracker = PlaybackProgressTracker(
          client: client,
          metadata: _meta(),
          player: player,
          isOffline: false,
          updateInterval: const Duration(seconds: 1),
        );

        tracker.startTracking();
        async.flushMicrotasks();
        expect(client.updateProgressCalls, hasLength(1));

        player.position = const Duration(seconds: 10);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, [10000]);

        player.position = const Duration(seconds: 20);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        player.position = const Duration(seconds: 30);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, [10000]);

        client.progressGates.first.complete();
        async.flushMicrotasks();
        expect(client.progressAttempts, [10000, 30000]);

        client.progressGates.last.complete();
        async.flushMicrotasks();
        expect(client.updateProgressCalls.map((call) => call.time), [5000, 10000, 30000]);

        tracker.dispose();
      });
    });

    test('backs off by one then two ticks and resumes after success', () {
      fakeAsync((async) {
        final client = _FailingProgressClient(failuresRemaining: 2);
        final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
        final tracker = PlaybackProgressTracker(
          client: client,
          metadata: _meta(),
          player: player,
          isOffline: false,
          updateInterval: const Duration(seconds: 1),
        );

        tracker.startTracking();
        async.flushMicrotasks();
        expect(client.updateProgressCalls, hasLength(1));

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, 1);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, 1);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, 2);

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(client.progressAttempts, 2);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, 3);
        expect(client.updateProgressCalls, hasLength(2));

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(client.progressAttempts, 4);
        expect(client.updateProgressCalls, hasLength(3));

        tracker.dispose();
      });
    });

    test('dispose cancels future periodic reports', () {
      fakeAsync((async) {
        final client = _FakePlexClient();
        final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
        final tracker = PlaybackProgressTracker(
          client: client,
          metadata: _meta(),
          player: player,
          isOffline: false,
          updateInterval: const Duration(seconds: 1),
        );

        tracker.startTracking();
        async.flushMicrotasks();
        expect(client.updateProgressCalls, hasLength(1));

        tracker.dispose();
        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();
        expect(client.updateProgressCalls, hasLength(1));
      });
    });
  });

  test('resumeAfterStoppedReport opens a fresh reporting session', () async {
    final client = _FakePlexClient();
    final player = _FakePlayer(position: const Duration(seconds: 5), duration: const Duration(seconds: 100));
    final tracker = PlaybackProgressTracker(client: client, metadata: _meta(), player: player, isOffline: false);
    addTearDown(tracker.dispose);

    await tracker.sendStoppedProgressOnce();
    await tracker.sendStoppedProgressOnce();
    expect(client.updateProgressCalls.map((call) => call.state), ['stopped']);

    tracker.resumeAfterStoppedReport();
    await tracker.sendProgress('playing');
    await Future<void>.delayed(Duration.zero);
    await tracker.sendStoppedProgressOnce();

    expect(client.updateProgressCalls.map((call) => call.state), ['stopped', 'playing', 'stopped']);
  });

  test('a stopped report ends the session: a clock that runs past the end reports nothing', () {
    // #1673: the native clock can keep advancing after the file is over. Once
    // the completion flow has stopped the item, no later tick may reach the
    // server — a repeated `playing` at the end is what servers extrapolate into
    // a ghost session running past the item duration.
    fakeAsync((async) {
      final client = _FakePlexClient();
      final player = _FakePlayer(position: const Duration(seconds: 50), duration: const Duration(seconds: 100));
      final tracker = PlaybackProgressTracker(
        client: client,
        metadata: _meta(),
        player: player,
        isOffline: false,
        updateInterval: const Duration(seconds: 1),
      );

      tracker.startTracking();
      async.flushMicrotasks();
      expect(client.updateProgressCalls.map((call) => call.state), ['playing']);

      unawaited(tracker.sendStoppedProgressOnce(positionOverride: const Duration(seconds: 100)));
      async.flushMicrotasks();

      player.position = const Duration(seconds: 160);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      expect(client.updateProgressCalls.map((call) => call.state), ['playing', 'stopped']);
      expect(client.updateProgressCalls.last.time, 100000);

      tracker.dispose();
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
class _ScrobblePreciseClient with PlaybackReportRecorder implements PlexClient {
  _ScrobblePreciseClient({this.thresholdPercent = 90, this.failScrobbleFirstTime = false});

  final int thresholdPercent;

  /// markWatchedFromPlaybackStop resolves the event's cacheServerId from
  /// [serverId] after the transport call — without this override the
  /// notify step throws NoSuchMethodError and a successful markWatched
  /// still registers as a failed scrobble.
  @override
  ServerId get serverId => ServerId('scrobbler');
  @override
  PlexProfileScopeId profileScopeId = buildPlexProfileScopeId(serverId: ServerId('scrobbler'), profileId: 'profile-a');

  @override
  String get scopedServerId => profileScopeId;

  @override
  int get watchedThresholdPercent => thresholdPercent;

  @override
  double get watchedThreshold => thresholdPercent / 100.0;

  @override
  bool get marksWatchedOnPlaybackStopped => false;

  bool failScrobbleFirstTime;
  int markWatchedAttempts = 0;
  int markWatchedSuccesses = 0;

  /// When set, [markWatched] blocks on this so a test can observe whether the
  /// caller awaits the mark.
  Completer<void>? markGate;
  @override
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state,
    int? duration,
    String? sessionIdentifier,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {}

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {}

  @override
  Future<void> markWatched(MediaItem item) async {
    markWatchedAttempts++;
    final gate = markGate;
    if (gate != null) await gate.future;
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
