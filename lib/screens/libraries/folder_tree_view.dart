import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/jellyfin_client.dart';
import '../../services/jellyfin_sequential_launcher.dart';
import '../../services/play_queue_launcher.dart';
import '../../services/plex_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../i18n/strings.g.dart';
import 'folder_tree_item.dart';
import 'state_messages.dart';

/// Expandable tree view for browsing library folders
/// Shows a hierarchical file/folder structure
class FolderTreeView extends StatefulWidget {
  final String libraryKey;
  final String? serverId; // Server this library belongs to
  final MediaKind? libraryKind;
  final void Function(String)? onRefresh;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onNavigateUp;

  const FolderTreeView({
    super.key,
    required this.libraryKey,
    this.serverId,
    this.libraryKind,
    this.onRefresh,
    this.firstItemFocusNode,
    this.onNavigateUp,
  });

  @override
  State<FolderTreeView> createState() => FolderTreeViewState();
}

/// Public state so parents can trigger a refresh via GlobalKey.
class FolderTreeViewState extends State<FolderTreeView> {
  /// Reload the root folders. Exposed for parent-driven pull-to-refresh.
  Future<void> refresh() => _loadRootFolders();

  /// Folders/items returned by the backend's folder API and mapped to neutral
  /// [MediaItem]s. Plex folder URLs survive in [MediaItem.raw]['key'];
  /// Jellyfin folders use the item id as their recursive parent id.
  List<MediaItem> _rootFolders = [];
  final Map<String, List<MediaItem>> _childrenCache = {};
  final Set<String> _expandedFolders = {};
  final Set<String> _loadingFolders = {};
  bool _isLoadingRoot = false;
  String? _errorMessage;

  /// Resolve the Plex folder key from a [MediaItem]'s `raw` map. The key is
  /// a relative URL (e.g. `/library/sections/1/folder?parent=...`) used to
  /// recursively fetch children from [PlexClient.fetchFolderChildren].
  String? _folderKey(MediaItem item) => item.raw?['key'] as String?;

  String? _itemType(MediaItem item) => (item.raw?['Type'] as String? ?? item.raw?['type'] as String?)?.toLowerCase();

  String? _folderIdentity(MediaItem item) {
    if (item.backend == MediaBackend.plex) return _folderKey(item);
    if (_isFolder(item)) return item.id;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadRootFolders();
  }

