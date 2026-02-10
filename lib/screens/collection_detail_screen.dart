import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/plex_metadata.dart';
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
  String get title => widget.collection.title;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  int get appBarButtonCount => items.isNotEmpty ? 3 : 1; // play, shuffle, delete (or just delete if empty)

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
  List<AppBarButtonConfig> getAppBarButtons() {
    final buttons = <AppBarButtonConfig>[];
    if (items.isNotEmpty) {
      buttons.add(AppBarButtonConfig(icon: Symbols.play_arrow_rounded, tooltip: t.common.play, onPressed: playItems));
      buttons.add(
        AppBarButtonConfig(icon: Symbols.shuffle_rounded, tooltip: t.common.shuffle, onPressed: shufflePlayItems),
      );
    }
    buttons.add(
      AppBarButtonConfig(
        icon: Symbols.delete_rounded,
        tooltip: t.common.delete,
        onPressed: _deleteCollection,
        color: Colors.red,
      ),
    );
    return buttons;
  }

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
      message: t.collections.deleteConfirm(title: widget.collection.title),
    );

    if (confirmed != true) return;
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
            CustomAppBar(title: Text(widget.collection.title), actions: buildFocusableAppBarActions()),
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
