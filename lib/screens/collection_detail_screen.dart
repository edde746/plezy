import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../mixins/paginated_item_loader.dart';
import '../models/plex_metadata.dart';
import '../providers/download_provider.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/download_utils.dart';
import '../utils/plex_http_client.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final PlexMetadata collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends BaseMediaListDetailScreen<CollectionDetailScreen>
    with
        GridFocusNodeMixin<CollectionDetailScreen>,
        FocusableDetailScreenMixin<CollectionDetailScreen>,
        PaginatedItemLoader<CollectionDetailScreen> {
  static const int _pageSize = 200;

  @override
  PlexMetadata get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title!;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  bool get hasItems => totalSize > 0;

  @override
  void dispose() {
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<LibraryContentResult> fetchPage(int start, int size, AbortController? abort) =>
      client.getCollectionItems(widget.collection.ratingKey, start: start, size: size, abort: abort);

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    // Search [loadedItems] (not the flat [items] snapshot, which only has
    // the first page) so refreshing an item at a scrolled-in position updates
    // the grid in place.
    for (final entry in loadedItems.entries) {
      if (entry.value.ratingKey == ratingKey) {
        loadedItems[entry.key] = updatedMetadata;
        return;
      }
    }
  }

  @override
  Future<void> loadItems() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      resetPaginationState();
    });
    try {
      await loadInitialPage(_pageSize);
      if (!mounted) return;
      // Mirror loadedItems into base-class [items] once so state-sliver checks
      // (items.isEmpty vs items.isEmpty && isLoading) pick the right branch.
      // Further pages only update loadedItems; items.isEmpty stays false.
      setState(() {
        items = loadedItems.values.toList();
        isLoading = false;
      });
      appLogger.d('Loaded ${loadedItems.length} of $totalSize items for collection: ${widget.collection.title}');
      autoFocusFirstItemAfterLoad();
    } catch (e) {
      appLogger.e('Failed to load collection items', error: e);
      if (!mounted) return;
      setState(() {
        errorMessage = t.collections.failedToLoadItems(error: e.toString());
        isLoading = false;
      });
    }
  }

  @override
  List<FocusableAction> getAppBarActions() {
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the app bar.
    final hasRule = context.select<DownloadProvider, bool>((p) => p.hasSyncRule(widget.collection.globalKey));

    return [
      if (hasItems) ...[
        FocusableAction(icon: Symbols.play_arrow_rounded, tooltip: t.common.play, onPressed: playItems),
        FocusableAction(icon: Symbols.shuffle_rounded, tooltip: t.common.shuffle, onPressed: shufflePlayItems),
      ],
      FocusableAction(
        icon: hasRule ? Symbols.sync_rounded : Symbols.download_rounded,
        tooltip: hasRule ? t.downloads.manageSyncRule : t.downloads.downloadNow,
        onPressed: hasRule ? _manageCollectionSyncRule : _downloadCollection,
        iconColor: hasRule ? Colors.teal : null,
      ),
      if (hasRule)
        FocusableAction(
          icon: Symbols.sync_disabled_rounded,
          tooltip: t.downloads.removeSyncRule,
          onPressed: _removeCollectionSyncRule,
        ),
      FocusableAction(
        icon: Symbols.delete_rounded,
        tooltip: t.common.delete,
        onPressed: _deleteCollection,
        iconColor: Colors.red,
      ),
    ];
  }

  Future<void> _downloadCollection() async {
    if (!hasItems) {
      showErrorSnackBar(context, t.collections.empty);
      return;
    }

    final downloadProvider = context.read<DownloadProvider>();
    try {
      final allItems = await client.fetchAllCollectionItems(widget.collection.ratingKey);
      if (!mounted) return;
      final result = await showCollectionDownloadOptionsAndQueue(
        context,
        collectionMetadata: widget.collection,
        items: allItems,
        client: client,
        downloadProvider: downloadProvider,
      );
      if (result == null || !mounted) return;
      showSuccessSnackBar(context, result.toSnackBarMessage());
    } catch (e) {
      appLogger.e('Failed to queue collection download', error: e);
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  Future<void> _manageCollectionSyncRule() => manageSyncRule(
    context,
    downloadProvider: context.read<DownloadProvider>(),
    globalKey: widget.collection.globalKey,
  );

  Future<void> _removeCollectionSyncRule() => removeSyncRuleAndSnack(
    context,
    downloadProvider: context.read<DownloadProvider>(),
    globalKey: widget.collection.globalKey,
    displayTitle: widget.collection.displayTitle,
  );

  Future<void> _deleteCollection() async {
    int? sectionId = widget.collection.librarySectionID;
    if (sectionId == null && loadedItems.isNotEmpty) {
      sectionId = loadedItems.values.first.librarySectionID;
    }

    if (sectionId == null) {
      if (mounted) {
        showErrorSnackBar(context, t.collections.unknownLibrarySection);
      }
      return;
    }

    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.deleteCollection,
      message: t.collections.deleteConfirm(title: widget.collection.displayTitle),
    );

    if (!confirmed) return;
    if (!mounted) return;

    try {
      final success = await client.deleteCollection(sectionId.toString(), widget.collection.ratingKey);

      if (!mounted) return;

      if (success) {
        showSuccessSnackBar(context, t.collections.deleted);
        Navigator.pop(context, true);
      } else {
        showErrorSnackBar(context, t.collections.deleteFailed);
      }
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      if (mounted) {
        showErrorSnackBar(context, t.collections.deleteFailedWithError(error: e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(title: Text(widget.collection.title!), actions: buildFocusableAppBarActions()),
        ...buildStateSlivers(),
        if (hasItems)
          buildSparseFocusableGrid(
            totalItems: totalSize,
            itemAt: (index) => loadedItems[index],
            onRefresh: updateItem,
            onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
            collectionId: widget.collection.ratingKey,
            onListRefresh: loadItems,
          ),
      ],
    );
  }
}
