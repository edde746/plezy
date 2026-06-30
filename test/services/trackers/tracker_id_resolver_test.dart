import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/models/trackers/anime_lists_mapping.dart';
import 'package:vibe_stream/models/trackers/fribb_mapping_row.dart';
import 'package:vibe_stream/services/trackers/anime_episode_progress_resolver.dart';
import 'package:vibe_stream/services/trackers/anime_lists_mapping_store.dart';
import 'package:vibe_stream/services/trackers/fribb_mapping_store.dart';
import 'package:vibe_stream/services/trackers/tracker_id_resolver.dart';
import 'package:vibe_stream/utils/external_ids.dart';

class _FakeMediaServerClient implements MediaServerClient {
  final Map<String, ExternalIds> externalIdsByItem;
  final List<String> externalIdCalls = [];

  _FakeMediaServerClient(this.externalIdsByItem);

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    externalIdCalls.add(itemId);
    return externalIdsByItem[itemId] ?? const ExternalIds();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFribbLookup implements FribbMappingLookup {
  final List<FribbMappingRow> rows;
  int lookups = 0;

  _FakeFribbLookup(this.rows);

  @override
  Future<List<FribbMappingRow>> lookup({int? tvdbId, int? tmdbId, String? imdbId}) async {
    lookups++;
    return rows;
  }
}

class _FakeAnimeProgressLookup implements AnimeEpisodeProgressLookup {
  ResolvedAnimeProgress? result;
  int resolveCalls = 0;
  int clearCalls = 0;
  MediaItem? lastEpisode;
  AnimeProgressScope? lastScope;
  AnimeEpisodeMatch? lastMatch;
  bool? lastIncludeCurrentEpisode;

  _FakeAnimeProgressLookup(int? progress)
    : result = progress == null ? null : ResolvedAnimeProgress(progress: progress);

  @override
  Future<ResolvedAnimeProgress?> resolve(
    MediaItem episode, {
    required AnimeProgressScope scope,
    AnimeEpisodeMatch? animeMatch,
    Future<AnimeEpisodeMatch?> Function(MediaItem episode)? episodeMatcher,
    bool includeCurrentEpisode = true,
  }) async {
    resolveCalls++;
    lastEpisode = episode;
    lastScope = scope;
    lastMatch = animeMatch;
    lastIncludeCurrentEpisode = includeCurrentEpisode;
    return result;
  }

  @override
  void clearCache() {
    clearCalls++;
  }
}

class _FakeAnimeListsLookup implements AnimeListsMappingLookup {
  final Map<String, AnimeEpisodeMatch> matches;

  const _FakeAnimeListsLookup({this.matches = const {}});

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async {
    return matches['$season-$episodeNumber'];
  }

  @override
  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) async => const <int>{};

  @override
  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId}) async => const <int>{};
}

MediaItem _episode({int season = 23, int number = 6}) => MediaItem(
  id: 'episode-$season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  grandparentId: 'show-1',
  parentIndex: season,
  index: number,
);

