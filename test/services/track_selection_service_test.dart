import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/jellyfin/jellyfin_user_profile.dart';
import 'package:plezy/models/plex/plex_user_profile.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/track_selection_service.dart';
import '../test_helpers/media_items.dart';

// NOTE on coverage scope:
// `TrackSelectionService` is a large pure logic surface with one async
// integration point (`selectAndApplyTracks`). We cover:
//
//   - `languageMatches` — direct, base-code, and ISO 639 variation matching.
//   - `findBestTrackMatch` / `findBestAudioMatch` / `findBestSubtitleMatch` —
//     id+title+language exact, title+language, language-only, and the
//     "auto"/"no" filtering rule.
//   - `findAudioTrackByProfile` — picks the first preferred-language match,
//     respects autoSelectAudio, falls back across the language list.
//   - `selectAudioTrack` — full priority cascade:
//       Priority 1 (preferred from navigation),
//       Priority 2 (Plex-selected via media info),
//       Priority 3 (per-media metadata.audioLanguage),
//       Priority 4 (user profile),
//       Priority 5 (default / first track),
//       and the empty-list null return.
//   - `selectSubtitleTrack` — preferred=off, preferred=tracked,
//       Plex-selected, Plex-server-explicit-no-subtitles, default fallback,
//       and the off-by-default branch.
//
// Top-level subtitle matching helpers are exercised directly for complete,
// partial, unique, ambiguous, and container catalogs. Audio helpers are
// exercised through `selectAudioTrack` (Priority 2) and their focused
// disambiguation tests below.
//
// What's NOT covered:
//   - `selectAndApplyTracks` — depends on a real Player + SettingsService
//     singleton + `player.streams.tracks`. Out of scope for a unit test.

// ============================================================
// Fixtures
// ============================================================

MediaItem _meta({MediaBackend backend = MediaBackend.plex, String? audioLanguage, String? subtitleLanguage}) =>
    testMediaItem(
      id: 'rk1',
      backend: backend,
      kind: MediaKind.movie,
      audioLanguage: audioLanguage,
      subtitleLanguage: subtitleLanguage,
    );

PlexUserProfile _profile({
  bool autoSelectAudio = true,
  String? defaultAudioLanguage,
  List<String>? defaultAudioLanguages,
  String? defaultSubtitleLanguage,
  List<String>? defaultSubtitleLanguages,
  int autoSelectSubtitle = 0,
}) {
  return PlexUserProfile(
    autoSelectAudio: autoSelectAudio,
    defaultAudioAccessibility: 0,
    defaultAudioLanguage: defaultAudioLanguage,
    defaultAudioLanguages: defaultAudioLanguages,
    defaultSubtitleLanguage: defaultSubtitleLanguage,
    defaultSubtitleLanguages: defaultSubtitleLanguages,
    autoSelectSubtitle: autoSelectSubtitle,
    defaultSubtitleAccessibility: 0,
    defaultSubtitleForced: 1,
    watchedIndicator: 1,
    mediaReviewsVisibility: 0,
  );
}

JellyfinUserProfile _jellyfinProfile({
  String? defaultAudioLanguage,
  String? defaultSubtitleLanguage,
  SubtitlePlaybackMode? subtitleMode,
}) {
  return JellyfinUserProfile(
    autoSelectAudio: true,
    defaultAudioLanguage: defaultAudioLanguage,
    defaultSubtitleLanguage: defaultSubtitleLanguage,
    subtitleMode: subtitleMode,
  );
}

AudioTrack _audio(String id, {String? lang, String? title, String? codec, int? channels, bool isDefault = false}) =>
    AudioTrack(id: id, language: lang, title: title, codec: codec, channels: channels, isDefault: isDefault);

SubtitleTrack _sub(
  String id, {
  String? lang,
  String? title,
  String? codec,
  bool isDefault = false,
  bool isForced = false,
  bool isExternal = false,
  bool isContainer = false,
}) => SubtitleTrack(
  id: id,
  language: lang,
  title: title,
  codec: codec,
  isDefault: isDefault,
  isForced: isForced,
  isExternal: isExternal,
  isContainer: isContainer,
);

