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

  /// Provider-reported size of the whole result set, when the envelope says
  /// (Seerr `totalResults`). Null when the provider only reports `hasMore`.
  final int? totalResults;

  const CatalogPage({required this.items, this.hasMore = false, this.totalResults});
}

/// How a provider intends a hub to be presented. Providers tag hubs (Plex
/// `style`), and rendering every one as the same shelf discards that.
///
/// Only values a provider was actually observed to send are declared. A live
/// Plex Home response returned 17 renderable hubs: 5 `shelf`, 1
/// `availabilityPlatforms`, 11 with no style at all. Absent stays absent —
/// null means "the provider expressed no preference", which is not the same
/// as `shelf`, even though both render identically today. Do not add a
/// speculative style before a provider is seen sending it.
enum CatalogHubStyle {
  /// The default horizontal poster shelf.
  shelf,

  /// A hub whose entries are streaming services/platforms rather than titles.
  availabilityPlatforms,
}

/// One provider-defined Explore shelf. Unlike [CatalogRowId], hubs are
/// discovered at runtime and retain the provider's title and stable id.
class CatalogHub {
  final String id;
  final String title;
  final CatalogPage page;

  /// The provider's presentation hint, or null when it sent none.
  final CatalogHubStyle? style;

  const CatalogHub({required this.id, required this.title, required this.page, this.style});
}

/// Everything a catalog detail screen needs from the item's own provider.
///
/// The contract is a request-count ceiling, not a single response: an
/// implementation must issue no more requests than the separate cast and
/// related calls it replaces, and [item] must be enriched purely from bodies
/// it was already fetching. Providers differ — Simkl's detail body already
/// carries recommendations, while Plex (`/library/metadata/{id}` plus
/// `/related`) and Seerr (detail plus `/recommendations`) genuinely need two.
/// Where two calls remain, run them concurrently and isolate their failures:
/// a failed related call must still yield the enriched item and its cast.
class CatalogDetail {
  /// The opening item enriched with everything the detail body added, via
  /// [CatalogItem.enrichedWith]. Equal to the input item when the provider
  /// has no detail endpoint.
  final CatalogItem item;

  /// Actors with characters, or characters with roles, in billing order.
  final List<CatalogCastMember> cast;

  /// "More like this" — recommendations, which are a similarity judgement and
  /// carry no relationship to the item.
  final List<CatalogItem> related;

  /// Franchise relations, grouped and labelled by how each group relates to
  /// the item (MAL `related_anime`, AniList `relations`). Deliberately not
  /// merged into [related]: "sequel" is a fact about the work, "recommended"
  /// is an opinion about taste, and flattening them would lose the label the
  /// UI needs to head each shelf.
  final List<CatalogRelation> relations;

  const CatalogDetail({required this.item, this.cast = const [], this.related = const [], this.relations = const []});
}

/// How a group of titles relates to the item they were fetched from.
enum CatalogRelationType {
  prequel,
  sequel,
  sideStory,
  spinOff,
  alternativeVersion,
  summary,
  parentStory,
  adaptation,
  other,
}

/// One labelled group of franchise relations.
class CatalogRelation {
  final CatalogRelationType type;
  final List<CatalogItem> items;

  const CatalogRelation({required this.type, required this.items});
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

  /// Enriched item, cast and related titles for a detail screen, in as few
  /// requests as the provider allows. Fetched lazily on detail open; a
  /// provider with nothing to add returns the item unchanged and empty lists.
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20});

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
