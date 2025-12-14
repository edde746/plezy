import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/multi_server_provider.dart';
import '../utils/provider_extensions.dart';
import '../services/play_queue_launcher.dart';
import '../models/plex_playlist.dart';
import '../utils/app_logger.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import 'libraries/error_state_widget.dart';
import 'libraries/empty_state_widget.dart';

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

  /// Optional icon to show when list is empty
  IconData? get emptyIcon => null;

  /// Get the correct PlexClient for this media item's server
  PlexClient _getClientForMediaItem() {
    // Try to get serverId from the media item
    String? serverId;

    // Check if mediaItem has serverId property
    if (mediaItem is PlexMetadata) {
      serverId = (mediaItem as PlexMetadata).serverId;
    } else if (mediaItem != null) {
      // For playlists or other types, use dynamic access
      try {
        final dynamic item = mediaItem;
        serverId = item.serverId as String?;
      } catch (_) {
        // Ignore if serverId is not available
      }
    }

    // If serverId is null, fall back to first available server
    if (serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.errors.noClientAvailable);
      }
      serverId = multiServerProvider.onlineServerIds.first;
    }

    return context.getClientForServer(serverId);
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
    final item = mediaItem;

    final launcher = PlayQueueLauncher(
      context: context,
      client: client,
      serverId: item is PlexMetadata
          ? item.serverId
          : (item as PlexPlaylist).serverId,
      serverName: item is PlexMetadata
          ? item.serverName
          : (item as PlexPlaylist).serverName,
    );

    await launcher.launchFromCollectionOrPlaylist(
      item: item,
      shuffle: shuffle,
      showLoadingIndicator: false,
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

  /// Build common error/loading/empty state slivers
  /// Returns a list of slivers to display based on current state
  List<Widget> buildStateSlivers() {
    if (errorMessage != null) {
      return [
        SliverFillRemaining(
          child: ErrorStateWidget(
            message: errorMessage!,
            icon: Symbols.error_outline_rounded,
            onRetry: loadItems,
          ),
        ),
      ];
    }

    if (items.isEmpty && isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          child: EmptyStateWidget(
            message: emptyMessage,
            icon: emptyIcon,
          ),
        ),
      ];
    }

    return [];
  }

  /// Build standard app bar actions (play, shuffle, delete)
  /// Subclasses can override to customize actions
  List<Widget> buildAppBarActions({
    VoidCallback? onDelete,
    String? deleteTooltip,
    Color? deleteColor,
    bool showDelete = true,
  }) {
    return [
      // Play button
      if (items.isNotEmpty)
        IconButton(
          icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
          tooltip: t.discover.play,
          onPressed: playItems,
        ),
      // Shuffle button
      if (items.isNotEmpty)
        IconButton(
          icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
          tooltip: t.common.shuffle,
          onPressed: shufflePlayItems,
        ),
      // Delete button
      if (showDelete && onDelete != null)
        IconButton(
          icon: const AppIcon(Symbols.delete_rounded, fill: 1),
          tooltip: deleteTooltip ?? t.common.delete,
          onPressed: onDelete,
          color: deleteColor ?? Colors.red,
        ),
    ];
  }
}

/// Mixin that provides standard loadItems implementation for media lists
/// Handles the common pattern of fetching, tagging, and setting items
mixin StandardItemLoader<T extends StatefulWidget>
    on BaseMediaListDetailScreen<T> {
  /// Fetch items from the API (must be implemented by subclass)
  Future<List<PlexMetadata>> fetchItems();

  /// Get error message for failed load (can be overridden)
  String getLoadErrorMessage(Object error) {
    return 'Failed to load items: ${error.toString()}';
  }

  /// Get log message for successful load (can be overridden)
  String getLoadSuccessMessage(int itemCount) {
    return 'Loaded $itemCount items';
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
      // Items are automatically tagged with server info by PlexClient
      final newItems = await fetchItems();

      if (mounted) {
        setState(() {
          items = newItems;
          isLoading = false;
        });
      }

      appLogger.d(getLoadSuccessMessage(newItems.length));
    } catch (e) {
      appLogger.e('Failed to load items', error: e);
      if (mounted) {
        setState(() {
          errorMessage = getLoadErrorMessage(e);
          isLoading = false;
        });
      }
    }
  }
}
