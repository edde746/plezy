import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/download_progress.dart';
import '../models/download_status.dart';

/// Represents a node type in the download tree
enum DownloadNodeType { show, season, episode, movie }

/// Node in the download tree hierarchy
class DownloadTreeNode {
  final String id;
  final DownloadNodeType type;
  final String title;
  final DownloadProgress? progress;
  final List<DownloadTreeNode> children;

  // Episode-specific
  final int? episodeNumber;
  final int? seasonNumber;

  DownloadTreeNode({
    required this.id,
    required this.type,
    required this.title,
    this.progress,
    this.children = const [],
    this.episodeNumber,
    this.seasonNumber,
  });

  /// Calculate aggregate progress for shows/seasons
  int get aggregateProgress {
    if (progress != null) return progress!.progress;
    if (children.isEmpty) return 0;

    int total = 0;
    for (final child in children) {
      total += child.aggregateProgress;
    }
    return (total / children.length).round();
  }

  /// Get the status - individual or aggregate
  DownloadStatus get status {
    if (progress != null) return progress!.status;
    if (children.isEmpty) return DownloadStatus.queued;

    // Aggregate status from children
    final statuses = children.map((c) => c.status).toSet();
    if (statuses.contains(DownloadStatus.downloading))
      return DownloadStatus.downloading;
    if (statuses.contains(DownloadStatus.queued)) return DownloadStatus.queued;
    if (statuses.contains(DownloadStatus.paused)) return DownloadStatus.paused;
    if (statuses.contains(DownloadStatus.failed)) return DownloadStatus.failed;
    if (statuses.every((s) => s == DownloadStatus.completed))
      return DownloadStatus.completed;
    return DownloadStatus.queued;
  }
}

/// Widget that renders a single node in the download tree with radial progress indicator
class DownloadTreeItem extends StatelessWidget {
  final DownloadTreeNode node;
  final int depth;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onPause;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;

  const DownloadTreeItem({
    super.key,
    required this.node,
    required this.depth,
    this.isExpanded = false,
    this.onToggle,
    this.onPause,
    this.onCancel,
    this.onDelete,
    this.onResume,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final indentation = depth * 24.0;

    return Container(
      padding: EdgeInsets.only(left: indentation),
      child: InkWell(
        onTap: node.children.isNotEmpty ? onToggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            children: [
              // Expand/collapse icon for parent nodes
              if (node.children.isNotEmpty)
                _buildExpandIcon()
              else if (node.type == DownloadNodeType.episode)
                const SizedBox(width: 24), // Spacing for episodes
              // Radial progress indicator
              _buildRadialProgress(context),

              const SizedBox(width: 12),

              // Title and metadata
              Expanded(child: _buildTitleSection(context)),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: AppIcon(
        isExpanded
            ? Symbols.expand_more_rounded
            : Symbols.chevron_right_rounded,
        fill: 1,
        size: 24,
      ),
    );
  }

  Widget _buildRadialProgress(BuildContext context) {
    final size = _getProgressSize();
    final progress = node.aggregateProgress;
    final color = _getStatusColor(node.status);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.2)),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: progress / 100.0,
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          // Percentage text
          Text(
            '$progress%',
            style: TextStyle(
              fontSize: size > 30 ? 10 : 8,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    switch (node.type) {
      case DownloadNodeType.show:
        return _buildShowTitle(context);
      case DownloadNodeType.season:
        return _buildSeasonTitle(context);
      case DownloadNodeType.episode:
        return _buildEpisodeTitle(context);
      case DownloadNodeType.movie:
        return _buildMovieTitle(context);
    }
  }

  Widget _buildShowTitle(BuildContext context) {
    final episodeCount = node.children.fold<int>(
      0,
      (sum, season) => sum + season.children.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '$episodeCount episode${episodeCount != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonTitle(BuildContext context) {
    final seasonNum = node.seasonNumber ?? 1;
    return Text(
      'Season $seasonNum',
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  Widget _buildEpisodeTitle(BuildContext context) {
    final episodeNum = node.episodeNumber ?? 0;
    final episodeLabel = episodeNum.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E$episodeLabel - ${node.title}',
          style: const TextStyle(fontSize: 14),
        ),
        if (node.progress != null && node.progress!.currentFile != null)
          Text(
            node.progress!.currentFile!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }

  Widget _buildMovieTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (node.progress != null && node.progress!.currentFile != null)
          Text(
            node.progress!.currentFile!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Only show action buttons for leaf nodes (episodes/movies)
    if (node.type != DownloadNodeType.episode &&
        node.type != DownloadNodeType.movie) {
      return const SizedBox.shrink();
    }

    final status = node.status;

    switch (status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const AppIcon(Symbols.pause_rounded, fill: 1),
          onPressed: onPause,
          tooltip: 'Pause',
          iconSize: 20,
        );

      case DownloadStatus.queued:
        return IconButton(
          icon: const AppIcon(Symbols.close_rounded, fill: 1),
          onPressed: onCancel,
          tooltip: 'Cancel',
          iconSize: 20,
        );

      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
              onPressed: onResume,
              tooltip: 'Resume',
              iconSize: 20,
            ),
            IconButton(
              icon: const AppIcon(Symbols.close_rounded, fill: 1),
              onPressed: onCancel,
              tooltip: 'Cancel',
              iconSize: 20,
            ),
          ],
        );

      case DownloadStatus.completed:
        return IconButton(
          icon: const AppIcon(Symbols.delete_outline_rounded, fill: 1),
          onPressed: onDelete,
          tooltip: 'Delete',
          iconSize: 20,
        );

      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
              onPressed: onRetry,
              tooltip: 'Retry',
              iconSize: 20,
            ),
            IconButton(
              icon: const AppIcon(Symbols.delete_outline_rounded, fill: 1),
              onPressed: onDelete,
              tooltip: 'Delete',
              iconSize: 20,
            ),
          ],
        );

      case DownloadStatus.cancelled:
        return IconButton(
          icon: const AppIcon(Symbols.delete_outline_rounded, fill: 1),
          onPressed: onDelete,
          tooltip: 'Delete',
          iconSize: 20,
        );
    }
  }

  double _getProgressSize() {
    switch (node.type) {
      case DownloadNodeType.show:
      case DownloadNodeType.movie:
        return 36.0;
      case DownloadNodeType.season:
      case DownloadNodeType.episode:
        return 28.0;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.queued:
        return Colors.orange;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.amber;
      case DownloadStatus.cancelled:
        return Colors.grey;
    }
  }
}
