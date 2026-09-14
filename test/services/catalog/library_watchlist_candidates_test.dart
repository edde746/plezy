import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/library_watchlist_candidates.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';

class _ExternalIdsClient implements MediaServerClient {
  _ExternalIdsClient(this.ids, {this.error});

  ExternalIds ids;
  Object? error;
  int calls = 0;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    calls++;
    if (error != null) throw error!;
    return ids;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWatchlistSource implements CatalogSource {
  _FakeWatchlistSource(this.id, {this.resolveTo, this.resolveError, this.mutationGate, this.mutationError});

  @override
  final CatalogSourceId id;

  final CatalogItemIds? resolveTo;
  final Object? resolveError;
  final Completer<void>? mutationGate;
  final Object? mutationError;

  int resolveCalls = 0;
  final List<({MediaKind kind, CatalogItemIds ids, bool add})> mutations = [];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    resolveCalls++;
    if (resolveError != null) throw resolveError!;
    return resolveTo;
  }

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) => _mutate(kind, ids, add: true);

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) => _mutate(kind, ids, add: false);

  Future<void> _mutate(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    await mutationGate?.future;
    if (mutationError != null) throw mutationError!;
    mutations.add((kind: kind, ids: ids, add: add));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final item = testMediaItem(id: 'movie-1', serverId: 'server-1');

  group('resolveWatchlistCandidates', () {
    test('pairs each source with its resolved ids, skipping out-of-domain and failing sources', () async {
      final trakt = _FakeWatchlistSource(CatalogSourceId.trakt, resolveTo: const CatalogItemIds(imdb: 'tt1'));
      final mal = _FakeWatchlistSource(CatalogSourceId.mal); // resolves null: not in domain
      final simkl = _FakeWatchlistSource(CatalogSourceId.simkl, resolveError: StateError('down'));

      final candidates = await resolveWatchlistCandidates(
        client: _ExternalIdsClient(const ExternalIds(imdb: 'tt1')),
        item: item,
        sources: [trakt, mal, simkl],
      );

      expect(candidates.map((c) => c.source.id), [CatalogSourceId.trakt]);
      expect(candidates.single.ids.imdb, 'tt1');
      expect(mal.resolveCalls, 1);
      expect(simkl.resolveCalls, 1);
    });

    test('an item without external ids resolves to nothing without asking any source', () async {
      final trakt = _FakeWatchlistSource(CatalogSourceId.trakt, resolveTo: const CatalogItemIds(imdb: 'tt1'));

      final candidates = await resolveWatchlistCandidates(
        client: _ExternalIdsClient(const ExternalIds()),
        item: item,
        sources: [trakt],
      );

      expect(candidates, isEmpty);
      expect(trakt.resolveCalls, 0);
    });

    test('a null client (server offline) resolves to nothing', () async {
      final candidates = await resolveWatchlistCandidates(
        client: null,
        item: item,
        sources: [_FakeWatchlistSource(CatalogSourceId.trakt)],
      );
      expect(candidates, isEmpty);
    });

    test('a failed external-id fetch propagates to the caller', () {
      expect(
        resolveWatchlistCandidates(
          client: _ExternalIdsClient(const ExternalIds(), error: StateError('unreachable')),
          item: item,
          sources: [_FakeWatchlistSource(CatalogSourceId.trakt)],
        ),
        throwsStateError,
      );
    });
  });

  group('mutateWatchlistMembership', () {
    const ids = CatalogItemIds(imdb: 'tt1');

    test('dispatches add and remove to the candidate source', () async {
      final source = _FakeWatchlistSource(CatalogSourceId.trakt);

      expect(await mutateWatchlistMembership(MediaKind.movie, (source: source, ids: ids), add: true), isTrue);
      expect(await mutateWatchlistMembership(MediaKind.movie, (source: source, ids: ids), add: false), isTrue);

      expect(source.mutations.map((m) => m.add), [true, false]);
      expect(source.mutations.first.ids.imdb, 'tt1');
    });

    test('an identical mutation already in flight is refused instead of double-firing', () async {
      final gate = Completer<void>();
      final source = _FakeWatchlistSource(CatalogSourceId.trakt, mutationGate: gate);
      final candidate = (source: source, ids: ids);

      final first = mutateWatchlistMembership(MediaKind.movie, candidate, add: true);
      expect(await mutateWatchlistMembership(MediaKind.movie, candidate, add: true), isFalse);
      expect(source.mutations, isEmpty);

      gate.complete();
      expect(await first, isTrue);
      expect(source.mutations, hasLength(1));

      // The guard releases with the mutation.
      expect(await mutateWatchlistMembership(MediaKind.movie, candidate, add: false), isTrue);
      expect(source.mutations, hasLength(2));
    });

    test('a failed mutation rethrows and releases the guard', () async {
      final failing = _FakeWatchlistSource(CatalogSourceId.trakt, mutationError: StateError('api down'));
      final candidate = (source: failing, ids: ids);

      await expectLater(mutateWatchlistMembership(MediaKind.movie, candidate, add: true), throwsStateError);

      final working = _FakeWatchlistSource(CatalogSourceId.trakt);
      expect(await mutateWatchlistMembership(MediaKind.movie, (source: working, ids: ids), add: true), isTrue);
      expect(working.mutations, hasLength(1));
    });
  });
}
