import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_role.dart';
import 'package:plezy/media/media_version.dart';

/// Backend-agnostic [MediaItem] tests. Existing coverage is split between
/// `plex_mappers_test` and `jellyfin_mappers_test` — those exercise the
/// JSON mappers but never the neutral model itself. If a mapper is removed
/// or refactored these tests still pin the model contract: equality,
/// copyWith, watch-state derived getters.
MediaItem _movie({
  String id = 'm1',
  String? title = 'Movie',
  int? viewCount,
  int? leafCount,
  int? viewedLeafCount,
  int? durationMs,
  int? viewOffsetMs,
  String? artPath,
  String? backgroundSquarePath,
  MediaBackend backend = MediaBackend.plex,
}) => MediaItem(
  id: id,
  backend: backend,
  kind: MediaKind.movie,
  title: title,
  viewCount: viewCount,
  leafCount: leafCount,
  viewedLeafCount: viewedLeafCount,
  durationMs: durationMs,
  viewOffsetMs: viewOffsetMs,
  artPath: artPath,
  backgroundSquarePath: backgroundSquarePath,
  serverId: 's1',
);

void main() {
  group('MediaItem.isWatched', () {
    test('movie with viewCount > 0 is watched', () {
      expect(_movie(viewCount: 1).isWatched, isTrue);
      expect(_movie(viewCount: 5).isWatched, isTrue);
    });

    test('movie with viewCount 0 or null is unwatched', () {
      expect(_movie(viewCount: 0).isWatched, isFalse);
      expect(_movie(viewCount: null).isWatched, isFalse);
    });

    test('show with all leaves watched is watched', () {
      final show = MediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 10,
        serverId: 's1',
      );
      expect(show.isWatched, isTrue);
    });

    test('show with viewedLeafCount > leafCount is still watched (defensive)', () {
      final show = MediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 11,
        serverId: 's1',
      );
      expect(show.isWatched, isTrue);
    });

    test('show with no leaf info falls back to viewCount', () {
      final show = MediaItem(id: 's', backend: MediaBackend.plex, kind: MediaKind.show, viewCount: 1, serverId: 's1');
      expect(show.isWatched, isTrue);
    });
  });

  group('MediaItem.heroArtCandidates', () {
    test('near-square containers prefer square art before wide cover art', () {
      final movie = _movie(artPath: '/art', backgroundSquarePath: '/square');

      expect(movie.heroArtCandidates(containerAspectRatio: 1.0), ['/square', '/art']);
      expect(movie.heroArt(containerAspectRatio: 1.0), '/square');
    });

    test('near-square containers fall back to wide cover art when square art is missing', () {
      final movie = _movie(artPath: '/art');

      expect(movie.heroArtCandidates(containerAspectRatio: 1.0), ['/art']);
      expect(movie.heroArt(containerAspectRatio: 1.0), '/art');
    });

    test('wide containers prefer wide cover art before square art', () {
      final movie = _movie(artPath: '/art', backgroundSquarePath: '/square');

      expect(movie.heroArtCandidates(containerAspectRatio: 16 / 9), ['/art', '/square']);
      expect(movie.heroArt(containerAspectRatio: 16 / 9), '/art');
    });

    test('episodes prefer show art before episode art for wide hero containers', () {
      final episode = MediaItem(
        id: 'e1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode',
        grandparentTitle: 'Show',
        grandparentArtPath: '/show-art',
        artPath: '/episode-art',
        backgroundSquarePath: '/square',
        serverId: 's1',
      );

      expect(episode.heroArtCandidates(containerAspectRatio: 16 / 9), ['/show-art', '/episode-art', '/square']);
      expect(episode.heroArt(containerAspectRatio: 16 / 9), '/show-art');
      expect(episode.heroArtCandidates(containerAspectRatio: 1.0), ['/square', '/show-art', '/episode-art']);
    });
  });

  group('MediaItem.isPartiallyWatched', () {
    test('show with some leaves watched is partially watched', () {
      final show = MediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 3,
        serverId: 's1',
      );
      expect(show.isPartiallyWatched, isTrue);
    });

    test('show with zero leaves watched is NOT partially watched', () {
      final show = MediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 0,
        serverId: 's1',
      );
      expect(show.isPartiallyWatched, isFalse);
    });

    test('show with all leaves watched is NOT partially watched', () {
      final show = MediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 10,
        serverId: 's1',
      );
      expect(show.isPartiallyWatched, isFalse);
    });

    test('movie without leaf info is NOT partially watched (concept doesn\'t apply)', () {
      expect(_movie(viewCount: 0).isPartiallyWatched, isFalse);
      expect(_movie(viewCount: 1).isPartiallyWatched, isFalse);
    });
  });

  group('MediaItem.hasActiveProgress', () {
    test('viewOffset between 0 and duration counts as active progress', () {
      expect(_movie(durationMs: 10000, viewOffsetMs: 5000).hasActiveProgress, isTrue);
    });

    test('viewOffset 0 is NOT active progress (haven\'t started yet)', () {
      expect(_movie(durationMs: 10000, viewOffsetMs: 0).hasActiveProgress, isFalse);
    });

    test('viewOffset >= duration is NOT active progress (already finished)', () {
      expect(_movie(durationMs: 10000, viewOffsetMs: 10000).hasActiveProgress, isFalse);
      expect(_movie(durationMs: 10000, viewOffsetMs: 99999).hasActiveProgress, isFalse);
    });

    test('null durationMs or viewOffsetMs disables the check', () {
      expect(_movie(durationMs: null, viewOffsetMs: 5000).hasActiveProgress, isFalse);
      expect(_movie(durationMs: 10000, viewOffsetMs: null).hasActiveProgress, isFalse);
    });
  });

  group('MediaItem.copyWith', () {
    test('round-trips an unchanged copy', () {
      final original = _movie(viewCount: 1, durationMs: 1000);
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.viewCount, original.viewCount);
      expect(copy.durationMs, original.durationMs);
      expect(copy.kind, original.kind);
    });

    test('overrides only the named fields', () {
      final original = _movie(title: 'Old', viewCount: 0);
      final copy = original.copyWith(title: 'New', viewCount: 3);
      expect(copy.title, 'New');
      expect(copy.viewCount, 3);
      expect(copy.id, 'm1', reason: 'untouched fields preserved');
    });

    test('preserves backend across copyWith for both backends', () {
      for (final backend in MediaBackend.values) {
        final original = _movie(backend: backend);
        expect(original.backend, backend);
        expect(original.copyWith(title: 'New').backend, backend, reason: 'copyWith must preserve backend');
      }
    });

    test('preserves Plex-only fields when omitted', () {
      const original = PlexMediaItem(
        id: 'p1',
        kind: MediaKind.movie,
        title: 'Old',
        editionTitle: 'Director Cut',
        audienceRating: 8.9,
        ratingImage: 'rottentomatoes://rating',
        audienceRatingImage: 'rottentomatoes://audience',
        subtitleLanguage: 'eng',
        subtitleMode: 1,
        trailerKey: '/library/metadata/1',
        playlistItemId: 42,
        playQueueItemId: 7,
        subtype: 'trailer',
        extraType: 1,
      );

      final copy = original.copyWith(title: 'New');

      expect(copy.title, 'New');
      expect(copy.editionTitle, 'Director Cut');
      expect(copy.audienceRating, 8.9);
      expect(copy.ratingImage, 'rottentomatoes://rating');
      expect(copy.audienceRatingImage, 'rottentomatoes://audience');
      expect(copy.subtitleLanguage, 'eng');
      expect(copy.subtitleMode, 1);
      expect(copy.trailerKey, '/library/metadata/1');
      expect(copy.playlistItemId, 42);
      expect(copy.playQueueItemId, 7);
      expect(copy.subtype, 'trailer');
      expect(copy.extraType, 1);
    });

    test('preserves Jellyfin playlist item id when omitted', () {
      const original = JellyfinMediaItem(
        id: 'j1',
        kind: MediaKind.movie,
        title: 'Old',
        playlistItemId: 'playlist-entry-1',
      );

      final copy = original.copyWith(title: 'New');

      expect(copy.title, 'New');
      expect(copy.playlistItemId, 'playlist-entry-1');
    });

    test('can clear nullable fields explicitly', () {
      final original = _movie(title: 'Movie', viewCount: 1, durationMs: 1000, viewOffsetMs: 500);

      final copy = original.copyWith(title: null, viewOffsetMs: null);

      expect(copy.title, isNull);
      expect(copy.viewOffsetMs, isNull);
      expect(copy.viewCount, 1);
    });
  });

  group('MediaItem JSON', () {
    test('round-trips Plex-only fields', () {
      const original = PlexMediaItem(
        id: 'p1',
        kind: MediaKind.movie,
        title: 'Movie',
        editionTitle: 'Theatrical',
        audienceRating: 9.1,
        ratingImage: 'rottentomatoes://rating',
        audienceRatingImage: 'rottentomatoes://audience',
        genres: ['Drama'],
        roles: [MediaRole(id: '1', tag: 'Actor', role: 'Lead', thumbPath: '/photo')],
        mediaVersions: [
          MediaVersion(
            id: 'v1',
            width: 1920,
            height: 1080,
            parts: [MediaPart(id: 'part1', streamPath: '/stream', sizeBytes: 1000)],
          ),
        ],
        subtitleLanguage: 'eng',
        subtitleMode: 2,
        trailerKey: '/trailer',
        playlistItemId: 4,
        playQueueItemId: 5,
        subtype: 'trailer',
        extraType: 9,
      );

      final json = original.toJson();
      final decoded = MediaItem.fromJson(json);

      expect(json['backend'], 'plex');
      expect(json.containsKey('summary'), isFalse);
      expect(decoded, isA<PlexMediaItem>());
      final plex = decoded as PlexMediaItem;
      expect(plex.editionTitle, 'Theatrical');
      expect(plex.audienceRating, 9.1);
      expect(plex.ratingImage, 'rottentomatoes://rating');
      expect(plex.audienceRatingImage, 'rottentomatoes://audience');
      expect(plex.genres, ['Drama']);
      expect(plex.roles?.single.tag, 'Actor');
      expect(plex.mediaVersions?.single.parts.single.streamPath, '/stream');
      expect(plex.subtitleLanguage, 'eng');
      expect(plex.subtitleMode, 2);
      expect(plex.trailerKey, '/trailer');
      expect(plex.playlistItemId, 4);
      expect(plex.playQueueItemId, 5);
      expect(plex.subtype, 'trailer');
      expect(plex.extraType, 9);
    });

    test('round-trips Jellyfin playlist item id', () {
      const original = JellyfinMediaItem(id: 'j1', kind: MediaKind.movie, title: 'Movie', playlistItemId: 'entry-1');

      final json = original.toJson();
      final decoded = MediaItem.fromJson(json);

      expect(json['backend'], 'jellyfin');
      expect(decoded, isA<JellyfinMediaItem>());
      expect((decoded as JellyfinMediaItem).playlistItemId, 'entry-1');
    });

    test('missing backend keeps legacy Plex fallback', () {
      final decoded = MediaItem.fromJson({'id': 'legacy', 'kind': 'movie'});

      expect(decoded, isA<PlexMediaItem>());
      expect(decoded.backend, MediaBackend.plex);
      expect(decoded.id, 'legacy');
      expect(decoded.kind, MediaKind.movie);
    });
  });

  group('MediaItem.displayTitle', () {
    test('episode prefers grandparent (show) title', () {
      final ep = MediaItem(
        id: 'e1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Pilot',
        grandparentTitle: 'Breaking Bad',
        parentTitle: 'Season 1',
        serverId: 's1',
      );
      expect(ep.displayTitle, 'Breaking Bad');
      expect(ep.displaySubtitle, 'Pilot');
    });

    test('season prefers grandparent over parent (when both present)', () {
      final season = MediaItem(
        id: 'sn1',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'Season 1',
        grandparentTitle: 'Breaking Bad',
        parentTitle: null,
        serverId: 's1',
      );
      expect(season.displayTitle, 'Breaking Bad');
    });

    test('movie returns its own title with no subtitle', () {
      final movie = _movie(title: 'Inception');
      expect(movie.displayTitle, 'Inception');
      expect(movie.displaySubtitle, isNull);
    });

    test('null title degrades to empty string (no NPE)', () {
      final movie = _movie(title: null);
      expect(movie.displayTitle, '');
    });
  });
}
