import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/jellyfin/jellyfin_user_profile.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/jellyfin_media_info_mapper.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/services/subtitle_preference.dart';

import '../test_helpers/media_items.dart';

MediaSubtitleTrack _sourceSubtitle(
  int id, {
  String language = 'eng',
  String codec = 'srt',
  bool forced = false,
  bool selected = false,
  bool external = false,
  bool usesExternalDelivery = false,
  String? key,
  String? title,
}) {
  return MediaSubtitleTrack(
    id: id,
    language: language,
    languageCode: language,
    codec: codec,
    title: title ?? 'Subtitle $id',
    selected: selected,
    forced: forced,
    // Mirrors JellyfinFileInfoStreamReader: the server ships a delivery URL
    // with every row it marks external, and _sidecar's URL contains it.
    key: key ?? (external || usesExternalDelivery ? '/subtitles/$id.srt' : null),
    external: external,
    usesExternalDelivery: usesExternalDelivery,
  );
}

PlaybackSubtitleSidecar _sidecar(
  int id, {
  String language = 'eng',
  bool isDefault = false,
  bool preload = false,
  bool isContainer = false,
  String? uri,
}) {
  final sidecarUri = uri ?? 'https://example.test/subtitles/$id.srt';
  return PlaybackSubtitleSidecar(
    sourceStreamId: id,
    preload: preload,
    track: isContainer
        ? SubtitleTrack(
            id: 'container:$id',
            title: 'Subtitle $id',
            language: language,
            codec: 'srt',
            isDefault: isDefault,
            isExternal: true,
            isContainer: true,
            uri: sidecarUri,
          )
        : SubtitleTrack.uri(sidecarUri, title: 'Subtitle $id', language: language, codec: 'srt', isDefault: isDefault),
  );
}

MediaSourceInfo _mediaInfo(List<MediaSubtitleTrack> subtitles) {
  return MediaSourceInfo(videoUrl: '', audioTracks: const [], subtitleTracks: subtitles, chapters: const []);
}

