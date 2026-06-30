import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_source_info.dart';
import 'package:vibe_stream/mpv/mpv.dart';
import 'package:vibe_stream/mpv/player/player_stream_controllers.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/services/track_manager.dart';

import '../test_helpers/prefs.dart';

// NOTE on coverage scope:
// `TrackManager` orchestrates the player + Plex client + SettingsService
// singleton. Most paths require a real (or fake) Player surface plus an
// initialized SettingsService.
//
// Coverage:
//   - Constructor wiring (mutable fields are settable, default values).
//   - `cacheExternalSubtitles` / `lastExternalSubtitles` round-trip.
//   - `addExternalSubtitles` invokes the player's addSubtitleTrack for each
//     entry with a non-null URI, preserves order, and silently swallows errors
//     thrown by the player.
//   - `cycleSubtitleTrack` / `cycleAudioTrack` are no-ops when the player has
//     fewer than 2 real tracks (early-return paths).
//   - `applyTrackSelectionWhenReady` waits for subtitle tracks when server
//     metadata says they exist.
//   - `onPlaybackRestart` is a no-op when not waiting for external subs.
//   - `onSecondarySubtitleTrackChanged` is a documented no-op.
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

MediaItem _meta({String id = 'rk1'}) => MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie);

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

  @override
  bool get disposed => false;

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

  /// If non-null and >0, fail this many addSubtitleTrack calls before succeeding.
  int failAddSubtitleTimes = 0;
  Future<void> Function(String uri)? onAddSubtitleTrack;

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
  Future<void> selectAudioTrack(AudioTrack t) async => selectedAudio.add(t);

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack t) async => selectedSubtitle.add(t);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrackManager _make({
  required _FakePlayer player,
  MediaItem? metadata,
  MediaSourceInfo? mediaInfo,
  bool active = true,
  void Function(String, {Duration? duration})? showMessage,
  TrackPreferencePersister? persister,
}) {
  return TrackManager(
    player: player,
    isActive: () => active,
    persistTrackPreference: persister ?? _noopPersister,
    getProfileSettings: () => null,
    waitForProfileSettings: () async {},
    metadata: metadata ?? _meta(),
    mediaInfo: mediaInfo,
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
  // Construction
  // ============================================================

  group('constructor', () {
    test('initialises mutable fields with the provided values', () {
      final player = _FakePlayer();
      final mgr = TrackManager(
        player: player,
        isActive: () => true,
        persistTrackPreference: _noopPersister,
        getProfileSettings: () => null,
        waitForProfileSettings: () async {},
        metadata: _meta(),
        preferredAudioTrack: const AudioTrack(id: 'a-1', language: 'eng'),
        preferredSubtitleTrack: const SubtitleTrack(id: 's-1', language: 'eng'),
        preferredSecondarySubtitleTrack: const SubtitleTrack(id: 's-2', language: 'fre'),
      );
      addTearDown(mgr.dispose);

      expect(mgr.preferredAudioTrack?.id, 'a-1');
      expect(mgr.preferredSubtitleTrack?.id, 's-1');
      expect(mgr.preferredSecondarySubtitleTrack?.id, 's-2');
      expect(mgr.metadata.id, 'rk1');
      expect(mgr.waitingForExternalSubsTrackSelection, isFalse);
      expect(mgr.lastExternalSubtitles, isEmpty);
      expect(mgr.mediaInfo, isNull);
    });

    test('mutable fields can be reassigned (episode-navigation pattern)', () {
      final mgr = _make(player: _FakePlayer());
      addTearDown(mgr.dispose);

      mgr.metadata = _meta(id: 'next');
      mgr.preferredAudioTrack = const AudioTrack(id: 'a2', language: 'fre');
      mgr.waitingForExternalSubsTrackSelection = true;

      expect(mgr.metadata.id, 'next');
      expect(mgr.preferredAudioTrack?.id, 'a2');
      expect(mgr.waitingForExternalSubsTrackSelection, isTrue);
    });
  });

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

  group('onSecondarySubtitleTrackChanged', () {
    test('is a documented no-op', () {
      final mgr = _make(player: _FakePlayer());
      addTearDown(mgr.dispose);
      // Just verify it returns normally; nothing else to assert.
      expect(() => mgr.onSecondarySubtitleTrackChanged(const SubtitleTrack(id: '1')), returnsNormally);
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