MediaAudioTrack _plexAudio(
  int id, {
  int? index,
  String? language,
  String? languageCode,
  String? title,
  int? channels,
  bool selected = false,
  String? codec,
}) {
  return MediaAudioTrack(
    id: id,
    index: index,
    language: language,
    languageCode: languageCode ?? language,
    title: title,
    channels: channels,
    selected: selected,
    codec: codec,
  );
}

MediaSubtitleTrack _plexSub(
  int id, {
  int? index,
  String? language,
  String? languageCode,
  String? title,
  bool selected = false,
  bool forced = false,
  String? codec,
  bool external = false,
  String? key,
}) {
  return MediaSubtitleTrack(
    id: id,
    index: index,
    language: language,
    languageCode: languageCode ?? language,
    title: title,
    selected: selected,
    forced: forced,
    codec: codec,
    external: external,
    key: key,
  );
}

MediaSourceInfo _info({
  List<MediaAudioTrack>? audio,
  List<MediaSubtitleTrack>? subs,
  int? defaultAudioStreamIndex,
  int? defaultSubtitleStreamIndex,
}) => MediaSourceInfo(
  videoUrl: '',
  audioTracks: audio ?? const [],
  subtitleTracks: subs ?? const [],
  chapters: const [],
  defaultAudioStreamIndex: defaultAudioStreamIndex,
  defaultSubtitleStreamIndex: defaultSubtitleStreamIndex,
);