void main() {
  group('source subtitle routing', () {
    test('matches an embedded source to its loaded native track', () {
      final source = _sourceSubtitle(2, language: 'eng');
      const native = SubtitleTrack(id: '7', language: 'eng', codec: 'srt');

      expect(
        PlaybackSubtitleResolver.nativeTrackForSource(
          sourceTrack: source,
          nativeTracks: const [native],
          allSourceTracks: [source],
          isResolvedSidecar: false,
          isContainerSidecar: false,
        ),
        native,
      );
    });

    test('does not fuzzy-match a different loaded external sidecar', () {
      final source = MediaSubtitleTrack(
        id: 2,
        codec: 'srt',
        languageCode: 'eng',
        key: '/library/streams/2',
        external: true,
        selected: false,
        forced: false,
      );
      const other = SubtitleTrack(
        id: '9',
        language: 'eng',
        codec: 'srt',
        isExternal: true,
        uri: 'https://server/library/streams/9.srt',
      );

      expect(
        PlaybackSubtitleResolver.nativeTrackForSource(
          sourceTrack: source,
          nativeTracks: const [other],
          allSourceTracks: [source],
          isResolvedSidecar: true,
          isContainerSidecar: false,
        ),
        isNull,
      );
    });

    test('cycles through typed off and every authoritative source id, including zero', () {
      final tracks = [_sourceSubtitle(0), _sourceSubtitle(2)];

      expect(
        PlaybackSubtitleResolver.advanceSourceChoice(tracks, const PlaybackSourceSubtitleChoice.off(), 1),
        const PlaybackSourceSubtitleChoice.source(0),
      );
      expect(
        PlaybackSubtitleResolver.advanceSourceChoice(tracks, const PlaybackSourceSubtitleChoice.source(0), 1),
        const PlaybackSourceSubtitleChoice.source(2),
      );
      expect(
        PlaybackSubtitleResolver.advanceSourceChoice(tracks, const PlaybackSourceSubtitleChoice.source(2), 1),
        const PlaybackSourceSubtitleChoice.off(),
      );
      expect(
        PlaybackSubtitleResolver.advanceSourceChoice(tracks, const PlaybackSourceSubtitleChoice.off(), 4),
        const PlaybackSourceSubtitleChoice.source(0),
      );
    });

    test('fuzzy-matches a Jellyfin external-delivery row once direct play strips its sidecar identity', () {
      // JellyfinClient.getPlaybackInitialization normalizes rows it did not
      // fetch as sidecars, which is what makes the embedded stream reachable.
      final source = _sourceSubtitle(2, language: 'eng', usesExternalDelivery: true).withoutSidecarIdentity();
      const native = SubtitleTrack(id: '7', language: 'eng', codec: 'srt');

      expect(
        PlaybackSubtitleResolver.nativeTrackForSource(
          sourceTrack: source,
          nativeTracks: const [native],
          allSourceTracks: [source],
          isResolvedSidecar: false,
          isContainerSidecar: false,
        ),
        native,
      );
    });

    test('a row that kept its sidecar identity never fuzzy-matches a native track', () {
      final source = _sourceSubtitle(2, language: 'eng', usesExternalDelivery: true);
      const native = SubtitleTrack(id: '7', language: 'eng', codec: 'srt');

      expect(
        PlaybackSubtitleResolver.nativeTrackForSource(
          sourceTrack: source,
          nativeTracks: const [native],
          allSourceTracks: [source],
          isResolvedSidecar: false,
          isContainerSidecar: false,
        ),
        isNull,
      );
    });

    test('matches a requested source among tracks from one container sidecar', () {
      final sources = [_sourceSubtitle(2, language: 'eng'), _sourceSubtitle(3, language: 'eng')];
      const nativeTracks = [
        SubtitleTrack(
          id: '7',
          title: 'Subtitle 2',
          language: 'eng',
          codec: 'srt',
          isExternal: true,
          isContainer: true,
          uri: 'https://example.test/video.mkv',
        ),
        SubtitleTrack(
          id: '8',
          title: 'Subtitle 3',
          language: 'eng',
          codec: 'srt',
          isExternal: true,
          isContainer: true,
          uri: 'https://example.test/video.mkv',
        ),
      ];

      expect(
        PlaybackSubtitleResolver.nativeTrackForSource(
          sourceTrack: sources.last,
          nativeTracks: nativeTracks,
          allSourceTracks: sources,
          isResolvedSidecar: true,
          isContainerSidecar: true,
        ),
        nativeTracks.last,
      );
    });
  });

  final metadata = testMediaItem(id: 'movie-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie);

  test('attaches only the server-selected sidecar from the full catalog', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([
        _sourceSubtitle(2, selected: true, usesExternalDelivery: true),
        _sourceSubtitle(3, language: 'swe', usesExternalDelivery: true),
      ]),
      sidecars: [
        _sidecar(2),
        _sidecar(3, language: 'swe'),
      ],
    );

    expect(result.primarySourceStreamId, 2);
    expect(result.sidecarsAtOpen, hasLength(1));
    expect(result.sidecarsAtOpen.single.uri, 'https://example.test/subtitles/2.srt');
  });

  test('a transcode drops a carried secondary it cannot deliver', () {
    // The burn covers the primary, and an embedded secondary has neither a sidecar to fetch nor a
    // native track to land on. Kept selected, it made `TrackManager` wait out its thirty-second
    // deadline and then read as active while nothing was on screen.
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true), _sourceSubtitle(3, language: 'swe')]),
      sidecars: const [],
      preferredSecondarySubtitleTrack: SubtitlePreference.track(const SubtitleTrack(id: 'source:3', language: 'swe')),
      isTranscoding: true,
    );

    expect(result.secondaryTrack, isNull, reason: 'nothing can carry it, so it must not stay selected');
    expect(result.secondarySourceStreamId, isNull);
  });

  test('a direct play keeps a carried secondary the player can select natively', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true), _sourceSubtitle(3, language: 'swe')]),
      sidecars: const [],
      preferredSecondarySubtitleTrack: SubtitlePreference.track(const SubtitleTrack(id: 'source:3', language: 'swe')),
    );

    expect(result.secondarySourceStreamId, 3, reason: 'the container still carries it');
  });

  test('explicit off produces an open with zero sidecars', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true, usesExternalDelivery: true)]),
      sidecars: [_sidecar(2)],
      preferredSubtitleTrack: const SubtitlePreference.off(),
    );

    expect(result.isOff, isTrue);
    expect(result.sidecarsAtOpen, isEmpty);
  });

  group('Jellyfin server subtitle answer', () {
    // Verbatim shape of a direct-played episode from a real Jellyfin server:
    // the container flags one row default+forced, and the response carries the
    // index the server picked for this user (null when it picked none).
    MediaSourceInfo jellyfinInfo({Object? defaultSubtitleStreamIndex}) => jellyfinMediaSourceToMediaSourceInfo({
      'Id': 'src-1',
      'DefaultSubtitleStreamIndex': defaultSubtitleStreamIndex,
      'MediaStreams': [
        {'Index': 1, 'Type': 'Audio', 'Language': 'eng', 'IsDefault': true},
        {'Index': 3, 'Type': 'Subtitle', 'Language': 'eng', 'Codec': 'ass', 'IsDefault': true, 'IsForced': true},
        {'Index': 4, 'Type': 'Subtitle', 'Language': 'eng', 'Codec': 'ass'},
      ],
    });

    JellyfinUserProfile profileWithMode(String mode) => JellyfinUserProfile.fromUserDto({
      'Configuration': {'SubtitleMode': mode, 'PlayDefaultAudioTrack': true},
    });

    test('a user who turned subtitles off on the server gets none (#1779)', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: jellyfinInfo(),
        sidecars: const [],
        profileSettings: profileWithMode('None'),
      );

      expect(result.isOff, isTrue);
    });

    test('the stream the server did pick still plays', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: jellyfinInfo(defaultSubtitleStreamIndex: 3),
        sidecars: const [],
        profileSettings: profileWithMode('Default'),
      );

      expect(result.isOff, isFalse);
      expect(result.primarySourceStreamId, 3);
    });

    test('an off persisted through progress reports plays nothing', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: jellyfinInfo(defaultSubtitleStreamIndex: -1),
        sidecars: const [],
        profileSettings: profileWithMode('Default'),
      );

      expect(result.isOff, isTrue);
    });
  });

  test('retains each source metadata row for a shared preloaded container', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true), _sourceSubtitle(3)]),
      sidecars: [
        _sidecar(2, preload: true, isContainer: true, uri: 'https://example.test/video.mkv'),
        _sidecar(3, preload: true, isContainer: true, uri: 'https://example.test/video.mkv'),
      ],
      preferredSubtitleTrack: const SubtitlePreference.off(),
    );

    expect(result.isOff, isTrue);
    expect(result.sidecarsAtOpen, hasLength(2));
    expect(result.sidecarsAtOpen.every((track) => track.isContainer), isTrue);
    expect(result.sidecarsAtOpen.map((track) => track.id), ['container:2', 'container:3']);
    expect(result.sidecarsAtOpen.map((track) => track.uri).toSet(), {'https://example.test/video.mkv'});
  });

  test('explicit source selection wins over the server default', () {
    final mediaInfo = _mediaInfo([
      _sourceSubtitle(2, selected: true, usesExternalDelivery: true),
      _sourceSubtitle(3, language: 'swe', usesExternalDelivery: true),
    ]);
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: mediaInfo,
      sidecars: [
        _sidecar(2),
        _sidecar(3, language: 'swe'),
      ],
      preferredSubtitleTrack: SubtitlePreference.trackOrNull(
        PlaybackSubtitleResolver.preferredTrackForSource(mediaInfo, 3),
      ),
    );

    expect(result.primarySourceStreamId, 3);
    expect(result.sidecarsAtOpen.single.uri, 'https://example.test/subtitles/3.srt');
  });

  test('explicit source identity wins when subtitle metadata is identical', () {
    final mediaInfo = _mediaInfo([
      MediaSubtitleTrack(
        id: 2,
        language: 'eng',
        languageCode: 'eng',
        codec: 'ass',
        title: 'English',
        selected: true,
        forced: false,
      ),
      MediaSubtitleTrack(
        id: 3,
        language: 'eng',
        languageCode: 'eng',
        codec: 'ass',
        title: 'English',
        selected: false,
        forced: false,
      ),
    ]);
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: mediaInfo,
      sidecars: [
        _sidecar(2, isContainer: true, uri: 'https://example.test/video.mkv'),
        _sidecar(3, isContainer: true, uri: 'https://example.test/video.mkv'),
      ],
      preferredSubtitleTrack: SubtitlePreference.trackOrNull(
        PlaybackSubtitleResolver.preferredTrackForSource(mediaInfo, 3),
      ),
    );

    expect(result.primarySourceStreamId, 3);
  });

  test('source identity is ignored across media-source changes', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([
        _sourceSubtitle(3, language: 'eng', selected: true, usesExternalDelivery: true),
        _sourceSubtitle(7, language: 'fra', usesExternalDelivery: true),
      ]),
      sidecars: [
        _sidecar(3),
        _sidecar(7, language: 'fra'),
      ],
      preferredSubtitleTrack: const SubtitlePreference.track(
        SubtitleTrack(
          id: 'source:3',
          title: 'French from the previous source',
          language: 'fra',
          codec: 'srt',
          isExternal: true,
          uri: 'https://example.test/previous/3.srt',
        ),
      ),
      preserveSourceIdentity: false,
    );

    expect(result.primarySourceStreamId, 7);
  });

  test('unmatched source identity cannot bind a reused id after a source change', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(3, language: 'eng'), _sourceSubtitle(7, language: 'spa', selected: true)]),
      sidecars: const [],
      preferredSubtitleTrack: const SubtitlePreference.track(
        SubtitleTrack(id: 'source:3', title: 'French from the previous source', language: 'fra', codec: 'srt'),
      ),
      preserveSourceIdentity: false,
    );

    expect(result.primarySourceStreamId, 7);
  });

  test('item-change semantic preference selects the matching new sidecar', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([
        _sourceSubtitle(7, language: 'eng', usesExternalDelivery: true),
        _sourceSubtitle(9, language: 'fra', usesExternalDelivery: true),
      ]),
      sidecars: [
        _sidecar(7),
        _sidecar(9, language: 'fra'),
      ],
      preferredSubtitleTrack: const SubtitlePreference.intent(
        SubtitleIntent(
          language: 'eng',
          forced: false,
          title: 'English from the previous episode',
          codec: 'srt',
          isExternal: true,
        ),
      ),
    );

    expect(result.primarySourceStreamId, 7);
    expect(result.primarySidecar?.track.uri, 'https://example.test/subtitles/7.srt');
    expect(result.sidecarsAtOpen, hasLength(1));
  });

  test('item-change semantic preference distinguishes forced and full subtitles in one language', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([
        _sourceSubtitle(7, language: 'eng', usesExternalDelivery: true),
        _sourceSubtitle(8, language: 'eng', forced: true, usesExternalDelivery: true),
      ]),
      sidecars: [_sidecar(7), _sidecar(8)],
      preferredSubtitleTrack: const SubtitlePreference.intent(
        SubtitleIntent(
          language: 'eng',
          forced: true,
          title: 'English forced from the previous episode',
          codec: 'srt',
          isExternal: true,
        ),
      ),
    );

    expect(result.primarySourceStreamId, 8);
    expect(result.primaryTrack.isForced, isTrue);
    expect(result.primarySidecar?.track.uri, 'https://example.test/subtitles/8.srt');
  });

  group('issue #1716/#1717 forced-class carry-over', () {
    const forcedIntent = SubtitlePreference.intent(
      SubtitleIntent(language: 'fra', forced: true, title: 'FR Forced [ASS]', codec: 'srt', isExternal: true),
    );

    test("picks the next episode's title-only forced row", () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([
          _sourceSubtitle(7, language: 'fra', usesExternalDelivery: true),
          _sourceSubtitle(8, language: 'fra', title: 'FR Forced', usesExternalDelivery: true),
        ]),
        sidecars: [
          _sidecar(7, language: 'fra'),
          _sidecar(8, language: 'fra'),
        ],
        preferredSubtitleTrack: forcedIntent,
      );

      expect(result.primarySourceStreamId, 8);
      expect(result.primaryTrack.isForced, isTrue);
    });

    test('picks a flag-forced row for a title-forced intent (cross-form)', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([
          _sourceSubtitle(7, language: 'fra', usesExternalDelivery: true),
          _sourceSubtitle(8, language: 'fra', forced: true, usesExternalDelivery: true),
        ]),
        sidecars: [
          _sidecar(7, language: 'fra'),
          _sidecar(8, language: 'fra'),
        ],
        preferredSubtitleTrack: forcedIntent,
      );

      expect(result.primarySourceStreamId, 8);
    });

    test('declines to the server-selected full row when no forced row exists', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([
          _sourceSubtitle(7, language: 'fra', selected: true, usesExternalDelivery: true),
          _sourceSubtitle(9, language: 'eng', usesExternalDelivery: true),
        ]),
        sidecars: [
          _sidecar(7, language: 'fra'),
          _sidecar(9),
        ],
        preferredSubtitleTrack: forcedIntent,
      );

      expect(result.primarySourceStreamId, 7);
    });

    test('subtitles stay off when no forced row exists and nothing is selected', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([_sourceSubtitle(7, language: 'fra', usesExternalDelivery: true)]),
        sidecars: [_sidecar(7, language: 'fra')],
        preferredSubtitleTrack: forcedIntent,
      );

      expect(result.isOff, isTrue);
    });

    test('a full intent does not inherit a forced-only catalog (symmetric)', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([
          _sourceSubtitle(8, language: 'fra', title: 'FR Forced', usesExternalDelivery: true),
          _sourceSubtitle(9, language: 'eng', selected: true, usesExternalDelivery: true),
        ]),
        sidecars: [
          _sidecar(8, language: 'fra'),
          _sidecar(9),
        ],
        preferredSubtitleTrack: const SubtitlePreference.intent(
          SubtitleIntent(language: 'fra', forced: false, title: 'French', codec: 'srt', isExternal: true),
        ),
      );

      expect(result.primarySourceStreamId, 9);
    });
  });

  group('issue #1785 declined-carry surfacing', () {
    const swedishIntent = SubtitlePreference.intent(
      SubtitleIntent(language: 'swe', forced: false, title: 'Swedish', codec: 'srt'),
    );

    MediaSubtitleTrack untaggedRow(int id, {String? title, String codec = 'srt'}) =>
        MediaSubtitleTrack(id: id, title: title, codec: codec, selected: false, forced: false);

    test('an untagged catalog row with the matching title still serves the carry', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([untaggedRow(3, title: 'English'), untaggedRow(4, title: 'Swedish')]),
        sidecars: const [],
        preferredSubtitleTrack: swedishIntent,
        preserveSourceIdentity: false,
      );

      expect(result.primarySourceStreamId, 4);
      expect(result.declinedPreference, isNull);
    });

    test('a carry no row can serve is kept as declined, not converted to off', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([_sourceSubtitle(3, language: 'eng')]),
        sidecars: const [],
        preferredSubtitleTrack: swedishIntent,
        preserveSourceIdentity: false,
      );

      expect(result.isOff, isTrue);
      expect(result.declinedPreference, swedishIntent);
    });

    test('an explicit off carry is a decision, never a decline', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([_sourceSubtitle(3, language: 'eng')]),
        sidecars: const [],
        preferredSubtitleTrack: const SubtitlePreference.off(),
        preserveSourceIdentity: false,
      );

      expect(result.isOff, isTrue);
      expect(result.declinedPreference, isNull);
    });

    test('a ladder off with no carry at all is a decision, never a decline', () {
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([_sourceSubtitle(3, language: 'eng')]),
        sidecars: const [],
      );

      expect(result.isOff, isTrue);
      expect(result.declinedPreference, isNull);
    });

    test('same-language rows are told apart by their titles across episodes (#1785)', () {
      // Real-world shape (Madoka Magica on Plex): both rows English ASS with
      // the bare displayTitle "English"; only Title separates the full
      // dialogue track from the signs/songs track.
      MediaSubtitleTrack row(int id, String title, {bool selected = false}) => MediaSubtitleTrack(
        id: id,
        language: 'English',
        languageCode: 'eng',
        title: title,
        displayTitle: 'English',
        codec: 'ass',
        selected: selected,
        forced: false,
      );

      // E1: the viewer picks the signs track and the session commits it. The
      // committed track must keep the discriminating row title, not the
      // language-only display title.
      final committed = PlaybackSubtitleResolver.subtitleTrackForSource(row(53164, 'Signs/OP/ED'));
      expect(committed.title, 'Signs/OP/ED');

      // Episode boundary demotes the committed reference to its intent.
      final carried = SubtitlePreference.demoteToIntent(SubtitlePreference.track(committed));

      // E2: same pair; the dialogue row sorts first AND is server-selected —
      // the carried signs choice must still win over both.
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: _mediaInfo([row(53193, 'Styled Subtitles', selected: true), row(53194, 'Signs/OP/ED')]),
        sidecars: const [],
        preferredSubtitleTrack: carried,
        preserveSourceIdentity: false,
      );

      expect(result.primarySourceStreamId, 53194);
      expect(result.declinedPreference, isNull);
    });

    test('a Jellyfin signs pick beats the server per-episode default on the next episode (#1785)', () {
      // Verbatim shape from a live Jellyfin server (Attack on Titan): both
      // rows English ASS, discriminated by Title, and the server names the
      // full-dialogue row (DefaultSubtitleStreamIndex 3) on every episode.
      MediaSourceInfo episodeInfo() => jellyfinMediaSourceToMediaSourceInfo({
        'Id': 'src-1',
        'DefaultSubtitleStreamIndex': 3,
        'MediaStreams': [
          {'Index': 1, 'Type': 'Audio', 'Language': 'jpn', 'IsDefault': true},
          {
            'Index': 3,
            'Type': 'Subtitle',
            'Language': 'eng',
            'Codec': 'ass',
            'Title': 'Full Subtitles',
            'DisplayTitle': 'Full Subtitles - English - Default - ASS',
            'IsDefault': true,
          },
          {
            'Index': 4,
            'Type': 'Subtitle',
            'Language': 'eng',
            'Codec': 'ass',
            'Title': 'Signs & Songs',
            'DisplayTitle': 'Signs & Songs - English - ASS',
          },
        ],
      });

      final e1 = episodeInfo();
      final picked = e1.subtitleTracks.firstWhere((row) => row.id == 4);
      final committed = PlaybackSubtitleResolver.subtitleTrackForSource(picked);
      expect(committed.title, 'Signs & Songs');

      final carried = SubtitlePreference.demoteToIntent(SubtitlePreference.track(committed));
      final result = PlaybackSubtitleResolver.resolve(
        metadata: metadata,
        mediaInfo: episodeInfo(),
        sidecars: const [],
        preferredSubtitleTrack: carried,
        preserveSourceIdentity: false,
      );

      expect(result.primarySourceStreamId, 4);
      expect(result.declinedPreference, isNull);
    });
  });

  test('audio source descriptor keeps the discriminating row title', () {
    // Server display titles collapse to the bare language; a commentary or
    // alternate mix is only identifiable by the row's own title.
    final row = MediaAudioTrack(
      id: 7,
      languageCode: 'eng',
      title: 'Commentary',
      displayTitle: 'English',
      codec: 'ac3',
      channels: 6,
      selected: false,
    );
    final track = PlaybackSubtitleResolver.audioTrackForSource(row);
    expect(track.id, 'source:7');
    expect(track.title, 'Commentary');
    expect(track.language, 'eng');
    expect(track.channels, 6);
  });

  group('burned-in subtitles force a renegotiation', () {
    bool needsServer({
      bool isTranscoding = true,
      int? currentSourceStreamId,
      bool currentSelectionHasSidecar = false,
      bool targetIsOff = false,
      bool targetIsExternalFile = false,
    }) => PlaybackSubtitleResolver.burnRequiresRenegotiation(
      isTranscoding: isTranscoding,
      currentSourceStreamId: currentSourceStreamId,
      currentSelectionHasSidecar: currentSelectionHasSidecar,
      targetIsOff: targetIsOff,
      targetIsExternalFile: targetIsExternalFile,
    );

    // Burned pixels are not a track: off leaves them on screen, anything else is drawn over them.
    // So from a burned selection the target is irrelevant - every change goes back to the server.
    test('every change from a burned selection goes back to the server', () {
      expect(needsServer(currentSourceStreamId: 3, targetIsOff: true), isTrue);
      expect(needsServer(currentSourceStreamId: 3, targetIsExternalFile: true), isTrue);
      expect(needsServer(currentSourceStreamId: 3), isTrue, reason: 'another embedded track');
    });

    // The other direction: nothing is burned yet, but the target can only arrive burned.
    test('an embedded target has to be negotiated even with nothing burned', () {
      expect(
        needsServer(currentSourceStreamId: null),
        isTrue,
        reason: 'applying it locally attaches nothing and reports success over an unchanged picture',
      );
      expect(
        needsServer(currentSourceStreamId: 3, currentSelectionHasSidecar: true),
        isTrue,
        reason: 'a sidecar-backed current selection does not make an embedded target local',
      );
    });

    test('what the client already holds stays local', () {
      expect(needsServer(currentSourceStreamId: null, targetIsOff: true), isFalse);
      expect(needsServer(currentSourceStreamId: null, targetIsExternalFile: true), isFalse);
      expect(
        needsServer(currentSourceStreamId: 3, currentSelectionHasSidecar: true, targetIsOff: true),
        isFalse,
        reason: 'a sidecar was delivered as a file, so turning it off is a real local change',
      );
    });

    test('a direct play never burns, whatever is selected', () {
      expect(needsServer(isTranscoding: false, currentSourceStreamId: 3), isFalse);
      expect(needsServer(isTranscoding: false), isFalse);
    });
  });

  test('selected embedded subtitle keeps sidecars out of the open', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true)]),
      sidecars: const [],
    );

    expect(result.isOff, isFalse);
    expect(result.primarySourceStreamId, 2);
    expect(result.primarySidecar, isNull);
    expect(result.sidecarsAtOpen, isEmpty);
  });

  test('selected metadata-free embedded subtitle resolves by source identity', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([MediaSubtitleTrack(id: 2, codec: 'ass', selected: true, forced: false)]),
      sidecars: const [],
    );

    expect(result.isOff, isFalse);
    expect(result.primarySourceStreamId, 2);
  });

  test('preferred secondary subtitle attaches a second distinct sidecar', () {
    final mediaInfo = _mediaInfo([
      _sourceSubtitle(2, selected: true, usesExternalDelivery: true),
      _sourceSubtitle(3, language: 'swe', usesExternalDelivery: true),
    ]);
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: mediaInfo,
      sidecars: [
        _sidecar(2),
        _sidecar(3, language: 'swe'),
      ],
      preferredSecondarySubtitleTrack: SubtitlePreference.trackOrNull(
        PlaybackSubtitleResolver.preferredTrackForSource(mediaInfo, 3),
      ),
    );

    expect(result.primarySourceStreamId, 2);
    expect(result.secondarySourceStreamId, 3);
    expect(result.sidecarsAtOpen, hasLength(2));
  });

  test('legacy sidecar without source metadata still follows default selection', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: null,
      sidecars: [
        PlaybackSubtitleSidecar(
          sourceStreamId: null,
          track: SubtitleTrack.uri('file:///tmp/subtitle.srt', title: 'Local', isDefault: true),
        ),
      ],
    );

    expect(result.isOff, isFalse);
    expect(result.primarySourceStreamId, isNull);
    expect(result.sidecarsAtOpen.single.uri, 'file:///tmp/subtitle.srt');
  });
}
