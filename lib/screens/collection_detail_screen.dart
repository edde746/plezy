import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../models/plex_metadata.dart';
import '../providers/download_provider.dart';
import '../utils/download_utils.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';
import '../utils/dialogs.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../focus/key_event_utils.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final PlexMetadata collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends BaseMediaListDetailScreen<CollectionDetailScreen>
    with
        StandardItemLoader<CollectionDetailScreen>,
        GridFocusNodeMixin<CollectionDetailScreen>,
        FocusableDetailScreenMixin<CollectionDetailScreen> {
  @override
  PlexMetadata get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title!;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<List<PlexMetadata>> fetchItems() async {
    return await client.getCollectionItems(widget.collection.ratingKey);
  }

  @override
  Future<void> loadItems() async {
    await super.loadItems();
    autoFocusFirstItemAfterLoad();
  }

  @override
  String getLoadErrorMessage(Object error) {
    return t.collections.failedToLoadItems(error: error.toString());
  }

  @override
  String getLoadSuccessMessage(int itemCount) {
    return 'Loaded $itemCount items for collection: ${widget.collection.title}';
  }

  @override
  List<FocusableAction> getAppBarActions() {
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the app bar.
    final hasRule = context.select<DownloadProvider, bool>((p) => p.hasSyncRule(widget.collection.globalKey));

    return [
      if (items.isNotEmpty) ...[
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
    if (items.isEmpty) {
      showErrorSnackBar(context, t.collections.empty);
      return;
    }

    final downloadProvider = context.read<DownloadProvider>();
    try {
      final result = await showCollectionDownloadOptionsAndQueue(
        context,
        collectionMetadata: widget.collection,
        items: items,
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
    if (sectionId == null && items.isNotEmpty) {
      sectionId = items.first.librarySectionID;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        if (didPop) return;
        final shouldPop = handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            CustomAppBar(title: Text(widget.collection.title!), actions: buildFocusableAppBarActions()),
            ...buildStateSlivers(),
            if (items.isNotEmpty)
              buildFocusableGrid(
                items: items,
                onRefresh: updateItem,
                collectionId: widget.collection.ratingKey,
                onListRefresh: loadItems,
              ),
          ],
        ),
      ),
    );
  }
}
