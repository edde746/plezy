import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

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
