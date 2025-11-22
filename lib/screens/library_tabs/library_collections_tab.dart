import 'package:flutter/material.dart';
import '../../models/plex_metadata.dart';
import '../../utils/library_refresh_notifier.dart';
import '../../utils/server_tagging_extensions.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/adaptive_media_grid.dart';
import 'base_library_tab.dart';

/// Collections tab for library screen
/// Shows collections for the current library
class LibraryCollectionsTab extends BaseLibraryTab<PlexMetadata> {
  const LibraryCollectionsTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
  });

  @override
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState
    extends BaseLibraryTabState<PlexMetadata, LibraryCollectionsTab> {
  @override
  IconData get emptyIcon => Icons.collections;

  @override
  String get emptyMessage => t.libraries.noCollections;

  @override
  String get errorContext => t.collections.title;

  @override
  Stream<void>? getRefreshStream() =>
      LibraryRefreshNotifier().collectionsStream;

  @override
  Future<List<PlexMetadata>> loadData() async {
    // Use server-specific client for this library
    final client = getClientForLibrary();

    final collections = await client.getLibraryCollections(widget.library.key);

    // Tag collections with server info
    return collections.tagWithLibrary(widget.library);
  }

  @override
  Widget buildContent(List<PlexMetadata> items) {
    return AdaptiveMediaGrid(items: items, onRefresh: loadItems);
  }
}
