import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/plex_metadata.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../i18n/strings.g.dart';
import 'base_library_tab.dart';
import 'library_grid_tab_state.dart';

/// Collections tab for library screen
/// Shows collections for the current library
class LibraryCollectionsTab extends BaseLibraryTab<PlexMetadata> {
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

class _LibraryCollectionsTabState extends LibraryGridTabState<PlexMetadata, LibraryCollectionsTab> {
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
  Future<List<PlexMetadata>> loadData() async {
    // Use server-specific client for this library
    final client = getClientForLibrary();

    // Collections are automatically tagged with server info by PlexClient
    return await client.getLibraryCollections(widget.library.key);
  }

  @override
  @override
  Widget buildGridItem(BuildContext context, PlexMetadata item, int index) {
    return FocusableMediaCard(
      key: Key(item.ratingKey),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      onListRefresh: loadItems,
      onBack: widget.onBack,
    );
  }
}