TrackerIdResolver _resolver({
  required List<FribbMappingRow> rows,
  required _FakeAnimeProgressLookup animeProgress,
  _FakeFribbLookup? lookup,
  AnimeListsMappingLookup animeLists = const _FakeAnimeListsLookup(),
}) {
  return TrackerIdResolver(
    _FakeMediaServerClient({'show-1': const ExternalIds(tvdb: 81797, tmdb: 37854, imdb: 'tt0388629')}),
    store: lookup ?? _FakeFribbLookup(rows),
    animeLists: animeLists,
    animeProgress: animeProgress,
  );
}

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
  group('TrackerIdResolver anime progress', () {
    test('one unseasoned regular TV row uses show-scope progress', () async {
      final animeProgress = _FakeAnimeProgressLookup(6);
      final resolver = _resolver(
        animeProgress: animeProgress,
        rows: const [
          FribbMappingRow(
            tvdbId: 81797,
            tmdbIds: [37854],
            imdbIds: ['tt0388629'],
            malId: 21,
            anilistId: 21,
            type: 'TV',
          ),
        ],
      );

      final ids = await resolver.resolveShowForEpisode(_episode());

      expect(ids?.anime?.mal, 21);
      expect(ids?.animeProgressScope, AnimeProgressScope.show);
      expect(ids?.animeProgress, 6);
      expect(animeProgress.resolveCalls, 1);
      expect(animeProgress.lastEpisode?.id, 'episode-23-6');
      expect(animeProgress.lastScope, AnimeProgressScope.show);
    });

    test('exact season-scoped row uses season-scope progress', () async {
      final animeProgress = _FakeAnimeProgressLookup(18);
      final resolver = _resolver(
        animeProgress: animeProgress,
        rows: const [
          FribbMappingRow(tvdbId: 81797, malId: 100, tvdbSeason: 1, type: 'TV'),
          FribbMappingRow(tvdbId: 81797, malId: 200, tvdbSeason: 2, type: 'TV'),
        ],
      );

      final ids = await resolver.resolveShowForEpisode(_episode(season: 2));

      expect(ids?.anime?.mal, 200);
      expect(ids?.animeProgressScope, AnimeProgressScope.season);
      expect(ids?.animeProgress, 18);
      expect(animeProgress.resolveCalls, 1);
      expect(animeProgress.lastScope, AnimeProgressScope.season);
    });

    test('does not guess when multiple regular rows are unseasoned', () async {
      final animeProgress = _FakeAnimeProgressLookup(1061);
      final resolver = _resolver(
        animeProgress: animeProgress,
        rows: const [
          FribbMappingRow(tvdbId: 81797, malId: 1, type: 'TV'),
          FribbMappingRow(tvdbId: 81797, malId: 2, type: 'ONA'),
        ],
      );

      final ids = await resolver.resolveShowForEpisode(_episode());

      expect(ids?.anime?.mal, 1);
      expect(ids?.animeProgressScope, isNull);
      expect(ids?.animeProgress, isNull);
      expect(animeProgress.resolveCalls, 0);
    });

    test('movie and special rows do not make a regular TV row ambiguous', () async {
      final animeProgress = _FakeAnimeProgressLookup(1061);
      final resolver = _resolver(
        animeProgress: animeProgress,
        rows: const [
          FribbMappingRow(tvdbId: 81797, malId: 21, type: 'TV'),
          FribbMappingRow(tvdbId: 81797, malId: 459, tvdbSeason: 0, type: 'MOVIE'),
          FribbMappingRow(tvdbId: 81797, malId: 466, tvdbSeason: 0, type: 'OVA'),
          FribbMappingRow(tvdbId: 81797, malId: 492, tvdbSeason: 0, type: 'SPECIAL'),
        ],
      );

      final ids = await resolver.resolveShowForEpisode(_episode());

      expect(ids?.anime?.mal, 21);
      expect(ids?.animeProgressScope, AnimeProgressScope.show);
      expect(ids?.animeProgress, 1061);
      expect(animeProgress.resolveCalls, 1);
      expect(animeProgress.lastScope, AnimeProgressScope.show);
    });

    test('clearCache clears ID and anime progress caches', () async {
      final animeProgress = _FakeAnimeProgressLookup(1061);
      final lookup = _FakeFribbLookup(const [FribbMappingRow(tvdbId: 81797, malId: 21, type: 'TV')]);
      final resolver = _resolver(rows: lookup.rows, lookup: lookup, animeProgress: animeProgress);

      await resolver.resolveShowForEpisode(_episode());
      resolver.clearCache();
      await resolver.resolveShowForEpisode(_episode(number: 7));

      expect(lookup.lookups, 2);
      expect(animeProgress.clearCalls, 1);
      expect(animeProgress.resolveCalls, 2);
    });

    test('same server season can select different anime entries by episode range', () async {
      final animeProgress = _FakeAnimeProgressLookup(2);
      final resolver = _resolver(
        animeProgress: animeProgress,
        animeLists: _FakeAnimeListsLookup(matches: {'1-14': _match(anidbId: 222, serverEpisode: 14, animeEpisode: 2)}),
        rows: const [
          FribbMappingRow(anidbId: 111, tvdbId: 81797, malId: 101, tvdbSeason: 1, type: 'TV'),
          FribbMappingRow(anidbId: 222, tvdbId: 81797, malId: 102, tvdbSeason: 1, type: 'TV'),
        ],
      );

      final ids = await resolver.resolveShowForEpisode(_episode(season: 1, number: 14));

      expect(ids?.anime?.mal, 102);
      expect(ids?.animeProgressScope, AnimeProgressScope.mapped);
      expect(ids?.animeEpisodeNumber, 2);
      expect(ids?.animeProgress, 2);
      expect(animeProgress.lastScope, AnimeProgressScope.mapped);
      expect(animeProgress.lastMatch?.anidbId, 222);
    });

    test('passes includeCurrentEpisode through for unwatch progress', () async {
      final animeProgress = _FakeAnimeProgressLookup(1);
      final resolver = _resolver(
        animeProgress: animeProgress,
        animeLists: _FakeAnimeListsLookup(matches: {'1-14': _match(anidbId: 222, serverEpisode: 14, animeEpisode: 2)}),
        rows: const [FribbMappingRow(anidbId: 222, tvdbId: 81797, malId: 102, tvdbSeason: 1, type: 'TV')],
      );

      final ids = await resolver.resolveShowForEpisode(_episode(season: 1, number: 14), includeCurrentEpisode: false);

      expect(ids?.animeProgress, 1);
      expect(animeProgress.lastIncludeCurrentEpisode, isFalse);
    });

    test('episode-aware cache does not reuse a same-season split-cour row', () async {
      final animeProgress = _FakeAnimeProgressLookup(null);
      final lookup = _FakeFribbLookup(const [
        FribbMappingRow(anidbId: 111, tvdbId: 81797, malId: 101, tvdbSeason: 1, type: 'TV'),
        FribbMappingRow(anidbId: 222, tvdbId: 81797, malId: 102, tvdbSeason: 1, type: 'TV'),
      ]);
      final client = _FakeMediaServerClient({'show-1': const ExternalIds(tvdb: 81797)});
      final resolver = TrackerIdResolver(
        client,
        store: lookup,
        animeLists: _FakeAnimeListsLookup(
          matches: {
            '1-12': _match(anidbId: 111, serverEpisode: 12, animeEpisode: 12),
            '1-13': _match(anidbId: 222, serverEpisode: 13, animeEpisode: 1),
          },
        ),
        animeProgress: animeProgress,
      );

      final first = await resolver.resolveShowForEpisode(_episode(season: 1, number: 12), includeAnimeProgress: false);
      final second = await resolver.resolveShowForEpisode(_episode(season: 1, number: 13), includeAnimeProgress: false);

      expect(first?.anime?.mal, 101);
      expect(second?.anime?.mal, 102);
      expect(client.externalIdCalls, ['show-1']);
      expect(lookup.lookups, 2);
    });
  });
}
