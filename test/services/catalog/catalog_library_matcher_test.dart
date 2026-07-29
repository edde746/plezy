import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';

class _LookupCall {
  final ExternalIds ids;
  final MediaKind kind;
  final List<String> titles;
  final int? year;
  final String? plexGuid;
  final ExternalSeasonRef? season;

  const _LookupCall({
    required this.ids,
    required this.kind,
    required this.titles,
    required this.year,
    required this.plexGuid,
    required this.season,
  });
}

class _FakeDataAggregationService extends DataAggregationService {
  _FakeDataAggregationService(super.serverManager);

  final List<_LookupCall> calls = [];
  final List<List<MediaItem>> responses = [];

  @override
  Future<List<MediaItem>> findByExternalIdsAcrossServers(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async {
    calls.add(
      _LookupCall(ids: ids, kind: kind, titles: List.of(titles), year: year, plexGuid: plexGuid, season: season),
    );
    return responses.removeAt(0);
  }
}

class _Harness {
  late final MultiServerManager manager;
  late final _FakeDataAggregationService aggregation;
  late final MultiServerProvider multiServer;
  late final CatalogLibraryMatcher matcher;

  _Harness({DateTime Function()? now}) {
    manager = MultiServerManager();
    aggregation = _FakeDataAggregationService(manager);
    multiServer = MultiServerProvider(manager, aggregation);
    matcher = now == null ? CatalogLibraryMatcher(multiServer) : CatalogLibraryMatcher.withClock(multiServer, now);
  }

