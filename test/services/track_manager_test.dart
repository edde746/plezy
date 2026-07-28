import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/player_stream_controllers.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/track_manager.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

// NOTE on coverage scope:
// `TrackManager` orchestrates the player + Plex client + SettingsService
// singleton. Most paths require a real (or fake) Player surface plus an
// initialized SettingsService.
//
// Coverage:
//   - `cacheExternalSubtitles` / `lastExternalSubtitles` replacement behavior.
//   - `addExternalSubtitles` invokes the player's addSubtitleTrack for each
//     entry with a non-null URI, preserves order, and silently swallows errors
//     thrown by the player.
//   - `cycleSubtitleTrack` / `cycleAudioTrack` are no-ops when the player has
//     fewer than 2 real tracks (early-return paths).
//   - `applyTrackSelectionWhenReady` waits for subtitle tracks when server
//     metadata says they exist.
//   - `applyTrackSelection` awaits one audio/subtitle application on its
//     captured player and reports failure or stale-owner cancellation.
//   - `dispose` is idempotent (timers/subscriptions cleared).
//
// What's NOT covered:
//   - Most `applyTrackSelection` selection permutations — the matching logic
//     itself lives in [TrackSelectionService] and is covered there.
//   - `onAudioTrackChanged` / `onSubtitleTrackChanged` — server-sync paths
//     require a fully-faked PlexClient and MediaSourceInfo with realistic
//     stream IDs. The matching logic itself lives in [TrackSelectionService]
//     and is covered there.
//   - `onBackendSwitched` — wraps applyTrackSelectionWhenReady and is
//     therefore gated on the same SettingsService dependency.
//   - `resumeAfterSubtitleLoad` — schedules a real wall-clock fallback Timer.

MediaItem _meta({String id = 'rk1'}) => testMediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie);

/// Player that records calls and can be configured per-test.
class _FakePlayer with PlayerStreamControllersMixin implements Player {
  PlayerState _state;
  _FakePlayer({
    Tracks tracks = const Tracks(),
    TrackSelection track = const TrackSelection(),
    this.attachesExternalSubtitlesAtOpen = false,
  }) : _state = PlayerState(tracks: tracks, track: track);

  @override
  PlayerState get state => _state;

  late final PlayerStreams _streams = createStreams();

  @override
  PlayerStreams get streams => _streams;

  @override
  final bool attachesExternalSubtitlesAtOpen;

  bool isDisposed = false;

  @override
  bool get disposed => isDisposed;

  set tracks(Tracks t) {
    _state = _state.copyWith(tracks: t);
  }

  void emitTracks(Tracks t) {
    tracks = t;
    tracksController.add(t);
  }

  // ── Recording surface ────────────────────────────────────────────
  final List<({String uri, String? title, String? language, bool select})> addSubtitleCalls = [];
  final List<AudioTrack> selectedAudio = [];
  final List<SubtitleTrack> selectedSubtitle = [];
  final List<double> rates = [];

  final List<Media> openedMedia = [];

