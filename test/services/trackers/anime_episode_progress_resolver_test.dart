import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/models/trackers/anime_lists_mapping.dart';
import 'package:vibe_stream/services/trackers/anime_episode_progress_resolver.dart';

class _FakeMediaServerClient implements MediaServerClient {
  final Map<String, List<MediaItem>> childrenByParent;
  final Map<String, List<MediaItem>> playableByParent;
  Object? throwOnFetchChildren;
  int fetchChildrenCalls = 0;
  int fetchPlayableDescendantsCalls = 0;

  _FakeMediaServerClient(this.childrenByParent, {this.playableByParent = const {}});

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    fetchChildrenCalls++;
    final error = throwOnFetchChildren;
    if (error != null) throw error;
    return childrenByParent[parentId] ?? const [];
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    fetchPlayableDescendantsCalls++;
    return playableByParent[parentId] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _season(int number, {int? watched, int? total}) => MediaItem(
  id: 'season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.season,
  title: 'Season $number',
  index: number,
  leafCount: total,
  viewedLeafCount: watched,
);

MediaItem _episode({int season = 2, int number = 6, String showId = 'show-1', int? viewCount}) => MediaItem(
  id: 'episode-$season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  grandparentId: showId,
  parentIndex: season,
  index: number,
  viewCount: viewCount,
);

AnimeEpisodeMatch _match({required int anidbId, required int serverEpisode, required int animeEpisode}) =>
    AnimeEpisodeMatch(
      anidbId: anidbId,
      anidbSeason: 1,
      anidbEpisode: animeEpisode,
      provider: AnimeListProvider.tvdb,
      externalSeason: 1,
      externalEpisode: serverEpisode,
      kind: AnimeListMatchKind.range,
    );

void main() {
  group('AnimeEpisodeProgressResolver', () {
    test('show scope sums watched counts across regular seasons', () async {
      final seasons = [_season(1, watched: 45), _season(2, watched: 10)];
      final resolver = AnimeEpisodeProgressResolver(_FakeMediaServerClient({'show-1': seasons}));

      final result = await resolver.resolve(_episode(), scope: AnimeProgressScope.show);

      expect(result?.progress, 56);
    });

    test('show scope ignores specials season', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(0, watched: 999), _season(1, watched: 5)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 1, number: 6), scope: AnimeProgressScope.show);

      expect(result?.progress, 6);
    });

    test('season scope uses only current season watched count', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(1, watched: 100), _season(2, watched: 5)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 2, number: 6), scope: AnimeProgressScope.season);

      expect(result?.progress, 6);
    });

    test('season scope caps progress at known season total', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(2, watched: 12, total: 12)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 2, number: 12), scope: AnimeProgressScope.season);

      expect(result?.progress, 12);
    });

    test('show scope caps progress at known show total', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(1, watched: 12, total: 12), _season(2, watched: 12, total: 12)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 2, number: 12), scope: AnimeProgressScope.show);

      expect(result?.progress, 24);
    });

    test('unknown total still returns progress', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(1, watched: 11)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 1, number: 12), scope: AnimeProgressScope.season);

      expect(result?.progress, 12);
    });

    test('already watched current episode does not add one', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(1, watched: 5)],
        }),
      );

      final result = await resolver.resolve(
        _episode(season: 1, number: 5, viewCount: 1),
        scope: AnimeProgressScope.season,
      );

      expect(result?.progress, 5);
    });

    test('missing viewedLeafCount returns null', () async {
      final resolver = AnimeEpisodeProgressResolver(
        _FakeMediaServerClient({
          'show-1': [_season(1, total: 12)],
        }),
      );

      final result = await resolver.resolve(_episode(season: 1, number: 1), scope: AnimeProgressScope.season);

      expect(result, isNull);
    });

    test('returns null instead of throwing when season fetch fails', () async {
      final client = _FakeMediaServerClient(const {});
      client.throwOnFetchChildren = StateError('offline');
      final resolver = AnimeEpisodeProgressResolver(client);

      final result = await resolver.resolve(_episode(season: 2, number: 1), scope: AnimeProgressScope.show);

      expect(result, isNull);
    });

    test('in-flight load is reused for concurrent episodes in the same show', () async {
      final client = _FakeMediaServerClient({
        'show-1': [_season(1, watched: 10), _season(2, watched: 5)],
      });
      final resolver = AnimeEpisodeProgressResolver(client);

      final first = resolver.resolve(_episode(season: 2, number: 6), scope: AnimeProgressScope.show);
      final second = resolver.resolve(_episode(season: 2, number: 7), scope: AnimeProgressScope.show);

      expect((await first)?.progress, 16);
      expect((await second)?.progress, 16);
      expect(client.fetchChildrenCalls, 1);
    });

    test('sequential loads refetch watched counts', () async {
      final client = _FakeMediaServerClient({
        'show-1': [_season(1, watched: 5)],
      });
      final resolver = AnimeEpisodeProgressResolver(client);

      expect((await resolver.resolve(_episode(season: 1, number: 6), scope: AnimeProgressScope.season))?.progress, 6);
      client.childrenByParent['show-1'] = [_season(1, watched: 6)];
      expect((await resolver.resolve(_episode(season: 1, number: 7), scope: AnimeProgressScope.season))?.progress, 7);
      expect(client.fetchChildrenCalls, 2);
    });

    test('mapped scope counts only watched episodes in the selected anime entry', () async {
      final client = _FakeMediaServerClient(
        const {},
        playableByParent: {
          'show-1': [
            _episode(season: 1, number: 12, viewCount: 1),
            _episode(season: 1, number: 13, viewCount: 1),
            _episode(season: 1, number: 14),
          ],
        },
      );
      final resolver = AnimeEpisodeProgressResolver(client);

      final result = await resolver.resolve(
        _episode(season: 1, number: 14),
        scope: AnimeProgressScope.mapped,
        animeMatch: _match(anidbId: 2, serverEpisode: 14, animeEpisode: 2),
        episodeMatcher: (episode) async => switch (episode.index) {
          12 => _match(anidbId: 1, serverEpisode: 12, animeEpisode: 12),
          13 => _match(anidbId: 2, serverEpisode: 13, animeEpisode: 1),
          14 => _match(anidbId: 2, serverEpisode: 14, animeEpisode: 2),
          _ => null,
        },
      );

      expect(result?.progress, 2);
      expect(client.fetchPlayableDescendantsCalls, 1);
    });

    test('mapped scope can exclude the current episode for unwatch progress', () async {
      final client = _FakeMediaServerClient(
        const {},
        playableByParent: {
          'show-1': [_episode(season: 1, number: 13, viewCount: 1), _episode(season: 1, number: 14)],
        },
      );
      final resolver = AnimeEpisodeProgressResolver(client);

      final result = await resolver.resolve(
        _episode(season: 1, number: 14),
        scope: AnimeProgressScope.mapped,
        animeMatch: _match(anidbId: 2, serverEpisode: 14, animeEpisode: 2),
        includeCurrentEpisode: false,
        episodeMatcher: (episode) async => switch (episode.index) {
          13 => _match(anidbId: 2, serverEpisode: 13, animeEpisode: 1),
          14 => _match(anidbId: 2, serverEpisode: 14, animeEpisode: 2),
          _ => null,
        },
      );

      expect(result?.progress, 1);
    });
  });
}
