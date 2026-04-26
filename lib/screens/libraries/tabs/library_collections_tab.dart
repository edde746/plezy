import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../media/media_item.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../i18n/strings.g.dart';
import '../adaptive_media_grid.dart';
import 'base_library_tab.dart';
import 'library_grid_tab_state.dart';

/// Collections tab for library screen
/// Shows collections for the current library
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

class _LibraryCollectionsTabState extends LibraryGridTabState<MediaItem, LibraryCollectionsTab> {
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
  Future<List<MediaItem>> loadData() async {
    final client = getMediaClientForLibrary();
    return client.fetchCollections(widget.library.id);
  }

  @override
  Widget buildGridItem(BuildContext context, MediaItem item, int index, [GridItemContext? gridContext]) {
    return FocusableMediaCard(
      key: Key(item.id),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      disableScale: gridContext?.isListMode ?? false,
      onListRefresh: loadItems,
      onBack: widget.onBack,
      onNavigateLeft: gridContext?.isFirstColumn == true ? gridContext?.navigateToSidebar : null,
    );
  }
}
