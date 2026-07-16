import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/jellyfin_sequential_launcher.dart';
import '../../services/play_queue_launcher.dart';
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
  final void Function(MediaItem source)? onRefresh;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onBack;

  const FolderTreeView({
    super.key,
    required this.libraryKey,
    this.serverId,
    this.libraryKind,
    this.onRefresh,
    this.firstItemFocusNode,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onBack,
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

  /// Generation counter for in-flight loads. Jellyfin folder fetches render
  /// page-by-page via `onPage`; a root reload or deletion refresh bumps the
  /// epoch so superseded pagination callbacks are dropped.
  int _loadEpoch = 0;

  /// Stable expand/cache key for an expandable row: the backend folder key
  /// where one exists (Plex `/folder` rows), the item id otherwise.
  String? _folderIdentity(MediaItem item) {
    if (!_isExpandable(item)) return null;
    return item.backendFolderKey ?? item.id;
  }

  @override
  void initState() {
    super.initState();
    _loadRootFolders();
  }

  /// Invalidate in-flight loads (epoch bump) and drop their partial results
  /// so superseded pagination can't leave truncated listings behind.
  int _supersedeInFlightLoads() {
    final epoch = ++_loadEpoch;
    for (final id in _loadingFolders) {
      _childrenCache.remove(id);
      _expandedFolders.remove(id);
    }
    _loadingFolders.clear();
    return epoch;
  }

  Future<void> _loadRootFolders() async {
    final epoch = _supersedeInFlightLoads();
    setState(() {
      _isLoadingRoot = true;
      _errorMessage = null;
    });

    try {
      final client = context.getMediaClientForServer(ServerId(widget.serverId!));
      final folders = await _fetchRootFolders(
        client,
        onPage: (items) {
          if (!mounted || epoch != _loadEpoch) return;
          setState(() {
            _rootFolders = items;
            _isLoadingRoot = false;
          });
        },
      );

      if (!mounted || epoch != _loadEpoch) return;

      setState(() {
        _rootFolders = folders;
        _isLoadingRoot = false;
      });

      appLogger.d('Loaded ${folders.length} root folders');
    } catch (e, stackTrace) {
      if (!mounted || epoch != _loadEpoch) return;

      final message = localizedLoadErrorMessage(e, stackTrace, context: t.libraries.folders);
      setState(() {
        _errorMessage = message;
        _isLoadingRoot = false;
      });
    }
  }

  Future<void> _loadFolderChildren(MediaItem folder) async {
    final folderIdentity = _folderIdentity(folder);
    if (folderIdentity == null) return;

    // Already loading this folder — re-expand if partial pages are showing
    // (the user collapsed and re-expanded mid-pagination).
    if (_loadingFolders.contains(folderIdentity)) {
      if (_childrenCache.containsKey(folderIdentity)) {
        setState(() {
          _expandedFolders.add(folderIdentity);
        });
      }
      return;
    }

    // Already loaded and cached
    if (_childrenCache.containsKey(folderIdentity)) {
      setState(() {
        _expandedFolders.add(folderIdentity);
      });
      return;
    }

    final epoch = _loadEpoch;
    var pageDelivered = false;
    setState(() {
      _loadingFolders.add(folderIdentity);
    });

    try {
      final client = context.getMediaClientForServer(ServerId(widget.serverId!));
      final children = await _fetchFolderChildren(
        client,
        folder,
        onPage: (items) {
          if (!mounted || epoch != _loadEpoch) return;
          pageDelivered = true;
          setState(() {
            _childrenCache[folderIdentity] = items;
            _expandedFolders.add(folderIdentity);
          });
        },
      );

      if (!mounted || epoch != _loadEpoch) return;

      setState(() {
        _childrenCache[folderIdentity] = children;
        // Pages already expanded the folder; don't override a mid-load collapse.
        if (!pageDelivered) _expandedFolders.add(folderIdentity);
        _loadingFolders.remove(folderIdentity);
      });

      appLogger.d('Loaded ${children.length} children for folder: ${folder.title}');
    } catch (e, stackTrace) {
      if (!mounted || epoch != _loadEpoch) return;

      final message = localizedLoadErrorMessage(e, stackTrace, context: t.libraries.folders);
      setState(() {
        _loadingFolders.remove(folderIdentity);
        // Drop partial pages so a retry refetches instead of leaving a
        // truncated listing that looks complete.
        _childrenCache.remove(folderIdentity);
        _expandedFolders.remove(folderIdentity);
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

  /// Refetch the listing containing a deleted item: the whole tree for root
  /// items, otherwise just the enclosing folder.
  void _refreshAfterDeletion(MediaItem? parent) {
    if (parent == null) {
      _loadRootFolders();
      return;
    }
    _supersedeInFlightLoads();
    final folderIdentity = _folderIdentity(parent);
    if (folderIdentity != null) {
      setState(() {
        _childrenCache.remove(folderIdentity);
      });
    }
    _loadFolderChildren(parent);
  }

  Future<void> _handleItemTap(MediaItem item, MediaItem? parent) async {
    final result = await navigateToMediaItem(context, item, onRefresh: widget.onRefresh);
    if (!mounted) return;
    switch (result) {
      case MediaNavigationResult.unsupported:
        showAppSnackBar(context, t.messages.musicNotSupported);
      case MediaNavigationResult.listRefreshNeeded:
        _refreshAfterDeletion(parent);
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

    final folderKey = folder.backendFolderKey;
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(ServerId(widget.serverId!));
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

    final folderKey = folder.backendFolderKey;
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(ServerId(widget.serverId!));
    final launcher = PlexPlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(
      folderKey: folderKey,
      shuffle: true,
      libraryId: folder.libraryId,
      libraryTitle: folder.libraryTitle,
    );
  }

  /// Expandable rows: directory rows plus Jellyfin media containers whose
  /// direct children form the folder tree. Music libraries expose folder-
  /// backed artists and albums as MusicArtist/MusicAlbum rather than generic
  /// Folder DTOs, so those rows must expand instead of opening empty details.
  bool _isExpandable(MediaItem item) {
    return item.kind == MediaKind.folder || (item.backend == MediaBackend.jellyfin && _isJellyfinMediaContainer(item));
  }

  bool _isJellyfinMediaContainer(MediaItem item) {
    if (item.kind == MediaKind.show || item.kind == MediaKind.season) return true;
    return widget.libraryKind?.isMusic == true && (item.kind == MediaKind.artist || item.kind == MediaKind.album);
  }

  bool _canPlayFolder(MediaItem item) {
    if (item.backend == MediaBackend.plex) return true;
    if (item.backend == MediaBackend.jellyfin) return widget.libraryKind?.isMusic != true;
    return false;
  }

  Future<List<MediaItem>> _fetchRootFolders(
    MediaServerClient client, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) {
    return client.fetchLibraryFolders(widget.libraryKey, onPage: onPage);
  }

  Future<List<MediaItem>> _fetchFolderChildren(
    MediaServerClient client,
    MediaItem folder, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) {
    return client.fetchFolderChildren(folder, onPage: onPage);
  }

  /// Flatten the visible tree into a list of (item, depth, path, parent)
  /// tuples so `ListView.builder` can lazy-build only the rows currently on
  /// screen. [parent] is the enclosing folder (null for root items).
  void _flattenTreeItems(
    List<MediaItem> items,
    int depth,
    String parentPath,
    MediaItem? parent,
    List<({MediaItem item, int depth, String path, MediaItem? parent})> out,
  ) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemPath = parentPath.isEmpty ? '$i' : '$parentPath-$i';
      out.add((item: item, depth: depth, path: itemPath, parent: parent));

      final folderKey = _folderIdentity(item);
      if (_isExpandable(item) &&
          folderKey != null &&
          _expandedFolders.contains(folderKey) &&
          _childrenCache.containsKey(folderKey)) {
        _flattenTreeItems(_childrenCache[folderKey]!, depth + 1, itemPath, item, out);
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
          actionFocusNode: widget.firstItemFocusNode,
          onActionNavigateUp: widget.onNavigateUp,
          onActionNavigateLeft: widget.onNavigateLeft,
          onActionBack: widget.onBack,
        ),
      );
    }

    if (_rootFolders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(message: t.libraries.noFoldersFound, icon: Symbols.folder_open_rounded),
      );
    }

    final flattened = <({MediaItem item, int depth, String path, MediaItem? parent})>[];
    _flattenTreeItems(_rootFolders, 0, '', null, flattened);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList.builder(
        itemCount: flattened.length,
        itemBuilder: (context, index) {
          final entry = flattened[index];
          final item = entry.item;
          final isExpandable = _isExpandable(item);
          final isPlainFolder = item.kind == MediaKind.folder;
          final folderKey = _folderIdentity(item);
          final isExpanded = folderKey != null && _expandedFolders.contains(folderKey);
          final isLoading = folderKey != null && _loadingFolders.contains(folderKey);
          final isFirstRootItem = index == 0;
          final canPlayFolder = isPlainFolder && _canPlayFolder(item);

          return FolderTreeItem(
            // Path alone isn't unique enough as identity (the same Plex item
            // can appear under two folders), so combine it with the item id.
            key: ValueKey('${entry.path}:${item.id}'),
            item: item,
            depth: entry.depth,
            isFolder: isPlainFolder,
            isExpandable: isExpandable,
            isExpanded: isExpanded,
            isLoading: isLoading,
            serverId: widget.serverId,
            onExpand: isExpandable ? () => _toggleFolder(item) : null,
            onTap: !isExpandable ? () => _handleItemTap(item, entry.parent) : null,
            onPlayAll: canPlayFolder ? () => _handleFolderPlay(item) : null,
            onShuffle: canPlayFolder ? () => _handleFolderShuffle(item) : null,
            focusNode: isFirstRootItem ? widget.firstItemFocusNode : null,
            onNavigateUp: isFirstRootItem ? widget.onNavigateUp : null,
            onNavigateLeft: widget.onNavigateLeft,
            onRefresh: widget.onRefresh,
            onListRefresh: () => _refreshAfterDeletion(entry.parent),
          );
        },
      ),
    );
  }
}
