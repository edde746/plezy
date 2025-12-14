import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../widgets/media_grid_sliver.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../i18n/strings.g.dart';
import '../utils/dialogs.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import 'base_media_list_detail_screen.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final PlexMetadata collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends BaseMediaListDetailScreen<CollectionDetailScreen>
    with StandardItemLoader<CollectionDetailScreen> {
  @override
  PlexMetadata get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  Future<List<PlexMetadata>> fetchItems() async {
    return await client.getCollectionItems(widget.collection.ratingKey);
  }

  @override
  String getLoadErrorMessage(Object error) {
    return t.collections.failedToLoadItems(error: error.toString());
  }

  @override
  String getLoadSuccessMessage(int itemCount) {
    return 'Loaded $itemCount items for collection: ${widget.collection.title}';
  }

  Future<void> _deleteCollection() async {
    // Get library section ID from the collection or its items
    int? sectionId = widget.collection.librarySectionID;

    // If collection doesn't have it, try to get it from loaded items
    if (sectionId == null && items.isNotEmpty) {
      sectionId = items.first.librarySectionID;
    }

    if (sectionId == null) {
      if (mounted) {
        showErrorSnackBar(context, t.collections.unknownLibrarySection);
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.deleteCollection,
      message: t.collections.deleteConfirm(title: widget.collection.title),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final success = await client.deleteCollection(
        sectionId.toString(),
        widget.collection.ratingKey,
      );

      if (!mounted) return;

      if (mounted) {
        if (success) {
          showSuccessSnackBar(context, t.collections.deleted);
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate refresh needed
        } else {
          showErrorSnackBar(context, t.collections.deleteFailed);
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      if (mounted) {
        showErrorSnackBar(
          context,
          t.collections.deleteFailedWithError(error: e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(widget.collection.title),
      actions: buildAppBarActions(onDelete: _deleteCollection),
      slivers: [
        ...buildStateSlivers(),
        if (items.isNotEmpty)
          MediaGridSliver(
            items: items,
            onRefresh: updateItem,
            collectionId: widget.collection.ratingKey,
            onListRefresh: loadItems,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          ),
      ],
    );
  }
}
