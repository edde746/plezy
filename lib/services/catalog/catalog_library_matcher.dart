import '../../media/media_item.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/multi_server_provider.dart';

/// Matches external catalog items back to the user's libraries.
///
/// One reverse-lookup fan-out per tap (see
/// `DataAggregationService.findByExternalIdsAcrossServers`), memoized for
/// the session: positive hits are kept (library membership rarely shrinks
/// mid-session), negatives expire so newly-added media is picked up.
/// Profile-scoped via the provider subtree, so a profile switch drops the
/// cache by construction.
class CatalogLibraryMatcher {
  static const Duration negativeTtl = Duration(minutes: 10);

  final MultiServerProvider _multiServer;
  final Map<String, ({DateTime at, List<MediaItem> items})> _cache = {};

  CatalogLibraryMatcher(this._multiServer);

  Future<List<MediaItem>> match(CatalogItem item) async {
    if (!item.ids.hasAny) return const [];
    final key = item.identityKey;
    final cached = _cache[key];
    if (cached != null && (cached.items.isNotEmpty || DateTime.now().difference(cached.at) < negativeTtl)) {
      return cached.items;
    }
    final matches = await _multiServer.aggregationService.findByExternalIdsAcrossServers(
      item.ids.toExternalIds(),
      kind: item.kind,
      title: item.title,
      year: item.year,
    );
    _cache[key] = (at: DateTime.now(), items: matches);
    return matches;
  }
}
