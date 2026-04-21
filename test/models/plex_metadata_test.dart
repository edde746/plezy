import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/services/settings_service.dart' show EpisodePosterMode;

PlexMetadata _make({
  String ratingKey = '1',
  String? key,
  String? type,
  String? title,
  String? parentTitle,
  String? grandparentTitle,
  String? thumb,
  String? parentThumb,
  String? grandparentThumb,
  String? art,
  String? parentRatingKey,
  String? grandparentRatingKey,
  int? duration,
  int? viewOffset,
  int? viewCount,
  int? leafCount,
  int? viewedLeafCount,
  String? serverId,
}) {
  return PlexMetadata(
    ratingKey: ratingKey,
    key: key,
    type: type,
    title: title,
    parentTitle: parentTitle,
    grandparentTitle: grandparentTitle,
    thumb: thumb,
    parentThumb: parentThumb,
    grandparentThumb: grandparentThumb,
    art: art,
    parentRatingKey: parentRatingKey,
    grandparentRatingKey: grandparentRatingKey,
    duration: duration,
    viewOffset: viewOffset,
    viewCount: viewCount,
    leafCount: leafCount,
    viewedLeafCount: viewedLeafCount,
    serverId: serverId,
  );
}

void main() {
  group('PlexMetadata.mediaType', () {
    test('maps known lowercase type strings', () {
      for (final pair in const [
        ('movie', PlexMediaType.movie),
        ('show', PlexMediaType.show),
        ('season', PlexMediaType.season),
        ('episode', PlexMediaType.episode),
        ('artist', PlexMediaType.artist),
        ('album', PlexMediaType.album),
        ('track', PlexMediaType.track),
        ('collection', PlexMediaType.collection),
        ('playlist', PlexMediaType.playlist),
        ('clip', PlexMediaType.clip),
        ('photo', PlexMediaType.photo),
      ]) {
        expect(_make(type: pair.$1).mediaType, pair.$2, reason: 'type=${pair.$1}');
      }
    });

    test('case-insensitive', () {
      expect(_make(type: 'MOVIE').mediaType, PlexMediaType.movie);
      expect(_make(type: 'Episode').mediaType, PlexMediaType.episode);
    });

    test('unknown / null -> PlexMediaType.unknown', () {
      expect(_make(type: null).mediaType, PlexMediaType.unknown);
      expect(_make(type: '').mediaType, PlexMediaType.unknown);
      expect(_make(type: 'weird').mediaType, PlexMediaType.unknown);
    });
  });

  group('PlexMediaType enum extensions', () {
    test('isVideo', () {
      expect(PlexMediaType.movie.isVideo, isTrue);
      expect(PlexMediaType.episode.isVideo, isTrue);
      expect(PlexMediaType.clip.isVideo, isTrue);
      expect(PlexMediaType.show.isVideo, isFalse);
      expect(PlexMediaType.season.isVideo, isFalse);
      expect(PlexMediaType.track.isVideo, isFalse);
    });

    test('isShowRelated', () {
      expect(PlexMediaType.show.isShowRelated, isTrue);
      expect(PlexMediaType.season.isShowRelated, isTrue);
      expect(PlexMediaType.episode.isShowRelated, isTrue);
      expect(PlexMediaType.movie.isShowRelated, isFalse);
      expect(PlexMediaType.clip.isShowRelated, isFalse);
    });

    test('isMusic', () {
      expect(PlexMediaType.artist.isMusic, isTrue);
      expect(PlexMediaType.album.isMusic, isTrue);
      expect(PlexMediaType.track.isMusic, isTrue);
      expect(PlexMediaType.movie.isMusic, isFalse);
    });

    test('isPlayable', () {
      expect(PlexMediaType.movie.isPlayable, isTrue);
      expect(PlexMediaType.episode.isPlayable, isTrue);
      expect(PlexMediaType.clip.isPlayable, isTrue);
      expect(PlexMediaType.track.isPlayable, isTrue);
      expect(PlexMediaType.show.isPlayable, isFalse);
      expect(PlexMediaType.artist.isPlayable, isFalse);
    });

    test('typeNumber for API-addressable types', () {
      expect(PlexMediaType.movie.typeNumber, 1);
      expect(PlexMediaType.show.typeNumber, 2);
      expect(PlexMediaType.season.typeNumber, 3);
      expect(PlexMediaType.episode.typeNumber, 4);
      expect(PlexMediaType.artist.typeNumber, 8);
      expect(PlexMediaType.album.typeNumber, 9);
      expect(PlexMediaType.track.typeNumber, 10);
    });

    test('typeNumber fallback is 0 for collection/playlist/clip/photo/unknown', () {
      expect(PlexMediaType.collection.typeNumber, 0);
      expect(PlexMediaType.playlist.typeNumber, 0);
      expect(PlexMediaType.clip.typeNumber, 0);
      expect(PlexMediaType.photo.typeNumber, 0);
      expect(PlexMediaType.unknown.typeNumber, 0);
    });
  });

  group('globalKey', () {
    test('joins serverId:ratingKey when serverId present', () {
      expect(_make(ratingKey: '42', serverId: 'srv').globalKey, 'srv:42');
    });

    test('falls back to bare ratingKey when serverId is null', () {
      expect(_make(ratingKey: '42').globalKey, '42');
    });
  });

  group('parentChain', () {
    test('movie (no parents) -> empty list', () {
      expect(_make(type: 'movie').parentChain, isEmpty);
    });

    test('season (show parent only) -> [show]', () {
      expect(_make(type: 'season', grandparentRatingKey: 's1').parentChain, ['s1']);
    });

    test('episode (season + show) -> [season, show]', () {
      expect(_make(type: 'episode', parentRatingKey: 'se1', grandparentRatingKey: 'sh1').parentChain, ['se1', 'sh1']);
    });

    test('omits null entries (only parent, no grandparent)', () {
      expect(_make(parentRatingKey: 'p').parentChain, ['p']);
    });
  });

  group('isLibrarySection & librarySectionKey', () {
    test('non-library-section key', () {
      final m = _make(key: '/library/metadata/12345');
      expect(m.isLibrarySection, isFalse);
      expect(m.librarySectionKey, isNull);
    });

    test('library-section key extracts numeric id', () {
      final m = _make(key: '/library/sections/7/all');
      expect(m.isLibrarySection, isTrue);
      expect(m.librarySectionKey, '7');
    });

    test('library-section without trailing path still extracts id', () {
      final m = _make(key: '/library/sections/12');
      expect(m.isLibrarySection, isTrue);
      expect(m.librarySectionKey, '12');
    });

    test('null key -> not a library section', () {
      final m = _make();
      expect(m.isLibrarySection, isFalse);
      expect(m.librarySectionKey, isNull);
    });
  });

  group('displayTitle / displaySubtitle', () {
    test('episode with grandparentTitle prefers show name', () {
      final m = _make(type: 'episode', title: 'Pilot', grandparentTitle: 'My Show');
      expect(m.displayTitle, 'My Show');
      expect(m.displaySubtitle, 'Pilot');
    });

    test('episode without grandparentTitle falls back to title', () {
      final m = _make(type: 'episode', title: 'Pilot');
      expect(m.displayTitle, 'Pilot');
      expect(m.displaySubtitle, isNull);
    });

    test('season with grandparentTitle shows show name as title, season name as subtitle', () {
      final m = _make(type: 'season', title: 'Season 1', grandparentTitle: 'My Show');
      expect(m.displayTitle, 'My Show');
      expect(m.displaySubtitle, 'Season 1');
    });

    test('season without grandparent falls back to parentTitle', () {
      final m = _make(type: 'season', title: 'Season 1', parentTitle: 'My Show');
      expect(m.displayTitle, 'My Show');
      expect(m.displaySubtitle, 'Season 1');
    });

    test('movie uses its own title, no subtitle', () {
      final m = _make(type: 'movie', title: 'Inception');
      expect(m.displayTitle, 'Inception');
      expect(m.displaySubtitle, isNull);
    });

    test('missing title returns empty displayTitle', () {
      final m = _make(type: 'movie');
      expect(m.displayTitle, '');
    });
  });

  group('posterThumb', () {
    test('episode + seriesPoster -> grandparentThumb, fallback thumb', () {
      expect(
        _make(type: 'episode', thumb: 't', grandparentThumb: 'g').posterThumb(mode: EpisodePosterMode.seriesPoster),
        'g',
      );
      expect(_make(type: 'episode', thumb: 't').posterThumb(mode: EpisodePosterMode.seriesPoster), 't');
    });

    test('episode + seasonPoster -> parentThumb → grandparentThumb → thumb', () {
      expect(
        _make(
          type: 'episode',
          thumb: 't',
          parentThumb: 'p',
          grandparentThumb: 'g',
        ).posterThumb(mode: EpisodePosterMode.seasonPoster),
        'p',
      );
      expect(
        _make(type: 'episode', thumb: 't', grandparentThumb: 'g').posterThumb(mode: EpisodePosterMode.seasonPoster),
        'g',
      );
      expect(_make(type: 'episode', thumb: 't').posterThumb(mode: EpisodePosterMode.seasonPoster), 't');
    });

    test('episode + episodeThumbnail -> thumb', () {
      expect(
        _make(
          type: 'episode',
          thumb: 't',
          parentThumb: 'p',
          grandparentThumb: 'g',
        ).posterThumb(mode: EpisodePosterMode.episodeThumbnail),
        't',
      );
    });

    test('season -> grandparentThumb when available', () {
      expect(_make(type: 'season', thumb: 't', grandparentThumb: 'g').posterThumb(), 'g');
    });

    test('season without grandparent -> thumb', () {
      expect(_make(type: 'season', thumb: 't').posterThumb(), 't');
    });

    test('season + mixed hub + episodeThumbnail -> art fallback thumb', () {
      expect(
        _make(
          type: 'season',
          thumb: 't',
          art: 'a',
          grandparentThumb: 'g',
        ).posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true),
        'a',
      );
      expect(
        _make(
          type: 'season',
          thumb: 't',
          grandparentThumb: 'g',
        ).posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true),
        't',
      );
    });

    test('movie/show in mixed hub + episodeThumbnail -> art, fallback thumb', () {
      expect(
        _make(
          type: 'movie',
          thumb: 't',
          art: 'a',
        ).posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true),
        'a',
      );
      expect(
        _make(type: 'show', thumb: 't').posterThumb(mode: EpisodePosterMode.episodeThumbnail, mixedHubContext: true),
        't',
      );
    });

    test('movie/show outside mixed hub -> thumb regardless of mode', () {
      expect(_make(type: 'movie', thumb: 't', art: 'a').posterThumb(mode: EpisodePosterMode.episodeThumbnail), 't');
    });

    test('other types default to thumb', () {
      expect(_make(type: 'artist', thumb: 't').posterThumb(), 't');
      expect(_make(type: 'track', thumb: 't').posterThumb(), 't');
    });
  });

  group('usesWideAspectRatio', () {
    test('clips always wide', () {
      expect(_make(type: 'clip').usesWideAspectRatio(EpisodePosterMode.seriesPoster), isTrue);
      expect(_make(type: 'clip').usesWideAspectRatio(EpisodePosterMode.seasonPoster), isTrue);
    });

    test('episode + episodeThumbnail is wide', () {
      expect(_make(type: 'episode').usesWideAspectRatio(EpisodePosterMode.episodeThumbnail), isTrue);
    });

    test('episode + other modes is not wide', () {
      expect(_make(type: 'episode').usesWideAspectRatio(EpisodePosterMode.seriesPoster), isFalse);
      expect(_make(type: 'episode').usesWideAspectRatio(EpisodePosterMode.seasonPoster), isFalse);
    });

    test('movie/show/season in mixed hub + episodeThumbnail is wide', () {
      for (final t in const ['movie', 'show', 'season']) {
        expect(
          _make(type: t).usesWideAspectRatio(EpisodePosterMode.episodeThumbnail, mixedHubContext: true),
          isTrue,
          reason: 'type=$t',
        );
      }
    });

    test('movie/show/season outside mixed hub is not wide', () {
      expect(_make(type: 'movie').usesWideAspectRatio(EpisodePosterMode.episodeThumbnail), isFalse);
    });
  });

  group('watch-state predicates', () {
    test('hasActiveProgress requires both duration and viewOffset set, with 0 < vo < dur', () {
      expect(_make().hasActiveProgress, isFalse);
      expect(_make(duration: 100).hasActiveProgress, isFalse);
      expect(_make(viewOffset: 10).hasActiveProgress, isFalse);
      expect(_make(duration: 100, viewOffset: 0).hasActiveProgress, isFalse);
      expect(_make(duration: 100, viewOffset: 100).hasActiveProgress, isFalse);
      expect(_make(duration: 100, viewOffset: 50).hasActiveProgress, isTrue);
      expect(_make(duration: 100, viewOffset: 1).hasActiveProgress, isTrue);
      expect(_make(duration: 100, viewOffset: 99).hasActiveProgress, isTrue);
    });

    test('isPartiallyWatched requires leaf counts with 0 < viewed < total', () {
      expect(_make().isPartiallyWatched, isFalse);
      expect(_make(leafCount: 10).isPartiallyWatched, isFalse);
      expect(_make(viewedLeafCount: 3).isPartiallyWatched, isFalse);
      expect(_make(leafCount: 10, viewedLeafCount: 0).isPartiallyWatched, isFalse);
      expect(_make(leafCount: 10, viewedLeafCount: 10).isPartiallyWatched, isFalse);
      expect(_make(leafCount: 10, viewedLeafCount: 3).isPartiallyWatched, isTrue);
    });

    test('isWatched prefers leaf counts when both present', () {
      expect(_make(leafCount: 10, viewedLeafCount: 10).isWatched, isTrue);
      expect(_make(leafCount: 10, viewedLeafCount: 11).isWatched, isTrue);
      expect(_make(leafCount: 10, viewedLeafCount: 9).isWatched, isFalse);
    });

    test('isWatched uses viewCount when leaf counts absent', () {
      expect(_make(viewCount: 1).isWatched, isTrue);
      expect(_make(viewCount: 0).isWatched, isFalse);
      expect(_make().isWatched, isFalse);
    });
  });

  group('heroArt', () {
    test('uses backgroundSquare when container is squarer than ~1.39', () {
      final m = PlexMetadata(ratingKey: '1', art: 'wide.jpg', backgroundSquare: 'square.jpg');
      expect(m.heroArt(containerAspectRatio: 1.0), 'square.jpg');
      expect(m.heroArt(containerAspectRatio: 1.38), 'square.jpg');
    });

    test('uses art when container is wider', () {
      final m = PlexMetadata(ratingKey: '1', art: 'wide.jpg', backgroundSquare: 'square.jpg');
      expect(m.heroArt(containerAspectRatio: 1.39), 'wide.jpg');
      expect(m.heroArt(containerAspectRatio: 1.78), 'wide.jpg');
    });

    test('falls back to art when backgroundSquare is null regardless of aspect', () {
      final m = PlexMetadata(ratingKey: '1', art: 'wide.jpg');
      expect(m.heroArt(containerAspectRatio: 1.0), 'wide.jpg');
    });
  });
}
