import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/app_logger.dart';
import 'catalog_source.dart';

/// A watchlist-capable catalog source paired with a library item's ids in
/// that source's terms (see [resolveWatchlistCandidates]).
typedef WatchlistCandidate = ({CatalogSource source, CatalogItemIds ids});

/// Resolve which of [sources] can hold [item] on their watchlist, with the
/// ids each source needs for membership/mutation.
///
/// The item's external ids come from its owning server ([client]); each
/// source then maps them to its own id forms (MAL and AniList go through
/// Fribb; Plex Discover matches server-side). A source that cannot hold the
/// item (non-anime on MAL, no usable ids) is simply absent from the result.
/// Per-source resolution failures are logged and skipped so one flaky
/// provider does not hide the rest; a failed external-id fetch throws.
Future<List<WatchlistCandidate>> resolveWatchlistCandidates({
  required MediaServerClient? client,
  required MediaItem item,
  required List<CatalogSource> sources,
}) async {
  if (client == null || sources.isEmpty) return const [];
  final ids = await client.fetchExternalIds(item.id);
  if (!ids.hasAny) return const [];
  final candidates = <WatchlistCandidate>[];
  for (final source in sources) {
    try {
      final resolved = await source.resolveItemIds(item.kind, ids);
      if (resolved != null) candidates.add((source: source, ids: resolved));
    } catch (e, stackTrace) {
      appLogger.d('Watchlist external-id resolution failed for ${source.id.name}', error: e, stackTrace: stackTrace);
    }
  }
  return candidates;
}

/// Watchlist mutations keyed by source+item so surfaces without a per-screen
/// guard (context menus, which outlive their tap) can't double-fire while
/// one is still in flight.
final Set<String> _watchlistMutationsInFlight = {};

/// Add or remove [candidate]'s item on its source's watchlist.
///
/// Returns false when the identical mutation is already in flight (nothing
/// ran). API failures propagate to the caller, which owns user feedback.
Future<bool> mutateWatchlistMembership(MediaKind kind, WatchlistCandidate candidate, {required bool add}) async {
  final key = '${candidate.source.id.name}/${kind.id}/${candidate.ids.canonicalKey ?? ''}';
  if (!_watchlistMutationsInFlight.add(key)) return false;
  try {
    if (add) {
      await candidate.source.addToWatchlist(kind, candidate.ids);
    } else {
      await candidate.source.removeFromWatchlist(kind, candidate.ids);
    }
    return true;
  } finally {
    _watchlistMutationsInFlight.remove(key);
  }
}
