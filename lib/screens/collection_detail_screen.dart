import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/collection_playlist_play_helper.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import '../utils/grid_size_calculator.dart';

/// Screen to display the contents of a collection
class CollectionDetailScreen extends StatefulWidget {
  final PlexMetadata collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen>
    with Refreshable, ItemUpdatable {
  @override
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCollectionItems();
  }

  Future<void> _loadCollectionItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      final items = await client.getCollectionItems(widget.collection.ratingKey);

      setState(() {
        _items = items;
        _isLoading = false;
      });

      appLogger.d(
        'Loaded ${items.length} items for collection: ${widget.collection.title}',
      );
    } catch (e) {
      appLogger.e('Failed to load collection items', error: e);
      setState(() {
        _errorMessage = t.collections.failedToLoadItems(
          error: e.toString(),
        );
        _isLoading = false;
      });
    }
  }

  @override
  void refresh() {
    _loadCollectionItems();
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    setState(() {
      final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
      if (index != -1) {
        _items[index] = updatedMetadata;
      }
    });
  }

  Future<void> _playCollection() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.collections.empty)),
        );
      }
      return;
    }

    final clientProvider = context.plexClient;
    final client = clientProvider.client;
    if (client == null) return;

    await playCollectionOrPlaylist(
      context: context,
      client: client,
      item: widget.collection,
      shuffle: false,
    );
  }

  Future<void> _shufflePlayCollection() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.collections.empty)),
        );
      }
      return;
    }

    final clientProvider = context.plexClient;
    final client = clientProvider.client;
    if (client == null) return;

    await playCollectionOrPlaylist(
      context: context,
      client: client,
      item: widget.collection,
      shuffle: true,
    );
  }

  Future<void> _deleteCollection() async {
    // Get library section ID from the collection or its items
    int? sectionId = widget.collection.librarySectionID;

    // If collection doesn't have it, try to get it from loaded items
    if (sectionId == null && _items.isNotEmpty) {
      sectionId = _items.first.librarySectionID;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.collections.deleteCollection),
        content: Text(
          t.collections.deleteConfirm(title: widget.collection.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) return;

      final success = await client.deleteCollection(
        sectionId.toString(),
        widget.collection.ratingKey,
      );

      if (mounted) {
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.collections.deleted)),
            );
          Navigator.pop(context, true); // Return true to indicate refresh needed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.collections.deleteFailed)),
          );
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
              if (_items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: t.discover.play,
                  onPressed: _playCollection,
                ),
              // Shuffle button
              if (_items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: t.common.shuffle,
                  onPressed: _shufflePlayCollection,
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
          if (_errorMessage != null)
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
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCollectionItems,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(t.collections.noItems),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              sliver: Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
                        context,
                        settingsProvider.libraryDensity,
                      ),
                      childAspectRatio: 2 / 3.3,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        return MediaCard(
                          key: Key(item.ratingKey),
                          item: item,
                          onRefresh: updateItem,
                          collectionId: widget.collection.ratingKey,
                          onListRefresh: _loadCollectionItems,
                        );
                      },
                      childCount: _items.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
