import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/dialogs.dart';
import '../utils/provider_extensions.dart';
import 'base_media_list_detail_screen.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final PlexMetadata collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends BaseMediaListDetailScreen<CollectionDetailScreen> {
  @override
  PlexMetadata get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title;

  @override
  String get emptyMessage => t.collections.empty;

  /// Get the correct PlexClient for this collection's server
  PlexClient? _getClientForCollection() {
    final serverId = widget.collection.serverId;
    if (serverId == null) {
      appLogger.w('Collection ${widget.collection.title} has no serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    final multiServerProvider = context.read<MultiServerProvider>();
    final client = multiServerProvider.getClientForServer(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    return client;
  }

  @override
  Future<void> loadItems() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final client = this.client;
      final newItems = await client.getCollectionItems(
        widget.collection.ratingKey,
      );

      // Tag items with server info for correct client resolution
      final taggedItems = newItems
          .map(
            (item) => item.copyWith(
              serverId: widget.collection.serverId,
              serverName: widget.collection.serverName,
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          items = taggedItems;
          isLoading = false;
        });
      }

      appLogger.d(
        'Loaded ${newItems.length} items for collection: ${widget.collection.title}',
      );
    } catch (e) {
      appLogger.e('Failed to load collection items', error: e);
      if (mounted) {
        setState(() {
          errorMessage = t.collections.failedToLoadItems(error: e.toString());
          isLoading = false;
        });
      }
    }
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
      final client = _getClientForCollection();
      if (client == null) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(widget.collection.title),
            pinned: true,
            actions: [
              // Play button
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: t.discover.play,
                  onPressed: playItems,
                ),
              // Shuffle button
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: t.common.shuffle,
                  onPressed: shufflePlayItems,
                ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: t.common.delete,
                onPressed: _deleteCollection,
                color: Colors.red,
              ),
            ],
          ),
          if (errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadItems,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (items.isEmpty && isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(t.collections.noItems)),
            )
          else
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
    );
  }
}
