import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../i18n/strings.g.dart';
import '../models/download_progress.dart';
import '../models/download_status.dart';
import '../models/plex_metadata.dart';

/// Represents a node in the download tree
class DownloadTreeNode {
  final String key;
  final String title;
  final DownloadNodeType type;
  final double progress; // 0.0-1.0
  final DownloadStatus status;
  final List<DownloadTreeNode> children;
  final PlexMetadata? metadata;
  final DownloadProgress? downloadProgress;

  const DownloadTreeNode({
    required this.key,
    required this.title,
    required this.type,
    this.progress = 0.0,
    required this.status,
    this.children = const [],
    this.metadata,
    this.downloadProgress,
  });

  /// Check if this node has children
  bool get hasChildren => children.isNotEmpty;

  /// Get the number of completed children
  int get completedChildrenCount {
    return children
        .where((child) => child.status == DownloadStatus.completed)
        .length;
  }

  /// Get the number of downloading children
  int get downloadingChildrenCount {
    return children
        .where((child) => child.status == DownloadStatus.downloading)
        .length;
  }
}

/// Type of node in the download tree
enum DownloadNodeType { show, season, episode, movie }

/// Hierarchical tree view for downloads
/// Groups TV shows by show -> season -> episode
/// Movies appear at top level
class DownloadTreeView extends StatefulWidget {
  final Map<String, DownloadProgress> downloads;
  final Map<String, PlexMetadata> metadata;
  final void Function(String globalKey)? onPause;
  final void Function(String globalKey)? onResume;
  final void Function(String globalKey)? onRetry;
  final void Function(String globalKey)? onCancel;
  final void Function(String globalKey)? onDelete;

  const DownloadTreeView({
    super.key,
    required this.downloads,
    required this.metadata,
    this.onPause,
    this.onResume,
    this.onRetry,
    this.onCancel,
    this.onDelete,
  });

  @override
  State<DownloadTreeView> createState() => _DownloadTreeViewState();
}

class _DownloadTreeViewState extends State<DownloadTreeView> {
  final Set<String> _expandedNodes = {};

