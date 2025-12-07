import 'package:flutter/material.dart';
import '../../../models/plex_metadata.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../widgets/focusable_media_card.dart';
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
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState
    extends BaseLibraryTabState<PlexMetadata, LibraryCollectionsTab>
    with LibraryTabFocusMixin {
  @override
  String get focusNodeDebugLabel => 'collections_first_item';

  @override
  int get itemCount => items.length;

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
  Widget buildContent(List<PlexMetadata> items) {
    return AdaptiveMediaGrid<PlexMetadata>(
      items: items,
      itemBuilder: (context, item, index) {
        return FocusableMediaCard(
          key: Key(item.ratingKey),
          item: item,
          focusNode: index == 0 ? firstItemFocusNode : null,
          onListRefresh: loadItems,
          onBack: widget.onBack,
        );
      },
      onRefresh: loadItems,
      firstItemFocusNode: firstItemFocusNode,
      onBack: widget.onBack,
    );
  }
}
