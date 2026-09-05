import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/library_lookup.dart';
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
  final List<LibraryLookupResult> responses = [];

  @override
  Future<LibraryLookupResult> findByExternalIdsAcrossServers(
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
      libraryLookupResult([firstHit]),
      libraryLookupResult([secondHit]),
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
    expect((await harness.matcher.match(first)).items.single, same(firstHit));
    expect((await harness.matcher.match(second)).items.single, same(secondHit));
    expect((await harness.matcher.match(first)).items.single, same(firstHit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('negative cache entries are isolated by catalog source', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    final anilistHit = testMediaItem(id: 'japanese-title-match', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      libraryLookupResult(const []),
      libraryLookupResult([anilistHit]),
    ]);
    const malItem = CatalogItem(
      source: CatalogSourceId.mal,
      kind: MediaKind.show,
      title: 'English Title',
      ids: CatalogItemIds(mal: 100, tmdb: 200),
    );
    const anilistItem = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'English Title',
      originalTitle: '日本語タイトル',
      ids: CatalogItemIds(mal: 100, anilist: 300, tmdb: 200),
    );

    expect(malItem.entryIdentityKey, anilistItem.entryIdentityKey);
    expect((await harness.matcher.match(malItem)).items, isEmpty);
    expect((await harness.matcher.match(anilistItem)).items.single, same(anilistHit));
    expect(harness.aggregation.calls, hasLength(2));
    expect(harness.aggregation.calls.last.titles, contains('日本語タイトル'));
  });

  test('negative matches expire after negativeTtl while positive matches persist', () async {
    var now = DateTime.utc(2026, 7, 28, 12);
    final harness = _Harness(now: () => now);
    addTearDown(harness.dispose);
    final hit = testMediaItem(id: 'new-library-item', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      libraryLookupResult(const []),
      libraryLookupResult([hit]),
    ]);
    const item = CatalogItem(
      source: CatalogSourceId.anilist,
      kind: MediaKind.show,
      title: 'New Show',
      ids: CatalogItemIds(anilist: 1, tmdb: 42),
    );

    expect((await harness.matcher.match(item)).items, isEmpty);
    now = now.add(CatalogLibraryMatcher.negativeTtl - const Duration(seconds: 1));
    expect((await harness.matcher.match(item)).items, isEmpty);
    expect(harness.aggregation.calls, hasLength(1));

    now = now.add(const Duration(seconds: 1));
    expect((await harness.matcher.match(item)).items.single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));

    now = now.add(const Duration(days: 30));
    expect((await harness.matcher.match(item)).items.single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('a wave a server sat out is retried after negativeTtl even when it found copies', () async {
    // #2098: a slow server timing out is not evidence the title is absent
    // there. The degraded answer is shown, with the failed server named, but
    // it must not be memoized for the session like an authoritative hit.
    var now = DateTime.utc(2026, 7, 28, 12);
    final harness = _Harness(now: () => now);
    addTearDown(harness.dispose);
    final fastCopy = testMediaItem(id: 'fast-copy', serverId: 'fast');
    final slowCopy = testMediaItem(id: 'slow-copy', serverId: 'slow');
    harness.aggregation.responses.addAll([
      libraryLookupResult([fastCopy], succeeded: {'fast'}, failed: {'slow'}),
      libraryLookupResult([fastCopy, slowCopy], succeeded: {'fast', 'slow'}),
    ]);
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Slow Server Movie',
      ids: CatalogItemIds(trakt: 9, tmdb: 77),
    );

    final degraded = await harness.matcher.match(item);
    expect(degraded.items, [fastCopy]);
    expect(degraded.failedServerIds, {'slow'});
    now = now.add(CatalogLibraryMatcher.negativeTtl - const Duration(seconds: 1));
    expect(await harness.matcher.match(item), same(degraded));
    expect(harness.aggregation.calls, hasLength(1));

    now = now.add(const Duration(seconds: 1));
    expect((await harness.matcher.match(item)).items, [fastCopy, slowCopy]);
    expect(harness.aggregation.calls, hasLength(2));
    now = now.add(const Duration(days: 30));
    expect((await harness.matcher.match(item)).items, [fastCopy, slowCopy]);
    expect(harness.aggregation.calls, hasLength(2), reason: 'every server answered, so the hit is kept');
  });

  test('a server that sits out the retry keeps its last-known copies until it answers itself', () async {
    // Wave 1: A holds a copy, B is unreachable. After negativeTtl, wave 2:
    // A is unreachable, B answers empty. A's copy is verified and nothing
    // says A removed it, so it stays; only A's own answer may replace it.
    var now = DateTime.utc(2026, 7, 28, 12);
    final harness = _Harness(now: () => now);
    addTearDown(harness.dispose);
    final aCopy = testMediaItem(id: 'a-copy', serverId: 'a');
    harness.aggregation.responses.addAll([
      libraryLookupResult([aCopy], succeeded: {'a'}, failed: {'b'}),
      libraryLookupResult(const [], succeeded: {'b'}, failed: {'a'}),
      libraryLookupResult(const [], succeeded: {'a', 'b'}),
    ]);
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Flaky Servers Movie',
      ids: CatalogItemIds(trakt: 10, tmdb: 78),
    );

    expect((await harness.matcher.match(item)).items, [aCopy]);
    now = now.add(CatalogLibraryMatcher.negativeTtl);
    final retained = await harness.matcher.match(item);
    expect(retained.items, [aCopy]);
    expect(retained.failedServerIds, {'a'});
    expect(retained.succeededServerIds, {'b'});
    expect(harness.aggregation.calls, hasLength(2));

    // A answering empty for itself is the evidence that the copy is gone.
    now = now.add(CatalogLibraryMatcher.negativeTtl);
    expect((await harness.matcher.match(item)).items, isEmpty);
    expect(harness.aggregation.calls, hasLength(3));
  });

  test('forwards season-stripped title candidates and season reference', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(libraryLookupResult(const []));
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
    // The own family only: alternates are not candidates, and the native
    // title is absent here.
    expect(call.titles, ['You and I Are Polar Opposites Season 2', 'You and I Are Polar Opposites']);
  });

  test('keeps the year for an entry that is not a sequel', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(libraryLookupResult(const []));
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

  test('the native title leads and alternate titles are not candidates', () async {
    // #2098: both backends index `originalTitle`, so the native title alone
    // reaches a copy filed under English, romaji or a localized title. The
    // alternates only ever repeated that work.
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(libraryLookupResult(const []));
    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.show,
      title: "Frieren: Beyond Journey's End Season 2",
      originalTitle: '葬送のフリーレン',
      altTitles: ['Sousou no Frieren', 'Frieren: Tras finalizar el viaje'],
      ids: CatalogItemIds(trakt: 198225, tvdb: 424536),
    );

    await harness.matcher.match(item);

    expect(harness.aggregation.calls.single.titles, [
      '葬送のフリーレン',
      "Frieren: Beyond Journey's End Season 2",
      "Frieren: Beyond Journey's End",
    ]);
  });

  test('a detail load that adds the native title is not served the bare form\'s cached negative', () async {
    // A Plex Discover row carries no originalTitle; the detail body does,
    // and only that title reaches a romaji-filed library.
    final harness = _Harness();
    addTearDown(harness.dispose);
    final romajiCopy = testMediaItem(id: 'romaji-copy', kind: MediaKind.show);
    harness.aggregation.responses.addAll([
      libraryLookupResult(const []),
      libraryLookupResult([romajiCopy]),
    ]);
    const bare = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.show,
      title: "Frieren: Beyond Journey's End",
      ids: CatalogItemIds(plex: '631cc', tvdb: 424536),
    );
    const enriched = CatalogItem(
      source: CatalogSourceId.plex,
      kind: MediaKind.show,
      title: "Frieren: Beyond Journey's End",
      originalTitle: '葬送のフリーレン',
      ids: CatalogItemIds(plex: '631cc', tvdb: 424536),
    );

    expect((await harness.matcher.match(bare)).items, isEmpty);
    expect((await harness.matcher.match(enriched)).items.single, same(romajiCopy));
    expect(harness.aggregation.calls, hasLength(2));
    expect(harness.aggregation.calls.last.titles.first, '葬送のフリーレン');
  });

  test('drops the year from a sequel title even when Fribb mapped no season', () async {
    // RC3 entries carry no season, but a strippable suffix says sequel just as
    // reliably, and the year window around it would exclude the parent show.
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.add(libraryLookupResult(const []));
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
    harness.aggregation.responses.add(libraryLookupResult(const []));
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
      libraryLookupResult(const []),
      libraryLookupResult([hit]),
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
    expect((await harness.matcher.match(bare)).items, isEmpty);
    expect((await harness.matcher.match(enriched)).items.single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
    expect(harness.aggregation.calls.last.ids.imdb, 'tt0089445');

    // Both forms stay memoized independently.
    expect((await harness.matcher.match(enriched)).items.single, same(hit));
    expect(harness.aggregation.calls, hasLength(2));
  });

  test('only a Plex Discover item contributes a guid, and it costs no request', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.aggregation.responses.addAll([libraryLookupResult(const []), libraryLookupResult(const [])]);
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
