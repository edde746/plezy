import 'package:flutter/material.dart';
import '../models/plex_metadata.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../i18n/strings.g.dart';
import 'folder_tree_item.dart';
import 'empty_state_widget.dart';
import 'error_state_widget.dart';

/// Expandable tree view for browsing library folders
/// Shows a hierarchical file/folder structure
class FolderTreeView extends StatefulWidget {
  final String libraryKey;
  final String? serverId; // Server this library belongs to
  final void Function(String)? onRefresh;

  const FolderTreeView({
    super.key,
    required this.libraryKey,
    this.serverId,
    this.onRefresh,
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
        _errorMessage = t.errors.failedToLoad(
          context: t.libraries.folders,
          error: e.toString(),
        );
        _isLoadingRoot = false;
      });
    }
  }

  Future<void> _loadFolderChildren(PlexMetadata folder) async {
    // Already loading this folder
    if (_loadingFolders.contains(folder.key)) return;

    // Already loaded and cached
    if (_childrenCache.containsKey(folder.key)) {
      setState(() {
        _expandedFolders.add(folder.key);
      });
      return;
    }

    setState(() {
      _loadingFolders.add(folder.key);
    });

    try {
      final client = context.getClientForServer(widget.serverId!);

      // Items are automatically tagged with server info by PlexClient
      final children = await client.getFolderChildren(folder.key);

      if (!mounted) return;

      setState(() {
        _childrenCache[folder.key] = children;
        _expandedFolders.add(folder.key);
        _loadingFolders.remove(folder.key);
      });

      appLogger.d(
        'Loaded ${children.length} children for folder: ${folder.title}',
      );
    } catch (e) {
      if (!mounted) return;

      appLogger.e('Failed to load folder children', error: e);
      setState(() {
        _loadingFolders.remove(folder.key);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.errors.failedToLoad(
                context: t.libraries.folders,
                error: e.toString(),
              ),
            ),
          ),
        );
      }
    }
  }

  void _toggleFolder(PlexMetadata folder) {
    if (_expandedFolders.contains(folder.key)) {
      setState(() {
        _expandedFolders.remove(folder.key);
      });
    } else {
      _loadFolderChildren(folder);
    }
  }

  Future<void> _handleItemTap(
    PlexMetadata item, {
    bool isKeyboard = false,
  }) async {
    final itemType = item.type.toLowerCase();

    // For episodes, start playback directly
    if (itemType == 'episode') {
      final result = await navigateToVideoPlayer(context, metadata: item);
      if (result == true) {
        widget.onRefresh?.call(item.ratingKey);
      }
    } else if (itemType == 'season') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SeasonDetailScreen(season: item, focusFirstEpisode: isKeyboard),
        ),
      );
      widget.onRefresh?.call(item.ratingKey);
    } else {
      // For all other types (shows, movies), show detail screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(metadata: item),
        ),
      );
      if (result == true) {
        widget.onRefresh?.call(item.ratingKey);
      }
    }
  }

  bool _isFolder(PlexMetadata item) {
    // Folders typically don't have a specific type or might have special indicators
    // Check for common folder indicators
    return item.key.contains('/folder') ||
        item.type.isEmpty ||
        item.type.toLowerCase() == 'folder';
  }

  List<Widget> _buildTreeItems(
    List<PlexMetadata> items,
    int depth, [
    String parentPath = '',
  ]) {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isFolder = _isFolder(item);
      final isExpanded = _expandedFolders.contains(item.key);
      final isLoading = _loadingFolders.contains(item.key);

      // Create a unique key path that includes parent hierarchy and index
      final itemPath = parentPath.isEmpty ? '$i' : '$parentPath-$i';

      // Add the item itself
      widgets.add(
        FolderTreeItem(
          key: ValueKey(itemPath),
          item: item,
          depth: depth,
          isFolder: isFolder,
          isExpanded: isExpanded,
          isLoading: isLoading,
          onExpand: isFolder ? () => _toggleFolder(item) : null,
          onTap: !isFolder
              ? ({bool isKeyboard = false}) =>
                    _handleItemTap(item, isKeyboard: isKeyboard)
              : null,
        ),
      );

      // Add children if folder is expanded
      if (isFolder && isExpanded && _childrenCache.containsKey(item.key)) {
        final children = _childrenCache[item.key]!;
        widgets.addAll(_buildTreeItems(children, depth + 1, itemPath));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRoot) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        message: _errorMessage!,
        icon: Icons.error_outline,
        onRetry: _loadRootFolders,
        retryLabel: t.common.retry,
      );
    }

    if (_rootFolders.isEmpty) {
      return EmptyStateWidget(
        message: t.libraries.noFoldersFound,
        icon: Icons.folder_open,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRootFolders,
      child: ListView(children: _buildTreeItems(_rootFolders, 0)),
    );
  }
}
