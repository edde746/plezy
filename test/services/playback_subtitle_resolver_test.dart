import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';

import '../test_helpers/media_items.dart';

MediaSubtitleTrack _sourceSubtitle(
  int id, {
  String language = 'eng',
  bool forced = false,
  bool selected = false,
  bool external = false,
  bool usesExternalDelivery = false,
}) {
  return MediaSubtitleTrack(
    id: id,
    language: language,
    languageCode: language,
    title: 'Subtitle $id',
    selected: selected,
    forced: forced,
    external: external,
    usesExternalDelivery: usesExternalDelivery,
  );
}

PlaybackSubtitleSidecar _sidecar(int id, {String language = 'eng', bool isDefault = false}) {
  return PlaybackSubtitleSidecar(
    sourceStreamId: id,
    track: SubtitleTrack.uri(
      'https://example.test/subtitles/$id.srt',
      title: 'Subtitle $id',
      language: language,
      codec: 'srt',
      isDefault: isDefault,
    ),
  );
}

MediaSourceInfo _mediaInfo(List<MediaSubtitleTrack> subtitles) {
  return MediaSourceInfo(videoUrl: '', audioTracks: const [], subtitleTracks: subtitles, chapters: const []);
}

void main() {
  group('direct-play source routing', () {
    test('matches an embedded source to its loaded native track', () {
      final source = _sourceSubtitle(2, language: 'eng');
      const native = SubtitleTrack(id: '7', language: 'eng', codec: 'srt');

      expect(
        PlaybackSubtitleResolver.nativeTrackForDirectPlaySource(
          sourceTrack: source,
          nativeTracks: const [native],
          allSourceTracks: [source],
          isResolvedSidecar: false,
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
        PlaybackSubtitleResolver.nativeTrackForDirectPlaySource(
          sourceTrack: source,
          nativeTracks: const [other],
          allSourceTracks: [source],
          isResolvedSidecar: true,
        ),
        isNull,
      );
    });

    test('cycles through typed off and every authoritative source id, including zero', () {
      final tracks = [_sourceSubtitle(0), _sourceSubtitle(2)];

      expect(
        PlaybackSubtitleResolver.nextSourceChoice(tracks, const PlaybackSourceSubtitleChoice.off()),
        const PlaybackSourceSubtitleChoice.source(0),
      );
      expect(
        PlaybackSubtitleResolver.nextSourceChoice(tracks, const PlaybackSourceSubtitleChoice.source(0)),
        const PlaybackSourceSubtitleChoice.source(2),
      );
      expect(
        PlaybackSubtitleResolver.nextSourceChoice(tracks, const PlaybackSourceSubtitleChoice.source(2)),
        const PlaybackSourceSubtitleChoice.off(),
      );
      expect(
        PlaybackSubtitleResolver.advanceSourceChoice(tracks, const PlaybackSourceSubtitleChoice.off(), 4),
        const PlaybackSourceSubtitleChoice.source(0),
      );
    });

    test('fuzzy-matches Jellyfin external-delivery rows that remain embedded in direct play', () {
      final source = _sourceSubtitle(2, language: 'eng', usesExternalDelivery: true);
      const native = SubtitleTrack(id: '7', language: 'eng', codec: 'srt');

      expect(
        PlaybackSubtitleResolver.nativeTrackForDirectPlaySource(
          sourceTrack: source,
          nativeTracks: const [native],
          allSourceTracks: [source],
          isResolvedSidecar: false,
        ),
        native,
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

  test('explicit off produces an open with zero sidecars', () {
    final result = PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: _mediaInfo([_sourceSubtitle(2, selected: true, usesExternalDelivery: true)]),
      sidecars: [_sidecar(2)],
      preferredSubtitleTrack: SubtitleTrack.off,
    );

    expect(result.isOff, isTrue);
    expect(result.sidecarsAtOpen, isEmpty);
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
      preferredSubtitleTrack: PlaybackSubtitleResolver.preferredTrackForSource(mediaInfo, 3),
    );

    expect(result.primarySourceStreamId, 3);
    expect(result.sidecarsAtOpen.single.uri, 'https://example.test/subtitles/3.srt');
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
      preferredSubtitleTrack: const SubtitleTrack(
        id: 'navigation',
        title: 'English from the previous episode',
        language: 'eng',
        codec: 'srt',
        isExternal: true,
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
      preferredSubtitleTrack: const SubtitleTrack(
        id: 'navigation',
        title: 'English forced from the previous episode',
        language: 'eng',
        codec: 'srt',
        isForced: true,
        isExternal: true,
      ),
    );

    expect(result.primarySourceStreamId, 8);
    expect(result.primaryTrack.isForced, isTrue);
    expect(result.primarySidecar?.track.uri, 'https://example.test/subtitles/8.srt');
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
      preferredSecondarySubtitleTrack: PlaybackSubtitleResolver.preferredTrackForSource(mediaInfo, 3),
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
