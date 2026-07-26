import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../media/library_query.dart';
import '../media/media_item.dart';
import '../mixins/paginated_item_loader.dart';
import '../mixins/standard_paginated_view.dart';
import '../providers/download_provider.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/error_message_utils.dart';
import '../utils/download_utils.dart';
import '../utils/media_server_http_client.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../services/playlist_items_loader.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final MediaItem collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends BaseMediaListDetailScreen<CollectionDetailScreen>
    with
        GridFocusNodeMixin<CollectionDetailScreen>,
        FocusableDetailScreenMixin<CollectionDetailScreen>,
        PaginatedItemLoader<MediaItem, CollectionDetailScreen>,
        PaginatedItemUpdatable<CollectionDetailScreen>,
        StandardPaginatedView<MediaItem, CollectionDetailScreen> {
  static const int _pageSize = 200;

  @override
  MediaItem get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title!;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  bool get hasItems => totalSize > 0;

  CardShape? get _contentShape {
    final loaded = loadedItems.values;
    return loaded.isNotEmpty && loaded.every((item) => item.kind.isMusic) ? CardShape.square : null;
  }

  @override
  void dispose() {
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return mediaClient.fetchCollectionPage(
      widget.collection.id,
      start: start,
      size: size,
      abort: abort,
      libraryId: widget.collection.libraryId,
      libraryTitle: widget.collection.libraryTitle,
    );
  }

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: _pageSize,
      errorMessageFor: (error, stackTrace) =>
          localizedLoadErrorMessage(error, stackTrace, context: t.collections.collection),
      onLoaded: (loadedCount, totalCount) {
        appLogger.d('Loaded $loadedCount of $totalCount items for collection: ${widget.collection.title}');
        autoFocusFirstItemAfterLoad();
      },
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    final ruleKey = syncRuleKey;
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the app bar.
    final hasRule = context.select<DownloadProvider, bool>((p) => p.hasSyncRule(ruleKey));

    return [
      if (hasItems) ...[
        FocusableAction(icon: Symbols.play_arrow_rounded, tooltip: t.common.play, onPressed: playItems),
        FocusableAction(icon: Symbols.shuffle_rounded, tooltip: t.common.shuffle, onPressed: shufflePlayItems),
      ],
      // Emptiness is handled inside [_downloadCollection], so the download
      // entry stays visible for empty collections.
      ...buildSyncRuleActions(
        context,
        ruleKey: ruleKey,
        displayTitle: widget.collection.displayTitle,
        hasRule: hasRule,
        showDownload: true,
        onDownload: _downloadCollection,
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
      final allItems = await fetchAllCollectionItemsPaged(
        mediaClient,
        widget.collection.id,
        libraryId: widget.collection.libraryId,
        libraryTitle: widget.collection.libraryTitle,
      );
      if (!mounted) return;
      final result = await showCollectionDownloadOptionsAndQueue(
        context,
        collectionMetadata: widget.collection,
        items: allItems,
        client: mediaClient,
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

  Future<void> _deleteCollection() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.deleteCollection,
      message: t.collections.deleteConfirm(title: widget.collection.displayTitle),
    );

    if (!confirmed) return;
    if (!mounted) return;

    try {
      // Backend-neutral [deleteCollection] reads `libraryId` from the
      // [MediaItem] for Plex's section-id; Jellyfin ignores it.
      final success = await mediaClient.deleteCollection(widget.collection);

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
            collectionId: widget.collection.id,
            onListRefresh: loadItems,
            shape: _contentShape,
          ),
      ],
    );
  }
}
