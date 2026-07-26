import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../media/library_query.dart';
import '../../../media/media_item.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../i18n/strings.g.dart';
import 'base_library_tab.dart';
import 'paginated_card_grid_tab.dart';

/// Collections tab for library screen.
/// Plex scopes collections to the library; Jellyfin exposes a shared BoxSets root.
class LibraryCollectionsTab extends BaseLibraryTab<MediaItem> {
  const LibraryCollectionsTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState extends PaginatedCardGridTabState<MediaItem, LibraryCollectionsTab> {
  @override
  int get pageSize => 36;

  @override
  String get focusNodeDebugLabel => 'collections_first_item';

  @override
  IconData get emptyIcon => Symbols.collections_rounded;

  @override
  String get emptyMessage => t.libraries.noCollections;

  @override
  String get errorContext => t.collections.title;

  @override
  Stream<void>? getRefreshStream() => LibraryRefreshNotifier().collectionsStream;

  @override
  String idOf(MediaItem item) => item.id;

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    final client = getMediaClientForLibrary();
    return client.fetchCollectionsPage(widget.library.id, start: start, size: size, abort: abort);
  }

  @override
  bool get usesSquareCards {
    final loaded = loadedItems.values;
    return loaded.isNotEmpty && loaded.every(_isMusicCollection);
  }

  // Plex collection rows are library-scoped, so their container kind is a
  // safe fallback. Jellyfin BoxSets are server-wide and must opt in per item.
  bool _isMusicCollection(MediaItem item) =>
      item.kind.isMusic || (item is PlexMediaItem && widget.library.kind.isMusic);
}