  @override
  Widget build(BuildContext context) {
    final tree = _buildTree();
    final flattenedNodes = _flattenTree(tree);

    if (flattenedNodes.isEmpty) {
      return const Center(child: Text('No downloads'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: flattenedNodes.length,
      itemBuilder: (context, index) {
        final item = flattenedNodes[index];
        return _buildTreeItem(item.node, item.depth);
      },
    );
  }

  /// Build the download tree from flat download list
  List<DownloadTreeNode> _buildTree() {
    final Map<String, List<MapEntry<String, DownloadProgress>>> showGroups = {};
    final List<DownloadTreeNode> movies = [];

    // Group downloads
    for (final entry in widget.downloads.entries) {
      final globalKey = entry.key;
      final download = entry.value;
      final meta = widget.metadata[globalKey];

      if (meta == null) continue;

      if (meta.type.toLowerCase() == 'episode') {
        // Group episodes by show
        final showKey = meta.grandparentRatingKey ?? 'unknown';
        showGroups.putIfAbsent(showKey, () => []);
        showGroups[showKey]!.add(entry);
      } else if (meta.type.toLowerCase() == 'movie') {
        // Movies go at top level
        movies.add(
          DownloadTreeNode(
            key: globalKey,
            title: meta.title,
            type: DownloadNodeType.movie,
            progress: download.progressPercent,
            status: download.status,
            metadata: meta,
            downloadProgress: download,
          ),
        );
      }
    }

    // Build show nodes
    final List<DownloadTreeNode> shows = [];
    for (final showEntry in showGroups.entries) {
      final showKey = showEntry.key;
      final episodes = showEntry.value;

      if (episodes.isEmpty) continue;

      // Get show metadata from first episode
      final firstEpisode = widget.metadata[episodes.first.key];
      final showTitle = firstEpisode?.grandparentTitle ?? 'Unknown Show';

      // Group episodes by season
      final Map<String, List<MapEntry<String, DownloadProgress>>> seasonGroups =
          {};
      for (final episode in episodes) {
        final meta = widget.metadata[episode.key];
        if (meta == null) continue;

        final seasonKey = meta.parentRatingKey ?? 'unknown';
        seasonGroups.putIfAbsent(seasonKey, () => []);
        seasonGroups[seasonKey]!.add(episode);
      }

      // Build season nodes
      final List<DownloadTreeNode> seasons = [];
      for (final seasonEntry in seasonGroups.entries) {
        final seasonKey = seasonEntry.key;
        final seasonEpisodes = seasonEntry.value;

        if (seasonEpisodes.isEmpty) continue;

        // Get season metadata from first episode
        final firstEpisode = widget.metadata[seasonEpisodes.first.key];
        final seasonTitle = firstEpisode?.parentTitle ?? 'Unknown Season';
        final seasonNumber = firstEpisode?.parentIndex;

        // Build episode nodes
        final List<DownloadTreeNode> episodeNodes = [];
        for (final episodeEntry in seasonEpisodes) {
          final globalKey = episodeEntry.key;
          final download = episodeEntry.value;
          final meta = widget.metadata[globalKey];

          if (meta == null) continue;

          final episodeNumber = meta.index;
          final episodeTitle = episodeNumber != null
              ? 'Episode $episodeNumber - ${meta.title}'
              : meta.title;

          episodeNodes.add(
            DownloadTreeNode(
              key: globalKey,
              title: episodeTitle,
              type: DownloadNodeType.episode,
              progress: download.progressPercent,
              status: download.status,
              metadata: meta,
              downloadProgress: download,
            ),
          );
        }

        // Sort episodes by episode number only (not by status)
        episodeNodes.sort((a, b) {
          final aIndex = a.metadata?.index ?? 0;
          final bIndex = b.metadata?.index ?? 0;
          return aIndex.compareTo(bIndex);
        });

        // Calculate aggregate season progress
        final seasonProgress = episodeNodes.isEmpty
            ? 0.0
            : episodeNodes.map((e) => e.progress).reduce((a, b) => a + b) /
                  episodeNodes.length;
        final seasonStatus = _determineAggregateStatus(
          episodeNodes.map((e) => e.status).toList(),
        );

        final displayTitle = seasonNumber != null
            ? 'Season $seasonNumber'
            : seasonTitle;

        seasons.add(
          DownloadTreeNode(
            key: '$showKey:$seasonKey',
            title: displayTitle,
            type: DownloadNodeType.season,
            progress: seasonProgress,
            status: seasonStatus,
            children: episodeNodes,
          ),
        );
      }

      // Sort seasons by season number
      seasons.sort((a, b) {
        final aSeasonNum =
            widget.metadata[a.children.first.key]?.parentIndex ?? 0;
        final bSeasonNum =
            widget.metadata[b.children.first.key]?.parentIndex ?? 0;
        return aSeasonNum.compareTo(bSeasonNum);
      });

      // Calculate aggregate show progress
      final showProgress = seasons.isEmpty
          ? 0.0
          : seasons.map((s) => s.progress).reduce((a, b) => a + b) /
                seasons.length;
      final showStatus = _determineAggregateStatus(
        seasons.map((s) => s.status).toList(),
      );

      shows.add(
        DownloadTreeNode(
          key: showKey,
          title: showTitle,
          type: DownloadNodeType.show,
          progress: showProgress,
          status: showStatus,
          children: seasons,
        ),
      );
    }

    // Sort shows by status and title
    shows.sort((a, b) {
      final statusCompare = _compareByStatus(a.status, b.status);
      if (statusCompare != 0) return statusCompare;
      return a.title.compareTo(b.title);
    });

    // Sort movies by status and title
    movies.sort((a, b) {
      final statusCompare = _compareByStatus(a.status, b.status);
      if (statusCompare != 0) return statusCompare;
      return a.title.compareTo(b.title);
    });

    // Combine movies and shows
    return [...movies, ...shows];
  }

  /// Determine aggregate status from child statuses
  /// Priority: downloading > queued > paused > completed > failed
  DownloadStatus _determineAggregateStatus(List<DownloadStatus> statuses) {
    if (statuses.isEmpty) return DownloadStatus.queued;

    if (statuses.any((s) => s == DownloadStatus.downloading)) {
      return DownloadStatus.downloading;
    }
    if (statuses.any((s) => s == DownloadStatus.queued)) {
      return DownloadStatus.queued;
    }
    if (statuses.any((s) => s == DownloadStatus.paused)) {
      return DownloadStatus.paused;
    }
    if (statuses.any((s) => s == DownloadStatus.failed)) {
      return DownloadStatus.failed;
    }
    return DownloadStatus.completed;
  }

  /// Compare statuses for sorting (downloading first, then queued, etc.)
  int _compareByStatus(DownloadStatus a, DownloadStatus b) {
    const statusOrder = {
      DownloadStatus.downloading: 0,
      DownloadStatus.queued: 1,
      DownloadStatus.paused: 2,
      DownloadStatus.completed: 3,
      DownloadStatus.failed: 4,
      DownloadStatus.cancelled: 5,
    };
    return (statusOrder[a] ?? 99).compareTo(statusOrder[b] ?? 99);
  }

  /// Flatten the tree into a list of visible nodes with their depths
  List<_FlatNode> _flattenTree(List<DownloadTreeNode> nodes, [int depth = 0]) {
    final List<_FlatNode> result = [];

    for (final node in nodes) {
      result.add(_FlatNode(node: node, depth: depth));

      // Add children if node is expanded
      if (_expandedNodes.contains(node.key) && node.hasChildren) {
        result.addAll(_flattenTree(node.children, depth + 1));
      }
    }

    return result;
  }

  /// Toggle node expansion
  void _toggleExpansion(String key) {
    setState(() {
      if (_expandedNodes.contains(key)) {
        _expandedNodes.remove(key);
      } else {
        _expandedNodes.add(key);
      }
    });
  }

  /// Build a tree item widget
  Widget _buildTreeItem(DownloadTreeNode node, int depth) {
    final isExpanded = _expandedNodes.contains(node.key);
    final canExpand = node.hasChildren;

    return InkWell(
      onTap: canExpand ? () => _toggleExpansion(node.key) : null,
      child: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: _buildNodeContent(node, isExpanded, canExpand),
      ),
    );
  }

  /// Build the content for a node
  Widget _buildNodeContent(
    DownloadTreeNode node,
    bool isExpanded,
    bool canExpand,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Expand/collapse icon
          if (canExpand)
            AppIcon(
              isExpanded
                  ? Symbols.expand_more_rounded
                  : Symbols.chevron_right_rounded,
              fill: 1,
              size: 20,
            )
          else
            const SizedBox(width: 20),

          const SizedBox(width: 8),

          // Status icon
          _buildStatusIcon(node.status),

          const SizedBox(width: 12),

          // Title and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: canExpand ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (canExpand) ...[
                  const SizedBox(height: 4),
                Text(
                  _getNodeSummary(node),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],

                // Progress bar
                if (node.status == DownloadStatus.downloading ||
                    node.status == DownloadStatus.queued) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: node.progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  if (node.downloadProgress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(node.progress * 100).toStringAsFixed(1)}% - ${node.downloadProgress!.speedFormatted}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Actions
          _buildActions(node),
        ],
      ),
    );
  }

  /// Build status icon
  Widget _buildStatusIcon(DownloadStatus status) {
    IconData iconData;
    Color? color;

    switch (status) {
      case DownloadStatus.downloading:
        iconData = Symbols.downloading_rounded;
        color = Colors.blue;
        break;
      case DownloadStatus.queued:
        iconData = Symbols.schedule_rounded;
        color = Colors.orange;
        break;
      case DownloadStatus.paused:
        iconData = Symbols.pause_circle_outline_rounded;
        color = Colors.grey;
        break;
      case DownloadStatus.completed:
        iconData = Symbols.check_circle_rounded;
        color = Colors.green;
        break;
      case DownloadStatus.failed:
        iconData = Symbols.error_rounded;
        color = Colors.red;
        break;
      case DownloadStatus.cancelled:
        iconData = Symbols.cancel_rounded;
        color = Colors.grey;
        break;
      case DownloadStatus.partial:
        iconData = Symbols.downloading_rounded;
        color = Colors.orange;
        break;
    }

    return AppIcon(iconData, fill: 1, size: 20, color: color);
  }

  /// Get summary text for container nodes (shows/seasons)
  String _getNodeSummary(DownloadTreeNode node) {
    final total = node.children.length;
    final completed = node.completedChildrenCount;
    return '$completed/$total completed';
  }

  /// Build action buttons for nodes
  Widget _buildActions(DownloadTreeNode node) {
    final isContainer =
        node.type == DownloadNodeType.show ||
        node.type == DownloadNodeType.season;

    final actions = isContainer
        ? _getContainerActions(node)
        : _getItemActions(node);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  /// Get action buttons for individual items (episodes/movies)
  List<Widget> _getItemActions(DownloadTreeNode node) {
    final globalKey = node.key;
    final status = node.status;
    final actions = <Widget>[];

    // Pause button for downloading items
    if (status == DownloadStatus.downloading && widget.onPause != null) {
      actions.add(_buildActionButton(
        icon: Symbols.pause_rounded,
        tooltip: 'Pause',
        onPressed: () => widget.onPause!(globalKey),
      ));
    }

    // Resume button for paused items
    if (status == DownloadStatus.paused && widget.onResume != null) {
      actions.add(_buildActionButton(
        icon: Symbols.play_arrow_rounded,
        tooltip: 'Resume',
        onPressed: () => widget.onResume!(globalKey),
      ));
    }

    // Cancel button for downloading/queued items
    if ((status == DownloadStatus.downloading ||
            status == DownloadStatus.queued) &&
        widget.onCancel != null) {
      actions.add(_buildActionButton(
        icon: Symbols.close_rounded,
        tooltip: 'Cancel',
        onPressed: () => widget.onCancel!(globalKey),
      ));
    }

    // Retry button for failed items
    if (status == DownloadStatus.failed && widget.onRetry != null) {
      actions.add(_buildActionButton(
        icon: Symbols.refresh_rounded,
        tooltip: t.downloads.retryDownload,
        onPressed: () => widget.onRetry!(globalKey),
      ));
    }

    // Delete button for completed/failed/cancelled items
    if ((status == DownloadStatus.completed ||
            status == DownloadStatus.failed ||
            status == DownloadStatus.cancelled) &&
        widget.onDelete != null) {
      actions.add(_buildActionButton(
        icon: Symbols.delete_rounded,
        tooltip: 'Delete',
        onPressed: () => widget.onDelete!(globalKey),
      ));
    }

    return actions;
  }

  /// Get action buttons for container nodes (shows/seasons)
  List<Widget> _getContainerActions(DownloadTreeNode node) {
    final status = node.status;
    final actions = <Widget>[];

    // Pause all button - show if any children are downloading or queued
    if ((status == DownloadStatus.downloading ||
            status == DownloadStatus.queued) &&
        widget.onPause != null) {
      actions.add(_buildActionButton(
        icon: Symbols.pause_rounded,
        tooltip: 'Pause all',
        onPressed: () => _pauseAllChildren(node),
      ));
    }

    // Resume all button - show if container is paused
    if (status == DownloadStatus.paused && widget.onResume != null) {
      actions.add(_buildActionButton(
        icon: Symbols.play_arrow_rounded,
        tooltip: 'Resume all',
        onPressed: () => _resumeAllChildren(node),
      ));
    }

    // Delete all button
    if (widget.onDelete != null) {
      actions.add(_buildActionButton(
        icon: Symbols.delete_sweep_rounded,
        tooltip: 'Delete all',
        onPressed: () => _deleteAllChildren(node),
      ));
    }

    return actions;
  }

  /// Build a single action button
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: AppIcon(icon, fill: 1, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  /// Pause all active (downloading and queued) children of a container node
  void _pauseAllChildren(DownloadTreeNode node) {
    final keys = _getActiveChildKeys(node);
    for (final key in keys) {
      widget.onPause?.call(key);
    }
  }

  /// Resume all paused children of a container node
  void _resumeAllChildren(DownloadTreeNode node) {
    final keys = _getPausedChildKeys(node);
    for (final key in keys) {
      widget.onResume?.call(key);
    }
  }

  /// Get all active (downloading or queued) child keys from a container node
  List<String> _getActiveChildKeys(DownloadTreeNode node) {
    final List<String> keys = [];
    for (final child in node.children) {
      if (child.hasChildren) {
        keys.addAll(_getActiveChildKeys(child));
      } else if (child.status == DownloadStatus.downloading ||
          child.status == DownloadStatus.queued) {
        keys.add(child.key);
      }
    }
    return keys;
  }

  /// Get all paused child keys from a container node
  List<String> _getPausedChildKeys(DownloadTreeNode node) {
    final List<String> keys = [];
    for (final child in node.children) {
      if (child.hasChildren) {
        keys.addAll(_getPausedChildKeys(child));
      } else if (child.status == DownloadStatus.paused) {
        keys.add(child.key);
      }
    }
    return keys;
  }

  /// Delete all children of a container node
  void _deleteAllChildren(DownloadTreeNode node) {
    final allKeys = _getAllChildKeys(node);
    for (final key in allKeys) {
      widget.onDelete?.call(key);
    }
  }

  /// Get all leaf node keys from a container node
  List<String> _getAllChildKeys(DownloadTreeNode node) {
    final List<String> keys = [];

    for (final child in node.children) {
      if (child.hasChildren) {
        keys.addAll(_getAllChildKeys(child));
      } else {
        keys.add(child.key);
      }
    }

    return keys;
  }
}

/// Helper class to store a node with its depth in the flattened tree
class _FlatNode {
  final DownloadTreeNode node;
  final int depth;

  const _FlatNode({required this.node, required this.depth});
}
