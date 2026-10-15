import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/community_ratings.dart';
import 'package:plezy/utils/external_ids.dart';

MediaRatingSource _r(String source, double value, {int? votes}) =>
    MediaRatingSource(source: source, value: value, votes: votes);

List<(String, double)> _scores(List<MediaRatingSource> ratings) => [for (final r in ratings) (r.source, r.value)];

void main() {
  group('mergeCommunityRatings', () {
    test('keeps one score per source: its own service, then MDBList, then Simkl, then the rest', () {
      final merged = mergeCommunityRatings([
        (origin: CatalogSourceId.mal, ratings: [_r('mal', 8.6)]),
        (origin: CatalogSourceId.simkl, ratings: [_r('simkl', 8.4), _r('imdb', 9.0), _r('mal', 8.5)]),
        (origin: CatalogSourceId.mdblist, ratings: [_r('imdb', 9.3), _r('trakt', 9.1), _r('mal', 8.0)]),
        (origin: CatalogSourceId.trakt, ratings: [_r('trakt', 8.8)]),
      ]);

      expect(_scores(merged), [('imdb', 9.3), ('trakt', 8.8), ('simkl', 8.4), ('mal', 8.6)]);
    });

    test('a later answer from a lower-precedence provider does not replace an earlier one', () {
      final merged = mergeCommunityRatings([
        (origin: CatalogSourceId.mdblist, ratings: [_r('imdb', 9.3)]),
        (origin: CatalogSourceId.simkl, ratings: [_r('imdb', 9.0)]),
      ]);

      expect(_scores(merged), [('imdb', 9.3)]);
    });

    test('orders Rotten Tomatoes, IMDb, TMDB, Metacritic, Letterboxd before the trackers', () {
      final merged = mergeCommunityRatings([
        (
          origin: CatalogSourceId.mdblist,
          ratings: [
            _r('letterboxd', 9.2),
            _r('trakt', 9.1),
            _r('metacritic', 8.2),
            _r('tmdb', 8.7),
            _r('imdb', 9.3),
            _r('rottenTomatoesAudience', 9.8),
            _r('rottenTomatoesCritic', 8.9),
          ],
        ),
        (origin: CatalogSourceId.anilist, ratings: [_r('anilist', 8.5)]),
      ]);

      expect(merged.map((r) => r.source), [
        'rottenTomatoesCritic',
        'rottenTomatoesAudience',
        'imdb',
        'tmdb',
        'metacritic',
        'letterboxd',
        'trakt',
        'anilist',
      ]);
    });
  });

  group('withCommunityRatings', () {
    test('replaces the server copy of a source and keeps sources the trackers lack, in display order', () {
      final own = [_r('critic', 7.0), _r('imdb', 8.1), _r('rottenTomatoes', 9.0), _r('tmdb', 7.5)];
      final community = [_r('imdb', 8.3), _r('rottenTomatoesCritic', 9.1), _r('trakt', 8.0)];

      expect(_scores(withCommunityRatings(own, community)), [
        ('rottenTomatoesCritic', 9.1),
        ('imdb', 8.3),
        ('tmdb', 7.5),
        ('trakt', 8.0),
        ('critic', 7.0),
      ]);
    });

    test('returns the item scores unchanged while no tracker has answered', () {
      final own = [_r('audience', 6.0), _r('imdb', 8.1)];

      expect(withCommunityRatings(own, const []), same(own));
    });
  });

  group('CommunityRatingsLoader', () {
    const ids = CatalogItemIds(imdb: 'tt0111161');

    test('grows the merged list as each provider answers and closes when all have', () async {
      final trakt = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)]);
      final mdblist = _FakeRatingsSource(CatalogSourceId.mdblist, [_r('imdb', 9.3), _r('trakt', 8.0)]);
      final traktGate = Completer<void>();
      trakt.gate = traktGate.future;
      final loader = CommunityRatingsLoader();

      final emissions = <List<(String, double)>>[];
      final done = loader
          .load(MediaKind.movie, [trakt, mdblist], (_) async => ids)
          .listen((ratings) => emissions.add(_scores(ratings)))
          .asFuture<void>();
      await pumpEventQueue();
      expect(emissions, [
        [('imdb', 9.3), ('trakt', 8.0)],
      ]);

      traktGate.complete();
      await done;
      expect(emissions.last, [('imdb', 9.3), ('trakt', 9.1)]);
    });

    test('leaves out sources without scores, providers that fail and titles outside a provider', () async {
      final failing = _FakeRatingsSource(CatalogSourceId.simkl, [_r('simkl', 8.0)])..error = Exception('down');
      final outside = _FakeRatingsSource(CatalogSourceId.mal, [_r('mal', 8.0)]);
      final empty = _FakeRatingsSource(CatalogSourceId.anilist, const []);
      final scoring = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)]);
      final loader = CommunityRatingsLoader();

      final emissions = await loader.load(MediaKind.movie, [
        failing,
        outside,
        empty,
        scoring,
        _PlainSource(CatalogSourceId.seerr),
      ], (source) async => source == outside ? null : ids).toList();

      expect(emissions.map(_scores), [
        [('trakt', 9.1)],
      ]);
      expect(outside.calls, 0);
    });

    test('emits nothing and closes when no connected provider publishes scores', () async {
      final loader = CommunityRatingsLoader();

      expect(await loader.load(MediaKind.movie, [_PlainSource(CatalogSourceId.seerr)], (_) async => ids).toList(), []);
    });

    test('asks a provider again once its answer is older than the TTL', () async {
      final trakt = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)]);
      final loader = CommunityRatingsLoader();
      var now = DateTime(2026, 10, 14);

      Future<void> visit() =>
          withClock(Clock(() => now), () => loader.load(MediaKind.movie, [trakt], (_) async => ids).drain<void>());

      await visit();
      now = now.add(CommunityRatingsLoader.ttl - const Duration(minutes: 1));
      await visit();
      expect(trakt.calls, 1);

      now = now.add(const Duration(minutes: 2));
      await visit();
      expect(trakt.calls, 2);
    });

    test('keeps a title a provider does not know, but asks again after a failure', () async {
      final unknown = _FakeRatingsSource(CatalogSourceId.mal, const []);
      final failing = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)])..error = Exception('timeout');
      final loader = CommunityRatingsLoader();

      await loader.load(MediaKind.movie, [unknown, failing], (_) async => ids).drain<void>();
      failing.error = null;
      final second = await loader.load(MediaKind.movie, [unknown, failing], (_) async => ids).toList();

      expect(unknown.calls, 1);
      expect(failing.calls, 2);
      expect(second.map(_scores).last, [('trakt', 9.1)]);
    });

    test('keeps titles apart by kind and ids', () async {
      final trakt = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)]);
      final loader = CommunityRatingsLoader();

      await loader.load(MediaKind.movie, [trakt], (_) async => ids).drain<void>();
      await loader.load(MediaKind.show, [trakt], (_) async => ids).drain<void>();
      await loader.load(MediaKind.movie, [trakt], (_) async => const CatalogItemIds(imdb: 'tt0068646')).drain<void>();

      expect(trakt.calls, 3);
    });

    test('evicts the least recently used title beyond capacity', () async {
      final trakt = _FakeRatingsSource(CatalogSourceId.trakt, [_r('trakt', 9.1)]);
      final loader = CommunityRatingsLoader();
      Future<void> visit(int n) =>
          loader.load(MediaKind.movie, [trakt], (_) async => CatalogItemIds(tmdb: n)).drain<void>();

      for (var n = 0; n < CommunityRatingsLoader.capacity; n++) {
        await visit(n);
      }
      await visit(0); // most recently used again
      await visit(CommunityRatingsLoader.capacity); // evicts 1
      final calls = trakt.calls;

      await visit(0);
      expect(trakt.calls, calls);
      await visit(1);
      expect(trakt.calls, calls + 1);
    });
  });
}

class _FakeRatingsSource implements CatalogSource, CatalogCommunityRatings {
  _FakeRatingsSource(this.id, this.ratings);

  @override
  final CatalogSourceId id;
  final List<MediaRatingSource> ratings;
  Object? error;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<List<MediaRatingSource>> fetchCommunityRatings(MediaKind kind, CatalogItemIds ids) async {
    calls++;
    await gate;
    if (error case final error?) throw error;
    return ratings;
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PlainSource implements CatalogSource {
  _PlainSource(this.id);

  @override
  final CatalogSourceId id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
