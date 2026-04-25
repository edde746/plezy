import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_media_info.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/models/plex_user_profile.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/track_selection_service.dart';

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
// Top-level matching helpers (`findMpvTrackForPlexAudio`,
// `findPlexTrackForMpvAudio`, `findMpvTrackForPlexSubtitle`,
// `findPlexTrackForMpvSubtitle`) are exercised indirectly through
// `selectAudioTrack` (Priority 2) and `selectSubtitleTrack` (Priority 2).
//
// What's NOT covered:
//   - `selectAndApplyTracks` — depends on a real Player + SettingsService
//     singleton + `player.streams.tracks`. Out of scope for a unit test.

// ============================================================
// Fixtures
// ============================================================

PlexMetadata _meta({String? audioLanguage, String? subtitleLanguage}) =>
    PlexMetadata(ratingKey: 'rk1', audioLanguage: audioLanguage, subtitleLanguage: subtitleLanguage);

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

AudioTrack _audio(String id, {String? lang, String? title, String? codec, int? channels, bool isDefault = false}) =>
    AudioTrack(id: id, language: lang, title: title, codec: codec, channels: channels, isDefault: isDefault);

SubtitleTrack _sub(String id, {String? lang, String? title, String? codec, bool isDefault = false}) =>
    SubtitleTrack(id: id, language: lang, title: title, codec: codec, isDefault: isDefault);

PlexAudioTrack _plexAudio(
  int id, {
  String? language,
  String? languageCode,
  String? title,
  int? channels,
  bool selected = false,
  String? codec,
}) {
  return PlexAudioTrack(
    id: id,
    language: language,
    languageCode: languageCode ?? language,
    title: title,
    channels: channels,
    selected: selected,
    codec: codec,
  );
}

PlexSubtitleTrack _plexSub(
  int id, {
  String? language,
  String? languageCode,
  String? title,
  bool selected = false,
  bool forced = false,
  String? codec,
}) {
  return PlexSubtitleTrack(
    id: id,
    language: language,
    languageCode: languageCode ?? language,
    title: title,
    selected: selected,
    forced: forced,
    codec: codec,
  );
}

PlexMediaInfo _info({List<PlexAudioTrack>? audio, List<PlexSubtitleTrack>? subs}) =>
    PlexMediaInfo(videoUrl: '', audioTracks: audio ?? const [], subtitleTracks: subs ?? const [], chapters: const []);

/// Minimal Player stub — TrackSelectionService never reads from the player
/// in any of the public-pure helpers we test.
class _StubPlayer implements Player {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrackSelectionService _svc({PlexMetadata? metadata, PlexUserProfile? profile, PlexMediaInfo? info}) {
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
      expect(result!.priority, TrackSelectionPriority.plexSelected);
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
      final result = _svc().selectSubtitleTrack(tracks, const SubtitleTrack(id: 'no'), null);
      expect(result.priority, TrackSelectionPriority.navigation);
      expect(result.track.id, 'no');
    });

    test('Priority 1: preferred subtitle from navigation matches by language', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final result = _svc().selectSubtitleTrack(tracks, _sub('99', lang: 'fre'), null);
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
      final result = _svc(info: info).selectSubtitleTrack(tracks, null, null);
      expect(result.priority, TrackSelectionPriority.plexSelected);
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
      final result = _svc(info: info).selectSubtitleTrack(tracks, null, null);
      expect(result.priority, TrackSelectionPriority.plexSelected);
      expect(result.track.id, 'no');
    });

    test('Priority 3: default-flagged track when no Plex info', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre', isDefault: true)];
      final result = _svc().selectSubtitleTrack(tracks, null, null);
      expect(result.priority, TrackSelectionPriority.defaultTrack);
      expect(result.track.id, '2');
    });

    test('Priority 4: off when no default and no info', () {
      final tracks = [_sub('1', lang: 'eng'), _sub('2', lang: 'fre')];
      final result = _svc().selectSubtitleTrack(tracks, null, null);
      expect(result.priority, TrackSelectionPriority.off);
      expect(result.track.id, 'no');
    });

    test('Priority 4: off when no available tracks at all', () {
      final result = _svc().selectSubtitleTrack(const [], null, null);
      expect(result.priority, TrackSelectionPriority.off);
      expect(result.track.id, 'no');
    });
  });
}