  Future<void> _loadRootFolders() async {
    setState(() {
      _isLoadingRoot = true;
      _errorMessage = null;
    });

    try {
      final client = context.getMediaClientForServer(widget.serverId!);
      final folders = await _fetchRootFolders(client);

      if (!mounted) return;

      setState(() {
        _rootFolders = folders;
        _isLoadingRoot = false;
      });

      appLogger.d('Loaded ${folders.length} root folders');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = mapUnexpectedErrorToMessage(e, context: t.libraries.folders);
        _isLoadingRoot = false;
      });
    }
  }

  Future<void> _loadFolderChildren(MediaItem folder) async {
    final folderIdentity = _folderIdentity(folder);
    if (folderIdentity == null) return;

    // Already loading this folder
    if (_loadingFolders.contains(folderIdentity)) return;

    // Already loaded and cached
    if (_childrenCache.containsKey(folderIdentity)) {
      setState(() {
        _expandedFolders.add(folderIdentity);
      });
      return;
    }

    setState(() {
      _loadingFolders.add(folderIdentity);
    });

    try {
      final client = context.getMediaClientForServer(widget.serverId!);
      final children = await _fetchFolderChildren(client, folder);

      if (!mounted) return;

      setState(() {
        _childrenCache[folderIdentity] = children;
        _expandedFolders.add(folderIdentity);
        _loadingFolders.remove(folderIdentity);
      });

      appLogger.d('Loaded ${children.length} children for folder: ${folder.title}');
    } catch (e) {
      if (!mounted) return;

      final message = mapUnexpectedErrorToMessage(e, context: t.libraries.folders);
      setState(() {
        _loadingFolders.remove(folderIdentity);
      });

      if (mounted) {
        showErrorSnackBar(context, message);
      }
    }
  }

  void _toggleFolder(MediaItem folder) {
    final folderIdentity = _folderIdentity(folder);
    if (folderIdentity == null) return;
    if (_expandedFolders.contains(folderIdentity)) {
      setState(() {
        _expandedFolders.remove(folderIdentity);
      });
    } else {
      _loadFolderChildren(folder);
    }
  }

  Future<void> _handleItemTap(MediaItem item) async {
    final result = await navigateToMediaItem(context, item, onRefresh: widget.onRefresh);
    if (!context.mounted) return;
    switch (result) {
      case MediaNavigationResult.unsupported:
        showAppSnackBar(context, t.messages.musicNotSupported);
      case MediaNavigationResult.listRefreshNeeded:
        widget.onRefresh?.call(item.id);
      case MediaNavigationResult.navigated:
      case MediaNavigationResult.librarySelected:
        break;
    }
  }

  Future<void> _handleFolderPlay(MediaItem folder) async {
    if (folder.backend == MediaBackend.jellyfin) {
      final launcher = JellyfinSequentialLauncher(context: context);
      await launcher.launchFromFolder(folder: folder, shuffle: false);
      return;
    }

    final folderKey = _folderKey(folder);
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(widget.serverId!);
    final launcher = PlexPlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(
      folderKey: folderKey,
      shuffle: false,
      libraryId: folder.libraryId,
      libraryTitle: folder.libraryTitle,
    );
  }

  Future<void> _handleFolderShuffle(MediaItem folder) async {
    if (folder.backend == MediaBackend.jellyfin) {
      final launcher = JellyfinSequentialLauncher(context: context);
      await launcher.launchFromFolder(folder: folder, shuffle: true);
      return;
    }

    final folderKey = _folderKey(folder);
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(widget.serverId!);
    final launcher = PlexPlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(
      folderKey: folderKey,
      shuffle: true,
      libraryId: folder.libraryId,
      libraryTitle: folder.libraryTitle,
    );
  }

  bool _isFolder(MediaItem item) {
    if (item.backend == MediaBackend.jellyfin) {
      return _isJellyfinFilesystemFolder(item) || _isJellyfinMediaContainer(item);
    }

    // Plex folders typically have no media kind (mapped to [MediaKind.unknown])
    // or expose `/folder` in their key.
    final folderKey = _folderKey(item);
    final type = _itemType(item);
    return folderKey?.contains('/folder') == true || type == 'folder' || item.kind == MediaKind.unknown;
  }

  bool _isJellyfinFilesystemFolder(MediaItem item) {
    final type = _itemType(item);
    return type == 'folder' || type == 'collectionfolder' || (type == null && item.raw?['IsFolder'] == true);
  }

  bool _isJellyfinMediaContainer(MediaItem item) => item.kind == MediaKind.show || item.kind == MediaKind.season;

  bool _canPlayFolder(MediaItem item) {
    if (item.backend == MediaBackend.plex) return true;
    if (item.backend == MediaBackend.jellyfin) return widget.libraryKind?.isMusic != true;
    return false;
  }

  Future<List<MediaItem>> _fetchRootFolders(MediaServerClient client) {
    if (client is PlexClient) return client.fetchLibraryFolders(widget.libraryKey);
    if (client is JellyfinClient) return client.fetchLibraryFolders(widget.libraryKey);
    throw UnsupportedError('Folder browsing is not supported for ${client.backend.id}');
  }

  Future<List<MediaItem>> _fetchFolderChildren(MediaServerClient client, MediaItem folder) {
    if (client is PlexClient) {
      final folderKey = _folderKey(folder);
      if (folderKey == null) return Future.value(const <MediaItem>[]);
      return client.fetchFolderChildren(folderKey, libraryId: folder.libraryId, libraryTitle: folder.libraryTitle);
    }
    if (client is JellyfinClient) {
      if (_isJellyfinMediaContainer(folder)) return client.fetchChildren(folder.id);
      return client.fetchFolderChildren(folder.id);
    }
    throw UnsupportedError('Folder browsing is not supported for ${client.backend.id}');
  }

  /// Flatten the visible tree into a list of (item, depth, path) tuples so
  /// `ListView.builder` can lazy-build only the rows currently on screen.
  void _flattenTreeItems(
    List<MediaItem> items,
    int depth,
    String parentPath,
    List<({MediaItem item, int depth, String path})> out,
  ) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemPath = parentPath.isEmpty ? '$i' : '$parentPath-$i';
      out.add((item: item, depth: depth, path: itemPath));

      final folderKey = _folderIdentity(item);
      if (_isFolder(item) &&
          folderKey != null &&
          _expandedFolders.contains(folderKey) &&
          _childrenCache.containsKey(folderKey)) {
        _flattenTreeItems(_childrenCache[folderKey]!, depth + 1, itemPath, out);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRoot) {
      return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateWidget(
          message: _errorMessage!,
          icon: Symbols.error_outline_rounded,
          onRetry: _loadRootFolders,
          retryLabel: t.common.retry,
        ),
      );
    }

    if (_rootFolders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(message: t.libraries.noFoldersFound, icon: Symbols.folder_open_rounded),
      );
    }

    final flattened = <({MediaItem item, int depth, String path})>[];
    _flattenTreeItems(_rootFolders, 0, '', flattened);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList.builder(
        itemCount: flattened.length,
        itemBuilder: (context, index) {
          final entry = flattened[index];
          final item = entry.item;
          final isFolder = _isFolder(item);
          final folderKey = _folderIdentity(item);
          final isExpanded = folderKey != null && _expandedFolders.contains(folderKey);
          final isLoading = folderKey != null && _loadingFolders.contains(folderKey);
          final isFirstRootItem = index == 0;
          final canPlayFolder = isFolder && _canPlayFolder(item);

          return FolderTreeItem(
            key: ValueKey(entry.path),
            item: item,
            depth: entry.depth,
            isFolder: isFolder,
            isExpanded: isExpanded,
            isLoading: isLoading,
            serverId: widget.serverId,
            onExpand: isFolder ? () => _toggleFolder(item) : null,
            onTap: !isFolder ? () => _handleItemTap(item) : null,
            onPlayAll: canPlayFolder ? () => _handleFolderPlay(item) : null,
            onShuffle: canPlayFolder ? () => _handleFolderShuffle(item) : null,
            focusNode: isFirstRootItem ? widget.firstItemFocusNode : null,
            onNavigateUp: isFirstRootItem ? widget.onNavigateUp : null,
          );
        },
      ),
    );
  }
}