  void dispose() {
    multiServer.dispose();
    manager.dispose();
  }
}

void main() {
  test('season entries sharing canonical ids keep independent cached matches', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    final firstHit = testMediaItem(id: 'server-season-1', kind: MediaKind.show);
    final secondHit = testMediaItem(id: 'server-season-2', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      [firstHit],
      [secondHit],
    ]);
    const first = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'Mushoku Tensei',
      ids: CatalogItemIds(mal: 39535, imdb: 'tt13293588'),
    );
    const second = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'Mushoku Tensei II',
      ids: CatalogItemIds(mal: 51179, imdb: 'tt13293588'),
    );

    expect(first.identityKey, second.identityKey);
    expect(first.entryIdentityKey, isNot(second.entryIdentityKey));
    expect((await harness.matcher.match(first)).single, same(firstHit));
    expect((await harness.matcher.match(second)).single, same(secondHit));
    expect((await harness.matcher.match(first)).single, same(firstHit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('negative cache entries are isolated by catalog source', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    final anilistHit = testMediaItem(id: 'japanese-title-match', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      const [],
      [anilistHit],
    ]);
    const malItem = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'English Title',
      altTitles: ['MAL Synonym'],
      ids: CatalogItemIds(mal: 100, tmdb: 200),
    );
    const anilistItem = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'English Title',
      altTitles: ['日本語タイトル'],
      ids: CatalogItemIds(mal: 100, anilist: 300, tmdb: 200),
    );

    expect(malItem.entryIdentityKey, anilistItem.entryIdentityKey);
    expect(await harness.matcher.match(malItem), isEmpty);
    expect((await harness.matcher.match(anilistItem)).single, same(anilistHit));
    expect(harness.aggregation.calls, hasLength(2));
    expect(harness.aggregation.calls.last.titles, contains('日本語タイトル'));
  });

  test('negative matches expire after negativeTtl while positive matches persist', () async {
    var now = DateTime.utc(2026, 7, 28, 12);
    final harness = _Harness(now: () => now);
    addTearDown(harness.dispose);
    final hit = testMediaItem(id: 'new-library-item', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      const [],
      [hit],
    ]);
    const item = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'New Show',
      ids: CatalogItemIds(anilist: 1, tmdb: 42),
    );

    expect(await harness.matcher.match(item), isEmpty);
    now = now.add(CatalogLibraryMatcher.negativeTtl - const Duration(seconds: 1));
    expect(await harness.matcher.match(item), isEmpty);
    expect(harness.aggregation.calls, hasLength(1));

    now = now.add(const Duration(seconds: 1));
    expect((await harness.matcher.match(item)).single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));

    now = now.add(const Duration(days: 30));
    expect((await harness.matcher.match(item)).single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('forwards season-stripped title candidates and season reference', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(const []);
    const season = ExternalSeasonRef(tvdb: 2, tmdb: 1);
    const item = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'You and I Are Polar Opposites Season 2',
      altTitles: ['Seihantai na Kimi to Boku 2nd Season'],
      season: season,
      year: 2027,
      ids: CatalogItemIds(mal: 59193, tvdb: 457078),
    );

    await harness.matcher.match(item);

    final call = harness.aggregation.calls.single;
    expect(call.kind, MediaKind.show);
    expect(call.ids.tvdb, 457078);
    expect(call.year, isNull, reason: '2027 is season two\'s year, not the parent show\'s');
    expect(call.plexGuid, isNull);
    expect(call.season, same(season));
    // Capped at two: the entry's own title and its season-stripped form.
    expect(call.titles, ['You and I Are Polar Opposites Season 2', 'You and I Are Polar Opposites']);
  });

  test('keeps the year for an entry that is not a sequel', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(const []);
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: 'Severance',
      year: 2022,
      ids: CatalogItemIds(trakt: 1, tvdb: 371980),
    );

    await harness.matcher.match(item);

    final call = harness.aggregation.calls.single;
    expect(call.year, 2022);
    expect(call.titles, ['Severance'], reason: 'nothing to strip, so one candidate and one request');
  });

  test('drops the year from a sequel title even when Fribb mapped no season', () async {
    // RC3 entries carry no season, but a strippable suffix says sequel just as
    // reliably, and the year window around it would exclude the parent show.
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(const []);
    const item = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'Some Show 2nd Season',
      year: 2026,
      ids: CatalogItemIds(anilist: 5, tvdb: 1),
    );

    await harness.matcher.match(item);

    expect(harness.aggregation.calls.single.year, isNull);
  });

  test('constructs a Plex guid for Discover items without external ids', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(const []);
    const item = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.movie,
      title: 'Plex-only Movie',
      ids: CatalogItemIds(plex: '5d776828880197001ec90e13'),
    );

    await harness.matcher.match(item);

    final call = harness.aggregation.calls.single;
    expect(call.ids.hasAny, isFalse);
    expect(call.plexGuid, 'plex://movie/5d776828880197001ec90e13');
  });

  test('an id-poor negative does not suppress the detail-enriched retry', () async {
    // #1715: a Plex Discover row item carries only its rating key, and the
    // exact-guid lookup can miss even for owned titles (Discover dupes).
    // The detail body brings the external ids moments later; that richer
    // lookup must reach the servers instead of the bare form's cached
    // negative.
    final harness = _Harness();
    addTearDown(harness.dispose);
    final hit = testMediaItem(id: 'server-movie', kind: MediaKind.movie);
    harness.aggregation.responses.addAll([
      const [],
      [hit],
    ]);
    const bare = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.movie,
      title: 'Night on the Galactic Railroad',
      ids: CatalogItemIds(plex: '5d776b59ad5437001f79c6f8'),
    );
    const enriched = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.movie,
      title: 'Night on the Galactic Railroad',
      ids: CatalogItemIds(plex: '5d776b59ad5437001f79c6f8', imdb: 'tt0089445', tmdb: 34523),
    );

    expect(bare.entryIdentityKey, enriched.entryIdentityKey);
    expect(await harness.matcher.match(bare), isEmpty);
    expect((await harness.matcher.match(enriched)).single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
    expect(harness.aggregation.calls.last.ids.imdb, 'tt0089445');

    // Both forms stay memoized independently.
    expect((await harness.matcher.match(enriched)).single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('only a Plex Discover item contributes a guid, and it costs no request', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.addAll([const [], const []]);
    // A MAL entry can carry a Plex rating key through cross-source membership,
    // but that key is not a Discover guid and must never be synthesised into
    // one — the fast path is only sound for items that came from Discover.
    const foreign = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'Not A Discover Item',
      ids: CatalogItemIds(mal: 7, plex: '1234'),
    );
    const discover = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.show,
      title: 'Discover Show',
      ids: CatalogItemIds(plex: 'abc123'),
    );

    await harness.matcher.match(foreign);
    await harness.matcher.match(discover);

    expect(harness.aggregation.calls.map((call) => call.plexGuid), [null, 'plex://show/abc123']);
  });
}