/// Minimal Player stub — TrackSelectionService never reads from the player
/// in any of the public-pure helpers we test.
class _StubPlayer implements Player {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrackSelectionService _svc({MediaItem? metadata, MediaServerUserProfile? profile, MediaSourceInfo? info}) {
  return TrackSelectionService(
    player: _StubPlayer(),
    metadata: metadata ?? _meta(),
    profileSettings: profile,
    plexMediaInfo: info,
  );
}

void main() {
  // ============================================================
  // languageMatches
  // ============================================================

  group('languageMatches', () {
    final svc = _svc();

    test('null on either side never matches', () {
      expect(svc.languageMatches(null, 'eng'), isFalse);
      expect(svc.languageMatches('eng', null), isFalse);
      expect(svc.languageMatches(null, null), isFalse);
    });

    test('case-insensitive direct match', () {
      expect(svc.languageMatches('ENG', 'eng'), isTrue);
      expect(svc.languageMatches('en', 'EN'), isTrue);
    });

    test('strips region suffix on both sides', () {
      expect(svc.languageMatches('en-US', 'en'), isTrue);
      expect(svc.languageMatches('en', 'en-AU'), isTrue);
      expect(svc.languageMatches('en-GB', 'en-US'), isTrue);
    });

    test('matches across ISO 639-1 ↔ 639-2 variations', () {
      // "en" ↔ "eng"
      expect(svc.languageMatches('en', 'eng'), isTrue);
      expect(svc.languageMatches('eng', 'en'), isTrue);
    });

    test('different languages do not match', () {
      expect(svc.languageMatches('en', 'fr'), isFalse);
      expect(svc.languageMatches('eng', 'fre'), isFalse);
    });
  });

  // ============================================================
  // findBestTrackMatch (via the audio/subtitle wrappers)
  // ============================================================

  group('findBestAudioMatch', () {
    final svc = _svc();

    test('exact id + title + language match wins', () {
      final tracks = [_audio('1', lang: 'eng', title: 'Stereo'), _audio('2', lang: 'eng', title: 'Surround')];
      final preferred = _audio('2', lang: 'eng', title: 'Surround');
      expect(svc.findBestAudioMatch(tracks, preferred), tracks[1]);
    });

    test('falls back to title + language when id differs', () {
      final tracks = [_audio('1', lang: 'eng', title: 'Stereo'), _audio('2', lang: 'eng', title: 'Surround')];
      // Different id but matching title+language → tracks[1].
      final preferred = _audio('999', lang: 'eng', title: 'Surround');
      expect(svc.findBestAudioMatch(tracks, preferred), tracks[1]);
    });

    test('falls back to language-only match', () {
      final tracks = [_audio('1', lang: 'eng', title: 'Stereo')];
      final preferred = _audio('999', lang: 'eng', title: 'Different');
      expect(svc.findBestAudioMatch(tracks, preferred), tracks[0]);
    });

    test('returns null when no language match exists', () {
      final tracks = [_audio('1', lang: 'fre')];
      final preferred = _audio('1', lang: 'eng');
      expect(svc.findBestAudioMatch(tracks, preferred), isNull);
    });

    test('filters out auto and no tracks before matching', () {
      final tracks = [AudioTrack.auto, AudioTrack.off, _audio('3', lang: 'eng')];
      final preferred = _audio('3', lang: 'eng');
      expect(svc.findBestAudioMatch(tracks, preferred), tracks[2]);
    });

    test('returns null on an empty list', () {
      expect(svc.findBestAudioMatch(const [], _audio('1', lang: 'eng')), isNull);
    });

    test('returns null when only auto/no tracks remain after filtering', () {
      expect(svc.findBestAudioMatch([AudioTrack.auto, AudioTrack.off], _audio('1', lang: 'eng')), isNull);
    });
  });

  group('findBestSubtitleMatch', () {
    final svc = _svc();

    test('preferred id="no" returns SubtitleTrack.off', () {
      // Even with non-empty available tracks, "no" preference always means off.
      final result = svc.findBestSubtitleMatch([_sub('1', lang: 'eng')], const SubtitleTrack(id: 'no'));
      expect(identical(result, SubtitleTrack.off), isTrue);
    });

    test('matches by language when title differs', () {
      final tracks = [_sub('1', lang: 'eng', title: 'English')];
      expect(svc.findBestSubtitleMatch(tracks, _sub('999', lang: 'eng', title: 'Other')), tracks[0]);
    });

    test('returns null on no match', () {
      expect(svc.findBestSubtitleMatch([_sub('1', lang: 'fre')], _sub('1', lang: 'eng')), isNull);
    });
  });

  // ============================================================
  // findAudioTrackByProfile
  // ============================================================

  group('findAudioTrackByProfile', () {
    final svc = _svc();

    test('returns null when autoSelectAudio is false', () {
      final profile = _profile(autoSelectAudio: false, defaultAudioLanguage: 'eng');
      expect(svc.findAudioTrackByProfile([_audio('1', lang: 'eng')], profile), isNull);
    });

    test('returns null when no preferred languages are configured', () {
      final profile = _profile(); // autoSelect=true, but no languages.
      expect(svc.findAudioTrackByProfile([_audio('1', lang: 'eng')], profile), isNull);
    });

    test('matches the primary defaultAudioLanguage first', () {
      final tracks = [_audio('1', lang: 'fre'), _audio('2', lang: 'eng')];
      final profile = _profile(defaultAudioLanguage: 'eng', defaultAudioLanguages: const ['fre']);
      expect(svc.findAudioTrackByProfile(tracks, profile), tracks[1]);
    });

    test('falls back to next language in list when primary is missing', () {
      final tracks = [_audio('1', lang: 'spa')];
      final profile = _profile(defaultAudioLanguage: 'eng', defaultAudioLanguages: const ['spa']);
      expect(svc.findAudioTrackByProfile(tracks, profile), tracks[0]);
    });

    test('returns null when none of the preferred languages match', () {
      final tracks = [_audio('1', lang: 'jpn')];
      final profile = _profile(defaultAudioLanguage: 'eng', defaultAudioLanguages: const ['fre']);
      expect(svc.findAudioTrackByProfile(tracks, profile), isNull);
    });

    test('returns null on empty available tracks', () {
      final profile = _profile(defaultAudioLanguage: 'eng');
      expect(svc.findAudioTrackByProfile(const [], profile), isNull);
    });
  });

  // ============================================================
  // selectAudioTrack — the priority cascade
  // ============================================================

  group('selectAudioTrack', () {
    test('returns null on empty available tracks', () {
      expect(_svc().selectAudioTrack(const [], _audio('1', lang: 'eng')), isNull);
    });

    test('Priority 1: preferred-from-navigation wins when matching', () {
      final tracks = [_audio('1', lang: 'fre'), _audio('2', lang: 'eng')];
      final result = _svc().selectAudioTrack(tracks, _audio('2', lang: 'eng'));
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.navigation);
      expect(result.track, tracks[1]);
    });

    test('Priority 2: Plex-selected track from media info', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final info = _info(
        audio: [
          _plexAudio(1, language: 'eng', languageCode: 'eng', selected: false),
          _plexAudio(2, language: 'fre', languageCode: 'fre', selected: true), // selected by Plex
        ],
      );
      // No preferred → Priority 1 misses; per-media + profile not provided →
      // matcher resolves on Plex's selected (French).
      final result = _svc(info: info).selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('Jellyfin selected audio stream wins over DefaultAudioStreamIndex', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final info = _info(
        defaultAudioStreamIndex: 1,
        audio: [
          _plexAudio(1, index: 1, language: 'eng', languageCode: 'eng'),
          _plexAudio(2, index: 2, language: 'fre', languageCode: 'fre', selected: true),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('Jellyfin DefaultAudioStreamIndex selects audio when selected flag is missing', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final info = _info(
        defaultAudioStreamIndex: 2,
        audio: [
          _plexAudio(1, index: 1, language: 'eng', languageCode: 'eng'),
          _plexAudio(2, index: 2, language: 'fre', languageCode: 'fre'),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('Priority 3: per-media audioLanguage from metadata', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final result = _svc(metadata: _meta(audioLanguage: 'fre')).selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.perMedia);
      expect(result.track.language, 'fre');
    });

    test('Priority 4: user profile when nothing higher matches', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final profile = _profile(defaultAudioLanguage: 'eng');
      final result = _svc(profile: profile).selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.profile);
      expect(result.track.language, 'eng');
    });

    test('Priority 5: default-flagged track as last resort', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre', isDefault: true)];
      final result = _svc().selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, 'B');
    });

    test('Priority 5: first track when none flagged default', () {
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final result = _svc().selectAudioTrack(tracks, null);
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, 'A');
    });

    test('preferred mismatch falls through to lower priority', () {
      // preferred has a language that is NOT in the available tracks — Priority 1
      // misses; Priority 5 picks the first track.
      final tracks = [_audio('A', lang: 'eng'), _audio('B', lang: 'fre')];
      final result = _svc().selectAudioTrack(tracks, _audio('Z', lang: 'jpn'));
      expect(result, isNotNull);
      expect(result!.priority, TrackSelectionPriority.defaultTrack);
    });
  });

