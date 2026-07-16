import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_cast_member.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/utils/external_ids.dart';

/// Minimal controllable source: rows resolve immediately unless [gate] is
/// set, in which case fetches park on completers the test releases.
class _FakeSource implements CatalogSource {
  _FakeSource(this.id, {this.rows = const [CatalogRowId.watchlist, CatalogRowId.trendingMovies]});

  @override
  final CatalogSourceId id;
  final List<CatalogRowId> rows;
  final watchlist = WatchlistChangeNotifier();

  bool gate = false;
  final pending = <Completer<CatalogPage>>[];
  final fetches = <CatalogRowId, int>{};

  CatalogPage _page(CatalogRowId row) => CatalogPage(
    items: [
      CatalogItem(
        source: id,
        kind: MediaKind.movie,
        title: '${id.name}:${row.name}',
        ids: const CatalogItemIds(tmdb: 1),
      ),
    ],
  );

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) {
    fetches[row] = (fetches[row] ?? 0) + 1;
    if (gate) {
      final completer = Completer<CatalogPage>();
      pending.add(completer);
      return completer.future;
    }
    return Future.value(_page(row));
  }

  void releaseAll() {
    for (final completer in pending) {
      completer.complete(const CatalogPage(items: []));
    }
    pending.clear();
  }

  @override
  String get displayName => id.name;
  @override
  List<CatalogRowId> get supportedRows => rows;
  @override
  bool get supportsWatchlist => true;
  @override
  Listenable get watchlistChanges => watchlist;
  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async => const [];
  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async => const [];
  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async => const [];
  @override
  Future<void> ensureWatchlistLoaded() async {}
  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => null;
  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async => null;
  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) async {}
  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) async {}
  @override
  void dispose() => watchlist.dispose();
}

/// Drives [activeSource] directly; the real provider derives it from the
/// account providers, which is irrelevant to ExploreProvider's contract.
class _FakeSourcesProvider extends CatalogSourcesProvider {
  CatalogSource? _current;

  void setActive(CatalogSource? source) {
    _current = source;
    notifyListeners();
  }

  @override
  CatalogSource? get activeSource => _current;
}

Future<void> _pumpMicrotasks() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('ExploreProvider', () {
    late _FakeSourcesProvider sources;
    late ExploreProvider explore;

    setUp(() {
      LocaleSettings.setLocaleSync(AppLocale.en);
      sources = _FakeSourcesProvider();
      explore = ExploreProvider(sources);
      addTearDown(() {
        explore.dispose();
        sources.dispose();
      });
    });

    test('source switch during an in-flight load starts the new load instead of coalescing', () async {
      final slow = _FakeSource(CatalogSourceId.trakt)..gate = true;
      final fast = _FakeSource(CatalogSourceId.mal, rows: const [CatalogRowId.popularAnime]);
      addTearDown(() {
        slow.dispose();
        fast.dispose();
      });

      sources.setActive(slow);
      await _pumpMicrotasks();
      expect(explore.isLoading, isTrue);
      expect(slow.pending, isNotEmpty);

      // Switch while the old source's rows are still parked.
      sources.setActive(fast);
      await _pumpMicrotasks();

      expect(explore.state, ExploreLoadState.loaded);
      expect(explore.rowHubs.single.row, CatalogRowId.popularAnime);
      expect(explore.rowHubs.single.hub.items.single.title, 'mal:popularAnime');

      // The stale pass completing must not clobber the new source's state.
      slow.releaseAll();
      await _pumpMicrotasks();
      expect(explore.state, ExploreLoadState.loaded);
      expect(explore.rowHubs.single.row, CatalogRowId.popularAnime);
    });

    test('mutation during the initial load is caught up by ensureFresh', () async {
      final source = _FakeSource(CatalogSourceId.trakt)..gate = true;
      addTearDown(source.dispose);

      sources.setActive(source);
      await _pumpMicrotasks();
      expect(source.pending, hasLength(2));

      // A watchlist mutation lands while the full load is still in flight:
      // the pages about to land were fetched pre-mutation.
      source.watchlist.notify();
      source.gate = false;
      source.releaseAll();
      await _pumpMicrotasks();
      expect(explore.state, ExploreLoadState.loaded);

      final refetchesBefore = source.fetches[CatalogRowId.watchlist] ?? 0;
      explore.ensureFresh();
      await _pumpMicrotasks();
      expect(source.fetches[CatalogRowId.watchlist], refetchesBefore + 1);
    });
  });
}
