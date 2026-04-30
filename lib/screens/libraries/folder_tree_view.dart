import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../services/play_queue_launcher.dart';
import '../../utils/app_logger.dart';
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
  final void Function(String)? onRefresh;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onNavigateUp;

  const FolderTreeView({
    super.key,
    required this.libraryKey,
    this.serverId,
    this.onRefresh,
    this.firstItemFocusNode,
    this.onNavigateUp,
  });

  @override
  State<FolderTreeView> createState() => _FolderTreeViewState();
}

class _FolderTreeViewState extends State<FolderTreeView> {
  /// Folders/items returned by the Plex `/library/sections/{id}/folder`
  /// endpoint, mapped to neutral [MediaItem]s. The Plex `key` (folder URL)
  /// survives in [MediaItem.raw] under the `'key'` slot — see
  /// [_folderKey].
  List<MediaItem> _rootFolders = [];
  final Map<String, List<MediaItem>> _childrenCache = {};
  final Set<String> _expandedFolders = {};
  final Set<String> _loadingFolders = {};
  bool _isLoadingRoot = false;
  String? _errorMessage;

  /// Resolve the Plex folder key from a [MediaItem]'s `raw` map. The key is
  /// a relative URL (e.g. `/library/sections/1/folder?parent=...`) used as
  /// the cache key and to recursively fetch children from
  /// [PlexClient.getFolderChildren].
  String? _folderKey(MediaItem item) => item.raw?['key'] as String?;

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
      final client = context.getPlexClientForServer(widget.serverId!);

      // PlexClient.fetchLibraryFolders returns neutral [MediaItem]s; folders
      // come back already tagged with the client's serverId/serverName.
      final folders = await client.fetchLibraryFolders(widget.libraryKey);

      if (!mounted) return;

      setState(() {
        _rootFolders = folders;
        _isLoadingRoot = false;
      });

      appLogger.d('Loaded ${folders.length} root folders');
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Failed to load root folders', error: e);
      setState(() {
        _errorMessage = t.errors.failedToLoad(context: t.libraries.folders, error: e.toString());
        _isLoadingRoot = false;
      });
    }
  }

  Future<void> _loadFolderChildren(MediaItem folder) async {
    final folderKey = _folderKey(folder);
    if (folderKey == null) return;

    // Already loading this folder
    if (_loadingFolders.contains(folderKey)) return;

    // Already loaded and cached
    if (_childrenCache.containsKey(folderKey)) {
      setState(() {
        _expandedFolders.add(folderKey);
      });
      return;
    }

    setState(() {
      _loadingFolders.add(folderKey);
    });

    try {
      final client = context.getPlexClientForServer(widget.serverId!);

      // Items are automatically tagged with server info by PlexClient.
      final children = await client.fetchFolderChildren(folderKey);

      if (!mounted) return;

      setState(() {
        _childrenCache[folderKey] = children;
        _expandedFolders.add(folderKey);
        _loadingFolders.remove(folderKey);
      });

      appLogger.d('Loaded ${children.length} children for folder: ${folder.title}');
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Failed to load folder children', error: e);
      setState(() {
        _loadingFolders.remove(folderKey);
      });

      if (mounted) {
        showErrorSnackBar(context, t.errors.failedToLoad(context: t.libraries.folders, error: e.toString()));
      }
    }
  }

  void _toggleFolder(MediaItem folder) {
    final folderKey = _folderKey(folder);
    if (folderKey == null) return;
    if (_expandedFolders.contains(folderKey)) {
      setState(() {
        _expandedFolders.remove(folderKey);
      });
    } else {
      _loadFolderChildren(folder);
    }
  }

  Future<void> _handleItemTap(MediaItem item) async {
    await navigateToMediaItem(context, item, onRefresh: widget.onRefresh);
  }

  Future<void> _handleFolderPlay(MediaItem folder) async {
    final folderKey = _folderKey(folder);
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(widget.serverId!);
    final launcher = PlexPlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(folderKey: folderKey, shuffle: false);
  }

  Future<void> _handleFolderShuffle(MediaItem folder) async {
    final folderKey = _folderKey(folder);
    if (folderKey == null) return;
    final client = context.getPlexClientForServer(widget.serverId!);
    final launcher = PlexPlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(folderKey: folderKey, shuffle: true);
  }

  bool _isFolder(MediaItem item) {
    // Folders typically have no media kind (Plex returns `type: 'folder'`,
    // mapped to [MediaKind.unknown]) or expose `/folder` in their key.
    final folderKey = _folderKey(item);
    return folderKey?.contains('/folder') == true || item.kind == MediaKind.unknown;
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

      final folderKey = _folderKey(item);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        message: _errorMessage!,
        icon: Symbols.error_outline_rounded,
        onRetry: _loadRootFolders,
        retryLabel: t.common.retry,
      );
    }

    if (_rootFolders.isEmpty) {
      return EmptyStateWidget(message: t.libraries.noFoldersFound, icon: Symbols.folder_open_rounded);
    }

    final flattened = <({MediaItem item, int depth, String path})>[];
    _flattenTreeItems(_rootFolders, 0, '', flattened);

    return RefreshIndicator(
      onRefresh: _loadRootFolders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: flattened.length,
        itemBuilder: (context, index) {
          final entry = flattened[index];
          final item = entry.item;
          final isFolder = _isFolder(item);
          final folderKey = _folderKey(item);
          final isExpanded = folderKey != null && _expandedFolders.contains(folderKey);
          final isLoading = folderKey != null && _loadingFolders.contains(folderKey);
          final isFirstRootItem = index == 0;

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
            onPlayAll: isFolder ? () => _handleFolderPlay(item) : null,
            onShuffle: isFolder ? () => _handleFolderShuffle(item) : null,
            focusNode: isFirstRootItem ? widget.firstItemFocusNode : null,
            onNavigateUp: isFirstRootItem ? widget.onNavigateUp : null,
          );
        },
      ),
    );
  }
}