  /// If non-null and >0, fail this many addSubtitleTrack calls before succeeding.
  int failAddSubtitleTimes = 0;
  Future<void> Function(String uri)? onAddSubtitleTrack;
  Object? selectAudioError;
  Object? selectSubtitleError;
  Future<void> Function(AudioTrack track)? onSelectAudioTrack;
  Future<void> Function(SubtitleTrack track)? onSelectSubtitleTrack;

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    openedMedia.add(media);
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    if (failAddSubtitleTimes > 0) {
      failAddSubtitleTimes--;
      throw StateError('simulated addSubtitleTrack failure');
    }
    addSubtitleCalls.add((uri: uri, title: title, language: language, select: select));
    await onAddSubtitleTrack?.call(uri);
  }

  @override
  Future<void> selectAudioTrack(AudioTrack t) async {
    selectedAudio.add(t);
    await onSelectAudioTrack?.call(t);
    if (selectAudioError case final error?) throw error;
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack t) async {
    selectedSubtitle.add(t);
    await onSelectSubtitleTrack?.call(t);
    if (selectSubtitleError case final error?) throw error;
  }

  @override
  Future<void> setRate(double rate) async {
    rates.add(rate);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrackManager _make({
  required _FakePlayer player,
  MediaItem? metadata,
  MediaSourceInfo? mediaInfo,
  bool active = true,
  bool Function()? isActive,
  Future<void> Function()? waitForProfileSettings,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  void Function(String, {Duration? duration})? showMessage,
  TrackPreferencePersister? persister,
}) {
  return TrackManager(
    player: player,
    isActive: isActive ?? () => active,
    persistTrackPreference: persister ?? _noopPersister,
    getProfileSettings: () => null,
    waitForProfileSettings: waitForProfileSettings ?? () async {},
    metadata: metadata ?? _meta(),
    mediaInfo: mediaInfo,
    preferredAudioTrack: preferredAudioTrack,
    preferredSubtitleTrack: preferredSubtitleTrack,
    showMessage: showMessage,
  );
}

MediaSourceInfo _mediaInfoWithSubtitles({bool selected = false}) {
  return MediaSourceInfo(
    videoUrl: 'https://example.com/video.mp4',
    audioTracks: [MediaAudioTrack(id: 1, language: 'English', languageCode: 'eng', selected: true)],
    subtitleTracks: [
      MediaSubtitleTrack(id: 10, language: 'English', languageCode: 'eng', selected: selected, forced: false),
    ],
    chapters: const [],
  );
}

MediaSourceInfo _metadataFreeDirectMediaInfo({bool selected = true}) {
  return MediaSourceInfo(
    videoUrl: 'https://example.com/video.mp4',
    audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
    subtitleTracks: [MediaSubtitleTrack(id: 20, codec: 'ass', selected: selected, forced: false)],
    chapters: const [],
  );
}

Future<void> _drainAsync() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _noopPersister({required int partId, required String trackType, int? streamID}) async {}

void main() {
  // The constructor doesn't touch prefs, but [dispose] / [applyTrackSelection]
  // could leak across tests — reset to be safe.
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // External subtitle cache
  // ============================================================

  group('cacheExternalSubtitles', () {
    test('round-trips through the lastExternalSubtitles getter', () {
      final mgr = _make(player: _FakePlayer());
      addTearDown(mgr.dispose);

      expect(mgr.lastExternalSubtitles, isEmpty);

      final subs = [
        SubtitleTrack.uri('https://example/a.srt', title: 'EN', language: 'eng'),
        SubtitleTrack.uri('https://example/b.srt', title: 'FR', language: 'fre'),
      ];
      mgr.cacheExternalSubtitles(subs);
      expect(mgr.lastExternalSubtitles, subs);

      // Replacing the cache overwrites it (used during episode navigation).
      mgr.cacheExternalSubtitles(const []);
      expect(mgr.lastExternalSubtitles, isEmpty);
    });
  });

  // ============================================================
  // addExternalSubtitles
  // ============================================================

  group('addExternalSubtitles', () {
    test('returns immediately on empty input', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      await mgr.addExternalSubtitles(const []);
      expect(player.addSubtitleCalls, isEmpty);
    });

    test('forwards each subtitle with a URI to the player in metadata order', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      final subs = [
        SubtitleTrack.uri('https://example/a.srt', title: 'EN', language: 'eng'),
        SubtitleTrack.uri('https://example/b.srt', title: 'FR', language: 'fre'),
      ];
      await mgr.addExternalSubtitles(subs);

      expect(player.addSubtitleCalls, hasLength(2));
      expect(player.addSubtitleCalls.map((c) => c.uri), ['https://example/a.srt', 'https://example/b.srt']);
      // None should be auto-selected — manager picks afterwards.
      expect(player.addSubtitleCalls.every((c) => c.select == false), isTrue);
    });

    test('does not start the next add until the previous subtitle completes', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);
      final firstCompletes = Completer<void>();
      addTearDown(() {
        if (!firstCompletes.isCompleted) firstCompletes.complete();
      });
      player.onAddSubtitleTrack = (uri) async {
        if (uri == 'https://example/a.srt') {
          await firstCompletes.future;
        }
      };

      final addFuture = mgr.addExternalSubtitles([
        SubtitleTrack.uri('https://example/a.srt', title: 'EN'),
        SubtitleTrack.uri('https://example/b.srt', title: 'FR'),
      ]);
      await _drainAsync();

      expect(player.addSubtitleCalls.map((c) => c.uri), ['https://example/a.srt']);

      firstCompletes.complete();
      await addFuture;

      expect(player.addSubtitleCalls.map((c) => c.uri), ['https://example/a.srt', 'https://example/b.srt']);
    });

    test('skips subtitle entries with null URI', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      // SubtitleTrack default constructor allows uri: null even with
      // isExternal: true — exercise the where-filter.
      final subs = const [
        SubtitleTrack(id: 'no-uri', isExternal: true),
        SubtitleTrack(id: 'with-uri', isExternal: true, uri: 'https://example/c.srt'),
      ];
      await mgr.addExternalSubtitles(subs);

      expect(player.addSubtitleCalls, hasLength(1));
      expect(player.addSubtitleCalls.single.uri, 'https://example/c.srt');
    });

    test('selects subtitle sidecars marked as default', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      const subs = [
        SubtitleTrack(id: 'selected', uri: 'https://example/selected.srt', isExternal: true, isDefault: true),
      ];
      await mgr.addExternalSubtitles(subs);

      expect(player.addSubtitleCalls, hasLength(1));
      expect(player.addSubtitleCalls.single.select, isTrue);
    });

    test('a player error on one entry does not prevent others from succeeding', () async {
      final player = _FakePlayer()..failAddSubtitleTimes = 1;
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      final subs = [
        SubtitleTrack.uri('https://example/a.srt', title: 'EN'),
        SubtitleTrack.uri('https://example/b.srt', title: 'FR'),
      ];
      // Should NOT throw — each per-track future has its own try/catch.
      await mgr.addExternalSubtitles(subs);
      // One add failed, one succeeded.
      expect(player.addSubtitleCalls, hasLength(1));
    });

    test('waits for player readiness before adding subtitles', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);
      final ready = Completer<void>();

      final addFuture = mgr.addExternalSubtitles([
        SubtitleTrack.uri('https://example/ready.srt', title: 'EN'),
      ], waitUntilReady: ready.future);
      await Future<void>.delayed(Duration.zero);

      expect(player.addSubtitleCalls, isEmpty);

      ready.complete();
      await addFuture;

      expect(player.addSubtitleCalls, hasLength(1));
      expect(player.addSubtitleCalls.single.uri, 'https://example/ready.srt');
    });
  });

  // ============================================================
  // applyTrackSelectionWhenReady
  // ============================================================

  group('applyTrackSelectionWhenReady', () {
    test('waits for player subtitle tracks when Plex metadata advertises subtitles', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
        ),
      );
      final mgr = _make(player: player, mediaInfo: _mediaInfoWithSubtitles());
      addTearDown(mgr.dispose);

      mgr.applyTrackSelectionWhenReady();
      await _drainAsync();

      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
          subtitle: [SubtitleTrack(id: '10', language: 'eng')],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle, hasLength(1));
      expect(player.selectedSubtitle.single.id, 'no');
    });

    test('complete metadata-free direct catalog applies tracks without the five-second fallback', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.5);

      fakeAsync((async) {
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: 'native-audio', language: 'eng')],
            subtitle: [SubtitleTrack(id: 'native-ass', codec: 'ass')],
          ),
        );
        final mgr = _make(
          player: player,
          mediaInfo: _metadataFreeDirectMediaInfo(),
          preferredSubtitleTrack: const SubtitleTrack(id: 'source:20', codec: 'ass'),
        );

        mgr.applyTrackSelectionWhenReady();
        async.flushMicrotasks();

        expect(player.selectedAudio.map((track) => track.id), ['native-audio']);
        expect(player.selectedSubtitle.map((track) => track.id), ['native-ass']);
        expect(player.rates, [1.5]);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });

    test('server-selected metadata-free direct catalog applies without the five-second fallback', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.25);

      fakeAsync((async) {
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: 'native-audio', language: 'eng')],
            subtitle: [SubtitleTrack(id: 'native-ass', codec: 'ass')],
          ),
        );
        final mgr = _make(player: player, mediaInfo: _metadataFreeDirectMediaInfo());

        mgr.applyTrackSelectionWhenReady();
        async.flushMicrotasks();

        expect(player.selectedAudio.map((track) => track.id), ['native-audio']);
        expect(player.selectedSubtitle.map((track) => track.id), ['native-ass']);
        expect(player.rates, [1.25]);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });

    test('waits through a partial catalog until the selected Plex subtitle arrives', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
        ),
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: 'https://example.com/video.mp4',
        audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
        subtitleTracks: [
          MediaSubtitleTrack(id: 10, languageCode: 'eng', selected: true, forced: false),
          MediaSubtitleTrack(id: 11, languageCode: 'fre', selected: false, forced: false),
        ],
        chapters: const [],
      );
      final mgr = _make(player: player, mediaInfo: mediaInfo);
      addTearDown(mgr.dispose);

      mgr.applyTrackSelectionWhenReady();
      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
          subtitle: [SubtitleTrack(id: '11', language: 'fre')],
        ),
      );
      await _drainAsync();
      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
          subtitle: [
            SubtitleTrack(id: '11', language: 'fre'),
            SubtitleTrack(id: '10', language: 'eng'),
          ],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle.map((track) => track.id), ['10']);
    });

    test('waits for a preferred subtitle even when the server-selected track arrives first', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
        ),
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: 'https://example.com/video.mp4',
        audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
        subtitleTracks: [
          MediaSubtitleTrack(id: 10, languageCode: 'eng', selected: true, forced: false),
          MediaSubtitleTrack(id: 11, languageCode: 'fre', selected: false, forced: false),
        ],
        chapters: const [],
      );
      final mgr = _make(
        player: player,
        mediaInfo: mediaInfo,
        preferredSubtitleTrack: const SubtitleTrack(id: 'source:11', language: 'fre'),
      );
      addTearDown(mgr.dispose);

      mgr.applyTrackSelectionWhenReady();
      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
          subtitle: [SubtitleTrack(id: '10', language: 'eng')],
        ),
      );
      await _drainAsync();
      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
          subtitle: [
            SubtitleTrack(id: '10', language: 'eng'),
            SubtitleTrack(id: '11', language: 'fre'),
          ],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle.map((track) => track.id), ['11']);
    });

    test('source identity waits for the intended identical container track', () async {
      await SettingsService.getInstance();
      final mediaInfo = MediaSourceInfo(
        videoUrl: 'https://example.com/transcode.m3u8',
        partId: 99,
        audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
        subtitleTracks: [
          MediaSubtitleTrack(
            id: 30,
            index: 0,
            languageCode: 'eng',
            title: 'English',
            codec: 'ass',
            selected: false,
            forced: false,
          ),
          MediaSubtitleTrack(
            id: 31,
            index: 1,
            languageCode: 'eng',
            title: 'English',
            codec: 'ass',
            selected: true,
            forced: false,
          ),
        ],
        chapters: const [],
      );
      const firstNativeTrack = SubtitleTrack(
        id: 'native-0',
        language: 'eng',
        title: 'English',
        codec: 'ass',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.com/video.mkv',
      );
      const secondNativeTrack = SubtitleTrack(
        id: 'native-1',
        language: 'eng',
        title: 'English',
        codec: 'ass',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.com/video.mkv',
      );
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
          subtitle: [firstNativeTrack],
        ),
      );
      final mgr = _make(
        player: player,
        mediaInfo: mediaInfo,
        preferredSubtitleTrack: const SubtitleTrack(
          id: 'source:31',
          language: 'eng',
          title: 'English',
          codec: 'ass',
          isExternal: true,
          isContainer: true,
          uri: 'https://example.com/video.mkv',
        ),
      );
      addTearDown(mgr.dispose);

      mgr.applyTrackSelectionWhenReady();
      await _drainAsync();
      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
          subtitle: [firstNativeTrack, secondNativeTrack],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle.map((track) => track.id), ['native-1']);
    });

    test('deferred transcode source choice applies after native discovery without requesting a reload', () async {
      await SettingsService.getInstance();
      final sourceTrack = MediaSubtitleTrack(
        id: 31,
        index: 0,
        languageCode: 'eng',
        title: 'English',
        codec: 'ass',
        selected: false,
        forced: false,
      );
      final mediaInfo = MediaSourceInfo(
        videoUrl: 'https://example.com/transcode.m3u8',
        partId: 99,
        audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
        subtitleTracks: [sourceTrack],
        chapters: const [],
      );
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
        ),
      );
      final mgr = _make(player: player, mediaInfo: mediaInfo);
      addTearDown(mgr.dispose);
      SubtitleTrack? persistedTrack;
      int? persistedSourceStreamId;

      final handledLocally = await deferTranscodeSubtitleSelection(
        trackManager: mgr,
        sourceTrack: sourceTrack,
        sourceSidecar: const PlaybackSubtitleSidecar(
          sourceStreamId: 31,
          preload: true,
          track: SubtitleTrack(
            id: 'container:31',
            language: 'eng',
            title: 'English',
            codec: 'ass',
            isExternal: true,
            isContainer: true,
            uri: 'https://example.com/video.mkv',
          ),
        ),
        sourceStreamId: 31,
        onSubtitleTrackChanged: (track, {sourceStreamId}) async {
          persistedTrack = track;
          persistedSourceStreamId = sourceStreamId;
          await mgr.onSubtitleTrackSelectedByUser(track, sourceStreamId: sourceStreamId);
        },
        shouldContinue: () => true,
      );

      expect(handledLocally, isTrue);
      expect(mgr.preferredSubtitleTrack?.id, 'source:31');
      expect(persistedTrack?.id, 'source:31');
      expect(persistedSourceStreamId, 31);
      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
          subtitle: [
            SubtitleTrack(
              id: 'native-0',
              language: 'eng',
              title: 'English',
              codec: 'ass',
              isExternal: true,
              isContainer: true,
              uri: 'https://example.com/video.mkv',
            ),
          ],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle.map((track) => track.id), ['native-0']);
    });

    test('persisting a deferred transcode choice keeps the late-track pass armed', () async {
      await SettingsService.getInstance();
      final sourceTrack = MediaSubtitleTrack(
        id: 32,
        index: 0,
        languageCode: 'spa',
        title: 'Spanish',
        codec: 'srt',
        selected: false,
        forced: false,
      );
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
        ),
      );
      final mgr = _make(
        player: player,
        mediaInfo: MediaSourceInfo(
          videoUrl: 'https://example.com/transcode.m3u8',
          partId: 100,
          audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
          subtitleTracks: [sourceTrack],
          chapters: const [],
        ),
      );
      addTearDown(mgr.dispose);

      await deferTranscodeSubtitleSelection(
        trackManager: mgr,
        sourceTrack: sourceTrack,
        sourceSidecar: const PlaybackSubtitleSidecar(
          sourceStreamId: 32,
          preload: true,
          track: SubtitleTrack(
            id: 'container:32',
            language: 'spa',
            title: 'Spanish',
            codec: 'srt',
            isExternal: true,
            isContainer: true,
            uri: 'https://example.com/video.mkv',
          ),
        ),
        sourceStreamId: 32,
        onSubtitleTrackChanged: (track, {sourceStreamId}) =>
            mgr.onSubtitleTrackSelectedByUser(track, sourceStreamId: sourceStreamId),
        shouldContinue: () => true,
      );
      expect(player.selectedSubtitle, isEmpty);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
          subtitle: [
            SubtitleTrack(
              id: 'native-late',
              language: 'spa',
              title: 'Spanish',
              codec: 'srt',
              isExternal: true,
              isContainer: true,
              uri: 'https://example.com/video.mkv',
            ),
          ],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle.map((track) => track.id), ['native-late']);
    });

    test('a transcode switch superseded while persisting never arms the late-track pass', () async {
      await SettingsService.getInstance();
      final sourceTrack = MediaSubtitleTrack(
        id: 33,
        index: 0,
        languageCode: 'fra',
        title: 'French',
        codec: 'srt',
        selected: false,
        forced: false,
      );
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
        ),
      );
      final mgr = _make(
        player: player,
        mediaInfo: MediaSourceInfo(
          videoUrl: 'https://example.com/transcode.m3u8',
          partId: 101,
          audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
          subtitleTracks: [sourceTrack],
          chapters: const [],
        ),
      );
      addTearDown(mgr.dispose);

      final persistGate = Completer<void>();
      var switchIsCurrent = true;

      final pending = deferTranscodeSubtitleSelection(
        trackManager: mgr,
        sourceTrack: sourceTrack,
        sourceSidecar: const PlaybackSubtitleSidecar(
          sourceStreamId: 33,
          preload: true,
          track: SubtitleTrack(
            id: 'container:33',
            language: 'fra',
            title: 'French',
            codec: 'srt',
            isExternal: true,
            isContainer: true,
            uri: 'https://example.com/video.mkv',
          ),
        ),
        sourceStreamId: 33,
        onSubtitleTrackChanged: (track, {sourceStreamId}) async {
          await persistGate.future;
          await mgr.onSubtitleTrackSelectedByUser(track, sourceStreamId: sourceStreamId);
        },
        shouldContinue: () => switchIsCurrent,
      );

      // The source switch is superseded while the persist is still suspended.
      switchIsCurrent = false;
      persistGate.complete();
      expect(await pending, isFalse);
      expect(player.tracksController.hasListener, isFalse);

      player.emitTracks(
        const Tracks(
          audio: [AudioTrack(id: 'audio', language: 'eng')],
          subtitle: [
            SubtitleTrack(
              id: 'native-superseded',
              language: 'fra',
              title: 'French',
              codec: 'srt',
              isExternal: true,
              isContainer: true,
              uri: 'https://example.com/video.mkv',
            ),
          ],
        ),
      );
      await _drainAsync();

      expect(player.selectedSubtitle, isEmpty);
    });

    test('arming a disposed manager subscribes nothing and starts no timer', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
          ),
        );
        final mgr = _make(player: player, mediaInfo: _mediaInfoWithSubtitles(selected: true));
        mgr.dispose();

        mgr.applyTrackSelectionWhenReady();

        expect(player.tracksController.hasListener, isFalse);
        expect(async.nonPeriodicTimerCount, 0);

        player.emitTracks(
          const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [SubtitleTrack(id: '10', language: 'eng')],
          ),
        );
        async.flushMicrotasks();

        expect(player.selectedSubtitle, isEmpty);
      });
    });

    test('five-second fallback keeps listening and applies a late advertised subtitle', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
          ),
        );
        final mgr = _make(player: player, mediaInfo: _mediaInfoWithSubtitles(selected: true));

        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(player.selectedAudio, hasLength(1));
        expect(player.selectedSubtitle, isEmpty);

        player.emitTracks(
          const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [SubtitleTrack(id: '10', language: 'eng')],
          ),
        );
        async.flushMicrotasks();

        expect(player.selectedSubtitle.map((track) => track.id), ['10']);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });

    test('five-second fallback keeps listening through a partial subtitle catalog', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        final mediaInfo = MediaSourceInfo(
          videoUrl: 'https://example.com/transcode.m3u8',
          audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
          subtitleTracks: [
            MediaSubtitleTrack(id: 10, languageCode: 'eng', selected: false, forced: false),
            MediaSubtitleTrack(id: 11, languageCode: 'fre', selected: true, forced: false),
          ],
          chapters: const [],
        );
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [SubtitleTrack(id: '10', language: 'eng')],
          ),
        );
        final mgr = _make(
          player: player,
          mediaInfo: mediaInfo,
          preferredSubtitleTrack: const SubtitleTrack(id: 'source:11', language: 'fre'),
        );

        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(player.selectedAudio, hasLength(1));
        expect(player.selectedSubtitle, isEmpty);

        player.emitTracks(
          const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [
              SubtitleTrack(id: '10', language: 'eng'),
              SubtitleTrack(id: '11', language: 'fre'),
            ],
          ),
        );
        async.flushMicrotasks();

        expect(player.selectedSubtitle.map((track) => track.id), ['11']);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });

    test('late subtitle arrival queues behind an in-flight fallback selection', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        final audioSelection = Completer<void>();
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
          ),
        );
        var blockFirstAudioSelection = true;
        player.onSelectAudioTrack = (_) {
          if (!blockFirstAudioSelection) return Future<void>.value();
          blockFirstAudioSelection = false;
          return audioSelection.future;
        };
        final mgr = _make(player: player, mediaInfo: _mediaInfoWithSubtitles(selected: true));

        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(player.selectedAudio, hasLength(1));

        player.emitTracks(
          const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [SubtitleTrack(id: '10', language: 'eng')],
          ),
        );
        async.flushMicrotasks();
        expect(player.selectedSubtitle, isEmpty);

        audioSelection.complete();
        async.flushMicrotasks();

        expect(player.selectedSubtitle.map((track) => track.id), ['10']);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });

    test('thirty-second deadline resolves a subtitle the source never delivered', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        // A keyed sidecar that never attaches: the catalog can never prove it
        // is complete, so selection defers until the deadline gives up on it.
        final mediaInfo = MediaSourceInfo(
          videoUrl: 'https://example.com/video.mp4',
          audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
          subtitleTracks: [
            MediaSubtitleTrack(
              id: 10,
              languageCode: 'eng',
              codec: 'srt',
              selected: true,
              forced: false,
              key: '/library/streams/10',
              external: true,
            ),
          ],
          chapters: const [],
        );
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [SubtitleTrack(id: '10', language: 'eng', codec: 'srt', isDefault: true)],
          ),
        );
        final mgr = _make(player: player, mediaInfo: mediaInfo);

        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        // The five-second pass applies ready audio and keeps waiting.
        expect(player.selectedAudio, hasLength(1));
        expect(player.selectedSubtitle, isEmpty);

        async.elapse(const Duration(seconds: 25));
        async.flushMicrotasks();

        // The deadline must decide rather than defer a third time.
        expect(player.selectedSubtitle.map((track) => track.id), ['10']);
        expect(async.nonPeriodicTimerCount, 0);
        mgr.dispose();
      });
    });
  });

  // ============================================================
  // Explicit user selection vs. the pending automatic pass
  // ============================================================

  group('explicit user selection', () {
    test('user audio choice survives the advertised-subtitle deadline', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        const userPick = AudioTrack(id: 'hin', language: 'hin');
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [
              AudioTrack(id: 'eng', language: 'eng'),
              userPick,
            ],
          ),
        );
        final mgr = _make(player: player, mediaInfo: _mediaInfoWithSubtitles(selected: true));

        // The advertised subtitle never materializes, so the five-second
        // fallback applies the ready audio and keeps the 30-second pass armed.
        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(player.selectedAudio.map((track) => track.id), ['eng']);

        // The user picks a different audio track from the sheet.
        player.selectAudioTrack(userPick);
        unawaited(mgr.onAudioTrackSelectedByUser(userPick));
        async.flushMicrotasks();
        expect(player.selectedAudio.map((track) => track.id), ['eng', 'hin']);

        // The deadline must not re-run selection and reset that choice.
        async.elapse(const Duration(seconds: 25));
        async.flushMicrotasks();
        expect(player.selectedAudio.map((track) => track.id), ['eng', 'hin']);

        mgr.dispose();
      });
    });

    test('user subtitle choice survives a late native track-list update', () async {
      await SettingsService.getInstance();

      fakeAsync((async) {
        const userPick = SubtitleTrack(id: '10', language: 'eng');
        final mediaInfo = MediaSourceInfo(
          videoUrl: 'https://example.com/transcode.m3u8',
          audioTracks: [MediaAudioTrack(id: 1, languageCode: 'eng', selected: true)],
          subtitleTracks: [
            MediaSubtitleTrack(id: 10, languageCode: 'eng', selected: false, forced: false),
            MediaSubtitleTrack(id: 11, languageCode: 'fre', selected: true, forced: false),
          ],
          chapters: const [],
        );
        final player = _FakePlayer(
          tracks: const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [userPick],
          ),
        );
        final mgr = _make(
          player: player,
          mediaInfo: mediaInfo,
          preferredSubtitleTrack: const SubtitleTrack(id: 'source:11', language: 'fre'),
        );

        // Still waiting for the French subtitle the catalog advertises.
        mgr.applyTrackSelectionWhenReady();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(player.selectedSubtitle, isEmpty);

        // The user settles on the English subtitle that is already present.
        player.selectSubtitleTrack(userPick);
        unawaited(mgr.onSubtitleTrackSelectedByUser(userPick, sourceStreamId: 10));
        async.flushMicrotasks();
        expect(player.selectedSubtitle.map((track) => track.id), ['10']);

        // The late native list must not swap the user onto the French track.
        player.emitTracks(
          const Tracks(
            audio: [AudioTrack(id: '1', language: 'eng')],
            subtitle: [
              userPick,
              SubtitleTrack(id: '11', language: 'fre'),
            ],
          ),
        );
        async.elapse(const Duration(seconds: 25));
        async.flushMicrotasks();
        expect(player.selectedSubtitle.map((track) => track.id), ['10']);

        mgr.dispose();
      });
    });
  });

  group('applyTrackSelection ownership', () {
    const audioTracks = [AudioTrack(id: 'audio-en', language: 'eng'), AudioTrack(id: 'audio-ja', language: 'jpn')];
    const subtitleTracks = [SubtitleTrack(id: 'sub-en', language: 'eng'), SubtitleTrack(id: 'sub-es', language: 'spa')];
    const availableTracks = Tracks(audio: audioTracks, subtitle: subtitleTracks);

    test('awaits preferred audio and subtitle exactly once on the intended player', () async {
      await SettingsService.getInstance();
      final intendedPlayer = _FakePlayer(tracks: availableTracks);
      final otherPlayer = _FakePlayer(tracks: availableTracks);
      final mgr = _make(
        player: intendedPlayer,
        preferredAudioTrack: audioTracks[1],
        preferredSubtitleTrack: subtitleTracks[1],
      );
      addTearDown(mgr.dispose);

      final applied = await mgr.applyTrackSelection();

      expect(applied, isTrue);
      expect(intendedPlayer.selectedAudio.map((track) => track.id), ['audio-ja']);
      expect(intendedPlayer.selectedSubtitle.map((track) => track.id), ['sub-es']);
      expect(otherPlayer.selectedAudio, isEmpty);
      expect(otherPlayer.selectedSubtitle, isEmpty);
    });

    test('reports player selection failure and does not continue to subtitles', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(tracks: availableTracks)..selectAudioError = StateError('audio selection failed');
      final mgr = _make(player: player, preferredAudioTrack: audioTracks[1], preferredSubtitleTrack: subtitleTracks[1]);
      addTearDown(mgr.dispose);

      final applied = await mgr.applyTrackSelection();

      expect(applied, isFalse);
      expect(player.selectedAudio.map((track) => track.id), ['audio-ja']);
      expect(player.selectedSubtitle, isEmpty);
    });

    test('cancels between selections when ownership moves to another player', () async {
      await SettingsService.getInstance();
      final audioSelectionStarted = Completer<void>();
      final releaseAudioSelection = Completer<void>();
      final intendedPlayer = _FakePlayer(tracks: availableTracks)
        ..onSelectAudioTrack = (_) async {
          audioSelectionStarted.complete();
          await releaseAudioSelection.future;
        };
      final replacementPlayer = _FakePlayer(tracks: availableTracks);
      Player activePlayer = intendedPlayer;
      final mgr = _make(
        player: intendedPlayer,
        isActive: () => identical(activePlayer, intendedPlayer),
        preferredAudioTrack: audioTracks[1],
        preferredSubtitleTrack: subtitleTracks[1],
      );
      addTearDown(mgr.dispose);

      final application = mgr.applyTrackSelection();
      await audioSelectionStarted.future;
      activePlayer = replacementPlayer;
      releaseAudioSelection.complete();

      expect(await application, isFalse);
      expect(intendedPlayer.selectedAudio.map((track) => track.id), ['audio-ja']);
      expect(intendedPlayer.selectedSubtitle, isEmpty);
      expect(replacementPlayer.selectedAudio, isEmpty);
      expect(replacementPlayer.selectedSubtitle, isEmpty);
    });

    test('media generation invalidation ignores a late completion before any player mutation', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.5);
      final profileWaitStarted = Completer<void>();
      final releaseProfileWait = Completer<void>();
      final player = _FakePlayer(tracks: availableTracks);
      final mgr = _make(
        player: player,
        waitForProfileSettings: () async {
          profileWaitStarted.complete();
          await releaseProfileWait.future;
        },
        preferredAudioTrack: audioTracks[1],
        preferredSubtitleTrack: subtitleTracks[1],
      );
      addTearDown(mgr.dispose);

      final application = mgr.applyTrackSelection();
      await profileWaitStarted.future;
      await mgr.invalidatePendingSelection();
      releaseProfileWait.complete();

      expect(await application, isFalse);
      expect(player.selectedAudio, isEmpty);
      expect(player.selectedSubtitle, isEmpty);
      expect(player.rates, isEmpty);
    });

    test('replacement generation selection waits for stale selection unwind', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.5);
      final staleProfileWaitStarted = Completer<void>();
      final releaseStaleProfileWait = Completer<void>();
      var profileWaitCount = 0;
      final player = _FakePlayer(tracks: availableTracks);
      final mgr = _make(
        player: player,
        waitForProfileSettings: () {
          profileWaitCount++;
          if (profileWaitCount == 1) {
            staleProfileWaitStarted.complete();
            return releaseStaleProfileWait.future;
          }
          return Future<void>.value();
        },
        preferredAudioTrack: audioTracks[0],
        preferredSubtitleTrack: subtitleTracks[0],
      );
      addTearDown(mgr.dispose);
      addTearDown(() {
        if (!releaseStaleProfileWait.isCompleted) releaseStaleProfileWait.complete();
      });

      final staleApplication = mgr.applyTrackSelection();
      await staleProfileWaitStarted.future;
      await mgr.invalidatePendingSelection();

      mgr.preferredAudioTrack = audioTracks[1];
      mgr.preferredSubtitleTrack = subtitleTracks[1];
      final replacementApplication = mgr.applyTrackSelection();
      await _drainAsync();

      expect(player.selectedAudio, isEmpty);
      expect(player.selectedSubtitle, isEmpty);
      expect(player.rates, isEmpty);

      releaseStaleProfileWait.complete();

      expect(await staleApplication, isFalse);
      expect(await replacementApplication, isTrue);
      expect(profileWaitCount, 2);
      expect(player.selectedAudio.map((track) => track.id), ['audio-ja']);
      expect(player.selectedSubtitle.map((track) => track.id), ['sub-es']);
      expect(player.rates, [1.5]);
    });

    test('replacement open waits for an already-dispatched selection mutation to drain', () async {
      await SettingsService.getInstance();
      final audioSelectionStarted = Completer<void>();
      final releaseAudioSelection = Completer<void>();
      final player = _FakePlayer(tracks: availableTracks)
        ..onSelectAudioTrack = (_) async {
          audioSelectionStarted.complete();
          await releaseAudioSelection.future;
        };
      final mgr = _make(player: player, preferredAudioTrack: audioTracks[1], preferredSubtitleTrack: subtitleTracks[1]);
      addTearDown(mgr.dispose);
      addTearDown(() {
        if (!releaseAudioSelection.isCompleted) releaseAudioSelection.complete();
      });

      final application = mgr.applyTrackSelection();
      await audioSelectionStarted.future;

      final dispatchedMutationDrain = mgr.invalidatePendingSelection();
      var reloadCompleted = false;
      final reload = () async {
        await dispatchedMutationDrain;
        await player.open(Media('https://example.com/replacement.mkv'));
        reloadCompleted = true;
      }();
      await _drainAsync();

      expect(player.openedMedia, isEmpty, reason: 'replacement media must not open across the native mutation');
      expect(reloadCompleted, isFalse);

      releaseAudioSelection.complete();
      await reload;

      expect(await application, isFalse);
      expect(player.openedMedia, hasLength(1));
      expect(reloadCompleted, isTrue);
      expect(player.selectedSubtitle, isEmpty);
      expect(player.rates, isEmpty);
    });

    test('disposing during an audio selection prevents later subtitle and rate writes', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.5);
      final audioSelectionStarted = Completer<void>();
      final releaseAudioSelection = Completer<void>();
      final player = _FakePlayer(tracks: availableTracks)
        ..onSelectAudioTrack = (_) async {
          audioSelectionStarted.complete();
          await releaseAudioSelection.future;
        };
      final mgr = _make(player: player, preferredAudioTrack: audioTracks[1], preferredSubtitleTrack: subtitleTracks[1]);

      final application = mgr.applyTrackSelection();
      await audioSelectionStarted.future;
      mgr.dispose();
      releaseAudioSelection.complete();

      expect(await application, isFalse);
      expect(player.selectedAudio.map((track) => track.id), ['audio-ja']);
      expect(player.selectedSubtitle, isEmpty);
      expect(player.rates, isEmpty);
    });
  });

  // ============================================================
  // Track cycling early-return paths
  // ============================================================

  group('cycleSubtitleTrack', () {
    test('no-op when no real subtitle tracks exist', () {
      // Tracks contains only auto/none (filtered out).
      final player = _FakePlayer(
        tracks: const Tracks(subtitle: [SubtitleTrack(id: 'auto')]),
      );
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cycleSubtitleTrack();
      expect(player.selectedSubtitle, isEmpty);
    });

    test('no-op when subtitle list is empty', () {
      final player = _FakePlayer(); // empty tracks
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cycleSubtitleTrack();
      expect(player.selectedSubtitle, isEmpty);
    });
  });

  group('cycleAudioTrack', () {
    test('no-op when fewer than 2 real audio tracks exist', () {
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [AudioTrack(id: '1', language: 'eng')],
        ),
      );
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cycleAudioTrack();
      expect(player.selectedAudio, isEmpty);
    });

    test('filters out auto/no when computing the cycle length', () {
      // 1 real + 1 auto + 1 no = 1 real → still <2, no cycle.
      final player = _FakePlayer(
        tracks: const Tracks(
          audio: [
            AudioTrack(id: '1', language: 'eng'),
            AudioTrack(id: 'auto'),
            AudioTrack(id: 'no'),
          ],
        ),
      );
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cycleAudioTrack();
      expect(player.selectedAudio, isEmpty);
    });
  });

  // ============================================================
  // Misc handlers
  // ============================================================

  group('onPlaybackRestart', () {
    test('no-op when not waiting for external subs', () {
      final mgr = _make(player: _FakePlayer());
      addTearDown(mgr.dispose);

      // Don't set the waiting flag — onPlaybackRestart should be a pure no-op
      // and must not call applyTrackSelection (which would touch the player).
      expect(mgr.waitingForExternalSubsTrackSelection, isFalse);
      mgr.onPlaybackRestart();
      // No exception is the contract.
      expect(mgr.waitingForExternalSubsTrackSelection, isFalse);
    });

    test('keeps selection pending while external subtitle add is in flight', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);
      final ready = Completer<void>();

      mgr.waitingForExternalSubsTrackSelection = true;
      final addFuture = mgr.addExternalSubtitles([
        SubtitleTrack.uri('https://example/pending.srt', title: 'EN'),
      ], waitUntilReady: ready.future);
      await Future<void>.delayed(Duration.zero);

      mgr.onPlaybackRestart();

      expect(mgr.waitingForExternalSubsTrackSelection, isTrue);
      expect(player.addSubtitleCalls, isEmpty);

      ready.complete();
      await addFuture;

      mgr.onPlaybackRestart();

      expect(mgr.waitingForExternalSubsTrackSelection, isFalse);
      expect(player.addSubtitleCalls, hasLength(1));
    });
  });

  group('onBackendSwitched', () {
    test('re-adds cached external subtitles for post-open fallback backends', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cacheExternalSubtitles([SubtitleTrack.uri('https://example/fallback.srt', title: 'EN')]);

      await mgr.onBackendSwitched();

      expect(player.addSubtitleCalls.map((c) => c.uri), ['https://example/fallback.srt']);
    });

    test('does not duplicate subtitles when fallback attached them at open', () async {
      final player = _FakePlayer(attachesExternalSubtitlesAtOpen: true);
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      mgr.cacheExternalSubtitles([SubtitleTrack.uri('https://example/fallback.srt', title: 'EN')]);

      await mgr.onBackendSwitched();

      expect(player.addSubtitleCalls, isEmpty);
    });
  });

  // ============================================================
  // onSubtitleTrackChanged — same-language stream mapping (#1443)
  // ============================================================

  group('onSubtitleTrackChanged', () {
    // Reproduces the #1443 MKVToolNix screenshot: the "forced" French subtitle
    // is NOT flagged forced in the container — it only carries the name
    // "Forced" — and the regular French sub has an empty name. So both sides
    // report forced=false, and the saved streamID must come from the title
    // (forced sub) and ordinal position (the empty-title regular sub), not from
    // "first language match wins".
    MediaSourceInfo info() => MediaSourceInfo(
      videoUrl: 'https://example.com/video.mkv',
      partId: 1,
      audioTracks: [MediaAudioTrack(id: 1, languageCode: 'fre', selected: true)],
      subtitleTracks: [
        MediaSubtitleTrack(id: 30, languageCode: 'fre', title: 'Forced', codec: 'ass', selected: false, forced: false),
        MediaSubtitleTrack(id: 31, languageCode: 'fre', codec: 'ass', selected: false, forced: false),
        MediaSubtitleTrack(id: 32, languageCode: 'eng', title: 'SDH', codec: 'ass', selected: false, forced: false),
      ],
      chapters: const [],
    );

    const playerSubs = [
      SubtitleTrack(id: '2_0', language: 'fre', title: 'Forced', codec: 'ass'),
      SubtitleTrack(id: '2_1', language: 'fre', codec: 'ass'),
      SubtitleTrack(id: '2_2', language: 'eng', title: 'SDH', codec: 'ass'),
    ];

    test('persists distinct streamIDs for title-only-forced vs regular same-language subs', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(tracks: const Tracks(subtitle: playerSubs));
      int? captured;
      final mgr = _make(
        player: player,
        mediaInfo: info(),
        persister: ({required int partId, required String trackType, int? streamID}) async {
          captured = streamID;
        },
      );
      addTearDown(mgr.dispose);

      await mgr.onSubtitleTrackChanged(playerSubs[0]); // "Forced"-named track
      expect(captured, 30);

      await mgr.onSubtitleTrackChanged(playerSubs[1]); // regular (empty title)
      expect(captured, 31);
    });

    test('persists stream 0 when subtitles are turned off', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(tracks: const Tracks(subtitle: playerSubs));
      int? captured = -1;
      final mgr = _make(
        player: player,
        mediaInfo: info(),
        persister: ({required int partId, required String trackType, int? streamID}) async {
          captured = streamID;
        },
      );
      addTearDown(mgr.dispose);

      await mgr.onSubtitleTrackChanged(SubtitleTrack.off);
      expect(captured, 0);
    });

    test('persists a known source stream id without reverse-matching native metadata', () async {
      await SettingsService.getInstance();
      final player = _FakePlayer(tracks: const Tracks(subtitle: playerSubs));
      int? captured;
      final mgr = _make(
        player: player,
        mediaInfo: info(),
        persister: ({required int partId, required String trackType, int? streamID}) async {
          captured = streamID;
        },
      );
      addTearDown(mgr.dispose);

      await mgr.onSubtitleTrackChanged(const SubtitleTrack(id: 'native-without-metadata'), sourceStreamId: 32);
      expect(captured, 32);
    });
  });

  // ============================================================
  // Lifecycle
  // ============================================================

  group('dispose', () {
    test('is idempotent', () {
      final mgr = _make(player: _FakePlayer());
      mgr.dispose();
      expect(mgr.dispose, returnsNormally);
    });
  });
}
