import 'package:flutter/foundation.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/external_ids.dart';

/// Content rows a catalog source can serve on the Explore tab.
enum CatalogRowId {
  watchlist,
  recommendedMovies,
  recommendedShows,
  trendingMovies,
  trendingShows,
  popularMovies,
  popularShows,
  // Anime rows (MAL has no movie/show split).
  trendingAnime,
  suggestedAnime,
  airingAnime,
  popularAnime,
  // Seerr rows (its trending endpoint is mixed movie/TV).
  trending,
  upcomingMovies,
  upcomingShows,
}

/// Notify-guarded [ChangeNotifier] for [CatalogSource.watchlistChanges]: a
/// snapshot load or mutation that resolves after the source was disposed
/// (provider disconnected mid-session) must not trip the used-after-dispose
/// assert.
class WatchlistChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// One page of a catalog row.
class CatalogPage {
  final List<CatalogItem> items;
  final bool hasMore;

  const CatalogPage({required this.items, this.hasMore = false});
}

/// One provider-defined Explore shelf. Unlike [CatalogRowId], hubs are
/// discovered at runtime and retain the provider's title and stable id.
class CatalogHub {
  final String id;
  final String title;
  final CatalogPage page;

  const CatalogHub({required this.id, required this.title, required this.page});
}

/// Optional capability for catalog providers that expose dynamic hub rows.
///
/// [CatalogSource] stays fixed-row by default. Providers such as Plex can
/// implement this alongside it without forcing every source to grow no-op
/// methods.
abstract interface class CatalogHubSource {
  Future<List<CatalogHub>> fetchHubs({int limit = 25});

  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25});
}

/// A pluggable external catalog provider backing the Explore tab (Trakt
/// today; Overseerr/Jellyfin or MAL later).
///
/// Implementations wrap an authenticated API client owned by their account
/// provider; disposing a source must not dispose that client.
abstract class CatalogSource {
  CatalogSourceId get id;

  String get displayName;

  /// Rows this source serves, in display order.
  List<CatalogRowId> get supportedRows;

  /// Whether the source has a user watchlist that can be read and mutated.
  bool get supportsWatchlist;

  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25});

  /// Free-text title search for the Explore search screen. Returns an empty
  /// list when the query is below the provider's minimum length (MAL
  /// rejects queries under 3 characters).
  Future<List<CatalogItem>> search(String query, {int limit = 30});

  /// Cast of an item for its detail screen (actors with characters, or MAL
  /// characters with roles), in billing order. One request, fetched lazily
  /// on detail open; empty when the provider has none for this item.
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20});

  /// "More like this" titles for an item's detail screen (Trakt related,
  /// MAL recommendations, Seerr/TMDB recommendations). One request, fetched
  /// lazily on detail open; empty when the provider has none.
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20});

  /// Load the full watchlist membership snapshot (coalesced; cached for the
  /// session). [isOnWatchlist] returns null until this has completed once.
  Future<void> ensureWatchlistLoaded();

  /// Whether the item is on the user's watchlist, or null when the snapshot
  /// has not loaded yet.
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids);

  /// Resolve the ids this source needs for watchlist membership/mutation of
  /// a library item, given the external ids its server knows. Returns null
  /// when the item cannot exist in this source's domain (e.g. non-anime for
  /// MAL) — callers hide the watchlist action then.
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external);

  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids);

  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids);

  /// Fires after any watchlist membership change (mutation or snapshot load)
  /// so watchers (Explore rows, detail-screen buttons) can rebuild.
  Listenable get watchlistChanges;

  void dispose();
}
