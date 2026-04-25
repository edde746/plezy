import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/plex_metadata.dart';
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
  List<PlexMetadata> _rootFolders = [];
  final Map<String, List<PlexMetadata>> _childrenCache = {};
  final Set<String> _expandedFolders = {};
  final Set<String> _loadingFolders = {};
  bool _isLoadingRoot = false;
  String? _errorMessage;

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
      final client = context.getClientForServer(widget.serverId!);

      final folders = await client.getLibraryFolders(widget.libraryKey);

      if (!mounted) return;

      final taggedFolders = folders
          .map(
            (folder) => folder.copyWith(
              serverId: widget.serverId!,
              serverName: null, // server name not required for folders listing
            ),
          )
          .toList();

      setState(() {
        _rootFolders = taggedFolders;
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

  Future<void> _loadFolderChildren(PlexMetadata folder) async {
    // Already loading this folder
    if (_loadingFolders.contains(folder.key!)) return;

    // Already loaded and cached
    if (_childrenCache.containsKey(folder.key!)) {
      setState(() {
        _expandedFolders.add(folder.key!);
      });
      return;
    }

    setState(() {
      _loadingFolders.add(folder.key!);
    });

    try {
      final client = context.getClientForServer(widget.serverId!);

      // Items are automatically tagged with server info by PlexClient
      final children = await client.getFolderChildren(folder.key!);

      if (!mounted) return;

      setState(() {
        _childrenCache[folder.key!] = children;
        _expandedFolders.add(folder.key!);
        _loadingFolders.remove(folder.key!);
      });

      appLogger.d('Loaded ${children.length} children for folder: ${folder.title}');
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Failed to load folder children', error: e);
      setState(() {
        _loadingFolders.remove(folder.key!);
      });

      if (mounted) {
        showErrorSnackBar(context, t.errors.failedToLoad(context: t.libraries.folders, error: e.toString()));
      }
    }
  }

  void _toggleFolder(PlexMetadata folder) {
    if (_expandedFolders.contains(folder.key!)) {
      setState(() {
        _expandedFolders.remove(folder.key!);
      });
    } else {
      _loadFolderChildren(folder);
    }
  }

  Future<void> _handleItemTap(PlexMetadata item) async {
    await navigateToMediaItem(context, item, onRefresh: widget.onRefresh);
  }

  Future<void> _handleFolderPlay(PlexMetadata folder) async {
    final client = context.getClientForServer(widget.serverId!);
    final launcher = PlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(folderKey: folder.key!, shuffle: false);
  }

  Future<void> _handleFolderShuffle(PlexMetadata folder) async {
    final client = context.getClientForServer(widget.serverId!);
    final launcher = PlayQueueLauncher(context: context, client: client, serverId: widget.serverId);
    await launcher.launchFromFolder(folderKey: folder.key!, shuffle: true);
  }

  bool _isFolder(PlexMetadata item) {
    // Folders typically don't have a specific type or might have special indicators
    // Check for common folder indicators
    return item.key?.contains('/folder') == true ||
        item.type == null ||
        item.type!.isEmpty ||
        item.mediaType == PlexMediaType.unknown;
  }

  /// Flatten the visible tree into a list of (item, depth, path) tuples so
  /// `ListView.builder` can lazy-build only the rows currently on screen.
  void _flattenTreeItems(
    List<PlexMetadata> items,
    int depth,
    String parentPath,
    List<({PlexMetadata item, int depth, String path})> out,
  ) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemPath = parentPath.isEmpty ? '$i' : '$parentPath-$i';
      out.add((item: item, depth: depth, path: itemPath));

      if (_isFolder(item) && _expandedFolders.contains(item.key) && _childrenCache.containsKey(item.key)) {
        _flattenTreeItems(_childrenCache[item.key]!, depth + 1, itemPath, out);
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

    final flattened = <({PlexMetadata item, int depth, String path})>[];
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
          final isExpanded = _expandedFolders.contains(item.key);
          final isLoading = _loadingFolders.contains(item.key);
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
