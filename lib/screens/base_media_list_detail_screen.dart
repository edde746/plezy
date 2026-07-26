import 'package:flutter/material.dart';
import '../media/ids.dart';
import 'package:provider/provider.dart';
import '../media/media_item.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/provider_extensions.dart';
import '../services/media_list_playback_launcher.dart';
import '../services/jellyfin_sequential_launcher.dart';
import '../widgets/loading_indicator_box.dart';
import '../utils/app_logger.dart';
import '../utils/error_message_utils.dart';
import '../utils/snackbar_helper.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import 'libraries/content_state_builder.dart';

/// Abstract base class for screens displaying media lists (collections/playlists)
/// Provides common state management and playback functionality
abstract class BaseMediaListDetailScreen<T extends StatefulWidget> extends State<T> with Refreshable, ItemUpdatable {
  // State properties - concrete implementations to avoid duplication
  List<MediaItem> items = [];
  bool isLoading = false;
  String? errorMessage;

  /// Backend-neutral client for the media item's server.
  MediaServerClient get mediaClient => _getMediaClientForMediaItem();

  /// The media item being displayed (collection or playlist) — either a
  /// [MediaItem] or a [MediaPlaylist].
  Object get mediaItem;

  /// Title to display in app bar
  String get title;

  /// Message to show when list is empty
  String get emptyMessage;

  /// Optional icon to show when list is empty
  IconData? get emptyIcon => null;

  /// Server the displayed item was tagged with, if any.
  String? get _mediaItemServerId => switch (mediaItem) {
    MediaItem(:final serverId) => serverId,
    MediaPlaylist(:final serverId) => serverId,
    _ => null,
  };

  /// Sync-rule global key for the displayed collection/playlist, keyed to the
  /// item's own server when it has one and to the resolved client's otherwise.
  String get syncRuleKey {
    final client = mediaClient;
    final id = switch (mediaItem) {
      MediaItem(:final id) => id,
      MediaPlaylist(:final id) => id,
      _ => '',
    };
    return context.read<DownloadProvider>().syncRuleKeyForClient(
      client,
      id,
      serverId: ServerId(_mediaItemServerId ?? client.serverId),
    );
  }

  String? _resolveMediaItemServerId() {
    final serverId = _mediaItemServerId;
    if (serverId != null) return serverId;
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    return multiServerProvider.onlineServerIds.firstOrNull;
  }

  MediaServerClient _getMediaClientForMediaItem() {
    final serverId = _resolveMediaItemServerId();
    if (serverId == null) {
      throw Exception(t.errors.noClientAvailable);
    }
    return context.getMediaClientWithFallback(ServerId(serverId));
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

  /// Internal helper to play items with optional shuffle.
  ///
  /// Dispatches to the right launcher implementation based on the item's
  /// backend — Plex uses server-side `/playQueues`, Jellyfin builds an
  /// in-memory queue via [JellyfinSequentialLauncher].
  Future<void> _playWithShuffle(bool shuffle) async {
    if (items.isEmpty) {
      if (mounted) {
        showAppSnackBar(context, emptyMessage);
      }
      return;
    }

    final item = mediaItem;
    final launcher = MediaListPlaybackLauncher.forItem(context, item);
    await launcher.launchFromCollectionOrPlaylist(
      item: item,
      shuffle: shuffle,
      showLoadingIndicator: launcher is JellyfinSequentialLauncher,
    );
  }

  @override
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    final index = items.indexWhere((item) => item.globalKey == sourceGlobalKey);
    if (index != -1) {
      items[index] = updatedItem;
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
      return [SliverErrorState(message: errorMessage!, onRetry: loadItems)];
    }

    if (items.isEmpty && isLoading) {
      return [LoadingIndicatorBox.sliver];
    }

    if (items.isEmpty) {
      return [SliverEmptyState(message: emptyMessage, icon: emptyIcon)];
    }

    return [];
  }
}

/// Mixin that provides standard loadItems implementation for media lists
/// Handles the common pattern of fetching, tagging, and setting items
mixin StandardItemLoader<T extends StatefulWidget> on BaseMediaListDetailScreen<T> {
  /// Fetch items from the API (must be implemented by subclass)
  Future<List<MediaItem>> fetchItems();

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
    } catch (e, stackTrace) {
      final message = localizedLoadErrorMessage(e, stackTrace, context: title);
      if (mounted) {
        setState(() {
          errorMessage = message;
          isLoading = false;
        });
      }
    }
  }
}
