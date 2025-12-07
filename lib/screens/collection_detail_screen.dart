import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../focus/dpad_navigator.dart';
import '../models/plex_metadata.dart';
import '../providers/settings_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/dialogs.dart';
import '../utils/app_logger.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.collections.unknownLibrarySection)),
        );
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.collections.deleted)));
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate refresh needed
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.collections.deleteFailed)));
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.collections.deleteFailedWithError(error: e.toString()),
            ),
          ),
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey.isBackKey) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(widget.collection.title),
            pinned: true,
            actions: buildAppBarActions(onDelete: _deleteCollection),
          ),
          ...buildStateSlivers(),
          if (items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              sliver: Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          GridSizeCalculator.getMaxCrossAxisExtent(
                            context,
                            settingsProvider.libraryDensity,
                          ),
                      childAspectRatio: 2 / 3.3,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];
                      return MediaCard(
                        key: Key(item.ratingKey),
                        item: item,
                        onRefresh: updateItem,
                        collectionId: widget.collection.ratingKey,
                        onListRefresh: loadItems,
                      );
                    }, childCount: items.length),
                  );
                },
              ),
            ),
        ],
      ),
      ),
    );
  }
}