  // ============================================================
  // selectSubtitleTrack
  // ============================================================

  group('selectSubtitleTrack', () {
    test('Priority 1: preferred id="no" forces subtitles off', () {
      final tracks = [_sub('1', lang: 'eng', isDefault: true)];
      final result = _svc().selectSubtitleTrack(tracks, const SubtitleTrack(id: 'no'), null)!;
      expect(result.priority, TrackSelectionPriority.navigation);
      expect(result.track.id, 'no');
    });

    test('Priority 1: preferred subtitle from navigation matches by language', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final result = _svc().selectSubtitleTrack(tracks, _sub('99', lang: 'fre'), null)!;
      expect(result.priority, TrackSelectionPriority.navigation);
      expect(result.track.id, '2');
    });

    test('Priority 2: Plex server-selected subtitle wins', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final info = _info(
        subs: [
          _plexSub(10, language: 'eng', languageCode: 'eng'),
          _plexSub(11, language: 'fre', languageCode: 'fre', selected: true),
        ],
      );
      final result = _svc(info: info).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('complete metadata-free direct catalog selects its unique native subtitle', () {
      final sourceTrack = _plexSub(20, codec: 'ass', selected: true);
      final info = _info(subs: [sourceTrack]);
      final nativeTrack = _sub('native-ass', codec: 'ass');
      final service = _svc(info: info);

      final preferredResult = service.selectSubtitleTrack(
        [nativeTrack],
        const SubtitleTrack(id: 'source:20', codec: 'ass'),
        null,
      )!;
      final serverResult = service.selectSubtitleTrack([nativeTrack], null, null)!;

      expect(preferredResult.priority, TrackSelectionPriority.navigation);
      expect(preferredResult.track, same(nativeTrack));
      expect(serverResult.priority, TrackSelectionPriority.serverSelected);
      expect(serverResult.track, same(nativeTrack));
      expect(findMpvTrackForPlexSubtitle(sourceTrack, [nativeTrack], allPlexTracks: [sourceTrack]), same(nativeTrack));
      expect(findPlexTrackForMpvSubtitle(nativeTrack, [sourceTrack], allMpvTracks: [nativeTrack]), same(sourceTrack));
    });

    test('complete low-metadata direct catalog uses facts instead of ordinal order', () {
      final sourceAss = _plexSub(30, codec: 'ass', selected: true);
      final sourceSrt = _plexSub(31, codec: 'srt');
      final plexTracks = [sourceAss, sourceSrt];
      final nativeSrt = _sub('native-srt', codec: 'srt');
      final nativeAss = _sub('native-ass', codec: 'ass');
      final nativeTracks = [nativeSrt, nativeAss];

      expect(findMpvTrackForPlexSubtitle(sourceAss, nativeTracks, allPlexTracks: plexTracks), same(nativeAss));
      expect(findPlexTrackForMpvSubtitle(nativeAss, plexTracks, allMpvTracks: nativeTracks), same(sourceAss));
    });

    test('ambiguous metadata-free direct catalog does not use ordinal fallback', () {
      final selectedSource = _plexSub(40, codec: 'ass', selected: true);
      final otherSource = _plexSub(41, codec: 'ass');
      final plexTracks = [selectedSource, otherSource];
      final nativeTracks = [_sub('native-second', codec: 'ass'), _sub('native-first', codec: 'ass')];
      final service = _svc(info: _info(subs: plexTracks));

      expect(findMpvTrackForPlexSubtitle(selectedSource, nativeTracks, allPlexTracks: plexTracks), isNull);
      expect(findPlexTrackForMpvSubtitle(nativeTracks.first, plexTracks, allMpvTracks: nativeTracks), isNull);

      final preferredResult = service.selectSubtitleTrack(
        nativeTracks,
        const SubtitleTrack(id: 'source:40', codec: 'ass'),
        null,
      )!;
      final serverResult = service.selectSubtitleTrack(nativeTracks, null, null)!;

      expect(preferredResult.priority, TrackSelectionPriority.off);
      expect(preferredResult.track.id, SubtitleTrack.off.id);
      expect(serverResult.priority, TrackSelectionPriority.off);
      expect(serverResult.track.id, SubtitleTrack.off.id);
    });

    test('ambiguous complete direct catalog falls through to native default', () {
      final plexTracks = [_plexSub(50, codec: 'ass', selected: true), _plexSub(51, codec: 'ass')];
      final nativeTracks = [_sub('native-first', codec: 'ass'), _sub('native-default', codec: 'ass', isDefault: true)];

      final result = _svc(
        info: _info(subs: plexTracks),
      ).selectSubtitleTrack(nativeTracks, const SubtitleTrack(id: 'source:50', codec: 'ass'), null)!;

      expect(result.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, 'native-default');
    });

    test('partial metadata-free direct catalog remains pending', () {
      final plexTracks = [_plexSub(60, codec: 'ass', selected: true), _plexSub(61, codec: 'ass')];
      final nativeTracks = [_sub('native-only', codec: 'ass', isDefault: true)];
      final service = _svc(info: _info(subs: plexTracks));

      expect(
        service.selectSubtitleTrack(nativeTracks, const SubtitleTrack(id: 'source:60', codec: 'ass'), null),
        isNull,
      );
      expect(service.selectSubtitleTrack(nativeTracks, null, null), isNull);
    });

    test('partial native catalog stays undetermined until the selected Plex track arrives', () {
      final info = _info(
        subs: [
          _plexSub(10, language: 'eng', selected: true),
          _plexSub(11, language: 'fre'),
        ],
      );

      final result = _svc(info: info).selectSubtitleTrack([_sub('2', lang: 'fre')], null, null);

      expect(result, isNull);
    });

    test('preferred source waits for its ordinal in a partial identical container catalog', () {
      final info = _info(
        subs: [
          _plexSub(30, index: 0, language: 'eng', title: 'English', codec: 'ass'),
          _plexSub(31, index: 1, language: 'eng', title: 'English', codec: 'ass', selected: true),
        ],
      );
      const preferred = SubtitleTrack(
        id: 'source:31',
        language: 'eng',
        title: 'English',
        codec: 'ass',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.test/video.mkv',
      );
      const first = SubtitleTrack(
        id: 'native-0',
        language: 'eng',
        title: 'English',
        codec: 'ass',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.test/video.mkv',
      );
      const second = SubtitleTrack(
        id: 'native-1',
        language: 'eng',
        title: 'English',
        codec: 'ass',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.test/video.mkv',
      );
      final service = _svc(info: info);

      expect(service.selectSubtitleTrack(const [first], preferred, null), isNull);
      expect(service.selectSubtitleTrack(const [first, second], preferred, null)?.track.id, 'native-1');
    });

    test('preferred keyed source does not fuzzy-match an early same-language container track', () {
      final info = _info(
        subs: [
          _plexSub(10, language: 'eng', codec: 'srt', external: true, key: '/library/streams/10'),
          _plexSub(11, language: 'eng', codec: 'srt'),
        ],
      );
      const preferred = SubtitleTrack(
        id: 'source:10',
        language: 'eng',
        codec: 'srt',
        isExternal: true,
        uri: 'https://example.test/library/streams/10.srt',
      );
      const earlyContainer = SubtitleTrack(
        id: 'native-0',
        language: 'eng',
        codec: 'srt',
        isExternal: true,
        isContainer: true,
        uri: 'https://example.test/video.mkv',
      );

      expect(_svc(info: info).selectSubtitleTrack(const [earlyContainer], preferred, null), isNull);
    });

    test('Jellyfin selected subtitle stream wins over DefaultSubtitleStreamIndex', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final info = _info(
        defaultSubtitleStreamIndex: 10,
        subs: [
          _plexSub(10, index: 10, language: 'eng', languageCode: 'eng'),
          _plexSub(11, index: 11, language: 'fre', languageCode: 'fre', selected: true),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('Priority 2: Plex media info has subs but none selected → off', () {
      // Server's explicit decision: there ARE subs but the user opted out.
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final info = _info(
        subs: [
          _plexSub(10, language: 'eng'),
          _plexSub(11, language: 'fre'),
        ],
      );
      final result = _svc(info: info).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.id, 'no');
    });

    test('Jellyfin media info with subs but none selected falls through to default fallback', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre', isDefault: true)];
      final info = _info(
        subs: [
          _plexSub(10, language: 'eng'),
          _plexSub(11, language: 'fre'),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, '2');
    });

    test('Jellyfin DefaultSubtitleStreamIndex selects subtitle when selected flag is missing', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final info = _info(
        defaultSubtitleStreamIndex: 11,
        subs: [
          _plexSub(10, index: 10, language: 'eng', languageCode: 'eng'),
          _plexSub(11, index: 11, language: 'fre', languageCode: 'fre'),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.language, 'fre');
    });

    test('Jellyfin explicit DefaultSubtitleStreamIndex=-1 forces subtitles off', () {
      final tracks = [_sub('1', lang: 'eng', isDefault: true), _sub('2', lang: 'fre')];
      final info = _info(
        defaultSubtitleStreamIndex: -1,
        subs: [
          _plexSub(10, language: 'eng'),
          _plexSub(11, language: 'fre'),
        ],
      );
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        info: info,
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.serverSelected);
      expect(result.track.id, 'no');
    });

    test('Jellyfin SubtitleMode.None forces subtitles off', () {
      final tracks = [_sub('1', lang: 'eng', isDefault: true)];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(defaultSubtitleLanguage: 'eng', subtitleMode: SubtitlePlaybackMode.none),
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, 'no');
    });

    test('Jellyfin SubtitleMode.OnlyForced selects matching forced subtitle', () {
      final tracks = [
        _sub('1', lang: 'eng'),
        _sub('2', lang: 'eng', isForced: true),
        _sub('3', lang: 'jpn', isForced: true),
      ];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(defaultSubtitleLanguage: 'eng', subtitleMode: SubtitlePlaybackMode.onlyForced),
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, '2');
    });

    test('Jellyfin SubtitleMode.OnlyForced turns off when no forced subtitle exists', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'jpn')];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(defaultSubtitleLanguage: 'eng', subtitleMode: SubtitlePlaybackMode.onlyForced),
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, 'no');
    });

    test('Jellyfin SubtitleMode.Always selects preferred subtitle language', () {
      final tracks = [_sub('1', lang: 'jpn'), _sub('2', lang: 'eng')];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(defaultSubtitleLanguage: 'eng', subtitleMode: SubtitlePlaybackMode.always),
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, '2');
    });

    test('Jellyfin SubtitleMode.Always falls back to default then first subtitle', () {
      final tracks = [_sub('1', lang: 'jpn'), _sub('2', lang: 'fre', isDefault: true)];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(defaultSubtitleLanguage: 'eng', subtitleMode: SubtitlePlaybackMode.always),
      ).selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, '2');
    });

    test('Jellyfin SubtitleMode.Smart uses forced subtitle when audio matches preferred language', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'eng', isForced: true)];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(
          defaultAudioLanguage: 'eng',
          defaultSubtitleLanguage: 'eng',
          subtitleMode: SubtitlePlaybackMode.smart,
        ),
      ).selectSubtitleTrack(tracks, null, _audio('A', lang: 'eng'))!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, '2');
    });

    test('Jellyfin SubtitleMode.Smart uses preferred subtitle when audio differs', () {
      final tracks = [_sub('1', lang: 'jpn'), _sub('2', lang: 'eng')];
      final result = _svc(
        metadata: _meta(backend: MediaBackend.jellyfin),
        profile: _jellyfinProfile(
          defaultAudioLanguage: 'eng',
          defaultSubtitleLanguage: 'eng',
          subtitleMode: SubtitlePlaybackMode.smart,
        ),
      ).selectSubtitleTrack(tracks, null, _audio('A', lang: 'jpn'))!;
      expect(result.priority, TrackSelectionPriority.profile);
      expect(result.track.id, '2');
    });

    test('Priority 3: default-flagged track when no Plex info', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre', isDefault: true)];
      final result = _svc().selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, '2');
    });

    test('Priority 4: off when no default and no info', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final result = _svc().selectSubtitleTrack(tracks, null, null)!;
      expect(result.priority, TrackSelectionPriority.off);
      expect(result.track.id, 'no');
    });

    test('Priority 4: off when no available tracks at all', () {
      final result = _svc().selectSubtitleTrack(const [], null, null)!;
      expect(result.priority, TrackSelectionPriority.off);
      expect(result.track.id, 'no');
    });

    test('empty native track list remains undetermined when Plex advertises subtitles', () {
      final info = _info(subs: [_plexSub(10, language: 'eng', selected: true)]);

      final result = _svc(info: info).selectSubtitleTrack(const [], null, null);

      expect(result, isNull);
    });

    test('empty native track list is also undetermined when Plex selected no subtitle', () {
      final info = _info(subs: [_plexSub(10, language: 'eng')]);

      final result = _svc(info: info).selectSubtitleTrack(const [], null, null);

      expect(result, isNull);
    });

    test('selected keyed sidecar remains pending when only a same-language container has arrived', () {
      final info = _info(
        subs: [_plexSub(10, language: 'eng', selected: true, external: true, key: '/library/streams/10')],
      );
      final earlyContainer = _sub('20', lang: 'eng', isExternal: true, isContainer: true);

      final result = _svc(info: info).selectSubtitleTrack([earlyContainer], null, null);

      expect(result, isNull);
    });
  });

  // ============================================================
  // findPlexTrackForMpvSubtitle / findPlexTrackForMpvAudio — same-language
  // disambiguation (regression for #1443). The player reports null titles for
  // MKV tracks that carry only a forced flag, so the forced flag (+2) and the
  // ordinal tiebreaker (+1) must separate two tracks that share a language.
  // ============================================================

  group('findPlexTrackForMpvSubtitle - forced disambiguation', () {
    // Disposition-flagged forced track: forced is set in the container, so both
    // Plex and the player carry forced=true on the forced track.
    test('disposition-flagged forced track maps via the forced flag', () {
      final plexTracks = [
        _plexSub(10, index: 0, languageCode: 'fre', codec: 'ass', forced: false),
        _plexSub(11, index: 1, languageCode: 'fre', codec: 'ass', forced: true),
      ];
      final mpvNonForced = _sub('2_0', lang: 'fre', codec: 'ass');
      final mpvForced = _sub('2_1', lang: 'fre', codec: 'ass', isForced: true);
      final allMpv = [mpvNonForced, mpvForced];

      expect(findPlexTrackForMpvSubtitle(mpvForced, plexTracks, allMpvTracks: allMpv)?.id, 11);
      expect(findPlexTrackForMpvSubtitle(mpvNonForced, plexTracks, allMpvTracks: allMpv)?.id, 10);
    });

    // Title-only "forced" track — the exact #1443 file (MKVToolNix screenshot):
    // the forced sub is NOT flagged forced in the container, it only carries the
    // name "Forced"; the regular French sub has an empty name. Both sides report
    // forced=false, so disambiguation rides on title (forced sub) and ordinal
    // position (the empty-title regular sub).
    test('title-only forced track and empty-title regular track stay distinct (#1443)', () {
      final plexTracks = [
        _plexSub(30, index: 0, languageCode: 'fre', title: 'Forced', codec: 'ass', forced: false),
        _plexSub(31, index: 1, languageCode: 'fre', codec: 'ass', forced: false),
        _plexSub(32, index: 2, languageCode: 'eng', title: 'SDH', codec: 'ass', forced: false),
      ];
      final mpvForcedByName = _sub('2_0', lang: 'fre', title: 'Forced', codec: 'ass');
      final mpvRegular = _sub('2_1', lang: 'fre', codec: 'ass');
      final mpvSdh = _sub('2_2', lang: 'eng', title: 'SDH', codec: 'ass');
      final allMpv = [mpvForcedByName, mpvRegular, mpvSdh];

      expect(findPlexTrackForMpvSubtitle(mpvForcedByName, plexTracks, allMpvTracks: allMpv)?.id, 30);
      expect(findPlexTrackForMpvSubtitle(mpvRegular, plexTracks, allMpvTracks: allMpv)?.id, 31);
    });
  });

  group('container-sidecar ordinal fallback', () {
    final plexTracks = [_plexSub(40, index: 0), _plexSub(41, index: 1)];
    final nativeTracks = [
      _sub('2_0', isExternal: true, isContainer: true),
      _sub('2_1', isExternal: true, isContainer: true),
    ];

    test('maps a metadata-free Plex stream to its container track', () {
      expect(findMpvTrackForPlexSubtitle(plexTracks[1], nativeTracks, allPlexTracks: plexTracks), nativeTracks[1]);
    });

    test('maps a metadata-free container track back to its Plex stream', () {
      expect(findPlexTrackForMpvSubtitle(nativeTracks[0], plexTracks, allMpvTracks: nativeTracks)?.id, 40);
    });
  });

  group('findPlexTrackForMpvAudio - same-language disambiguation', () {
    // Two French audio tracks differing only by channel count, titles null.
    final plexTracks = [
      _plexAudio(20, index: 0, languageCode: 'fre', codec: 'ac3', channels: 2),
      _plexAudio(21, index: 1, languageCode: 'fre', codec: 'ac3', channels: 6),
    ];
    final mpvStereo = _audio('1_0', lang: 'fre', codec: 'ac3', channels: 2);
    final mpvSurround = _audio('1_1', lang: 'fre', codec: 'ac3', channels: 6);
    final allMpv = [mpvStereo, mpvSurround];

    test('surround player track maps to the 6-channel Plex stream', () {
      final match = findPlexTrackForMpvAudio(mpvSurround, plexTracks, allMpvTracks: allMpv);
      expect(match?.id, 21);
    });

    test('stereo player track maps to the 2-channel Plex stream', () {
      final match = findPlexTrackForMpvAudio(mpvStereo, plexTracks, allMpvTracks: allMpv);
      expect(match?.id, 20);
    });
  });
}
