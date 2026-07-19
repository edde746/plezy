import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import 'catalog_source.dart';

typedef _FavoriteLibrary = ({MediaServerClient client, MediaLibrary library});

/// Selectable Explore source backed by the active user's Jellyfin favorites.
///
/// Unlike Trakt/MAL, these rows contain real server items. The
/// [MediaItemCatalogSource] capability keeps them out of the external-catalog
/// stand-in conversion so taps route directly to the owning Jellyfin server.
class JellyfinFavoritesCatalogSource implements CatalogSource, MediaItemCatalogSource {
  JellyfinFavoritesCatalogSource(List<MediaServerClient> clients, {Set<String> hiddenLibraryKeys = const {}})
    : _clients = List.unmodifiable(clients),
      _hiddenLibraryKeys = Set.unmodifiable(hiddenLibraryKeys);

  final List<MediaServerClient> _clients;
  final Set<String> _hiddenLibraryKeys;
  final WatchlistChangeNotifier _changes = WatchlistChangeNotifier();

  @override
  CatalogSourceId get id => CatalogSourceId.jellyfin;

  @override
  String get displayName => 'Jellyfin ${t.libraries.filterCategories.favorites}';

  @override
  List<CatalogRowId> get supportedRows => const [CatalogRowId.favorites];

  @override
  bool get supportsWatchlist => false;

  @override
  bool get supportsExploreSearch => false;

  @override
  Listenable get watchlistChanges => _changes;

  @override
  Future<ExploreMediaPage> fetchMediaRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    if (row != CatalogRowId.favorites) throw ArgumentError('Jellyfin Favorites does not serve ${row.name}');
    if (page < 1 || limit <= 0 || _clients.isEmpty) return const ExploreMediaPage(items: []);

    final libraries = await _favoriteLibraries();
    if (libraries.isEmpty) return const ExploreMediaPage(items: []);

    // Fetch every source through the end of the requested global page. Since
    // each response is title-sorted, no source can contribute more than this
    // many items to the prefix, allowing a deterministic cross-server slice.
    final requestedEnd = page * limit;
    Object? firstError;
    final pages = await Future.wait<LibraryPage<MediaItem>?>([
      for (final target in libraries)
        () async {
          try {
            return await target.client.fetchLibraryContent(
              target.library.id,
              LibraryQuery(
                offset: 0,
                limit: requestedEnd,
                sort: const LibrarySort(field: 'title', direction: LibrarySortDirection.ascending),
                favoritesOnly: true,
              ),
            );
          } catch (error, stackTrace) {
            firstError ??= error;
            appLogger.w(
              'Jellyfin Favorites: failed to load ${target.library.globalKey}',
              error: error,
              stackTrace: stackTrace,
            );
            return null;
          }
        }(),
    ]);

    final successful = pages.whereType<LibraryPage<MediaItem>>().toList();
    if (successful.isEmpty && firstError != null) throw firstError!;

    final seen = <String>{};
    final merged = <MediaItem>[
      for (final result in successful)
        for (final item in result.items)
          if ((item.kind.isVideo || item.kind.isShowRelated) && seen.add(item.globalKey)) item,
    ];
    merged.sort(_compareItems);

    final start = (page - 1) * limit;
    final end = requestedEnd < merged.length ? requestedEnd : merged.length;
    final items = start >= merged.length ? const <MediaItem>[] : merged.sublist(start, end);
    final hasMore = merged.length > requestedEnd || successful.any((result) => result.totalCount > result.items.length);
    return ExploreMediaPage(items: items, hasMore: hasMore);
  }

  Future<List<_FavoriteLibrary>> _favoriteLibraries() async {
    Object? firstError;
    final results = await Future.wait<List<_FavoriteLibrary>?>([
      for (final client in _clients)
        () async {
          try {
            final libraries = await client.fetchLibraries();
            return [
              for (final library in libraries)
                if (!library.hidden &&
                    !_hiddenLibraryKeys.contains(library.globalKey) &&
                    (library.kind == MediaKind.movie ||
                        library.kind == MediaKind.show ||
                        library.kind == MediaKind.clip ||
                        library.kind == MediaKind.unknown))
                  (client: client, library: library),
            ];
          } catch (error, stackTrace) {
            firstError ??= error;
            appLogger.w(
              'Jellyfin Favorites: failed to load libraries from ${client.serverId}',
              error: error,
              stackTrace: stackTrace,
            );
            return null;
          }
        }(),
    ]);
    final successful = results.whereType<List<_FavoriteLibrary>>().toList();
    if (successful.isEmpty && firstError != null) throw firstError!;
    return [for (final result in successful) ...result];
  }

  static int _compareItems(MediaItem a, MediaItem b) {
    final byTitle = (a.title ?? '').toLowerCase().compareTo((b.title ?? '').toLowerCase());
    if (byTitle != 0) return byTitle;
    final byYear = (a.year ?? 0).compareTo(b.year ?? 0);
    if (byYear != 0) return byYear;
    return a.globalKey.compareTo(b.globalKey);
  }

  // External-catalog operations do not apply to real Jellyfin items.
  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) =>
      throw UnsupportedError('Jellyfin Favorites rows contain server media items');

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
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) =>
      throw UnsupportedError('Jellyfin Favorites is not an external watchlist');

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) =>
      throw UnsupportedError('Jellyfin Favorites is not an external watchlist');

  @override
  void dispose() => _changes.dispose();
}
