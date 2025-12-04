import 'package:flutter/material.dart';
import '../../../models/plex_metadata.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../i18n/strings.g.dart';
import '../adaptive_media_grid.dart';
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
  /// Focus node for the first item in the grid
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'CollectionsFirstItem',
  );

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

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

    // Collections are automatically tagged with server info by PlexClient
    return await client.getLibraryCollections(widget.library.key);
  }

  @override
  void focusFirstItem() {
    if (items.isNotEmpty) {
      _firstItemFocusNode.requestFocus();
    }
  }

  @override
  Widget buildContent(List<PlexMetadata> items) {
    return AdaptiveMediaGrid(
      items: items,
      onRefresh: loadItems,
      firstItemFocusNode: _firstItemFocusNode,
    );
  }
}
