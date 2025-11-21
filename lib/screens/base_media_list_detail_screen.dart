import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/collection_playlist_play_helper.dart';
import '../utils/app_logger.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';

/// Abstract base class for screens displaying media lists (collections/playlists)
/// Provides common state management and playback functionality
abstract class BaseMediaListDetailScreen<T extends StatefulWidget>
    extends State<T>
    with Refreshable, ItemUpdatable {
  // State properties - concrete implementations to avoid duplication
  List<PlexMetadata> items = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  PlexClient get client => _getClientForMediaItem();

  /// The media item being displayed (collection or playlist)
  dynamic get mediaItem;

  /// Title to display in app bar
  String get title;

  /// Message to show when list is empty
  String get emptyMessage;

  /// Get the correct PlexClient for this media item's server
  PlexClient _getClientForMediaItem() {
    // Try to get serverId from the media item
    String? serverId;

    // Check if mediaItem has serverId property
    if (mediaItem is PlexMetadata) {
      serverId = (mediaItem as PlexMetadata).serverId;
    } else if (mediaItem != null &&
               mediaItem.runtimeType.toString().contains('PlexPlaylist')) {
      // For playlists, use reflection-like access
      try {
        final dynamic item = mediaItem;
        serverId = item.serverId as String?;
      } catch (_) {
        // Ignore if serverId is not available
      }
    }

    if (serverId == null) {
      appLogger.w('Media item has no serverId, using legacy client');
      return context.read<PlexClientProvider>().client!;
    }

    final multiServerProvider = context.read<MultiServerProvider>();
    final client = multiServerProvider.getClientForServer(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId, using legacy client');
      return context.read<PlexClientProvider>().client!;
    }

    return client;
  }

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  /// Load or reload the items (subclasses implement this)
  Future<void> loadItems();

  /// Play all items in the list
  Future<void> playItems() => _playWithShuffle(false);

  /// Shuffle play all items in the list
  Future<void> shufflePlayItems() => _playWithShuffle(true);

  /// Internal helper to play items with optional shuffle
  Future<void> _playWithShuffle(bool shuffle) async {
    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      }
      return;
    }

    final client = _getClientForMediaItem();

    await playCollectionOrPlaylist(
      context: context,
      client: client,
      item: mediaItem,
      shuffle: shuffle,
    );
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    if (mounted) {
      setState(() {
        final index = items.indexWhere((item) => item.ratingKey == ratingKey);
        if (index != -1) {
          items[index] = updatedMetadata;
        }
      });
    }
  }

  @override
  void refresh() {
    loadItems();
  }
}
