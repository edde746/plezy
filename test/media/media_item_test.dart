import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/media/media_role.dart';
import 'package:plezy/media/media_version.dart';
import '../test_helpers/media_items.dart';

/// Backend-agnostic [MediaItem] tests. Existing coverage is split between
/// `plex_mappers_test` and `jellyfin_mappers_test` — those exercise the
/// JSON mappers but never the neutral model itself. If a mapper is removed
/// or refactored these tests still pin the model contract: equality,
/// copyWith, watch-state derived getters.
MediaItem _movie({
  String id = 'm1',
  String? title = 'Movie',
  int? year,
  int? viewCount,
  int? leafCount,
  int? viewedLeafCount,
  int? durationMs,
  int? viewOffsetMs,
  String? artPath,
  List<String>? backdropPaths,
  String? backgroundSquarePath,
  MediaBackend backend = MediaBackend.plex,
}) => testMediaItem(
  id: id,
  backend: backend,
  kind: MediaKind.movie,
  title: title,
  year: year,
  viewCount: viewCount,
  leafCount: leafCount,
  viewedLeafCount: viewedLeafCount,
  durationMs: durationMs,
  viewOffsetMs: viewOffsetMs,
  artPath: artPath,
  backdropPaths: backdropPaths,
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
      final show = testMediaItem(
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
      final show = testMediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 11,
        serverId: 's1',
      );
      expect(show.isWatched, isTrue);
      expect(show.unwatchedCount, 0);
    });

    test('show with no leaf info falls back to viewCount', () {
      final show = testMediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        viewCount: 1,
        serverId: 's1',
      );
      expect(show.isWatched, isTrue);
    });

    test('leaf media ignores aggregate leaf counts', () {
      expect(_movie(viewCount: 0, leafCount: 1, viewedLeafCount: 1).isWatched, isFalse);
      expect(_movie(viewCount: 1, leafCount: 1, viewedLeafCount: 0).isWatched, isTrue);
    });

    test('container media uses aggregate leaf counts', () {
      final album = testMediaItem(
        id: 'a',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        viewCount: 0,
        leafCount: 8,
        viewedLeafCount: 8,
        serverId: 's1',
      );
      expect(album.isWatched, isTrue);
    });

    test('every media kind has explicit leaf or container watch semantics', () {
      const containerKinds = [
        MediaKind.show,
        MediaKind.season,
        MediaKind.artist,
        MediaKind.album,
        MediaKind.collection,
        MediaKind.playlist,
        MediaKind.folder,
      ];
      expect(MediaKind.values.where((kind) => kind.usesLeafWatchCounts), containerKinds);

      for (final kind in MediaKind.values) {
        final item = testMediaItem(
          id: kind.id,
          backend: MediaBackend.plex,
          kind: kind,
          viewCount: 0,
          leafCount: 2,
          viewedLeafCount: 2,
          serverId: 's1',
        );
        final usesLeaves = containerKinds.contains(kind);
        expect(item.isWatched, usesLeaves, reason: '${kind.id} watched semantics');
        expect(item.isPartiallyWatched, isFalse, reason: '${kind.id} partial semantics');
        expect(item.unwatchedCount, usesLeaves ? 0 : null, reason: '${kind.id} unwatched count semantics');
      }
    });

    test('zero container leaf total falls back to viewCount', () {
      final show = testMediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        viewCount: 1,
        leafCount: 0,
        viewedLeafCount: 0,
        serverId: 's1',
      );
      expect(show.isWatched, isTrue);
    });
  });

  group('MediaItem.heroArtCandidates', () {
    test('near-square containers prefer square art before wide cover art', () {
      final movie = _movie(artPath: '/art', backgroundSquarePath: '/square');

      expect(movie.heroArtCandidates(containerAspectRatio: 1.0), ['/square', '/art']);
    });

    test('near-square containers fall back to wide cover art when square art is missing', () {
      final movie = _movie(artPath: '/art');

      expect(movie.heroArtCandidates(containerAspectRatio: 1.0), ['/art']);
    });

    test('wide containers prefer wide cover art before square art', () {
      final movie = _movie(artPath: '/art', backgroundSquarePath: '/square');

      expect(movie.heroArtCandidates(containerAspectRatio: 16 / 9), ['/art', '/square']);
    });

    test('episodes prefer show art before episode art for wide hero containers', () {
      final episode = testMediaItem(
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
      expect(episode.heroArtCandidates(containerAspectRatio: 1.0), ['/square', '/show-art', '/episode-art']);
    });

    test('Jellyfin movies expose every backdrop in display order', () {
      final movie = _movie(
        backend: MediaBackend.jellyfin,
        artPath: '/art-0',
        backdropPaths: ['/art-0', '/art-1', '/art-2'],
        backgroundSquarePath: '/square',
      );

      expect(movie.heroBackdropPaths, ['/art-0', '/art-1', '/art-2']);
      expect(movie.heroArtCandidates(containerAspectRatio: 16 / 9), ['/art-0', '/art-1', '/art-2', '/square']);
    });

    test('episodes prefer inherited backdrops over their own art', () {
      final episode = testMediaItem(
        id: 'e-multi',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        artPath: '/episode-0',
        backdropPaths: ['/episode-0', '/episode-1'],
        grandparentArtPath: '/show-0',
        grandparentBackdropPaths: ['/show-0', '/show-1', '/show-2'],
      );

      expect(episode.heroBackdropPaths, ['/show-0', '/show-1', '/show-2']);
      expect(episode.heroArtCandidates(containerAspectRatio: 16 / 9), [
        '/show-0',
        '/show-1',
        '/show-2',
        '/episode-0',
        '/episode-1',
      ]);
    });

    test('legacy scalar art remains a single static backdrop', () {
      final movie = _movie(artPath: '/legacy-art');

      expect(movie.resolvedBackdropPaths, ['/legacy-art']);
      expect(movie.heroBackdropPaths, ['/legacy-art']);
    });
  });

  group('MediaItem.heroRotationPaths', () {
    /// The order `CyclingMediaBackdrop` attempts paths as each one fails:
    /// every rotating path, then the fallbacks it is not already rotating.
    /// Only the head of this list is ever displayed by a healthy server.
    List<String> displayOrder(MediaItem item, double aspect) {
      final rotation = item.heroRotationPaths(containerAspectRatio: aspect);
      final candidates = item.heroArtCandidates(containerAspectRatio: aspect);
      return [...rotation, ...candidates.where((path) => !rotation.contains(path))];
    }

    test('near-square containers hold on square art instead of rotating backdrops', () {
      final movie = _movie(
        backend: MediaBackend.jellyfin,
        artPath: '/art-0',
        backdropPaths: ['/art-0', '/art-1'],
        backgroundSquarePath: '/square',
      );

      expect(movie.heroRotationPaths(containerAspectRatio: 1.0), ['/square']);
    });

    test('near-square containers rotate backdrops when there is no square art', () {
      final movie = _movie(backend: MediaBackend.jellyfin, artPath: '/art-0', backdropPaths: ['/art-0', '/art-1']);

      expect(movie.heroRotationPaths(containerAspectRatio: 1.0), ['/art-0', '/art-1']);
    });

    test('wide containers rotate backdrops and leave square art behind them', () {
      final movie = _movie(
        backend: MediaBackend.jellyfin,
        artPath: '/art-0',
        backdropPaths: ['/art-0', '/art-1'],
        backgroundSquarePath: '/square',
      );

      expect(movie.heroRotationPaths(containerAspectRatio: 16 / 9), ['/art-0', '/art-1']);
    });

    test('rotation before fallback reproduces the candidate order at every aspect', () {
      final episode = testMediaItem(
        id: 'e-order',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        artPath: '/episode-0',
        backdropPaths: ['/episode-0', '/episode-1'],
        grandparentArtPath: '/show-0',
        grandparentBackdropPaths: ['/show-0', '/show-1'],
        backgroundSquarePath: '/square',
        serverId: 's1',
      );

      for (final aspect in [0.75, 1.0, 1.38, 1.39, 16 / 9, 2.4]) {
        expect(
          displayOrder(episode, aspect),
          episode.heroArtCandidates(containerAspectRatio: aspect),
          reason: 'aspect $aspect',
        );
      }
    });
  });

  group('MediaItem.isPartiallyWatched', () {
    test('show with some leaves watched is partially watched', () {
      final show = testMediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 3,
        serverId: 's1',
      );
      expect(show.isPartiallyWatched, isTrue);
    });

    test('season progress uses direct episode count only when the leaf total is absent', () {
      final season = testMediaItem(
        id: 'season',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.season,
        childCount: 8,
        viewedLeafCount: 3,
      );

      expect(season.leafWatchTotal, 8);
      expect(season.leafWatchFraction, 3 / 8);
      expect(season.isPartiallyWatched, isTrue);
    });

    test('show with zero leaves watched is NOT partially watched', () {
      final show = testMediaItem(
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
      final show = testMediaItem(
        id: 's',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 10,
        serverId: 's1',
      );
      expect(show.isPartiallyWatched, isFalse);
    });

    test('aggregate progress clamps contradictory counts', () {
      final overReported = testMediaItem(
        id: 'show',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 11,
      );
      final negative = overReported.copyWith(viewedLeafCount: -1);

      expect(overReported.leafWatchFraction, 1);
      expect(negative.leafWatchFraction, 0);
    });

    test('movie without leaf info is NOT partially watched (concept doesn\'t apply)', () {
      expect(_movie(viewCount: 0).isPartiallyWatched, isFalse);
      expect(_movie(viewCount: 1).isPartiallyWatched, isFalse);
    });
  });

  group('MediaItem watch-state normalization', () {
    test('leaf state ignores and clears stale aggregate fields', () {
      final movie = testMediaItem(
        id: 'm',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        viewCount: 0,
        leafCount: 3,
        viewedLeafCount: 3,
        raw: {
          'UserData': {'UnplayedItemCount': '0'},
        },
      );

      expect(movie.isWatched, isFalse);
      expect(movie.isPartiallyWatched, isFalse);
      expect(movie.unwatchedCount, isNull);
      expect(movie.withWatchedFlag(false).viewedLeafCount, isNull);
      expect(movie.withWatchedFlag(true).isWatched, isTrue);
    });

    test('container mutations update the aggregate and item flags together', () {
      final album = testMediaItem(
        id: 'a',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        viewCount: 0,
        leafCount: 8,
        viewedLeafCount: 3,
      );

      final watched = album.withWatchedFlag(true);
      expect(watched.viewCount, 1);
      expect(watched.viewedLeafCount, 8);
      expect(watched.isWatched, isTrue);

      final unwatched = watched.withWatchedFlag(false);
      expect(unwatched.viewCount, 0);
      expect(unwatched.viewedLeafCount, 0);
      expect(unwatched.isWatched, isFalse);
    });

    test('container unwatched counts are clamped and tolerate string API values', () {
      final overReported = testMediaItem(
        id: 's1',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        leafCount: 10,
        viewedLeafCount: 11,
      );
      final slimJellyfin = testMediaItem(
        id: 's2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        raw: {
          'UserData': {'UnplayedItemCount': '4'},
        },
      );

      expect(overReported.unwatchedCount, 0);
      expect(slimJellyfin.unwatchedCount, 4);
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
        ratings: [
          MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.4),
          MediaRatingSource(source: 'imdb', value: 8.9, votes: 1200),
        ],
        subtitleLanguage: 'eng',
        trailerKey: '/library/metadata/1',
        playlistItemId: 42,
        playQueueItemId: 7,
      );

      final copy = original.copyWith(title: 'New');

      expect(copy.title, 'New');
      expect(copy.editionTitle, 'Director Cut');
      expect(copy.ratings?.map((rating) => rating.source), ['rottenTomatoesCritic', 'imdb']);
      expect(copy.ratings?.last.votes, 1200);
      expect(copy.subtitleLanguage, 'eng');
      expect(copy.trailerKey, '/library/metadata/1');
      expect(copy.playlistItemId, 42);
      expect(copy.playQueueItemId, 7);
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
        ratings: [
          MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.1),
          MediaRatingSource(source: 'imdb', value: 8.4, votes: 250858),
        ],
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
        trailerKey: '/trailer',
        playlistItemId: 4,
        playQueueItemId: 5,
      );

      final json = original.toJson();
      final decoded = MediaItem.fromJson(json);

      expect(json['backend'], 'plex');
      expect(json.containsKey('summary'), isFalse);
      expect(decoded, isA<PlexMediaItem>());
      final plex = decoded as PlexMediaItem;
      expect(plex.editionTitle, 'Theatrical');
      expect(plex.ratings?.map((rating) => rating.source), ['rottenTomatoesCritic', 'imdb']);
      expect(plex.ratings?.first.value, 9.1);
      expect(plex.ratings?.last.votes, 250858);
      expect(plex.genres, ['Drama']);
      expect(plex.roles?.single.tag, 'Actor');
      expect(plex.mediaVersions?.single.parts.single.streamPath, '/stream');
      expect(plex.subtitleLanguage, 'eng');
      expect(plex.trailerKey, '/trailer');
      expect(plex.playlistItemId, 4);
      expect(plex.playQueueItemId, 5);
    });

    test('round-trips Jellyfin playlist item id', () {
      const original = JellyfinMediaItem(id: 'j1', kind: MediaKind.movie, title: 'Movie', playlistItemId: 'entry-1');

      final json = original.toJson();
      final decoded = MediaItem.fromJson(json);

      expect(json['backend'], 'jellyfin');
      expect(decoded, isA<JellyfinMediaItem>());
      expect((decoded as JellyfinMediaItem).playlistItemId, 'entry-1');
    });

    test('round-trips Jellyfin backdrop lists', () {
      const original = JellyfinMediaItem(
        id: 'j-backdrops',
        kind: MediaKind.episode,
        artPath: '/episode-0',
        backdropPaths: ['/episode-0', '/episode-1'],
        grandparentArtPath: '/show-0',
        grandparentBackdropPaths: ['/show-0', '/show-1'],
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.backdropPaths, ['/episode-0', '/episode-1']);
      expect(decoded.grandparentBackdropPaths, ['/show-0', '/show-1']);
      expect(decoded.heroBackdropPaths, ['/show-0', '/show-1']);
    });

    test('cached leaf items ignore stale aggregate watch fields', () {
      const original = JellyfinMediaItem(
        id: 'cached-music-video',
        kind: MediaKind.clip,
        viewCount: 0,
        leafCount: 1,
        viewedLeafCount: 1,
        raw: {
          'UserData': {'UnplayedItemCount': 0},
        },
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.viewedLeafCount, 1);
      expect(decoded.isWatched, isFalse);
      expect(decoded.isPartiallyWatched, isFalse);
      expect(decoded.unwatchedCount, isNull);
    });

    test('missing backend keeps legacy Plex fallback', () {
      final decoded = MediaItem.fromJson({'id': 'legacy', 'kind': 'movie'});

      expect(decoded, isA<PlexMediaItem>());
      expect(decoded.backend, MediaBackend.plex);
      expect(decoded.id, 'legacy');
      expect(decoded.kind, MediaKind.movie);
    });

    test('an Emby item persists its own backend id and restores the dialect', () {
      const original = JellyfinMediaItem(
        dialect: MediaBrowserDialect.emby,
        // Emby item ids are short numeric strings, not GUIDs.
        id: '7330',
        kind: MediaKind.movie,
        title: 'Movie 001',
        playlistItemId: 'entry-1',
      );

      final json = original.toJson();
      final decoded = MediaItem.fromJson(json);

      // One discriminator on the wire: the union key carries the resolved
      // backend and the dialect is rebuilt from it.
      expect(json['backend'], 'emby');
      expect(json.containsKey('dialect'), isFalse);
      expect(decoded, isA<JellyfinMediaItem>());
      expect(decoded.backend, MediaBackend.emby);
      expect((decoded as JellyfinMediaItem).dialect, MediaBrowserDialect.emby);
      expect(decoded.playlistItemId, 'entry-1');
      expect(decoded.id, '7330');
    });

    test('the compat factory routes both MediaBrowser backends to one variant', () {
      final emby = MediaItem(id: 'e1', backend: MediaBackend.emby, kind: MediaKind.movie);
      final jellyfin = MediaItem(id: 'j1', backend: MediaBackend.jellyfin, kind: MediaKind.movie);

      expect(emby, isA<JellyfinMediaItem>());
      expect(jellyfin, isA<JellyfinMediaItem>());
      expect(emby.backend, MediaBackend.emby);
      expect(jellyfin.backend, MediaBackend.jellyfin);
    });

    test('copyWith preserves the Emby dialect', () {
      final emby = MediaItem(id: 'e1', backend: MediaBackend.emby, kind: MediaKind.movie) as JellyfinMediaItem;

      expect(emby.copyWith(title: 'renamed').backend, MediaBackend.emby);
    });
  });

  group('MediaItem.displayTitle', () {
    test('episode prefers grandparent (show) title', () {
      final ep = testMediaItem(
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
      final season = testMediaItem(
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

  group('MediaItem music metadata', () {
    test('album year is exposed only for tracks and albums', () {
      final track = testMediaItem(kind: MediaKind.track, parentTitle: 'Album', year: 2001);
      final album = testMediaItem(kind: MediaKind.album, title: 'Album', year: 2001);

      expect(track.albumTitle, 'Album');
      expect(track.albumYear, 2001);
      expect(album.albumYear, 2001);
      expect(_movie(year: 2001).albumYear, isNull);
    });
  });
}
