import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/track_manager.dart';

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
//     entry with a non-null URI, and silently swallows errors thrown by the
//     player (the Future.wait branch wraps each item in try/catch).
//   - `cycleSubtitleTrack` / `cycleAudioTrack` are no-ops when the player has
//     fewer than 2 real tracks (early-return paths).
//   - `onPlaybackRestart` is a no-op when not waiting for external subs.
//   - `onSecondarySubtitleTrackChanged` is a documented no-op.
//   - `dispose` is idempotent (timers/subscriptions cleared).
//
// What's NOT covered:
//   - `applyTrackSelection` / `applyTrackSelectionWhenReady` — depends on
//     `SettingsService.getInstance()` returning a service AND `Player.streams`
//     emitting Tracks. Out of scope without re-implementing the player.
//   - `onAudioTrackChanged` / `onSubtitleTrackChanged` — server-sync paths
//     require a fully-faked PlexClient and MediaSourceInfo with realistic
//     stream IDs. The matching logic itself lives in [TrackSelectionService]
//     and is covered there.
//   - `onBackendSwitched` — wraps applyTrackSelectionWhenReady and is
//     therefore gated on the same SettingsService dependency.
//   - `resumeAfterSubtitleLoad` — schedules a real wall-clock fallback Timer.

MediaItem _meta({String id = 'rk1'}) => MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie);

/// Player that records calls and can be configured per-test.
class _FakePlayer implements Player {
  PlayerState _state;
  _FakePlayer({Tracks tracks = const Tracks(), TrackSelection track = const TrackSelection()})
    : _state = PlayerState(tracks: tracks, track: track);

  @override
  PlayerState get state => _state;

  set tracks(Tracks t) {
    _state = _state.copyWith(tracks: t);
  }

  // ── Recording surface ────────────────────────────────────────────
  final List<({String uri, String? title, String? language, bool select})> addSubtitleCalls = [];
  final List<AudioTrack> selectedAudio = [];
  final List<SubtitleTrack> selectedSubtitle = [];

  /// If non-null and >0, fail this many addSubtitleTrack calls before succeeding.
  int failAddSubtitleTimes = 0;

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    if (failAddSubtitleTimes > 0) {
      failAddSubtitleTimes--;
      throw StateError('simulated addSubtitleTrack failure');
    }
    addSubtitleCalls.add((uri: uri, title: title, language: language, select: select));
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
  bool active = true,
  void Function(String, {Duration? duration})? showMessage,
}) {
  return TrackManager(
    player: player,
    isActive: () => active,
    persistTrackPreference: _noopPersister,
    getProfileSettings: () => null,
    waitForProfileSettings: () async {},
    metadata: metadata ?? _meta(),
    showMessage: showMessage,
  );
}

Future<void> _noopPersister({
  required String id,
  required int partId,
  required String trackType,
  String? languageCode,
  int? streamID,
}) async {}

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

    test('forwards each subtitle with a URI to the player in parallel', () async {
      final player = _FakePlayer();
      final mgr = _make(player: player);
      addTearDown(mgr.dispose);

      final subs = [
        SubtitleTrack.uri('https://example/a.srt', title: 'EN', language: 'eng'),
        SubtitleTrack.uri('https://example/b.srt', title: 'FR', language: 'fre'),
      ];
      await mgr.addExternalSubtitles(subs);

      expect(player.addSubtitleCalls, hasLength(2));
      // Order is non-deterministic (Future.wait in parallel) — assert by URI set.
      final uris = player.addSubtitleCalls.map((c) => c.uri).toSet();
      expect(uris, {'https://example/a.srt', 'https://example/b.srt'});
      // None should be auto-selected — manager picks afterwards.
      expect(player.addSubtitleCalls.every((c) => c.select == false), isTrue);
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
